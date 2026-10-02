import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ash_shifa_ruqyah/features/easy_home/controllers/easy_home_controller.dart';
import 'package:ash_shifa_ruqyah/features/easy_home/models/easy_home_models.dart';
import 'package:ash_shifa_ruqyah/features/easy_home/screens/easy_home_page.dart';

import 'support/fake_easy_home.dart';
import 'package:ash_shifa_ruqyah/features/easy_home/screens/easy_home_management.dart';

void main() {
  Future<EasyHomeController> mount(
    WidgetTester tester,
    FakeEasyHomeRepository repo, {
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = EasyHomeController(repo);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorSchemeSeed: Colors.green, brightness: brightness),
        home: EasyHomePage(controller: controller),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      await repo.dispose();
    });
    return controller;
  }

  testWidgets('system and toolbar back return from tabs to summary', (
    tester,
  ) async {
    await mount(tester, FakeEasyHomeRepository());
    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
    await tester.tap(find.byType(NavigationDestination).at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
  });

  testWidgets(
    'owner expense form retries without losing data and report revokes',
    (tester) async {
      final repo = FakeEasyHomeRepository();
      final c = await mount(tester, repo);
      final context = tester.element(find.byType(EasyHomePage));
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EasyHomeManagement(
            controller: c,
            homeId: c.homeId!,
            viewerKey: c.member!.accessKey,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('খরচ যোগ করুন'));
      await tester.tap(find.text('খরচ যোগ করুন'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('title')),
        'পাম্প মেরামত',
      );
      await tester.enterText(find.byKey(const ValueKey('amount')), '১২৩.৪৫');
      repo.failSave = true;
      await tester.tap(find.text('সেভ করুন'));
      await tester.pumpAndSettle();
      expect(find.text('সংযোগ নেই'), findsOneWidget);
      repo.failSave = false;
      await tester.tap(find.text('সেভ করুন'));
      await tester.pumpAndSettle();
      expect(repo.expenses.single.amountPaisa, 12345);
      expect(find.text('পাম্প মেরামত'), findsOneWidget);
      repo.auth.add(null);
      await tester.pumpAndSettle();
      expect(find.text('পাম্প মেরামত'), findsNothing);
      expect(find.text('হিসাব দেখার অনুমতি নেই'), findsOneWidget);
      expect(c.expenses, isEmpty);
    },
  );

  testWidgets(
    'utility draft invalidates after editing and system back returns to summary',
    (tester) async {
      final repo = FakeEasyHomeRepository();
      final c = await mount(tester, repo);
      final context = tester.element(find.byType(EasyHomePage));
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EasyHomeManagement(
            controller: c,
            homeId: c.homeId!,
            viewerKey: c.member!.accessKey,
            utility: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('utility-amount')),
        '১০০.০১',
      );
      await tester.tap(find.text('ভাগ হিসাব করুন'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('utility-copy')),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('ভাগের হিসাব কপি'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('utility-amount')),
        -150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('utility-amount')),
        '২০০',
      );
      await tester.pump();
      expect(find.text('ভাগের হিসাব কপি'), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(EasyHomeManagement), findsNothing);
      expect(find.byType(EasyHomePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'small ${brightness.name} screen keeps search and keyboard form stable',
      (tester) async {
        final repo = FakeEasyHomeRepository();
        await mount(tester, repo, brightness: brightness);
        await tester.tap(find.byType(NavigationDestination).at(1));
        await tester.pumpAndSettle();
        final before = Map.of(repo.calls);
        await tester.enterText(find.byType(TextField), '2B');
        await tester.pump();
        expect(repo.calls, before);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('ফ্ল্যাট যোগ'));
        await tester.pumpAndSettle();
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const ValueKey('floor')), '৩');
        await tester.enterText(find.byKey(const ValueKey('unit')), 'A');
        expect(tester.takeException(), isNull);
        repo.failSave = true;
        await tester.tap(find.text('সেভ করুন'));
        await tester.pumpAndSettle();
        expect(find.text('সংযোগ নেই'), findsOneWidget);
        expect(find.byKey(const ValueKey('floor')), findsOneWidget);
        repo.failSave = false;
        await tester.tap(find.text('সেভ করুন'));
        await tester.pumpAndSettle();
        expect(repo.savedFloor, '৩');
        expect(find.byType(AlertDialog), findsNothing);
      },
    );
  }
  testWidgets(
    'tenant has no landlord switches, contact directory or write controls',
    (tester) async {
      final repo = FakeEasyHomeRepository(role: UserRole.tenant);
      await mount(tester, repo);
      expect(find.textContaining('বাড়ির কোড:'), findsNothing);
      expect(repo.calls['expenses'], isNull);
      expect(repo.calls['members'], isNull);
      expect(repo.calls['requests'], isNull);
      await tester.tap(find.byType(NavigationDestination).at(1));
      await tester.pumpAndSettle();
      expect(find.text('2B-K9X4'), findsOneWidget);
      expect(find.text('ফ্ল্যাট যোগ'), findsNothing);
      expect(find.text('ভাড়াটিয়া যোগ'), findsNothing);
      expect(find.textContaining('01700000000'), findsNothing);
    },
  );
  testWidgets('caretaker never subscribes to contact or rent collections', (
    tester,
  ) async {
    final repo = FakeEasyHomeRepository(role: UserRole.caretaker);
    await mount(tester, repo);
    expect(repo.calls['tenants'], isNull);
    expect(repo.calls['rents'], isNull);
    expect(repo.calls['expenses'], isNull);
    expect(repo.calls['members'], isNull);
    expect(find.text('ভাড়া'), findsNothing);
  });
  testWidgets('revocation and logout immediately clear privileged data', (
    tester,
  ) async {
    final repo = FakeEasyHomeRepository();
    final c = await mount(tester, repo);
    expect(c.flats, isNotEmpty);
    repo.changes.add(
      const UserModel(
        id: 'me',
        name: 'রুবেল',
        phone: '01700000000',
        role: UserRole.tenant,
        active: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(c.flats, isEmpty);
    expect(c.members, isEmpty);
    expect(c.rents, isEmpty);
    expect(find.text('বাড়ির সদস্যপদ সক্রিয় নয়'), findsOneWidget);
    repo.auth.add(null);
    await tester.pumpAndSettle();
    expect(c.homeId, isNull);
    expect(find.text('লগইন করুন'), findsOneWidget);
  });
  testWidgets('first use shows setup rather than invented tenants or rent', (
    tester,
  ) async {
    final repo = FakeEasyHomeRepository(connected: false);
    final c = await mount(tester, repo);
    expect(c.rents, isEmpty);
    expect(c.tenants, isEmpty);
    expect(find.text('বাড়িওয়ালা • বাড়ি তৈরি'), findsOneWidget);
    expect(find.text('ভাড়াটিয়া / কেয়ারটেকার • যোগ দিন'), findsOneWidget);
  });
  testWidgets(
    'an open receipt route hides cached data immediately on revocation',
    (tester) async {
      final repo = FakeEasyHomeRepository();
      final now = DateTime.now();
      repo.rents.add(
        RentModel(
          id: 'bill',
          tenantId: 'lease',
          flatCode: '2B-K9X4',
          month: '${now.year}-${now.month.toString().padLeft(2, '0')}',
          amountPaisa: 100000,
          paidPaisa: 100000,
          dueDate: now,
          createdAt: now,
        ),
      );
      await mount(tester, repo);
      await tester.tap(find.byType(NavigationDestination).at(2));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('রসিদ / ইতিহাস'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('রসিদ / ইতিহাস'));
      await tester.pumpAndSettle();
      expect(find.textContaining('secret-receipt'), findsOneWidget);
      repo.changes.add(
        const UserModel(
          id: 'me',
          name: 'রুবেল',
          phone: '01700000000',
          role: UserRole.tenant,
          active: false,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('secret-receipt'), findsNothing);
      expect(find.text('রসিদ দেখার অনুমতি বদলেছে'), findsOneWidget);
    },
  );
}
