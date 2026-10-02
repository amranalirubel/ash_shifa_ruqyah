import 'dart:async';
import 'package:ash_shifa_ruqyah/features/bazzer_reminder/models/bazzer_expense.dart';
import 'package:ash_shifa_ruqyah/features/bazzer_reminder/repositories/bazzer_repository.dart';
import 'package:ash_shifa_ruqyah/features/bazzer_reminder/screens/bazzer_monthly_expenses_page.dart';
import 'package:ash_shifa_ruqyah/features/bazzer_reminder/utils/bazzer_receipt.dart';
import 'package:ash_shifa_ruqyah/features/bazzer_reminder/widgets/bazzer_item_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'bazzer_price_flow_test.dart' show product, openPrices, reveal, textAt;
import 'support/fake_bazzer.dart';

void main() {
  test(
    'daily expense separates secure amounts and refuses incomplete data',
    () {
      final normal = product('a', 'রসুন', price: 2500);
      final secure = product('b', 'আদা', price: 3500, secure: true);
      final draft = BazzerExpenseDraft.fromNote(
        BazzerDailyNote('2026-09-24', [normal, secure]),
      );
      expect(draft.sharedPaisa, 2500);
      expect(draft.sharedCount, 1);
      expect(draft.totalPaisa, 6000);
      expect(draft.itemCount, 2);
      expect(
        () => BazzerExpenseDraft.fromNote(
          BazzerDailyNote('2026-09-25', [normal]),
        ),
        throwsFormatException,
      );
      expect(
        () => BazzerExpenseDraft.fromNote(
          BazzerDailyNote('2026-09-24', [product('c', 'তেল')]),
        ),
        throwsFormatException,
      );
      expect(
        () => BazzerExpenseDraft.fromNote(
          BazzerDailyNote('2026-09-24', [
            normal.copyWith(hasPendingWrites: true),
          ]),
        ),
        throwsFormatException,
      );
      expect(
        BazzerExpenseDraft.fromNote(
          BazzerDailyNote('2026-09-24', [normal.copyWith(pricePaisa: 0)]),
        ).totalPaisa,
        0,
      );
    },
  );

  testWidgets('presets, rapid plus five and reset operate in one compact row', (
    tester,
  ) async {
    final repo = FakeBazzerRepository(owner: true);
    repo.items.add(product('a', 'রসুন', price: 2000));
    await openPrices(tester, repo);
    tester.view.physicalSize = const Size(360, 1100);
    await tester.pumpAndSettle();
    final plus = find.byKey(const ValueKey('plus-five-false-a'));
    final reset = find.byKey(const ValueKey('reset-price-false-a'));
    await reveal(tester, plus);
    final controls = [
      for (final price in [10, 20, 30, 40, 50, 100, 200])
        find.byKey(ValueKey('price-false-a-$price')),
      plus,
      reset,
    ];
    final y = tester.getCenter(controls.first).dy;
    for (final control in controls) {
      expect(tester.getCenter(control).dy, closeTo(y, 0.1));
      expect(control.hitTestable(), findsOneWidget);
    }
    expect(tester.getSize(find.byType(BazzerItemTile)).height, lessThan(130));
    repo.priceGate = Completer<void>();
    await tester.tap(plus);
    await tester.tap(plus); // Both taps before a rebuild must accumulate.
    await tester.pumpAndSettle();
    expect(textAt(tester, 'item-price-false-a'), '৳ ৩০');
    expect(repo.priceWrites, [('a', 2500), ('a', 3000)]);
    final save = find.byKey(const ValueKey('save-2026-09-24-false'));
    await reveal(tester, save);
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    repo.priceGate!.complete();
    await tester.pumpAndSettle();
    repo.priceGate = null;
    await tester.tap(reset);
    await tester.pumpAndSettle();
    expect(repo.items.single.pricePaisa, 0);
    expect(textAt(tester, 'item-price-false-a'), '৳ ০');
    await tester.tap(find.byKey(const ValueKey('price-false-a-40')));
    await tester.pumpAndSettle();
    await tester.tap(plus);
    await tester.pumpAndSettle();
    expect(textAt(tester, 'item-price-false-a'), '৳ ৪৫');
    expect(find.text('এ পর্যন্ত'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'saving the full day is idempotent and updates a previous snapshot',
    (tester) async {
      final repo = FakeBazzerRepository(owner: true);
      repo.items.addAll([
        product('a', 'চাল', price: 1000, category: 'মুদি'),
        product('b', 'আদা', price: 2000, bought: true),
        product('c', 'রসুন', price: 3000, secure: true),
      ]);
      await openPrices(tester, repo);
      await tester.tap(find.widgetWithText(ChoiceChip, 'সবজি'));
      await tester.pumpAndSettle();
      final save = find.byKey(const ValueKey('save-2026-09-24-false'));
      await reveal(tester, save);
      expect(textAt(tester, 'total-2026-09-24-false'), '৳ ৬০');
      repo.expenseGate = Completer<void>();
      await tester.tap(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(repo.expenseWrites.length, 1);
      expect(repo.expenseWrites.single.sharedPaisa, 3000);
      expect(repo.expenseWrites.single.totalPaisa, 6000);
      repo.expenseGate!.complete();
      await tester.pumpAndSettle();
      repo.expenseGate = null;
      expect(find.text('Saved'), findsOneWidget);
      final plus = find.byKey(const ValueKey('plus-five-true-c'));
      await reveal(tester, plus);
      await tester.tap(plus);
      await tester.pumpAndSettle();
      expect(
        repo.adminExpenses.values.single.totalPaisa,
        6000,
      ); // Saved snapshot stays stable.
      await reveal(tester, save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(repo.adminExpenses.length, 1);
      expect(repo.adminExpenses.values.single.totalPaisa, 6500);
      expect(repo.sharedExpenses.values.single.totalPaisa, 3000);
      await tester.tap(find.byTooltip('মাসিক খরচ'));
      await tester.pumpAndSettle();
      expect(find.byType(BazzerMonthlyExpensesPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('save failure is visible and permits a retry', (tester) async {
    final repo = FakeBazzerRepository(owner: true)..failExpense = true;
    repo.items.add(product('a', 'রসুন', price: 2500));
    await openPrices(tester, repo);
    final save = find.byKey(const ValueKey('save-2026-09-24-false'));
    await reveal(tester, save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.textContaining('হিসাব সেভ হয়নি।'), findsOneWidget);
    expect(repo.adminExpenses, isEmpty);
    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
    repo.failExpense = false;
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(repo.adminExpenses.values.single.totalPaisa, 2500);
  });

  testWidgets(
    'missing prices and ordinary members cannot finalize family expenses',
    (tester) async {
      final repo = FakeBazzerRepository();
      repo.items.add(product('a', 'রসুন'));
      await openPrices(tester, repo);
      final save = find.byKey(const ValueKey('save-2026-09-24-false'));
      await reveal(tester, save);
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      await repo.setPrice('family', repo.items.single, 0);
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      expect(repo.expenseWrites, isEmpty);
    },
  );

  testWidgets(
    'monthly history groups dates, switches years and hides secure totals on revocation',
    (tester) async {
      final repo = FakeBazzerRepository();
      addTearDown(repo.dispose);
      repo.member = const BazzerMember(
        uid: 'member',
        name: 'Test',
        active: true,
        role: 'admin',
      );
      repo.sharedExpenses['2026-01-02'] = const BazzerExpense(
        day: '2026-01-02',
        totalPaisa: 2000,
        itemCount: 1,
      );
      repo.adminExpenses['2026-01-02'] = const BazzerExpense(
        day: '2026-01-02',
        totalPaisa: 9500,
        itemCount: 2,
      );
      repo.adminExpenses['2026-01-01'] = const BazzerExpense(
        day: '2026-01-01',
        totalPaisa: 500,
        itemCount: 1,
      );
      repo.adminExpenses['2025-12-31'] = const BazzerExpense(
        day: '2025-12-31',
        totalPaisa: 3000,
        itemCount: 1,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: BazzerMonthlyExpensesPage(
            repository: repo,
            familyId: 'family',
            initialMonth: '2026-01',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(textAt(tester, 'monthly-total'), '৳ ১০০');
      expect(find.byKey(const ValueKey('expense-2025-12-31')), findsNothing);
      await tester.tap(find.byTooltip('আগের মাস'));
      await tester.pumpAndSettle();
      expect(textAt(tester, 'expense-month'), 'ডিসেম্বর ২০২৫');
      expect(textAt(tester, 'monthly-total'), '৳ ৩০');
      await tester.tap(find.byTooltip('পরের মাস'));
      await tester.pumpAndSettle();
      repo.updateMember(
        const BazzerMember(uid: 'member', name: 'Test', active: true),
      );
      await tester.pumpAndSettle();
      expect(textAt(tester, 'monthly-total'), '৳ ২০');
      expect(find.text('৳ ৯৫'), findsNothing);
      expect(find.textContaining('Normal ও Secure'), findsNothing);
      repo.updateMember(
        const BazzerMember(uid: 'member', name: 'Test', active: false),
      );
      await tester.pumpAndSettle();
      expect(find.text('এই পরিবারের হিসাব দেখার অনুমতি নেই।'), findsOneWidget);
      expect(find.byKey(const ValueKey('monthly-total')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
