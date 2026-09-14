import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/repositories/health_repository.dart';
import '../data/health_content_catalog.dart';
import '../widgets/health_source_sheet.dart';

class DailyTipsPage extends StatefulWidget {
  const DailyTipsPage({super.key});

  @override
  State<DailyTipsPage> createState() => _DailyTipsPageState();
}

class _DailyTipsPageState extends State<DailyTipsPage> {
  static const HealthRepository _repository = HealthRepository();
  static const String _preferencePrefix = 'health_daily_habits_';

  final Set<String> _completedIds = <String>{};
  bool _isRestoring = true;

  List<DailyHealthTip> get _tips => _repository.dailyTips;

  String get _todayKey {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return _preferencePrefix +
        now.year.toString() +
        '-' +
        month +
        '-' +
        day;
  }

  @override
  void initState() {
    super.initState();
    _restoreCompletion();
  }

  Future<void> _restoreCompletion() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = preferences.getStringList(_todayKey) ?? const <String>[];
      final validIds = _tips.map((tip) => tip.id).toSet();
      _completedIds
        ..clear()
        ..addAll(saved.where(validIds.contains));
    } catch (_) {
      _completedIds.clear();
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  Future<void> _toggle(String id, bool complete) async {
    setState(() {
      if (complete) {
        _completedIds.add(id);
      } else {
        _completedIds.remove(id);
      }
    });

    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _todayKey,
      _completedIds.toList()..sort(),
    );
  }

  Future<void> _resetToday() async {
    if (_completedIds.isEmpty) return;

    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Icons.restart_alt_rounded),
          title: const Text('আজকের progress reset করবেন?'),
          content: const Text(
            'শুধু আজকের tick চিহ্নগুলো মুছবে; health content মুছবে না।',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('বাতিল'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (shouldReset != true || !mounted) return;
    setState(_completedIds.clear);
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_todayKey);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final completed = _completedIds.length;
    final progress = _tips.isEmpty ? 0.0 : completed / _tips.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('দৈনিক সুস্থতার অভ্যাস'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _completedIds.isEmpty ? null : _resetToday,
            tooltip: 'আজকের progress reset',
            icon: const Icon(Icons.restart_alt_rounded),
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: _isRestoring
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
              children: [
                _ProgressCard(
                  completed: completed,
                  total: _tips.length,
                  progress: progress,
                ),
                const SizedBox(height: 13),
                const HealthSafetyNotice(
                  title: 'লক্ষ্য perfection নয়—ধারাবাহিকতা',
                  message:
                      'আপনার চিকিৎসা, fluid restriction, diet plan বা activity restriction থাকলে সেটিই আগে মানুন। এই checklist সাধারণ wellbeing-এর জন্য।',
                ),
                const SizedBox(height: 17),
                Text(
                  'আজকের checklist',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 9),
                ..._tips.map(
                  (tip) => _DailyTipCard(
                    tip: tip,
                    isCompleted: _completedIds.contains(tip.id),
                    onChanged: (value) => _toggle(tip.id, value),
                  ),
                ),
                if (completed == _tips.length) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.celebration_rounded,
                          color: colors.primary,
                          size: 27,
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            'আজকের checklist সম্পন্ন। শরীরের প্রয়োজন বুঝে বিশ্রামও নিন।',
                            style: TextStyle(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w800,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  'Progress প্রতিদিন নতুনভাবে শুরু হয় এবং শুধু এই device-এ সংরক্ষিত থাকে।',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.completed,
    required this.total,
    required this.progress,
  });

  final int completed;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary.withValues(alpha: 0.20),
            colors.secondary.withValues(alpha: 0.11),
          ],
        ),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: colors.primary.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, color: colors.primary, size: 27),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'আজকের progress',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                completed.toString() + '/' + total.toString(),
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: progress,
            minHeight: 9,
            borderRadius: BorderRadius.circular(99),
            backgroundColor: colors.surface.withValues(alpha: 0.55),
          ),
        ],
      ),
    );
  }
}

class _DailyTipCard extends StatelessWidget {
  const _DailyTipCard({
    required this.tip,
    required this.isCompleted,
    required this.onChanged,
  });

  final DailyHealthTip tip;
  final bool isCompleted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = colors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: isCompleted
              ? accent.withValues(alpha: 0.40)
              : colors.outline.withValues(alpha: 0.52),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(19),
        onTap: () => onChanged(!isCompleted),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: isCompleted,
                onChanged: (value) => onChanged(value ?? false),
              ),
              const SizedBox(width: 2),
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  healthIconFor(tip.iconKey),
                  color: accent,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tip.title,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w800,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tip.details,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        height: 1.4,
                        fontSize: 12.3,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: HealthEvidenceButton(
                        sourceIds: tip.sourceIds,
                        compact: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
