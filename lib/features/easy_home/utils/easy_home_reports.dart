import '../models/easy_home_models.dart';
import 'easy_home_format.dart';

class HomeMonthReport {
  HomeMonthReport(
    String month,
    List<RentModel> rents,
    List<HomeExpense> expenses,
  ) : rents = rents.where((r) => r.month == month).toList()
        ..sort((a, b) => a.flatCode.compareTo(b.flatCode)),
      expenses = expenses.where((e) => e.month == month && !e.voided).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
  final List<RentModel> rents;
  final List<HomeExpense> expenses;
  int get billed => rents.fold(0, (sum, r) => sum + r.amountPaisa);
  int get collected => rents.fold(0, (sum, r) => sum + r.paidPaisa);
  int get due => billed - collected;
  int get spent => expenses.fold(0, (sum, e) => sum + e.amountPaisa);
  Map<String, int> get byCategory => {
    for (final key in expenseCategories.keys)
      key: expenses
          .where((e) => e.category == key)
          .fold(0, (sum, e) => sum + e.amountPaisa),
  };
}

String homeReportText(
  String homeName,
  String month,
  HomeMonthReport report, {
  bool cached = false,
  bool includeExpenses = true,
}) =>
    '$homeName • ${monthText(month)}\nমাসিক হিসাব\n'
    '${cached ? 'ডিভাইসে সংরক্ষিত তথ্য — সর্বশেষ নাও হতে পারে\n' : ''}'
    'ভাড়ার বিল: ${money(report.billed)}\nএই বিলগুলোর জমা: ${money(report.collected)}\nবকেয়া: ${money(report.due)}\n'
    '${includeExpenses ? 'এই মাসে দেওয়া বাড়ির খরচ: ${money(report.spent)}\n' : ''}\n'
    '${report.rents.map((r) => '${r.flatCode} • বিল ${money(r.amountPaisa)} • জমা ${money(r.paidPaisa)} • বকেয়া ${money(r.duePaisa)}').join('\n')}\n\n'
    '${report.expenses.map((e) => '${e.date} • ${e.title} • ${money(e.amountPaisa)}').join('\n')}\n\n'
    'জমা বিলের মাস অনুযায়ী; টাকা হাতে পাওয়ার মাস অনুযায়ী নয়। এটি লাভ বা ক্যাশ-ফ্লো রিপোর্ট নয়।\nEasyHome';

/// Quote every field and neutralize spreadsheet formulas in user-written text.
String csvCell(String value) {
  final safe = RegExp(r'^[\s]*[=+@\-]').hasMatch(value) ? "'$value" : value;
  return '"${safe.replaceAll('"', '""')}"';
}

String homeReportCsv(
  String month,
  HomeMonthReport report, {
  bool cached = false,
}) {
  final rows = <List<String>>[
    [
      'EasyHome',
      month,
      'Invoice-month rent balances, not cash flow',
      cached ? 'Cached data' : '',
    ],
    [
      'Type',
      'Date / month',
      'Flat / description',
      'Category',
      'Billed BDT',
      'Paid BDT',
      'Due BDT',
      'Expense BDT',
      'Reference',
    ],
    for (final r in report.rents)
      [
        'rent',
        r.month,
        r.flatCode,
        '',
        moneyInput(r.amountPaisa),
        moneyInput(r.paidPaisa),
        moneyInput(r.duePaisa),
        '',
        r.id,
      ],
    for (final e in report.expenses)
      [
        'expense',
        e.date,
        e.title,
        expenseCategories[e.category] ?? e.category,
        '',
        '',
        '',
        moneyInput(e.amountPaisa),
        e.reference,
      ],
  ];
  return '\uFEFF${rows.map((r) => r.map(csvCell).join(',')).join('\r\n')}';
}
