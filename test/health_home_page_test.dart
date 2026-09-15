import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ash_shifa_ruqyah/core/app_theme.dart';
import 'package:ash_shifa_ruqyah/features/health_tips/screens/health_home_page.dart';

void main() {
  testWidgets('health home shows evidence banner and professional sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const HealthHomePage()),
    );

    expect(find.text('স্বাস্থ্য সহায়তা'), findsOneWidget);
    expect(find.text('অল্প নড়াচড়াও শূন্যের চেয়ে ভালো'), findsOneWidget);
    expect(find.text('খাদ্য ও জীবনযাপন গাইড'), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('health banner advances automatically', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const HealthHomePage()),
    );

    expect(find.text('অল্প নড়াচড়াও শূন্যের চেয়ে ভালো'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('ঘুম শুধু বিশ্রাম নয়'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
