import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:ash_shifa_ruqyah/features/bazzer_reminder/screens/bazzer_reminder_page.dart';
import 'package:ash_shifa_ruqyah/features/easy_home/screens/easy_home_page.dart';
import 'package:ash_shifa_ruqyah/features/health_tips/screens/health_home_page.dart';
import 'package:ash_shifa_ruqyah/features/mom_child_care/screens/mom_child_care_page.dart';
import 'package:ash_shifa_ruqyah/features/prayer_reminder/prayer_reminder_page.dart';
import 'package:ash_shifa_ruqyah/features/ruqyah/screens/ruqyah_page.dart';

import 'auth_dialogs.dart';
import 'login_page.dart';
import 'profile_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.isDarkMode,
    required this.toggleTheme,
  });

  final bool isDarkMode;
  final VoidCallback toggleTheme;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final palette = _HomePalette(isDarkMode: isDarkMode);
    final features = _features();
    final displayName = user?.displayName?.trim();
    final visibleName = displayName != null && displayName.isNotEmpty
        ? displayName
        : 'Ash-Shifa Ruqyah';

    return Scaffold(
      backgroundColor: palette.background,
      appBar: _DashboardAppBar(
        name: visibleName,
        palette: palette,
        isSignedIn: user != null,
        onThemePressed: toggleTheme,
        onLogoutPressed: user == null ? null : () => _logout(context),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.15,
            colors: [
              palette.green.withValues(alpha: isDarkMode ? 0.10 : 0.07),
              palette.background.withValues(alpha: 0),
              palette.background,
            ],
            stops: const [0, 0.52, 1],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final singleColumn = constraints.maxWidth < 340;
            final compactHeight = constraints.maxHeight < 690;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    compactHeight ? 10 : 16,
                    18,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _InspirationCard(
                      palette: palette,
                      compact: compactHeight,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    compactHeight ? 14 : 22,
                    18,
                    10,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _SectionHeading(palette: palette),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: singleColumn ? 1 : 2,
                      mainAxisSpacing: 11,
                      crossAxisSpacing: 11,
                      mainAxisExtent: singleColumn
                          ? 126
                          : compactHeight
                          ? 116
                          : 132,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final feature = features[index];
                      return _FeatureCard(
                        feature: feature,
                        palette: palette,
                        onTap: () => Navigator.of(
                          context,
                        ).push(MaterialPageRoute(builder: feature.builder)),
                      );
                    }, childCount: features.length),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    compactHeight ? 10 : 18,
                    18,
                    compactHeight ? 10 : 22,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _SafetyNote(palette: palette),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) {
          _openBottomDestination(context, index, isSignedIn: user != null);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'হোম',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories_rounded),
            label: 'রুকইয়াহ',
          ),
          NavigationDestination(
            icon: Icon(Icons.family_restroom_outlined),
            selectedIcon: Icon(Icons.family_restroom_rounded),
            label: 'যত্ন',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'প্রোফাইল',
          ),
        ],
      ),
    );
  }

  List<_HomeFeature> _features() => [
    _HomeFeature(
      title: 'নামাজের সময়',
      subtitle: 'সময় ও রিমাইন্ডার',
      icon: Icons.schedule_rounded,
      accent: const Color(0xFFF4B942),
      builder: (_) => const PrayerReminderPage(),
    ),
    _HomeFeature(
      title: 'স্বাস্থ্য টিপস',
      subtitle: 'দৈনিক স্বাস্থ্য সহায়তা',
      icon: Icons.health_and_safety_rounded,
      accent: const Color(0xFF35D399),
      builder: (_) => const HealthHomePage(),
    ),
    _HomeFeature(
      title: 'মা ও শিশু',
      subtitle: 'পরিবারের যত্ন',
      icon: Icons.family_restroom_rounded,
      accent: const Color(0xFFF472B6),
      builder: (_) => const MomChildCarePage(),
    ),
    _HomeFeature(
      title: 'ইজি হোম',
      subtitle: 'ঘর ও ভাড়ার ব্যবস্থাপনা',
      icon: Icons.home_work_rounded,
      accent: const Color(0xFF60A5FA),
      builder: (_) => const EasyHomePage(),
    ),
    _HomeFeature(
      title: 'রুকইয়াহ',
      subtitle: 'কুরআন-সুন্নাহভিত্তিক যত্ন',
      icon: Icons.auto_stories_rounded,
      accent: const Color(0xFFA78BFA),
      builder: (_) => const RuqyahPage(),
    ),
    _HomeFeature(
      title: 'বাজার তালিকা',
      subtitle: 'সহজ ও গোছানো তালিকা',
      icon: Icons.shopping_cart_checkout_rounded,
      accent: const Color(0xFF2DD4BF),
      builder: (_) => const BazzerReminderPage(),
    ),
  ];

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showLogoutConfirmation(context);
    if (!shouldLogout || !context.mounted) return;

    try {
      await FirebaseAuth.instance.signOut();
    } on FirebaseAuthException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logout করা যায়নি। আবার চেষ্টা করুন।')),
        );
      }
    }
  }

  void _openBottomDestination(
    BuildContext context,
    int index, {
    required bool isSignedIn,
  }) {
    switch (index) {
      case 0:
        return;
      case 1:
        _open(context, const RuqyahPage());
        return;
      case 2:
        _open(context, const MomChildCarePage());
        return;
      case 3:
        if (isSignedIn) {
          _open(context, const ProfilePage());
        } else {
          _open(context, const LoginPage());
        }
        return;
    }
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

class _DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _DashboardAppBar({
    required this.name,
    required this.palette,
    required this.isSignedIn,
    required this.onThemePressed,
    this.onLogoutPressed,
  });

  final String name;
  final _HomePalette palette;
  final bool isSignedIn;
  final VoidCallback onThemePressed;
  final VoidCallback? onLogoutPressed;

  @override
  Size get preferredSize => const Size.fromHeight(78);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: preferredSize.height,
      backgroundColor: palette.background,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 18,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'আসসালামু আলাইকুম',
            style: TextStyle(
              color: palette.secondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      actions: [
        _AppBarAction(
          icon: palette.isDarkMode
              ? Icons.light_mode_rounded
              : Icons.dark_mode_rounded,
          tooltip: palette.isDarkMode ? 'Light mode' : 'Dark mode',
          color: palette.gold,
          onPressed: onThemePressed,
        ),
        if (isSignedIn && onLogoutPressed != null) ...[
          const SizedBox(width: 7),
          _AppBarAction(
            icon: Icons.logout_rounded,
            tooltip: 'Logout',
            color: palette.rose,
            onPressed: onLogoutPressed!,
          ),
        ],
        const SizedBox(width: 14),
      ],
    );
  }
}

class _AppBarAction extends StatelessWidget {
  const _AppBarAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.48)),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
        ),
      ),
    );
  }
}

class _InspirationCard extends StatelessWidget {
  const _InspirationCard({required this.palette, required this.compact});

  final _HomePalette palette;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final surface = Color.alphaBlend(
      palette.gold.withValues(alpha: palette.isDarkMode ? 0.10 : 0.08),
      palette.surface,
    );

    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 20,
        compact ? 13 : 18,
        compact ? 14 : 20,
        compact ? 13 : 18,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: palette.gold.withValues(
            alpha: palette.isDarkMode ? 0.46 : 0.58,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: palette.gold, size: 17),
              const SizedBox(width: 7),
              Text(
                'আজকের আয়াত',
                style: TextStyle(
                  color: palette.gold,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 6 : 11),
          Text(
            '“আমি নাযিল করছি এমন কোরআন, যা মুমিনদের জন্য শিফা ও রহমত।”',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.primaryText,
              fontSize: compact ? 13.8 : 15.2,
              height: 1.48,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: compact ? 3 : 7),
          Text(
            'সূরা আল-ইসরা • আয়াত ৮২',
            style: TextStyle(
              color: palette.secondaryText,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.palette});

  final _HomePalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'আপনার প্রয়োজনীয় সেবা',
          style: TextStyle(
            color: palette.primaryText,
            fontSize: 18.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'এক জায়গায় পরিবার, স্বাস্থ্য ও দৈনন্দিন সহায়তা',
          style: TextStyle(
            color: palette.secondaryText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatefulWidget {
  const _FeatureCard({
    required this.feature,
    required this.palette,
    required this.onTap,
  });

  final _HomeFeature feature;
  final _HomePalette palette;
  final VoidCallback onTap;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final accent = palette.effectiveAccent(widget.feature.accent);
    final surface = Color.alphaBlend(
      accent.withValues(alpha: palette.isDarkMode ? 0.17 : 0.11),
      palette.surface,
    );

    return Semantics(
      button: true,
      label: widget.feature.title,
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: accent.withValues(alpha: _pressed ? 0.76 : 0.48),
              width: _pressed ? 1.3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _pressed
                    ? accent.withValues(alpha: 0.19)
                    : palette.shadow,
                blurRadius: _pressed ? 19 : 13,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (value) {
                if (mounted) setState(() => _pressed = value);
              },
              splashColor: accent.withValues(alpha: 0.16),
              highlightColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 39,
                          height: 39,
                          decoration: BoxDecoration(
                            color: Color.alphaBlend(
                              accent.withValues(alpha: 0.20),
                              palette.surface,
                            ),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            widget.feature.icon,
                            color: accent,
                            size: 22,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_outward_rounded,
                          color: accent,
                          size: 17,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      widget.feature.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.primaryText,
                        fontSize: 14.7,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.feature.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.secondaryText,
                        fontSize: 10.8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SafetyNote extends StatelessWidget {
  const _SafetyNote({required this.palette});

  final _HomePalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.shield_outlined, color: palette.green, size: 17),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'আপনার account ও ব্যক্তিগত তথ্য নিরাপদ রাখুন।',
            style: TextStyle(
              color: palette.secondaryText,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _HomePalette {
  _HomePalette({required this.isDarkMode});

  final bool isDarkMode;

  Color get background =>
      isDarkMode ? const Color(0xFF07111F) : const Color(0xFFF1F5F3);
  Color get surface =>
      isDarkMode ? const Color(0xFF0E1A2B) : const Color(0xFFFFFFFF);
  Color get primaryText =>
      isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF10211B);
  Color get secondaryText =>
      isDarkMode ? const Color(0xFFC2CFDD) : const Color(0xFF40554D);
  Color get green =>
      isDarkMode ? const Color(0xFF55E0AC) : const Color(0xFF087A57);
  Color get gold =>
      isDarkMode ? const Color(0xFFF6C453) : const Color(0xFF8A5A00);
  Color get rose =>
      isDarkMode ? const Color(0xFFFF9AB0) : const Color(0xFFB4234D);
  Color get shadow => Colors.black.withValues(alpha: isDarkMode ? 0.24 : 0.09);

  Color effectiveAccent(Color color) {
    if (isDarkMode) return color;
    return Color.lerp(color, Colors.black, 0.30)!;
  }
}

class _HomeFeature {
  const _HomeFeature({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.builder,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final WidgetBuilder builder;
}
