import 'package:ash_shifa_ruqyah/features/bazzer_reminder/repositories/bazzer_repository.dart';
import 'package:ash_shifa_ruqyah/features/bazzer_reminder/widgets/bazzer_item_tile.dart';
import 'package:ash_shifa_ruqyah/features/bazzer_reminder/widgets/bazzer_price_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'bazzer_price_flow_test.dart'
    show product, openPrices, reveal, selectPrice, textAt;
import 'support/fake_bazzer.dart';

Finder control(String key) => find.byKey(ValueKey(key));

void expectNoSelection(WidgetTester tester) {
  expect(textAt(tester, 'price-panel-selected'), 'আইটেম বেছে নিন');
  for (final key in [
    'price-preset-20',
    'price-plus-five',
    'price-reset',
    'price-panel-custom',
  ]) {
    expect(tester.widget<TextButton>(control(key)).onPressed, isNull);
  }
}

void main() {
  testWidgets('one shared panel targets only the explicitly selected item', (
    tester,
  ) async {
    final repo = FakeBazzerRepository(owner: true);
    repo.items.addAll([
      product('a', 'রসুন', price: 1000),
      product('b', 'আদা', price: 1000),
      product('c', 'চাল', price: 5000, bought: true),
    ]);
    await openPrices(tester, repo);
    expect(find.byType(BazzerPricePanel), findsOneWidget);
    for (final price in [10, 20, 30, 40, 50, 100, 200]) {
      expect(control('price-preset-$price'), findsOneWidget);
    }
    expectNoSelection(tester);
    await tester.tap(control('price-preset-20'));
    expect(repo.priceWrites, isEmpty);
    await selectPrice(tester, 'a');
    expect(textAt(tester, 'price-panel-selected'), 'রসুন');
    expect(
      tester
          .widgetList<BazzerItemTile>(find.byType(BazzerItemTile))
          .where((tile) => tile.selected)
          .single
          .item
          .id,
      'a',
    );
    await tester.tap(control('price-preset-20'));
    await tester.pumpAndSettle();
    await tester.tap(control('price-plus-five'));
    await tester.pumpAndSettle();
    await selectPrice(tester, 'b');
    await tester.tap(control('price-preset-30'));
    await tester.pumpAndSettle();
    await tester.tap(control('price-plus-five'));
    await tester.pumpAndSettle();
    expect(repo.items.map((item) => item.pricePaisa), [2500, 3500, 5000]);
    expect(textAt(tester, 'price-panel-amount'), '৳ ৩৫');
    await reveal(tester, control('total-2026-09-24-false'));
    expect(textAt(tester, 'total-2026-09-24-false'), '৳ ১১০');
    await tester.tap(find.byTooltip('নির্বাচন বাতিল'));
    await tester.pumpAndSettle();
    expectNoSelection(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'shop and tab changes clear selection before further price taps',
    (tester) async {
      final repo = FakeBazzerRepository(owner: true);
      repo.items.addAll([
        product('a', 'রসুন', price: 2000),
        product('b', 'চাল', price: 3000, category: 'মুদি'),
        product('c', 'আদা', price: 4000, bought: true),
      ]);
      await openPrices(tester, repo);
      await selectPrice(tester, 'a');
      await reveal(tester, find.widgetWithText(ChoiceChip, 'মুদি'));
      await tester.tap(find.widgetWithText(ChoiceChip, 'মুদি'));
      await tester.pumpAndSettle();
      expectNoSelection(tester);
      await selectPrice(tester, 'b');
      await tester.tap(find.text('কেনা হয়েছে'));
      await tester.pumpAndSettle();
      expectNoSelection(tester);
      await selectPrice(tester, 'c');
      await tester.tap(control('price-preset-50'));
      await tester.pumpAndSettle();
      expect(repo.priceWrites, [('c', 5000)]);
      await tester.tap(find.text('কেনা বাকি'));
      await tester.pumpAndSettle();
      expectNoSelection(tester);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('search keyboard hides the panel and preserves focus and text', (
    tester,
  ) async {
    final repo = FakeBazzerRepository(owner: true);
    repo.items.add(product('a', 'রসুন', price: 2000));
    await openPrices(tester, repo);
    await selectPrice(tester, 'a');
    final subscriptions = Map.of(repo.streamCalls);
    final search = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'বাজারের জিনিস খুঁজুন',
    );
    await tester.ensureVisible(search);
    await tester.pumpAndSettle();
    final before = tester
        .widget<EditableText>(
          find.descendant(of: search, matching: find.byType(EditableText)),
        )
        .focusNode;
    addTearDown(tester.view.resetViewInsets);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.enterText(search, 'রসু');
    await tester.pumpAndSettle();
    await tester.enterText(search, 'রসুন');
    await tester.pumpAndSettle();
    expect(find.byType(BazzerPricePanel), findsNothing);
    final field = tester.widget<EditableText>(
      find.descendant(of: search, matching: find.byType(EditableText)),
    );
    expect(field.focusNode, same(before));
    expect(field.focusNode.hasFocus, isTrue);
    expect(field.controller.text, 'রসুন');
    expect(repo.streamCalls, subscriptions);
    field.focusNode.unfocus();
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expectNoSelection(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'buying or deleting the selected item disables its price controls',
    (tester) async {
      final repo = FakeBazzerRepository(owner: true);
      repo.items.addAll([product('a', 'রসুন'), product('b', 'আদা')]);
      await openPrices(tester, repo);
      await selectPrice(tester, 'a');
      final checkbox = find.descendant(
        of: control('select-price-false-a'),
        matching: find.byType(Checkbox),
      );
      await tester.tap(checkbox);
      await tester.pumpAndSettle();
      expectNoSelection(tester);
      expect(repo.items.first.isBought, isTrue);
      await selectPrice(tester, 'b');
      await repo.deleteItem('family', repo.items.last);
      await tester.pumpAndSettle();
      expectNoSelection(tester);
      expect(repo.priceWrites, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'revoked admin selection cannot reveal or change a private price',
    (tester) async {
      final repo = FakeBazzerRepository();
      repo.member = const BazzerMember(
        uid: 'member',
        name: 'Test',
        active: true,
        role: 'admin',
      );
      repo.items.addAll([
        product('a', 'নিজের রসুন', price: 2000),
        product('b', 'অন্যের চাল', author: 'other', price: 3000),
        product('s', 'গোপন বাজার', author: 'other', secure: true, price: 9000),
      ]);
      await openPrices(tester, repo);
      await selectPrice(tester, 's', secure: true);
      expect(textAt(tester, 'price-panel-selected'), 'গোপন বাজার');
      repo.updateMember(
        const BazzerMember(uid: 'member', name: 'Test', active: true),
      );
      await tester.pumpAndSettle();
      expectNoSelection(tester);
      expect(find.text('গোপন বাজার'), findsNothing);
      expect(find.text('৳ ৯০'), findsNothing);
      await selectPrice(tester, 'b');
      expectNoSelection(tester);
      await selectPrice(tester, 'a');
      await tester.tap(control('price-plus-five'));
      await tester.pumpAndSettle();
      expect(repo.priceWrites, [('a', 2500)]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'custom price cannot update a deleted target after the dialog opens',
    (tester) async {
      final repo = FakeBazzerRepository();
      repo.items.add(product('a', 'রসুন', price: 2000));
      await openPrices(tester, repo);
      await selectPrice(tester, 'a');
      await tester.tap(control('price-panel-custom'));
      await tester.pumpAndSettle();
      await tester.enterText(control('bazzer-custom-price'), '৩৫');
      await repo.deleteItem('family', repo.items.single);
      await tester.pumpAndSettle();
      await tester.tap(find.text('দাম রাখুন'));
      await tester.pumpAndSettle();
      expect(repo.priceWrites, isEmpty);
      expectNoSelection(tester);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'the shared panel stays fixed and never covers the final Save button',
    (tester) async {
      final repo = FakeBazzerRepository(owner: true);
      repo.items.addAll(
        List.generate(20, (i) => product('item-$i', 'বাজার $i', price: 1000)),
      );
      await openPrices(tester, repo);
      await selectPrice(tester, 'item-0');
      final panelTop = tester.getTopLeft(control('bazzer-price-panel')).dy;
      await selectPrice(tester, 'item-19');
      final save = control('save-2026-09-24-false');
      await reveal(tester, save);
      expect(tester.getTopLeft(control('bazzer-price-panel')).dy, panelTop);
      expect(tester.getBottomRight(save).dy, lessThanOrEqualTo(panelTop));
      expect(save.hitTestable(), findsOneWidget);
      expect(textAt(tester, 'price-panel-selected'), 'বাজার 19');
      expect(find.byType(BazzerPricePanel), findsOneWidget);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(repo.expenseWrites.single.totalPaisa, 20000);
      expect(tester.takeException(), isNull);
    },
  );
}
