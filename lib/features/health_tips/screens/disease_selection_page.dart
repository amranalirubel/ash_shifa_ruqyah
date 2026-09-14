import 'package:flutter/material.dart';

import '../../../data/repositories/health_repository.dart';
import '../data/health_content_catalog.dart';
import '../widgets/health_source_sheet.dart';
import 'diet_detail_screen.dart';

class DiseaseSelectionPage extends StatefulWidget {
  const DiseaseSelectionPage({super.key});

  @override
  State<DiseaseSelectionPage> createState() => _DiseaseSelectionPageState();
}

class _DiseaseSelectionPageState extends State<DiseaseSelectionPage> {
  static const HealthRepository _repository = HealthRepository();

  final TextEditingController _searchController = TextEditingController();

  List<DietGuide> get _filteredGuides {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _repository.dietGuides;

    return _repository.dietGuides.where((guide) {
      final text = (guide.title + ' ' + guide.summary).toLowerCase();
      return text.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _open(DietGuide guide) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DietDetailScreen(guide: guide)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final guides = _filteredGuides;

    return Scaffold(
      appBar: AppBar(
        title: const Text('খাদ্য ও জীবনযাপন'),
        centerTitle: true,
      ),
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primary.withValues(alpha: 0.18),
                      colors.secondary.withValues(alpha: 0.09),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.26),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.restaurant_menu_rounded,
                        color: colors.primary,
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Evidence-informed food guide',
                            style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'স্থানীয় খাবার বেছে নেওয়ার নীতি—কঠোর meal prescription নয়',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              height: 1.35,
                              fontSize: 12.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            sliver: SliverToBoxAdapter(
              child: HealthSafetyNotice(
                title: 'ব্যক্তিভেদে পরিকল্পনা বদলায়',
                message:
                    'গর্ভাবস্থা, kidney/liver disease, food allergy, diabetes medicine/insulin বা অন্য dietary restriction থাকলে registered doctor/dietitian-এর individual plan অনুসরণ করুন।',
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            sliver: SliverToBoxAdapter(
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'খাদ্য বা স্বাস্থ্য বিষয় খুঁজুন',
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
          if (guides.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'কোনো matching guide পাওয়া যায়নি।',
                  style: TextStyle(color: colors.onSurfaceVariant),
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
                  return _DietGuideCard(
                    guide: guide,
                    onTap: () => _open(guide),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _DietGuideCard extends StatelessWidget {
  const _DietGuideCard({required this.guide, required this.onTap});

  final DietGuide guide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rawAccent = switch (guide.iconKey) {
      'glucose' => const Color(0xFF38BDF8),
      'heart' => const Color(0xFFF472B6),
      _ => const Color(0xFF22C55E),
    };
    final accent = isDark
        ? rawAccent
        : Color.lerp(rawAccent, Colors.black, 0.30)!;

    return Semantics(
      button: true,
      label: guide.title + '. ' + guide.summary,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(21),
          side: BorderSide(color: colors.outline.withValues(alpha: 0.52)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 53,
                  height: 53,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
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
                        guide.title,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        guide.summary,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          height: 1.38,
                          fontSize: 12.2,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Icon(
                            Icons.fact_check_outlined,
                            color: accent,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            guide.sourceIds.length.toString() +
                                'টি verified source',
                            style: TextStyle(
                              color: accent,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 7),
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
