import 'package:flutter/material.dart';

import '../data/health_content_catalog.dart';
import '../widgets/health_source_sheet.dart';

class DietDetailScreen extends StatelessWidget {
  const DietDetailScreen({super.key, required this.guide});

  final DietGuide guide;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final positive = isDark
        ? const Color(0xFF4ADE80)
        : const Color(0xFF087A57);
    final caution = isDark
        ? const Color(0xFFFBBF24)
        : const Color(0xFF8A5A00);

    return Scaffold(
      appBar: AppBar(title: Text(guide.title), centerTitle: true),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(17, 8, 17, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  positive.withValues(alpha: 0.17),
                  colors.secondary.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: positive.withValues(alpha: 0.30)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: positive.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    healthIconFor(guide.iconKey),
                    color: positive,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guide.title,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        guide.summary,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          _FoodListCard(
            title: 'বেশি বেছে নিন',
            subtitle: 'পরিমাণ ও ব্যক্তিগত restriction বিবেচনায়',
            items: guide.chooseMoreOften,
            icon: Icons.add_circle_outline_rounded,
            accent: positive,
          ),
          const SizedBox(height: 12),
          _FoodListCard(
            title: 'কম বা সীমিত রাখুন',
            subtitle: 'সম্পূর্ণ নিষেধ নয়—নিজের clinical plan আগে',
            items: guide.limitMoreOften,
            icon: Icons.remove_circle_outline_rounded,
            accent: caution,
          ),
          const SizedBox(height: 12),
          HealthSafetyNotice(
            title: 'Clinical note',
            message: guide.clinicalNote,
          ),
          const SizedBox(height: 14),
          Center(child: HealthEvidenceButton(sourceIds: guide.sourceIds)),
          const SizedBox(height: 11),
          Text(
            'এই তথ্য রোগ নির্ণয়, meal prescription বা ওষুধ পরিবর্তনের নির্দেশ নয়।',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodListCard extends StatelessWidget {
  const _FoodListCard({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final List<String> items;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: accent, size: 23),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 10.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 13.2,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
