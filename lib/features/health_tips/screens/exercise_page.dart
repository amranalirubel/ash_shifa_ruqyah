import 'package:flutter/material.dart';

import '../../../data/repositories/health_repository.dart';
import '../data/health_content_catalog.dart';
import '../widgets/health_source_sheet.dart';
import 'breathing_session_page.dart';

class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  static const HealthRepository _repository = HealthRepository();

  final TextEditingController _searchController = TextEditingController();
  HealthGuideCategory? _selectedCategory;

  List<MovementGuide> get _filteredGuides {
    final query = _searchController.text.trim().toLowerCase();

    return _repository.movementGuides.where((guide) {
      final matchesCategory =
          _selectedCategory == null || guide.category == _selectedCategory;
      final haystack =
          (guide.title + ' ' + guide.summary + ' ' + guide.category.label)
              .toLowerCase();
      return matchesCategory && (query.isEmpty || haystack.contains(query));
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openGuide(MovementGuide guide) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => MovementGuidePage(guide: guide)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final guides = _filteredGuides;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ব্যায়াম ও Mindfulness'),
        centerTitle: true,
      ),
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
            sliver: SliverToBoxAdapter(
              child: HealthSafetyNotice(
                title: 'শুরু করার আগে',
                message:
                    'এগুলো প্রাপ্তবয়স্কদের সাধারণ educational guide। নতুন আঘাত, গুরুতর/দ্রুত বাড়তে থাকা ব্যথা, surgery, pregnancy, heart/neurological condition বা balance problem থাকলে clinician/physiotherapist-এর অনুমতি নিন।',
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            sliver: SliverToBoxAdapter(
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'হাঁটু, কোমর, হাত বা meditation খুঁজুন',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          tooltip: 'Search clear করুন',
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 46,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: FilterChip(
                      selected: _selectedCategory == null,
                      label: const Text('সব'),
                      onSelected: (_) {
                        setState(() => _selectedCategory = null);
                      },
                    ),
                  ),
                  ...HealthGuideCategory.values.map(
                    (category) => Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: FilterChip(
                        selected: _selectedCategory == category,
                        label: Text(category.label),
                        onSelected: (_) {
                          setState(() => _selectedCategory = category);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Text(
                    'নিরাপদভাবে শুরু করুন',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    guides.length.toString() + 'টি guide',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (guides.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Text(
                    'এই search-এর সঙ্গে কোনো guide মেলেনি।',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              sliver: SliverList.separated(
                itemCount: guides.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final guide = guides[index];
                  return _MovementGuideCard(
                    guide: guide,
                    onTap: () => _openGuide(guide),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class MovementGuidePage extends StatelessWidget {
  const MovementGuidePage({super.key, required this.guide});

  final MovementGuide guide;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = _categoryAccent(context, guide.category);

    return Scaffold(
      appBar: AppBar(title: Text(guide.category.label), centerTitle: true),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(17, 8, 17, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: accent.withValues(alpha: 0.34)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.20
                        : 0.07,
                  ),
                  blurRadius: 20,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Icon(
                        healthIconFor(guide.iconKey),
                        color: accent,
                        size: 29,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            guide.title,
                            style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 21,
                              height: 1.25,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Wrap(
                            spacing: 7,
                            runSpacing: 6,
                            children: [
                              _MetaPill(
                                icon: Icons.schedule_rounded,
                                label: guide.duration,
                                accent: accent,
                              ),
                              _MetaPill(
                                icon: Icons.signal_cellular_alt_rounded,
                                label: guide.level,
                                accent: accent,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  guide.summary,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    height: 1.48,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SectionTitle(
            icon: Icons.format_list_numbered_rounded,
            title: 'ধাপে ধাপে',
            color: accent,
          ),
          const SizedBox(height: 10),
          ...guide.steps.indexed.map(
            (entry) =>
                _StepCard(number: entry.$1 + 1, text: entry.$2, accent: accent),
          ),
          const SizedBox(height: 8),
          _InformationCard(
            icon: Icons.repeat_rounded,
            title: 'কতবার করবেন',
            text: guide.dosage,
            accent: colors.primary,
          ),
          const SizedBox(height: 12),
          _WarningCard(items: guide.stopAndSeekHelp),
          if (guide.hasGuidedSession) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BreathingSessionPage(),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('৫ মিনিটের guided session শুরু করুন'),
            ),
          ],
          const SizedBox(height: 12),
          Center(child: HealthEvidenceButton(sourceIds: guide.sourceIds)),
          const SizedBox(height: 10),
          Text(
            'Content version ' +
                HealthContentCatalog.schemaVersion.toString() +
                ' • Editorial check ' +
                HealthContentCatalog.editorialReviewDate,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

class _MovementGuideCard extends StatelessWidget {
  const _MovementGuideCard({required this.guide, required this.onTap});

  final MovementGuide guide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = _categoryAccent(context, guide.category);

    return Semantics(
      button: true,
      label: guide.title + '. ' + guide.summary,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.outline.withValues(alpha: 0.55)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    healthIconFor(guide.iconKey),
                    color: accent,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guide.category.label,
                        style: TextStyle(
                          color: accent,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        guide.title,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        guide.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          height: 1.35,
                          fontSize: 11.8,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            color: colors.onSurfaceVariant,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            guide.duration,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: colors.onSurfaceVariant,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.text,
    required this.accent,
  });

  final int number;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: colors.outline.withValues(alpha: 0.48)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: accent.withValues(alpha: 0.13),
            child: Text(
              number.toString(),
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: TextStyle(
                  color: colors.onSurface,
                  height: 1.45,
                  fontSize: 13.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.error.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.report_outlined, color: colors.error, size: 21),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'থামুন এবং প্রয়োজন হলে চিকিৎসা নিন',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: colors.error)),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        height: 1.4,
                        fontSize: 12.5,
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

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 22),
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
                  text,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

Color _categoryAccent(BuildContext context, HealthGuideCategory category) {
  final raw = switch (category) {
    HealthGuideCategory.dailyMovement => const Color(0xFF22C55E),
    HealthGuideCategory.kneeCare => const Color(0xFFF59E0B),
    HealthGuideCategory.backCare => const Color(0xFF38BDF8),
    HealthGuideCategory.handCare => const Color(0xFFA78BFA),
    HealthGuideCategory.mindfulness => const Color(0xFF2DD4BF),
  };

  return Theme.of(context).brightness == Brightness.dark
      ? raw
      : Color.lerp(raw, Colors.black, 0.30)!;
}
