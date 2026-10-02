const bazzerPricePresets = [10, 20, 30, 40, 50, 100, 200];
const bazzerMaxPricePaisa = 100000000; // Tk 10,00,000 per item.

String banglaNumber(Object value) => value.toString().replaceAllMapped(
  RegExp(r'[0-9]'),
  (match) => '০১২৩৪৫৬৭৮৯'[int.parse(match[0]!)],
);

String bazzerMoney(int paisa) {
  final whole = paisa ~/ 100;
  final fraction = paisa % 100;
  return '৳ ${banglaNumber(fraction == 0 ? '$whole' : '$whole.${fraction.toString().padLeft(2, '0')}')}';
}

int? parseBazzerPrice(String text) {
  const digits = '০১২৩৪৫৬৭৮৯';
  final normalized = text.trim().split('').map((c) {
    final index = digits.indexOf(c);
    return index < 0 ? c : '$index';
  }).join();
  if (!RegExp(r'^\d{1,7}(?:\.\d{1,2})?$').hasMatch(normalized)) return null;
  final parts = normalized.split('.');
  final paisa =
      int.parse(parts.first) * 100 +
      (parts.length == 2 ? int.parse(parts.last.padRight(2, '0')) : 0);
  return paisa <= bazzerMaxPricePaisa ? paisa : null;
}

/// A family shares one Bangladesh calendar day, including across time zones.
String bazzerDayKey(DateTime instant) {
  final date = instant.toUtc().add(const Duration(hours: 6));
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

bool validBazzerDayKey(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
  final date = DateTime.tryParse('${value}T00:00:00Z');
  return date != null && date.toIso8601String().substring(0, 10) == value;
}

String bazzerDayLabel(String key) {
  const months = [
    'জানুয়ারি',
    'ফেব্রুয়ারি',
    'মার্চ',
    'এপ্রিল',
    'মে',
    'জুন',
    'জুলাই',
    'আগস্ট',
    'সেপ্টেম্বর',
    'অক্টোবর',
    'নভেম্বর',
    'ডিসেম্বর',
  ];
  final parts = key.split('-').map(int.parse).toList();
  return '${banglaNumber(parts[2])} ${months[parts[1] - 1]} ${banglaNumber(parts[0])}';
}
