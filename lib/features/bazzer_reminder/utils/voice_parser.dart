import 'package:uuid/uuid.dart';

import '../models/bazzer_item_model.dart';

class VoiceParser {
  static const _uuid = Uuid();

  // ================== ১. বাংলা টেক্সট ফিক্স ==================
  static String fixBanglaText(String text) {
    final map = {
      'alu': 'আলু',
      'potol': 'পটল',
      'chini': 'চিনি',
      'dim': 'ডিম',
      'murgi': 'মুরগি',
      'mach': 'মাছ',
      'dudh': 'দুধ',
      'tel': 'তেল',
      'egg': 'ডিম',
      'sugar': 'চিনি',
      'potato': 'আলু',
      'chicken': 'মুরগি',
      'fish': 'মাছ',
      'milk': 'দুধ',
      'radhuni': 'রাধুনী',
      'masala': 'মসলা',
    };

    String fixed = text.toLowerCase();
    map.forEach((key, value) => fixed = fixed.replaceAll(key, value));
    return fixed;
  }

  // ================== ২. বাংলা সংখ্যা ও সাধারণ শব্দ → আরবি ==================
  static String normalizeNumbers(String text) {
    final numberMap = {
      'একটা': '1 টা',
      'দুটো': '2 টা',
      'তিনটা': '3 টা',
      'চারটা': '4 টা',
      'পাঁচটা': '5 টা',
      'এক': '1',
      'দুই': '2',
      'তিন': '3',
      'চার': '4',
      'পাঁচ': '5',
      'ছয়': '6',
      'সাত': '7',
      'আট': '8',
      'নয়': '9',
      'দশ': '10',
      'পনেরো': '15',
      'বিশ': '20',
      'পঁচিশ': '25',
      'ত্রিশ': '30',
      'পঞ্চাশ': '50',
      'শত': '100',
      'একশ': '100',
      'দুইশ': '200',
      'পাঁচশ': '500',
      'হাজার': '1000',
      '১': '1',
      '২': '2',
      '৩': '3',
      '৪': '4',
      '৫': '5',
      '৬': '6',
      '৭': '7',
      '৮': '8',
      '৯': '9',
      '০': '0',
    };

    String result = text;
    numberMap.forEach((bangla, arabic) {
      result = result.replaceAll(bangla, arabic);
    });
    return result;
  }

  // ================== ৩. মেইন পার্সার ==================
  static List<BazzerItem> parseVoice(String rawText) {
    String text = fixBanglaText(rawText);
    text = normalizeNumbers(text);

    final List<BazzerItem> items = [];

    final parts = text
        .split(RegExp(r'[,\.।!?;]'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty);

    for (var part in parts) {
      if (part.isEmpty) {
        continue;
      }

      final regex = RegExp(r'(.+?)\s*(\d+(?:\.\d+)?)?\s*([^\d\s]+)?$');
      final match = regex.firstMatch(part);

      if (match != null) {
        String name = match.group(1)!.trim();
        String qtyStr = (match.group(2) ?? '1').trim();
        String unit = (match.group(3) ?? 'টা').trim();

        double qty = double.tryParse(qtyStr) ?? 1.0;

        items.add(
          BazzerItem(
            id: _uuid.v4(),
            name: name,
            quantity: qty,
            unit: unit,
            category: _guessCategory(name),
            createdAt: DateTime.now(),
            addedBy: "ভয়েস",
          ),
        );
      }
    }

    return items;
  }

  // ================== ক্যাটেগরি গেস ==================
  static String _guessCategory(String name) {
    final lower = name.toLowerCase();

    if (lower.contains('আলু') ||
        lower.contains('পটল') ||
        lower.contains('বেগুন') ||
        lower.contains('শাক') ||
        lower.contains('পেঁয়াজ')) {
      return 'সবজি';
    }

    if (lower.contains('চিনি') ||
        lower.contains('দুধ') ||
        lower.contains('তেল') ||
        lower.contains('মসলা') ||
        lower.contains('রাধুনী') ||
        lower.contains('হলুদ')) {
      return 'মুদি';
    }

    if (lower.contains('মুরগি') ||
        lower.contains('মাছ') ||
        lower.contains('ডিম') ||
        lower.contains('মাংস')) {
      return 'মাংস/মাছ';
    }

    return 'নিত্যপণ্য';
  }
}
