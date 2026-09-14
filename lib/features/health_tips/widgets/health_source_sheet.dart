import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/health_content_catalog.dart';

IconData healthIconFor(String key) => switch (key) {
  'walk' => Icons.directions_walk_rounded,
  'sleep' => Icons.bedtime_rounded,
  'nutrition' => Icons.restaurant_rounded,
  'breathing' => Icons.air_rounded,
  'movement' => Icons.accessibility_new_rounded,
  'water' => Icons.water_drop_rounded,
  'safety' => Icons.health_and_safety_rounded,
  'knee' => Icons.airline_seat_legroom_extra_rounded,
  'chair' => Icons.event_seat_rounded,
  'back' => Icons.airline_seat_recline_extra_rounded,
  'hand' => Icons.back_hand_rounded,
  'mindfulness' => Icons.self_improvement_rounded,
  'glucose' => Icons.bloodtype_rounded,
  'heart' => Icons.favorite_rounded,
  _ => Icons.health_and_safety_rounded,
};

Future<void> showHealthSources(
  BuildContext context,
  Iterable<String> sourceIds,
) async {
  final sources = HealthContentCatalog.resolveSources(sourceIds);
  if (sources.isEmpty) return;

  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final colors = Theme.of(sheetContext).colorScheme;

      return FractionallySizedBox(
        heightFactor: sources.length > 2 ? 0.78 : 0.58,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'তথ্যের উৎস',
                    style: Theme.of(sheetContext).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Official guidance সংক্ষেপ করে বাংলায় উপস্থাপন করা হয়েছে।',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(18),
                itemCount: sources.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _SourceCard(source: sources[index]);
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

class HealthEvidenceButton extends StatelessWidget {
  const HealthEvidenceButton({
    super.key,
    required this.sourceIds,
    this.compact = false,
    this.foregroundColor,
  });

  final List<String> sourceIds;
  final bool compact;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'তথ্যের উৎস দেখুন',
      child: TextButton.icon(
        onPressed: () => showHealthSources(context, sourceIds),
        icon: const Icon(Icons.fact_check_outlined, size: 18),
        label: Text(compact ? 'উৎস' : 'তথ্যের উৎস'),
        style: TextButton.styleFrom(
          foregroundColor: foregroundColor,
          visualDensity: compact ? VisualDensity.compact : null,
          padding: compact
              ? const EdgeInsets.symmetric(horizontal: 9, vertical: 6)
              : null,
        ),
      ),
    );
  }
}

class HealthSafetyNotice extends StatelessWidget {
  const HealthSafetyNotice({
    super.key,
    required this.title,
    required this.message,
    this.urgent = false,
  });

  final String title;
  final String message;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = urgent ? colors.error : colors.secondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            urgent ? Icons.emergency_outlined : Icons.info_outline_rounded,
            color: accent,
            size: 22,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    height: 1.45,
                    fontSize: 12.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.source});

  final HealthSource source;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: source.url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Source link কপি হয়েছে।')));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outline.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_outlined,
                  color: colors.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.organization,
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      source.title,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            source.url,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.verified_outlined, size: 15, color: colors.primary),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Editorial check: ${source.reviewedOn}',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _copy(context),
                tooltip: 'Link copy করুন',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.copy_rounded, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
