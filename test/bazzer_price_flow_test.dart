import 'dart:async';

import 'package:ash_shifa_ruqyah/features/bazzer_reminder/models/bazzer_item_model.dart';
import 'package:ash_shifa_ruqyah/features/bazzer_reminder/screens/bazzer_reminder_page.dart';
import 'package:ash_shifa_ruqyah/features/bazzer_reminder/services/voice_service.dart';
import 'package:ash_shifa_ruqyah/features/bazzer_reminder/widgets/bazzer_daily_list.dart';
import 'package:ash_shifa_ruqyah/features/bazzer_reminder/widgets/bazzer_item_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_bazzer.dart';

BazzerItem product(
  String id,
  String name, {
  int? price,
  bool secure = false,
  String author = 'member',
  bool bought = false,
  String category = 'সবজি',
}) => BazzerItem(
  id: id,
  name: name,
  quantity: 1,
  unit: 'কেজি',
  category: category,
  createdAt: DateTime.utc(2026, 9, 24, 10),
  noteDate: '2026-09-24',
  pricePaisa: price,
  createdBy: author,
  addedBy: 'Test',
  isSecure: secure,
  isBought: bought,
);

Future<void> openPrices(
  WidgetTester tester,
  FakeBazzerRepository repository,
) async {
  addTearDown(repository.dispose);
  tester.view.physicalSize = const Size(420, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: BazzerReminderPage(
        repository: repository,
        voice: VoiceService(recognizer: FakeVoiceRecognizer()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.drag(find.byType(NestedScrollView), const Offset(0, -600));
  await tester.pumpAndSettle();
}

Future<void> reveal(WidgetTester tester, Finder target) async {
  final list = find.byType(BazzerDailyList).first;
  if (target.evaluate().isNotEmpty) {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    return;
  }
  final scrollable = find
      .descendant(of: list, matching: find.byType(Scrollable))
      .first;
  tester.state<ScrollableState>(scrollable).position.jumpTo(0);
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    target,
    180,
    scrollable: scrollable,
    maxScrolls: 20,
  );
  await tester.pumpAndSettle();
}

String textAt(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(ValueKey(key))).data!;

void main() {
  testWidgets(
    'price taps update immediately, replace values and roll back failures',
    (tester) async {
      final repository = FakeBazzerRepository(owner: true);
      repository.items.addAll([
        product('a', 'রসুন', price: 1000),
        product('b', 'আদা', price: 2000),
      ]);
      repository.priceGate = Completer<void>();
      await openPrices(tester, repository);
      final fifty = find.byKey(const ValueKey('price-false-a-50'));
      await reveal(tester, fifty);
      await tester.tap(fifty);
      await tester.pumpAndSettle();
      expect(
        repository.items.first.pricePaisa,
        1000,
      ); // Still awaiting the server.
      expect(textAt(tester, 'running-false-a'), '৳ ৫০');
      await tester.tap(fifty);
      await tester.pumpAndSettle();
      expect(repository.priceWrites, [('a', 5000)]);
      await reveal(tester, find.byKey(const ValueKey('running-false-b')));
      expect(textAt(tester, 'running-false-b'), '৳ ৭০');
      repository.priceGate!.complete();
      await tester.pumpAndSettle();
      repository.priceGate = null;
      repository.failPrice = true;
      final twenty = find.byKey(const ValueKey('price-false-a-20'));
      await reveal(tester, twenty);
      await tester.tap(twenty);
      await tester.pumpAndSettle();
      expect(textAt(tester, 'running-false-a'), '৳ ৫০');
      expect(find.textContaining('দাম রাখা যায়নি।'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('custom Bengali prices save and can be cleared', (tester) async {
    final repository = FakeBazzerRepository();
    repository.items.add(product('a', 'রসুন'));
    await openPrices(tester, repository);
    final custom = find.descendant(
      of: find.byType(BazzerItemTile).first,
      matching: find.text('অন্য দাম'),
    );
    await reveal(tester, custom);
    await tester.tap(custom);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('bazzer-custom-price')),
      '২৫.৫০',
    );
    await tester.tap(find.text('দাম রাখুন'));
    await tester.pumpAndSettle();
    expect(repository.priceWrites.last, ('a', 2550));
    expect(textAt(tester, 'running-false-a'), '৳ ২৫.৫০');
    await tester.tap(custom);
    await tester.pumpAndSettle();
    await tester.tap(find.text('দাম মুছুন'));
    await tester.pumpAndSettle();
    expect(repository.priceWrites.last, ('a', null));
    expect(repository.items.single.pricePaisa, isNull);
    expect(textAt(tester, 'running-false-a'), '৳ ০');
    expect(tester.takeException(), isNull);
  });

  testWidgets('store filters and bought state keep a separate full-day total', (
    tester,
  ) async {
    final repository = FakeBazzerRepository(owner: true);
    repository.items.addAll([
      product('a', 'চাল', price: 1000, category: 'মুদি'),
      product('b', 'আদা', price: 2000),
      product('c', 'রসুন', price: 3000, bought: true),
    ]);
    await openPrices(tester, repository);
    await reveal(tester, find.widgetWithText(ChoiceChip, 'সবজি'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'সবজি'));
    await tester.pumpAndSettle();
    await reveal(
      tester,
      find.byKey(const ValueKey('day-total-2026-09-24-false')),
    );
    expect(textAt(tester, 'total-2026-09-24-false'), '৳ ২০');
    expect(textAt(tester, 'day-total-2026-09-24-false'), contains('৳ ৬০'));
    await tester.tap(find.text('কেনা হয়েছে'));
    await tester.pumpAndSettle();
    await reveal(
      tester,
      find.byKey(const ValueKey('day-total-2026-09-24-true')),
    );
    expect(textAt(tester, 'total-2026-09-24-true'), '৳ ৩০');
    expect(textAt(tester, 'day-total-2026-09-24-true'), contains('৳ ৬০'));
    await repository.setBought('family', repository.items.last, false);
    await tester.pumpAndSettle();
    expect(find.text('এখনো কেনা হয়েছে এমন জিনিস নেই।'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('normal members totals exclude another members secure prices', (
    tester,
  ) async {
    final repository = FakeBazzerRepository();
    repository.items.addAll([
      product('a', 'রসুন', price: 1000),
      product('b', 'নিজের Secure', price: 2000, secure: true),
      product(
        'c',
        'অন্যের Secure',
        price: 990000,
        secure: true,
        author: 'someone-else',
      ),
    ]);
    await openPrices(tester, repository);
    await reveal(tester, find.byKey(const ValueKey('total-2026-09-24-false')));
    expect(textAt(tester, 'total-2026-09-24-false'), '৳ ৩০');
    expect(find.text('অন্যের Secure'), findsNothing);
    expect(repository.streamCalls['secure/null/member'], 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'price chips and daily totals fit a small phone with larger text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BazzerDailyList(
              items: [product('a', 'দেশি রসুন', price: 100000000)],
              bought: false,
              currentUid: 'member',
              isAdmin: false,
              search: '',
              onEdit: (_) {},
              onDelete: (_) {},
              onToggle: (_) {},
              onSetPrice: (_, _) {},
              onCustomPrice: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final price in [10, 20, 30, 40, 50, 100, 200]) {
        expect(find.byKey(ValueKey('price-false-a-$price')), findsOneWidget);
      }
      await reveal(
        tester,
        find.byKey(const ValueKey('total-2026-09-24-false')),
      );
      expect(textAt(tester, 'total-2026-09-24-false'), '৳ ১০০০০০০');
      expect(tester.takeException(), isNull);
    },
  );
}
