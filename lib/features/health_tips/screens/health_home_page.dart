import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/repositories/health_repository.dart';
import '../data/health_content_catalog.dart';
import '../widgets/health_source_sheet.dart';
import 'bmi_calculator_screen.dart';
import 'daily_tips_page.dart';
import 'disease_selection_page.dart';
import 'exercise_page.dart';

class HealthHomePage extends StatefulWidget {
  const HealthHomePage({super.key});

  @override
  State<HealthHomePage> createState() => _HealthHomePageState();
}

class _HealthHomePageState extends State<HealthHomePage>
    with WidgetsBindingObserver {
  static const HealthRepository _repository = HealthRepository();

  final PageController _bannerController = PageController(viewportFraction: 0.94);
  Timer? _bannerTimer;
  int _bannerIndex = 0;
  bool _isForeground = true;

  List<HealthBanner> get _banners => _repository.banners;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted ||
          !_isForeground ||
          !_bannerController.hasClients ||
          _banners.length < 2) {
        return;
      }

      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;

      final next = (_bannerIndex + 1) % _banners.length;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 620),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isForeground = state == AppLifecycleState.resumed;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final sections = <_HealthSection>[
      _HealthSection(
        title: 'খাদ্য ও জীবনযাপন গাইড',
        subtitle: 'সুষম খাবার, ডায়াবেটিস, রক্তচাপ ও কোলেস্টেরল',
        icon: Icons.restaurant_menu_rounded,
        accent: const Color(0xFF22C55E),
        badge: '৪টি গাইড',
        onTap: () => _open(const DiseaseSelectionPage()),
      ),
      _HealthSection(
        title: 'Adult BMI screening',
        subtitle: '২০+ বয়সে BMI হিসাব ও দায়িত্বশীল ব্যাখ্যা',
        icon: Icons.monitor_weight_outlined,
        accent: const Color(0xFFF59E0B),
        badge: 'CDC মানদণ্ড',
        onTap: () => _open(const BmiCalculatorScreen()),
      ),
      _HealthSection(
        title: 'ব্যায়াম ও Mindfulness',
        subtitle: 'হাঁটু, কোমর, হাত-কব্জি, হাঁটা ও guided breathing',
        icon: Icons.self_improvement_rounded,
        accent: const Color(0xFF38BDF8),
        badge: '১০টি গাইড',
        onTap: () => _open(const ExercisePage()),
      ),
      _HealthSection(
        title: 'দৈনিক সুস্থতার অভ্যাস',
        subtitle: 'ছোট কাজ, দৈনিক progress এবং evidence source',
        icon: Icons.task_alt_rounded,
        accent: const Color(0xFFA78BFA),
        badge: '৭টি অভ্যাস',
        onTap: () => _open(const DailyTipsPage()),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('স্বাস্থ্য সহায়তা'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => showHealthSources(
              context,
              HealthContentCatalog.sources.keys,
            ),
            tooltip: 'সকল উৎস',
            icon: const Icon(Icons.fact_check_outlined),
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
              child: _HealthBannerCarousel(
                banners: _banners,
                controller: _bannerController,
                selectedIndex: _bannerIndex,
                onPageChanged: (index) {
                  setState(() => _bannerIndex = index);
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 10),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'আপনার স্বাস্থ্য টুলসমূহ',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'শিক্ষামূলক guidance—ব্যক্তিগত diagnosis বা prescription নয়',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            sliver: SliverList.separated(
              itemCount: sections.length,
              separatorBuilder: (_, _) => const SizedBox(height: 11),
              itemBuilder: (context, index) {
                return _HealthSectionCard(section: sections[index]);
              },
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 30),
            sliver: SliverToBoxAdapter(
              child: HealthSafetyNotice(
                title: 'নিরাপত্তা আগে',
                message:
                    'তীব্র বা দ্রুত বাড়তে থাকা উপসর্গ, শ্বাসকষ্ট, বুকব্যথা, অজ্ঞান হওয়া, নতুন দুর্বলতা/অসাড়তা বা গুরুতর আঘাতে app-এর content অনুসরণ না করে স্থানীয় জরুরি চিকিৎসাসেবা নিন।',
                urgent: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthBannerCarousel extends StatelessWidget {
  const _HealthBannerCarousel({
    required this.banners,
    required this.controller,
    required this.selectedIndex,
    required this.onPageChanged,
  });

  final List<HealthBanner> banners;
  final PageController controller;
  final int selectedIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 208,
          child: PageView.builder(
            controller: controller,
            itemCount: banners.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: _HealthBannerCard(
                  banner: banners[index],
                  index: index,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 11),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: selectedIndex == index ? 22 : 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: selectedIndex == index
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.48),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HealthBannerCard extends StatelessWidget {
  const _HealthBannerCard({required this.banner, required this.index});

  final HealthBanner banner;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    final palette = <List<Color>>[
      const [Color(0xFF0F5132), Color(0xFF123C46)],
      const [Color(0xFF203A74), Color(0xFF262B55)],
      const [Color(0xFF615016), Color(0xFF324C39)],
      const [Color(0xFF49346C), Color(0xFF21495B)],
    ];
    final raw = palette[index % palette.length];
    final gradient = isDark
        ? raw
        : raw.map((color) => Color.lerp(color, Colors.white, 0.14)!).toList();

    return Semantics(
      label: banner.title + '. ' + banner.body,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 19, 18, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(27),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.14),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -8,
              top: -12,
              child: Icon(
                healthIconFor(banner.iconKey),
                color: Colors.white.withValues(alpha: 0.08),
                size: 108,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        healthIconFor(banner.iconKey),
                        color: const Color(0xFFFDE68A),
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        banner.eyebrow,
                        style: const TextStyle(
                          color: Color(0xFFFDE68A),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    HealthEvidenceButton(
                      sourceIds: banner.sourceIds,
                      compact: true,
                      foregroundColor: Colors.white,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  banner.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    height: 1.25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  banner.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 12.8,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthSectionCard extends StatelessWidget {
  const _HealthSectionCard({required this.section});

  final _HealthSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark
        ? section.accent
        : Color.lerp(section.accent, Colors.black, 0.28)!;

    return Semantics(
      button: true,
      label: section.title + '. ' + section.subtitle,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(21),
          side: BorderSide(
            color: accent.withValues(alpha: isDark ? 0.31 : 0.38),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: section.onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 13, 15),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.14 : 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(section.icon, color: accent, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              section.title,
                              style: TextStyle(
                                color: colors.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              section.badge,
                              style: TextStyle(
                                color: accent,
                                fontSize: 9.8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        section.subtitle,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12.2,
                          height: 1.38,
                        ),
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

class _HealthSection {
  const _HealthSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.badge,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final String badge;
  final VoidCallback onTap;
}
