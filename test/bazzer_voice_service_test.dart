import 'package:ash_shifa_ruqyah/features/bazzer_reminder/services/voice_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_bazzer.dart';

void main() {
  testWidgets('silent device startup failure is reported and can retry', (
    tester,
  ) async {
    final engine = FakeVoiceRecognizer()..reportListening = false;
    final service = VoiceService(recognizer: engine);
    final errors = <String>[];
    await service.startListening(
      onFinalText: (_) {},
      onListeningChanged: (_) {},
      onError: errors.add,
    );
    await tester.pump(const Duration(seconds: 7));
    expect(errors, hasLength(1));
    engine.reportListening = true;
    await service.startListening(
      onFinalText: (_) {},
      onListeningChanged: (_) {},
    );
    expect(engine.requestedLocales, hasLength(2));
    await service.dispose();
  });
  for (final locales in [
    <String>[],
    ['en-US'],
    ['bn_BD'],
    ['bn_IN'],
  ]) {
    testWidgets('requests Bengali even with device locales $locales', (
      tester,
    ) async {
      final engine = FakeVoiceRecognizer()..availableLocales = locales;
      final service = VoiceService(recognizer: engine);
      final heard = <String>[];
      final errors = <String>[];
      await service.startListening(
        onFinalText: heard.add,
        onListeningChanged: (_) {},
        onError: errors.add,
      );
      expect(engine.requestedLocales, [
        locales.contains('bn_IN') ? 'bn-IN' : 'bn-BD',
      ]);
      engine.result('আলু আধা কেজি তেল এক লিটার', true);
      expect(heard, ['আলু আধা কেজি তেল এক লিটার']);
      expect(errors, isEmpty);
      await service.dispose();
    });
  }

  testWidgets('failed locale discovery still starts Bengali recognition', (
    tester,
  ) async {
    final engine = FakeVoiceRecognizer()..failLocales = true;
    final service = VoiceService(recognizer: engine);
    await service.startListening(
      onFinalText: (_) {},
      onListeningChanged: (_) {},
    );
    expect(engine.requestedLocales, ['bn-BD']);
    await service.dispose();
  });

  testWidgets('language failure retries Bengali once, never English', (
    tester,
  ) async {
    final engine = FakeVoiceRecognizer();
    final service = VoiceService(recognizer: engine);
    final errors = <String>[];
    await service.startListening(
      onFinalText: (_) {},
      onListeningChanged: (_) {},
      onError: errors.add,
    );
    engine.error('error_language_not_supported');
    await tester.pump();
    expect(engine.requestedLocales, ['bn-BD', 'bn-IN']);
    engine.error('error_language_unavailable');
    await tester.pump();
    expect(engine.requestedLocales, hasLength(2));
    expect(errors, hasLength(1));
    expect(errors.single, isNot(contains('ইনস্টল')));
    await service.dispose();
  });

  testWidgets(
    'stop preserves partial text and ignores duplicate final results',
    (tester) async {
      final engine = FakeVoiceRecognizer();
      final service = VoiceService(recognizer: engine);
      final heard = <String>[];
      await service.startListening(
        onFinalText: heard.add,
        onListeningChanged: (_) {},
      );
      engine.result('আলু হাফ কেজি', false);
      await service.stopListening();
      await tester.pump(const Duration(seconds: 2));
      engine.result('আলু হাফ কেজি', true);
      expect(heard, ['আলু হাফ কেজি']);
      await service.dispose();
    },
  );

  testWidgets('reopening reuses initialization and only calls the new page', (
    tester,
  ) async {
    final engine = FakeVoiceRecognizer();
    final service = VoiceService(recognizer: engine);
    final oldResults = <String>[];
    final newResults = <String>[];
    await service.startListening(
      onFinalText: oldResults.add,
      onListeningChanged: (_) {},
    );
    final lateOldResult = engine.result;
    await service.dispose();
    await service.startListening(
      onFinalText: newResults.add,
      onListeningChanged: (_) {},
    );
    lateOldResult('পুরোনো লেখা', true);
    engine.result('তেল এক লিটার', true);
    expect(engine.initializeCount, 1);
    expect(oldResults, isEmpty);
    expect(newResults, ['তেল এক লিটার']);
    await service.dispose();
  });

  testWidgets('denied microphone never starts listening', (tester) async {
    final engine = FakeVoiceRecognizer()..ready = false;
    final service = VoiceService(recognizer: engine);
    final errors = <String>[];
    await service.startListening(
      onFinalText: (_) {},
      onListeningChanged: (_) {},
      onError: errors.add,
    );
    expect(engine.requestedLocales, isEmpty);
    expect(errors.single, contains('Microphone'));
    await service.dispose();
  });
}
