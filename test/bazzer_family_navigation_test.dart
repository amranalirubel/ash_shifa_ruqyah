import 'package:ash_shifa_ruqyah/features/bazzer_reminder/repositories/bazzer_repository.dart';
import 'package:ash_shifa_ruqyah/features/bazzer_reminder/screens/bazzer_family_page.dart';
import 'package:ash_shifa_ruqyah/features/bazzer_reminder/screens/bazzer_reminder_page.dart';
import 'package:ash_shifa_ruqyah/features/bazzer_reminder/screens/voice_review_sheet.dart';
import 'package:ash_shifa_ruqyah/features/bazzer_reminder/services/voice_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_bazzer.dart';

Future<void> openShopping(
  WidgetTester tester,
  FakeBazzerRepository repository, {
  FakeVoiceRecognizer? recognizer,
}) async {
  addTearDown(repository.dispose);
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
    'member can see and copy the family code without admin directory access',
    (tester) async {
      final repository = FakeBazzerRepository();
      await openShopping(tester, repository);
      await tester.tap(find.byKey(const ValueKey('bazzer-family-button')));
      await tester.pumpAndSettle();
      expect(find.byType(BazzerFamilyInfoPage), findsOneWidget);
      expect(find.text('মায়ের নাম'), findsOneWidget);
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('ABCDEFGHJKLM'), findsOneWidget);
      String? copiedCode;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedCode = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('bazzer-copy-family-code')));
      await tester.pumpAndSettle();
      expect(copiedCode, repository.family.inviteCode);
      expect(find.text('কোড কপি হয়েছে।'), findsOneWidget);
      expect(find.text('পরিবার পরিচালনা'), findsNothing);
      expect(find.byType(SwitchListTile), findsNothing);
      expect(repository.streamCalls['members'], isNull);
      expect(repository.managementWrites, isEmpty);
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
    expect(find.text('মূল অ্যাকাউন্ট • Admin'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('মায়ের নাম পরিচালনা'));
    await tester.tap(find.byTooltip('মায়ের নাম পরিচালনা'));
    await tester.pumpAndSettle();
    expect(find.text('নাম পরিবর্তন'), findsOneWidget);
    expect(find.text('Admin করুন'), findsOneWidget);
    expect(find.text('Secure করুন'), findsOneWidget);
    await tester.tap(find.text('নাম পরিবর্তন'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'আম্মু');
    await tester.tap(find.text('সংরক্ষণ করুন'));
    await tester.pumpAndSettle();
    expect(repository.managementWrites, contains(('name', 'member', 'আম্মু')));
    expect(find.text('আম্মু'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('আম্মু পরিচালনা'));
    await tester.tap(find.byTooltip('আম্মু পরিচালনা'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Admin করুন'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Admin করুন'));
    await tester.pumpAndSettle();
    expect(repository.managementWrites, contains(('admin', 'member', true)));
    expect(repository.member.isAdmin, isTrue);
    await tester.ensureVisible(find.byTooltip('আম্মু পরিচালনা'));
    await tester.tap(find.byTooltip('আম্মু পরিচালনা'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Secure করুন'));
    await tester.pumpAndSettle();
    expect(repository.managementWrites, contains(('secure', 'member', true)));
    expect(repository.member.secure, isTrue);
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(repository.managementWrites, contains(('joining', 'family', false)));
    expect(
      find.textContaining('নতুন সদস্য যুক্ত করা বন্ধ আছে।'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('member sees live joining state and loses code after removal', (
    tester,
  ) async {
    final repository = FakeBazzerRepository();
    await openShopping(tester, repository);
    await tester.tap(find.byTooltip('পরিবারের কোড ও তথ্য'));
    await tester.pumpAndSettle();
    expect(find.text('নতুন সদস্য যুক্ত করা চালু আছে।'), findsOneWidget);
    repository.updateFamily(
      BazzerFamily(
        id: repository.family.id,
        ownerUid: repository.family.ownerUid,
        inviteCode: repository.family.inviteCode,
        joiningEnabled: false,
        name: repository.family.name,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('নতুন সদস্য যুক্ত করা বন্ধ আছে।'),
      findsOneWidget,
    );
    expect(find.byType(SwitchListTile), findsNothing);
    repository.updateMember(
      BazzerMember(
        uid: repository.member.uid,
        name: repository.member.name,
        active: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ABCDEFGHJKLM'), findsNothing);
    expect(
      find.textContaining('আপনার সদস্যপদ এখন সক্রিয় নেই।'),
      findsOneWidget,
    );
    expect(repository.streamCalls['members'], isNull);
    expect(repository.managementWrites, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('promotion opens management and revocation removes controls', (
    tester,
  ) async {
    final repository = FakeBazzerRepository();
    await openShopping(tester, repository);
    await tester.tap(find.byKey(const ValueKey('bazzer-family-button')));
    await tester.pumpAndSettle();
    expect(find.text('পরিবার পরিচালনা'), findsNothing);
    repository.updateMember(
      BazzerMember(
        uid: repository.member.uid,
        name: repository.member.name,
        active: true,
        role: 'admin',
      ),
    );
    await tester.pumpAndSettle();
    final manageButton = find.byKey(const ValueKey('bazzer-family-manage'));
    expect(manageButton, findsOneWidget);
    await tester.ensureVisible(manageButton);
    await tester.tap(manageButton);
    await tester.pumpAndSettle();
    expect(find.byType(BazzerFamilyManagePage), findsOneWidget);
    expect(find.text('ABCDEFGHJKLM'), findsOneWidget);
    expect(repository.streamCalls['members'], 1);
    repository.updateMember(
      BazzerMember(
        uid: repository.member.uid,
        name: repository.member.name,
        active: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ABCDEFGHJKLM'), findsNothing);
    expect(find.byType(SwitchListTile), findsNothing);
    expect(
      find.text('পরিবার পরিচালনার জন্য সক্রিয় Admin-এর অধিকার প্রয়োজন।'),
      findsOneWidget,
    );
    expect(repository.managementWrites, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('family code and copy button fit a small phone with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openShopping(tester, FakeBazzerRepository());
    await tester.tap(find.byTooltip('পরিবারের কোড ও তথ্য'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('bazzer-copy-family-code')),
    );
    expect(find.text('ABCDEFGHJKLM'), findsOneWidget);
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
