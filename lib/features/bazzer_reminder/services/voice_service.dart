import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;
  String? _bengaliLocale;
  String _lastFinal = '';
  void Function(bool listening)? _statusCallback;
  void Function(String message)? _errorCallback;

  bool get isListening => _speech.isListening;

  Future<bool> initialize({void Function(String message)? onError}) async {
    _errorCallback = onError;
    if (!_initialized) {
      _initialized = await _speech.initialize(
        onStatus: (status) {
          if (status == 'listening') _statusCallback?.call(true);
          if (status == 'done' || status == 'notListening') {
            _statusCallback?.call(false);
          }
        },
        onError: (error) => _errorCallback?.call(error.errorMsg),
      );
    }
    if (!_initialized) {
      onError?.call(
        'মাইক্রোফোন/ভয়েস recognition চালু হয়নি। অনুমতি ও ফোনের সেটিংস দেখুন।',
      );
      return false;
    }
    final locales = await _speech.locales();
    for (final preferred in ['bn-BD', 'bn-IN', 'bn']) {
      for (final locale in locales) {
        final id = locale.localeId.toLowerCase().replaceAll('_', '-');
        if (id == preferred.toLowerCase() ||
            (preferred == 'bn' && id.startsWith('bn-'))) {
          _bengaliLocale = locale.localeId;
          break;
        }
      }
      if (_bengaliLocale != null) break;
    }
    if (_bengaliLocale == null) {
      onError?.call(
        'বাংলা voice recognition ফোনে নেই। বাংলা ভাষা ইনস্টল করুন অথবা লিখে যোগ করুন।',
      );
      return false;
    }
    return true;
  }

  Future<void> startListening({
    required void Function(String text) onFinalText,
    required void Function(bool listening) onListeningChanged,
    void Function(String text)? onPartialText,
    void Function(String message)? onError,
  }) async {
    _statusCallback = onListeningChanged;
    final ready = await initialize(onError: onError);
    if (!ready) return;
    _lastFinal = '';

    await _speech.listen(
      onResult: (result) {
        final text = result.recognizedWords.trim();
        if (result.finalResult && text.isNotEmpty && text != _lastFinal) {
          _lastFinal = text;
          onFinalText(text);
        } else if (!result.finalResult) {
          onPartialText?.call(text);
        }
      },
      localeId: _bengaliLocale,
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
      ),
    );
    onListeningChanged(_speech.isListening);
  }

  Future<void> stopListening() async {
    if (_speech.isListening) await _speech.stop();
    _statusCallback?.call(false);
  }

  Future<void> dispose() => stopListening();
}
