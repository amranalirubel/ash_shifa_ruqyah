import 'package:ash_shifa_ruqyah/features/bazzer_reminder/screens/bazzer_family_page.dart';
import 'package:ash_shifa_ruqyah/features/bazzer_reminder/screens/bazzer_reminder_page.dart';
import 'package:ash_shifa_ruqyah/features/bazzer_reminder/screens/voice_review_sheet.dart';
import 'package:ash_shifa_ruqyah/features/bazzer_reminder/services/voice_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_bazzer.dart';

Future<void> openShopping(
  WidgetTester tester,
  FakeBazzerRepository repository, {
  FakeVoiceRecognizer? recognizer,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BazzerReminderPage(
        repository: repository,
        voice: VoiceService(recognizer: recognizer ?? FakeVoiceRecognizer()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'member card opens own family info without querying admin directory',
    (tester) async {
      final repository = FakeBazzerRepository();
      await openShopping(tester, repository);
      await tester.tap(find.byKey(const ValueKey('bazzer-family-button')));
      await tester.pumpAndSettle();
      expect(find.byType(BazzerFamilyInfoPage), findsOneWidget);
      expect(find.text('মায়ের নাম'), findsOneWidget);
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('ABCDEFGHJKLM'), findsNothing);
      expect(repository.streamCalls['members'], isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('owner card opens working management and member actions', (
    tester,
  ) async {
    final repository = FakeBazzerRepository(owner: true);
    await openShopping(tester, repository);
    await tester.tap(find.byKey(const ValueKey('bazzer-family-button')));
    await tester.pumpAndSettle();
    expect(find.byType(BazzerFamilyManagePage), findsOneWidget);
    expect(find.text('ABCDEFGHJKLM'), findsOneWidget);
    await tester.tap(find.byTooltip('মায়ের নাম পরিচালনা'));
    await tester.pumpAndSettle();
    expect(find.text('নাম পরিবর্তন'), findsOneWidget);
    expect(find.text('Admin করুন'), findsOneWidget);
    expect(find.text('Secure করুন'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Bengali voice opens review with an empty device language list', (
    tester,
  ) async {
    final repository = FakeBazzerRepository();
    final engine = FakeVoiceRecognizer();
    await openShopping(tester, repository, recognizer: engine);
    await tester.tap(find.text('বাংলায় বলুন'));
    await tester.pumpAndSettle();
    expect(engine.requestedLocales, ['bn-BD']);
    engine.result('আলু আধা কেজি তেল এক লিটার', true);
    await tester.pumpAndSettle();
    expect(find.byType(VoiceReviewSheet), findsOneWidget);
    await tester.tap(find.text('2টি যোগ করুন'));
    await tester.pumpAndSettle();
    expect(repository.savedItems.map((item) => item.name), ['আলু', 'তেল']);
    expect(repository.savedItems.first.quantity, 0.5);
    expect(repository.savedAuthor, 'মায়ের নাম');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'search and store filters preserve focus and stream subscriptions',
    (tester) async {
      final repository = FakeBazzerRepository();
      await openShopping(tester, repository);
      final before = Map<String, int>.of(repository.streamCalls);
      final search = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'বাজারের জিনিস খুঁজুন',
      );
      await tester.enterText(search, 'কাঁচা');
      await tester.pumpAndSettle();
      await tester.enterText(search, 'কাঁচামরিচ');
      await tester.pumpAndSettle();
      final field = tester.widget<EditableText>(
        find.descendant(of: search, matching: find.byType(EditableText)),
      );
      expect(field.focusNode.hasFocus, isTrue);
      expect(field.controller.text, 'কাঁচামরিচ');
      for (final name in ['মুদি', 'সবজি', 'সব দোকান']) {
        await tester.tap(find.widgetWithText(ChoiceChip, name));
        await tester.pumpAndSettle();
      }
      expect(repository.streamCalls, before);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('add form scrolls on a small phone with keyboard visible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await openShopping(tester, FakeBazzerRepository(owner: true));
    await tester.tap(find.text('লিখে নতুন জিনিস যোগ করুন'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    final name = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'জিনিসের নাম (যেমন কাঁচামরিচ)',
    );
    await tester.ensureVisible(name);
    await tester.enterText(name, 'আলু');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
