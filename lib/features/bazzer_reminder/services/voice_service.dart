import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool get isListening => _speech.isListening;
  String? _selectedLocaleId;

  Future<bool> initialize({void Function(String message)? onError}) async {
    final available = await _speech.initialize(
      onError: (error) => onError?.call(error.errorMsg),
    );

    if (!available) {
      onError?.call('Speech recognition চালু হয়নি। ফোনের মাইক্রোফোন চেক করুন।');
      return false;
    }

    // 🔥 বাংলা লোকেল জোর করে সেট করা
    final locales = await _speech.locales();
    const preferredLocales = ['bn-BD', 'bn-IN', 'bn'];

    for (var code in preferredLocales) {
      final match = locales.firstWhere(
        (l) => l.localeId.toLowerCase().startsWith(code),
        orElse: () => locales.first,
      );
      if (match.localeId.toLowerCase().startsWith('bn')) {
        _selectedLocaleId = match.localeId;
        break; // print() removed (production code rule)
      }
    }

    _selectedLocaleId ??= 'bn-BD'; // null-aware assignment (recommended fix)

    return true;
  }

  Future<void> startListening({
    required void Function(String text) onFinalText,
    required void Function(bool listening) onListeningChanged,
    void Function(String message)? onError,
  }) async {
    final ready = await initialize(onError: onError);
    if (!ready) return;

    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        localeId: _selectedLocaleId,
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
      ),
      onResult: (result) {
        if (result.finalResult) {
          onFinalText(result.recognizedWords);
        }
      },
    );

    onListeningChanged(true);
  }

  Future<void> stopListening() async {
    if (_speech.isListening) await _speech.stop();
  }

  Future<void> dispose() async => await stopListening();
}
