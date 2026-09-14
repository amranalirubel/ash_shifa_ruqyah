import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ash_shifa_ruqyah/features/auth/screens/auth_dialogs.dart';

void main() {
  testWidgets('logout dialog can be cancelled without an exception', (
    tester,
  ) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showLogoutConfirmation(context);
              },
              child: const Text('Open logout'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open logout'));
    await tester.pumpAndSettle();
    expect(find.text('Logout করবেন?'), findsOneWidget);

    await tester.tap(find.text('বাতিল'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
    expect(find.text('Open logout'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edit-name dialog owns and disposes its controller safely', (
    tester,
  ) async {
    String? result = 'unchanged';

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showEditNameDialog(
                  context,
                  initialName: 'Rubel',
                );
              },
              child: const Text('Open name'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open name'));
    await tester.pumpAndSettle();
    expect(find.text('নাম পরিবর্তন'), findsOneWidget);

    await tester.tap(find.text('বাতিল'));
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(find.text('Open name'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
