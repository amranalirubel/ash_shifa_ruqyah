import 'package:ash_shifa_ruqyah/features/easy_home/models/easy_home_models.dart';
import 'package:ash_shifa_ruqyah/features/easy_home/utils/easy_home_reports.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'utility shares conserve every paisa with stable remainder allocation',
    () {
      expect(splitUtility(100, {'c': 1, 'a': 1, 'b': 1}), {
        'a': 34,
        'b': 33,
        'c': 33,
      });
      expect(splitUtility(101, {'a': 0, 'b': 1, 'c': 3}), {
        'a': 0,
        'b': 25,
        'c': 76,
      });
      expect(splitUtility(1, {'b': 1, 'a': 1}), {'a': 1, 'b': 0});
      for (var total = 1; total < 500; total += 7) {
        final shares = splitUtility(total, {'c': 12, 'a': 7, 'b': 0, 'd': 1});
        expect(shares.values.reduce((a, b) => a + b), total);
        expect(shares['b'], 0);
      }
      expect(() => splitUtility(100, {}), throwsArgumentError);
      expect(() => splitUtility(100, {'a': 0}), throwsArgumentError);
      expect(() => splitUtility(100, {'a': -1}), throwsArgumentError);
      expect(() => splitUtility(100000001, {'a': 1}), throwsArgumentError);
    },
  );
  test('dates reject future dates and normalized impossible days', () {
    expect(validExpenseDate('2026-02-30', DateTime(2026, 10, 2)), isFalse);
    expect(validExpenseDate('2026-10-03', DateTime(2026, 10, 2)), isFalse);
    expect(validExpenseDate('2024-02-29', DateTime(2026, 10, 2)), isTrue);
  });
  test(
    'report separates invoice month from expense date and excludes voids',
    () {
      final rents = [
        RentModel(
          id: 'r',
          tenantId: 't',
          flatCode: '2B',
          month: '2026-10',
          amountPaisa: 10001,
          paidPaisa: 3001,
          dueDate: DateTime(2026, 10, 5),
          createdAt: DateTime(2026),
        ),
      ];
      HomeExpense expense(String id, String date, {bool voided = false}) =>
          HomeExpense(
            id: id,
            title: '=FORMULA',
            category: 'repair',
            amountPaisa: 100,
            date: date,
            reference: '+123',
            note: '',
            voided: voided,
          );
      final report = HomeMonthReport('2026-10', rents, [
        expense('1', '2026-10-02'),
        expense('2', '2026-10-02', voided: true),
        expense('3', '2026-09-02'),
      ]);
      expect(report.billed, 10001);
      expect(report.collected, 3001);
      expect(report.due, 7000);
      expect(report.spent, 100);
      expect(report.byCategory['repair'], 100);
      final csv = homeReportCsv('2026-10', report);
      expect(csv, contains("'=FORMULA"));
      expect(csv, contains("'+123"));
      expect(csv, contains('100.01'));
      expect(csv, contains('30.01'));
      expect(csvCell('a,"b\nc'), '"a,""b\nc"');
      expect(csvCell(' \t=cmd'), '"\' \t=cmd"');
      expect(
        homeReportText('Home', '2026-10', report, cached: true),
        contains('সর্বশেষ নাও হতে পারে'),
      );
      expect(
        homeReportText('Home', '2026-10', report, includeExpenses: false),
        isNot(contains('বাড়ির খরচ:')),
      );
    },
  );
}
