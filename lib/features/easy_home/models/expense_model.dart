import '../utils/easy_home_format.dart';

const expenseCategories = {
  'repair': 'মেরামত',
  'electricity': 'সাধারণ বিদ্যুৎ',
  'water': 'পানি',
  'gas': 'গ্যাস',
  'salary': 'কেয়ারটেকার / নিরাপত্তা',
  'cleaning': 'পরিচ্ছন্নতা',
  'other': 'অন্যান্য',
};

/// Actual paid operating expense. Corrections retain the original entry.
class HomeExpense {
  const HomeExpense({
    required this.id,
    required this.title,
    required this.category,
    required this.amountPaisa,
    required this.date,
    required this.reference,
    required this.note,
    this.voided = false,
    this.voidReason = '',
  });
  final String id, title, category, date, reference, note, voidReason;
  final int amountPaisa;
  final bool voided;
  String get month => date.substring(0, 7);
  factory HomeExpense.fromMap(Map<String, dynamic> m) => HomeExpense(
    id: m['id'] as String,
    title: m['title'] as String,
    category: m['category'] as String,
    amountPaisa: (m['amountPaisa'] as num).toInt(),
    date: m['date'] as String,
    reference: m['reference'] as String,
    note: m['note'] as String,
    voided: m['voided'] as bool,
    voidReason: m['voidReason'] as String,
  );
}

String isoDay(DateTime date) =>
    '${monthKey(date)}-${date.day.toString().padLeft(2, '0')}';

bool validExpenseDate(String value, DateTime today) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
  final date = DateTime.tryParse(value);
  return date != null &&
      isoDay(date) == value &&
      date.year >= 2000 &&
      value.compareTo(isoDay(today)) <= 0;
}

/// Largest remainder allocation in integer paisa. Ties follow sorted flat IDs.
Map<String, int> splitUtility(int totalPaisa, Map<String, int> weights) {
  if (totalPaisa <= 0 ||
      totalPaisa > 100000000 ||
      weights.isEmpty ||
      weights.length > 200 ||
      weights.values.any((v) => v < 0 || v > 1000000)) {
    throw ArgumentError('সঠিক বিল ও ফ্ল্যাটের ব্যবহার লিখুন।');
  }
  final sum = weights.values.fold(0, (a, b) => a + b);
  if (sum == 0) {
    throw ArgumentError('অন্তত একটি ফ্ল্যাটের ব্যবহার শূন্যের বেশি দিন।');
  }
  final keys = weights.keys.toList()..sort();
  final shares = {
    for (final key in keys) key: totalPaisa * weights[key]! ~/ sum,
  };
  final left = totalPaisa - shares.values.fold(0, (a, b) => a + b);
  final priority = [...keys]
    ..sort((a, b) {
      final comparison = (totalPaisa * weights[b]! % sum).compareTo(
        totalPaisa * weights[a]! % sum,
      );
      return comparison == 0 ? a.compareTo(b) : comparison;
    });
  for (var i = 0; i < left; i++) {
    shares[priority[i]] = shares[priority[i]]! + 1;
  }
  return shares;
}
