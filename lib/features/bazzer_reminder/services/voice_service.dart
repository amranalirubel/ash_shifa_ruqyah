import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Small boundary so device failures can be tested without a microphone.
abstract class VoiceRecognizer {
  bool get isListening;
  Future<bool> initialize({
    required void Function(String) onStatus,
    required void Function(String) onError,
  });
  Future<List<String>> locales();
  Future<void> listen({
    required String localeId,
    required void Function(String, bool) onResult,
  });
  Future<void> stop();
  Future<void> cancel();
}

class _DeviceVoiceRecognizer implements VoiceRecognizer {
  final _speech = stt.SpeechToText();

  @override
  bool get isListening => _speech.isListening;

  @override
  Future<bool> initialize({
    required void Function(String) onStatus,
    required void Function(String) onError,
  }) => _speech.initialize(
    onStatus: onStatus,
    onError: (error) => onError(error.errorMsg),
  );

  @override
  Future<List<String>> locales() async =>
      (await _speech.locales()).map((locale) => locale.localeId).toList();

  @override
  Future<void> listen({
    required String localeId,
    required void Function(String, bool) onResult,
  }) async {
    await _speech.listen(
      onResult: (result) =>
          onResult(result.recognizedWords, result.finalResult),
      listenOptions: stt.SpeechListenOptions(
        localeId: localeId,
        onDevice: false,
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
        listenFor: const Duration(seconds: 45),
        pauseFor: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Future<void> stop() => _speech.stop();

  @override
  Future<void> cancel() => _speech.cancel();
}

class VoiceService {
  // The plugin retains the first initialization callbacks for the app's
  // lifetime. Keep one service and replace only its current page callbacks.
  factory VoiceService({VoiceRecognizer? recognizer}) =>
      recognizer == null ? _shared : VoiceService._(recognizer);
  VoiceService._(this._recognizer);
  static final VoiceService _shared = VoiceService._(_DeviceVoiceRecognizer());

  final VoiceRecognizer _recognizer;
  bool _initialized = false;
  bool _localesLoaded = false;
  String? _preferredLocale;
  bool _starting = false;
  bool _active = false;
  int _session = 0;
  int _localeIndex = 0;
  List<String> _locales = const ['bn-BD', 'bn-IN'];
  String _lastText = '';
  Timer? _finishTimer;
  Timer? _startTimer;
  void Function(bool)? _statusCallback;
  void Function(String)? _errorCallback;
  void Function(String)? _finalCallback;
  void Function(String)? _partialCallback;

  bool get isListening => _recognizer.isListening;

  Future<void> startListening({
    required void Function(String text) onFinalText,
    required void Function(bool listening) onListeningChanged,
    void Function(String text)? onPartialText,
    void Function(String message)? onError,
  }) async {
    if (_starting || _active) return;
    _starting = true;
    _active = true;
    final session = ++_session;
    _statusCallback = onListeningChanged;
    _errorCallback = onError;
    _finalCallback = onFinalText;
    _partialCallback = onPartialText;
    _lastText = '';
    _localeIndex = 0;
    try {
      if (!_initialized) {
        _initialized = await _recognizer.initialize(
          onStatus: _onStatus,
          onError: _onError,
        );
      }
      if (session != _session || !_active) return;
      if (!_initialized) {
        _fail(
          'মাইক্রোফোন চালু করা যায়নি। অ্যাপের Microphone অনুমতি ও ফোনের voice service দেখুন।',
        );
        return;
      }
      // Locale enumeration can be incomplete even when online Bengali
      // recognition is available. Always try an explicit Bengali request.
      if (!_localesLoaded) {
        var available = <String>[];
        try {
          available = await _recognizer.locales().timeout(
            const Duration(milliseconds: 500),
            onTimeout: () => <String>[],
          );
        } catch (_) {
          // Ask the recognizer directly using the explicit Bengali locale.
        }
        final bengali = available
            .map((id) => id.replaceAll('_', '-').toLowerCase())
            .toSet();
        _locales = bengali.contains('bn-in') && !bengali.contains('bn-bd')
            ? ['bn-IN', 'bn-BD']
            : ['bn-BD', 'bn-IN'];
        _localesLoaded = true;
      }
      if (session != _session || !_active) return;
      if (_preferredLocale != null) {
        _locales = [
          _preferredLocale!,
          _preferredLocale == 'bn-BD' ? 'bn-IN' : 'bn-BD',
        ];
      }
      await _listen(session);
    } catch (_) {
      if (session == _session) {
        _fail(
          'ভয়েস চালু করা যায়নি। ইন্টারনেট ও Microphone অনুমতি দেখে আবার চাপুন।',
        );
      }
    } finally {
      if (session == _session) _starting = false;
    }
  }

  Future<void> _listen(int session) async {
    await _recognizer.listen(
      localeId: _locales[_localeIndex],
      onResult: (text, isFinal) {
        if (!_active || session != _session) return;
        if (text.trim().isNotEmpty) {
          _lastText = text.trim();
          _preferredLocale = _locales[_localeIndex];
        }
        if (isFinal) {
          _finish();
        } else {
          _partialCallback?.call(_lastText);
        }
      },
    );
    if (_active && session == _session) {
      _statusCallback?.call(_recognizer.isListening);
      if (!_recognizer.isListening) {
        _startTimer?.cancel();
        _startTimer = Timer(const Duration(seconds: 6), () {
          if (_active && session == _session && !_recognizer.isListening) {
            _fail(
              'ভয়েস সেবা চালু হয়নি। ইন্টারনেট ও Microphone অনুমতি দেখে আবার চেষ্টা করুন।',
            );
          }
        });
      }
    }
  }

  void _onStatus(String status) {
    if (!_active) return;
    if (status == 'listening') {
      _startTimer?.cancel();
      _statusCallback?.call(true);
    } else if (status == 'done' || status == 'notListening') {
      _statusCallback?.call(false);
      // Some devices deliver the final result after the stop notification.
      _scheduleFinish();
    }
  }

  void _scheduleFinish() {
    _finishTimer?.cancel();
    _finishTimer = Timer(const Duration(milliseconds: 350), _finish);
  }

  void _finish() {
    if (!_active) return;
    _active = false;
    _finishTimer?.cancel();
    _startTimer?.cancel();
    _statusCallback?.call(false);
    if (_lastText.isNotEmpty) {
      _finalCallback?.call(_lastText);
    } else {
      _errorCallback?.call(
        'কথা শোনা যায়নি। আবার বাংলায় বলুন চাপুন, তারপর বলুন।',
      );
    }
  }

  void _onError(String code) {
    if (!_active) return;
    if (code.contains('language') &&
        _lastText.isEmpty &&
        _localeIndex + 1 < _locales.length) {
      unawaited(_retryBengali());
      return;
    }
    if ((code.contains('no_match') || code.contains('speech_timeout')) &&
        _lastText.isNotEmpty) {
      _finish();
      return;
    }
    _fail(
      code.contains('network')
          ? 'ইন্টারনেট সংযোগ পাওয়া যাচ্ছে না। সংযোগ চালু করে আবার বাংলায় বলুন।'
          : code.contains('permission')
          ? 'এই অ্যাপের Microphone অনুমতি দিন, তারপর আবার বাংলায় বলুন।'
          : code.contains('language')
          ? 'ফোনের voice service বাংলা অনুরোধ গ্রহণ করেনি। ইন্টারনেট চালু রেখে আবার চেষ্টা করুন।'
          : code.contains('no_match') || code.contains('speech_timeout')
          ? 'কথা পরিষ্কার শোনা যায়নি। আবার বাংলায় বলুন চাপুন।'
          : 'ভয়েস সেবা এখন সাড়া দিচ্ছে না। একটু পরে আবার বাংলায় বলুন চাপুন।',
    );
  }

  Future<void> _retryBengali() async {
    final session = ++_session;
    _localeIndex++;
    _finishTimer?.cancel();
    _startTimer?.cancel();
    try {
      await _recognizer.cancel();
      _finishTimer?.cancel();
      if (!_active || session != _session) return;
      await _listen(session);
    } catch (_) {
      if (session == _session) {
        _fail('ভয়েস চালু করা যায়নি। ইন্টারনেট চালু রেখে আবার চেষ্টা করুন।');
      }
    } finally {
      if (session == _session) _starting = false;
    }
  }

  void _fail(String message) {
    if (!_active) return;
    _active = false;
    _finishTimer?.cancel();
    _startTimer?.cancel();
    _statusCallback?.call(false);
    _errorCallback?.call(message);
  }

  Future<void> stopListening() async {
    if (!_active) return;
    if (_lastText.isNotEmpty) {
      // The user explicitly accepted the displayed partial text. Open review
      // immediately, without waiting for another network recognition result.
      _finish();
      try {
        await _recognizer.cancel();
      } catch (_) {
        // The text is already available for review; cleanup cannot erase it.
      }
      return;
    }
    _scheduleFinish();
    try {
      await _recognizer.stop();
    } catch (_) {
      if (_active) _finish();
    }
  }

  Future<void> dispose() async {
    _session++;
    _active = false;
    _starting = false;
    _finishTimer?.cancel();
    _startTimer?.cancel();
    _statusCallback = null;
    _errorCallback = null;
    _finalCallback = null;
    _partialCallback = null;
    if (_initialized) {
      try {
        await _recognizer.cancel();
      } catch (_) {
        // Page callbacks are already detached. A device teardown failure
        // must not stop back navigation or opening family information.
      }
    }
  }
}
