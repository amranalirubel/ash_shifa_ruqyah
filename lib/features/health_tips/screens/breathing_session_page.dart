import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../data/health_content_catalog.dart';
import '../widgets/health_source_sheet.dart';

class BreathingSessionPage extends StatefulWidget {
  const BreathingSessionPage({super.key});

  @override
  State<BreathingSessionPage> createState() => _BreathingSessionPageState();
}

class _BreathingSessionPageState extends State<BreathingSessionPage>
    with WidgetsBindingObserver {
  static const int _sessionSeconds = 5 * 60;
  static const int _phaseSeconds = 5;

  Timer? _timer;
  int _remainingSeconds = _sessionSeconds;
  int _phaseElapsed = 0;
  bool _isRunning = false;
  bool _isInhaling = true;
  bool _isComplete = false;

  double get _progress =>
      (_sessionSeconds - _remainingSeconds) / _sessionSeconds;

  String get _clock {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return minutes.toString().padLeft(2, '0') +
        ':' +
        seconds.toString().padLeft(2, '0');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  void _toggleSession() {
    if (_isRunning) {
      _pause();
    } else {
      _start();
    }
  }

  void _start() {
    if (_isComplete) _reset();
    _timer?.cancel();
    setState(() => _isRunning = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        _timer?.cancel();
        setState(() {
          _remainingSeconds = 0;
          _isRunning = false;
          _isComplete = true;
        });
        return;
      }

      setState(() {
        _remainingSeconds -= 1;
        _phaseElapsed += 1;
        if (_phaseElapsed >= _phaseSeconds) {
          _phaseElapsed = 0;
          _isInhaling = !_isInhaling;
        }
      });
    });
  }

  void _pause() {
    _timer?.cancel();
    if (mounted && _isRunning) setState(() => _isRunning = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _sessionSeconds;
      _phaseElapsed = 0;
      _isRunning = false;
      _isInhaling = true;
      _isComplete = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF5EEAD4)
        : const Color(0xFF087A6B);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guided Breathing'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _reset,
            tooltip: 'আবার শুরু করুন',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          children: [
            Text(
              'আরামদায়ক, জোরহীন শ্বাস',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'নাক দিয়ে শ্বাস নিন • মুখ দিয়ে ধীরে ছাড়ুন',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            Center(
              child: Semantics(
                liveRegion: true,
                label: _isComplete
                    ? 'Session complete'
                    : (_isInhaling ? 'শ্বাস নিন' : 'শ্বাস ছাড়ুন'),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeInOut,
                  width: _isRunning && _isInhaling ? 214 : 154,
                  height: _isRunning && _isInhaling ? 214 : 154,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accent.withValues(alpha: 0.34),
                        accent.withValues(alpha: 0.10),
                      ],
                    ),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.52),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.20),
                        blurRadius: 30,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isComplete
                            ? Icons.check_circle_rounded
                            : Icons.air_rounded,
                        color: accent,
                        size: 34,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isComplete
                            ? 'সম্পন্ন'
                            : !_isRunning
                            ? 'প্রস্তুত?'
                            : _isInhaling
                            ? 'শ্বাস নিন'
                            : 'শ্বাস ছাড়ুন',
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _clock,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(99),
              backgroundColor: colors.surfaceContainerHighest,
              color: accent,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _toggleSession,
              icon: Icon(
                _isRunning
                    ? Icons.pause_rounded
                    : _isComplete
                    ? Icons.replay_rounded
                    : Icons.play_arrow_rounded,
              ),
              label: Text(
                _isRunning
                    ? 'Pause'
                    : _isComplete
                    ? 'আবার করুন'
                    : _remainingSeconds < _sessionSeconds
                    ? 'Continue'
                    : 'শুরু করুন',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Reset'),
            ),
            const SizedBox(height: 22),
            const HealthSafetyNotice(
              title: 'নিজের স্বাচ্ছন্দ্যকে অগ্রাধিকার দিন',
              message:
                  'শ্বাস বড় বা গভীর করতে জোর করবেন না। মাথা ঘোরা, শ্বাসকষ্ট বা panic বাড়লে থামুন এবং স্বাভাবিক শ্বাসে ফিরুন। এই exercise চিকিৎসার বিকল্প নয়।',
            ),
            const SizedBox(height: 10),
            const Center(
              child: HealthEvidenceButton(sourceIds: ['nhs_breathing']),
            ),
            const SizedBox(height: 8),
            Text(
              'NHS guidance অনুযায়ী নিয়মিত অন্তত ৫ মিনিট practice সবচেয়ে উপকারী হতে পারে।',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
