import 'package:uuid/uuid.dart';

import '../models/bazzer_item_model.dart';
import 'store_category.dart';

class VoiceParseResult {
  const VoiceParseResult({required this.items, required this.needsReview});

  final List<BazzerItem> items;
  final List<String> needsReview;
}

/// A deterministic Bengali grocery parser. Recognition itself is provided by
/// the device; users review the parsed results before any shared write.
class VoiceParser {
  static const _uuid = Uuid();
  static const _digits = '০১২৩৪৫৬৭৮৯';
  static const _units = {
    'কেজি': 'কেজি',
    'কিলো': 'কেজি',
    'গ্রাম': 'গ্রাম',
    'লিটার': 'লিটার',
    'মিলি': 'মিলি',
    'মিলিলিটার': 'মিলি',
    'টা': 'টা',
    'টি': 'টা',
    'পিস': 'টা',
    'হালি': 'হালি',
    'ডজন': 'ডজন',
    'প্যাক': 'প্যাকেট',
    'প্যাকেট': 'প্যাকেট',
    'আঁটি': 'আঁটি',
    'আটি': 'আঁটি',
    'বোতল': 'বোতল',
  };
  static const _numbers = {
    'আধা': '0.5',
    'অর্ধেক': '0.5',
    'হাফ': '0.5',
    'দেড়': '1.5',
    'দেড়': '1.5',
    'এক': '1',
    'একটা': '1 টা',
    'একটি': '1 টা',
    'দুই': '2',
    'দুইটা': '2 টা',
    'দুটো': '2 টা',
    'দুটি': '2 টা',
    'তিন': '3',
    'তিনটা': '3 টা',
    'চার': '4',
    'চারটা': '4 টা',
    'পাঁচ': '5',
    'পাঁচটা': '5 টা',
    'ছয়': '6',
    'ছয়': '6',
    'সাত': '7',
    'আট': '8',
    'নয়': '9',
    'নয়': '9',
    'দশ': '10',
  };
  static const _latinAliases = {
    'alu': 'আলু',
    'tel': 'তেল',
    'chini': 'চিনি',
    'potol': 'পটল',
    'dim': 'ডিম',
    'soap': 'সাবান',
  };

  static String fixBanglaText(String text) {
    var result = text.toLowerCase().trim();
    for (final alias in _latinAliases.entries) {
      result = result.replaceAll(
        RegExp('\\b${RegExp.escape(alias.key)}\\b', caseSensitive: false),
        alias.value,
      );
    }
    for (final alias in StoreCategory.aliases.entries) {
      result = result.replaceAll(alias.key, alias.value);
    }
    return result.replaceAll(RegExp(r'\s+'), ' ');
  }

  static String normalizeNumbers(String text) {
    var result = text.split('').map((c) {
      final index = _digits.indexOf(c);
      return index < 0 ? c : index.toString();
    }).join();

    result = result.replaceAllMapped(
      RegExp(r'(^|[\s,;।])(সাড়ে|সাড়ে)\s+(\d+|এক|দুই|তিন)(?=\s|$)'),
      (match) {
        final n =
            {'এক': 1, 'দুই': 2, 'তিন': 3}[match.group(3)] ??
            int.tryParse(match.group(3) ?? '') ??
            0;
        return '${match.group(1)}${n + 0.5}';
      },
    );
    final keys = _numbers.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final word in keys) {
      result = result.replaceAllMapped(
        RegExp('(^|[\\s,;।])${RegExp.escape(word)}(?=\\s|\$)'),
        (match) => '${match.group(1)}${_numbers[word]}',
      );
    }
    return result;
  }

  static VoiceParseResult parsePreview(String rawText) {
    final text = normalizeNumbers(fixBanglaText(rawText));
    final items = <BazzerItem>[];
    final needsReview = <String>[];
    final names = StoreCategory.productCategories.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    final namePattern = RegExp(
      '(^|\\s)(${names.map(RegExp.escape).join('|')})(?=\\s|[0-9]|\$)',
    );

    for (final clause in text.split(
      RegExp(r'[,;।!?\n]|\s+(?:এবং|আর|তারপর)\s+'),
    )) {
      final clean = clause.trim();
      if (clean.isEmpty) continue;

      final matches = namePattern.allMatches(clean).toList();
      if (matches.isEmpty) {
        _parseFragment(clean, null, items, needsReview);
        continue;
      }

      final prefix = clean.substring(0, matches.first.start).trim();
      for (var i = 0; i < matches.length; i++) {
        final match = matches[i];
        final from = match.start + (match.group(1)?.length ?? 0);
        final until = i + 1 < matches.length
            ? matches[i + 1].start
            : clean.length;
        final fragment = [
          if (i == 0 && prefix.isNotEmpty) prefix,
          clean.substring(from, until).trim(),
        ].join(' ');
        _parseFragment(fragment, match.group(2), items, needsReview);
      }
    }

    return VoiceParseResult(items: items, needsReview: needsReview);
  }

  static List<BazzerItem> parseVoice(String rawText) =>
      parsePreview(rawText).items;

  static void _parseFragment(
    String fragment,
    String? knownName,
    List<BazzerItem> items,
    List<String> needsReview,
  ) {
    const unitPattern =
        r'মিলিলিটার|প্যাকেট|লিটার|বোতল|কেজি|কিলো|গ্রাম|মিলি|ডজন|হালি|প্যাক|আঁটি|আটি|পিস|টা|টি';
    final quantities = RegExp(
      '(\\d+(?:\\.\\d+)?)\\s*($unitPattern)(?=\\s|\$)',
    ).allMatches(fragment).toList();
    final extraNumbers = RegExp(r'\d+(?:\.\d+)?').allMatches(fragment).length;
    if (quantities.length > 1 || extraNumbers > 1) {
      needsReview.add(fragment.trim());
      return;
    }
    if (extraNumbers == 1 && quantities.isEmpty) {
      // A unitless quantity may be pieces, but 0.5 pieces is never inferred.
      final number = RegExp(r'\d+(?:\.\d+)?').firstMatch(fragment)!;
      final value = double.tryParse(number.group(0) ?? '');
      if (value == null || value <= 0 || value > 1000 || value % 1 != 0) {
        needsReview.add(fragment.trim());
        return;
      }
      if (knownName != null &&
          _unexpectedWords(fragment, knownName, number.group(0))) {
        needsReview.add(fragment.trim());
        return;
      }
      final name =
          knownName ??
          fragment.replaceRange(number.start, number.end, '').trim();
      _appendItem(name, value, 'টা', fragment, items, needsReview);
      return;
    }

    final quantity = quantities.isEmpty ? null : quantities.single;
    final value = double.tryParse(quantity?.group(1) ?? '1');
    final unit = _units[quantity?.group(2)] ?? 'টা';
    if (knownName != null &&
        _unexpectedWords(fragment, knownName, quantity?.group(0))) {
      needsReview.add(fragment.trim());
      return;
    }
    final name =
        knownName ??
        (quantity == null
            ? fragment.trim()
            : fragment.replaceRange(quantity.start, quantity.end, '').trim());
    if (value == null ||
        value <= 0 ||
        value > 1000 ||
        (unit == 'টা' && value % 1 != 0)) {
      needsReview.add(fragment.trim());
      return;
    }
    _appendItem(name, value, unit, fragment, items, needsReview);
  }

  static void _appendItem(
    String rawName,
    double quantity,
    String unit,
    String fragment,
    List<BazzerItem> items,
    List<String> needsReview,
  ) {
    final name = rawName
        .replaceAll(
          RegExp(
            r'(^|\s)(আমাকে|আমাদের|জন্য|নাও|দাও|লাগবে|'
            r'নিতে|হবে|কিনবে|দরকার)(?=\s|$)',
          ),
          ' ',
        )
        .trim();
    if (name.isEmpty || name.length > 120 || RegExp(r'\d').hasMatch(name)) {
      needsReview.add(fragment.trim());
      return;
    }
    items.add(
      BazzerItem(
        id: _uuid.v4(),
        name: name,
        quantity: quantity,
        unit: unit,
        category: StoreCategory.guess(name),
        createdAt: DateTime.now(),
      ),
    );
  }

  static bool _unexpectedWords(
    String fragment,
    String knownName,
    String? amount,
  ) {
    var rest = fragment.replaceFirst(knownName, '');
    if (amount != null) rest = rest.replaceFirst(amount, '');
    rest = rest.replaceAll(
      RegExp(
        r'(^|\s)(আমাকে|আমাদের|জন্য|কিছু|নাও|দাও|লাগবে|'
        r'নিতে|হবে|কিনবে|দরকার)(?=\s|$)',
      ),
      ' ',
    );
    return rest.trim().isNotEmpty;
  }
}
