import 'package:ash_shifa_ruqyah/features/bazzer_reminder/screens/voice_review_sheet.dart';
import 'package:ash_shifa_ruqyah/features/bazzer_reminder/utils/voice_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('editing and cancelling a recognized item closes safely', (
    tester,
  ) async {
    final parsed = VoiceParser.parsePreview('তেল এক লিটার');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) =>
                    VoiceReviewSheet(heard: 'তেল এক লিটার', parsed: parsed),
              ),
              child: const Text('Open voice review'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open voice review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('তেল'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('বাতিল'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(VoiceReviewSheet), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(VoiceReviewSheet),
        matching: find.text('বাতিল'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(VoiceReviewSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
