import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:ash_shifa_ruqyah/features/bazzer_reminder/screens/bazzer_reminder_page.dart';
import 'package:ash_shifa_ruqyah/features/easy_home/screens/easy_home_page.dart';
import 'package:ash_shifa_ruqyah/features/health_tips/screens/health_home_page.dart';
import 'package:ash_shifa_ruqyah/features/mom_child_care/screens/mom_child_care_page.dart';
import 'package:ash_shifa_ruqyah/features/prayer_reminder/prayer_reminder_page.dart';
import 'package:ash_shifa_ruqyah/features/ruqyah/screens/ruqyah_page.dart';

import 'auth_dialogs.dart';
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
    final displayName = user?.displayName?.trim();
    final visibleName = displayName != null && displayName.isNotEmpty
        ? displayName
        : 'Ash-Shifa Ruqyah';
    final features = _features();
    final background = isDarkMode
        ? const Color(0xFF070B12)
        : const Color(0xFFF4F7F5);
    final primaryText = isDarkMode ? Colors.white : const Color(0xFF111827);
    final secondaryText = isDarkMode
        ? Colors.white60
        : const Color(0xFF5B6472);

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: isDarkMode ? 0.08 : 0.04,
              child: Image.asset('assets/banner.png', fit: BoxFit.cover),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDarkMode
                      ? const [
                          Color(0xE6070B12),
                          Color(0xF2070B12),
                          Color(0xFF070B12),
                        ]
                      : const [
                          Color(0xE6F4F7F5),
                          Color(0xF2F4F7F5),
                          Color(0xFFF4F7F5),
                        ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final useSingleColumn = constraints.maxWidth < 340;

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: _HomeHeader(
                          name: visibleName,
                          isSignedIn: user != null,
                          isDarkMode: isDarkMode,
                          primaryText: primaryText,
                          secondaryText: secondaryText,
                          onThemePressed: toggleTheme,
                          onProfilePressed: user == null
                              ? () => Navigator.of(context).maybePop()
                              : () => _open(context, const ProfilePage()),
                          onLogoutPressed: user == null
                              ? null
                              : () => _logout(context),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: _InspirationCard(isDarkMode: isDarkMode),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 26, 20, 13),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'আপনার প্রয়োজনীয় সেবা',
                              style: TextStyle(
                                color: primaryText,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'এক জায়গায় পরিবার, স্বাস্থ্য ও দৈনন্দিন সহায়তা',
                              style: TextStyle(
                                color: secondaryText,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: useSingleColumn ? 1 : 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          mainAxisExtent: useSingleColumn ? 138 : 170,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final feature = features[index];
                            return _FeatureCard(
                              feature: feature,
                              isDarkMode: isDarkMode,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: feature.builder),
                              ),
                            );
                          },
                          childCount: features.length,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                      sliver: SliverToBoxAdapter(
                        child: _SafetyNote(isDarkMode: isDarkMode),
                      ),
                    ),
                  ],
                );
              },
            ),
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
      accent: const Color(0xFFFFB020),
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

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.name,
    required this.isSignedIn,
    required this.isDarkMode,
    required this.primaryText,
    required this.secondaryText,
    required this.onThemePressed,
    required this.onProfilePressed,
    this.onLogoutPressed,
  });

  final String name;
  final bool isSignedIn;
  final bool isDarkMode;
  final Color primaryText;
  final Color secondaryText;
  final VoidCallback onThemePressed;
  final VoidCallback onProfilePressed;
  final VoidCallback? onLogoutPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'আসসালামু আলাইকুম',
                style: TextStyle(
                  color: secondaryText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: primaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _HeaderActionButton(
          icon: isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          tooltip: isDarkMode ? 'Light mode' : 'Dark mode',
          accent: const Color(0xFFFFB020),
          isDarkMode: isDarkMode,
          onPressed: onThemePressed,
        ),
        const SizedBox(width: 8),
        _HeaderActionButton(
          icon: isSignedIn
              ? Icons.person_outline_rounded
              : Icons.login_rounded,
          tooltip: isSignedIn ? 'প্রোফাইল' : 'Login',
          accent: const Color(0xFF35D399),
          isDarkMode: isDarkMode,
          onPressed: onProfilePressed,
        ),
        if (onLogoutPressed != null) ...[
          const SizedBox(width: 8),
          _HeaderActionButton(
            icon: Icons.logout_rounded,
            tooltip: 'Logout',
            accent: const Color(0xFFFB7185),
            isDarkMode: isDarkMode,
            onPressed: onLogoutPressed!,
          ),
        ],
      ],
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.tooltip,
    required this.accent,
    required this.isDarkMode,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color accent;
  final bool isDarkMode;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isDarkMode ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: accent.withValues(alpha: 0.30)),
            ),
            child: Icon(icon, color: accent, size: 21),
          ),
        ),
      ),
    );
  }
}

class _InspirationCard extends StatelessWidget {
  const _InspirationCard({required this.isDarkMode});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? const [Color(0xFF111A2E), Color(0xFF151B2C)]
              : const [Color(0xFFFFFFFF), Color(0xFFF2F7F4)],
        ),
        border: Border.all(
          color: const Color(0xFFFFB020).withValues(alpha: 0.30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.24 : 0.08),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFB020), size: 18),
              SizedBox(width: 8),
              Text(
                'আজকের আয়াত',
                style: TextStyle(
                  color: Color(0xFFFFB020),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '“আমি নাযিল করছি এমন কোরআন, যা মুমিনদের জন্য শিফা ও রহমত।”',
            style: TextStyle(
              color: isDarkMode ? Colors.white : const Color(0xFF172033),
              fontSize: 15.5,
              height: 1.55,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'সূরা আল-ইসরা • আয়াত ৮২',
            style: TextStyle(
              color: isDarkMode ? Colors.white54 : const Color(0xFF6B7280),
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  const _FeatureCard({
    required this.feature,
    required this.isDarkMode,
    required this.onTap,
  });

  final _HomeFeature feature;
  final bool isDarkMode;
  final VoidCallback onTap;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.feature.accent;
    final titleColor = widget.isDarkMode
        ? Colors.white
        : const Color(0xFF111827);
    final subtitleColor = widget.isDarkMode
        ? Colors.white54
        : const Color(0xFF667085);

    return Semantics(
      button: true,
      label: widget.feature.title,
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isDarkMode
                  ? [
                      accent.withValues(alpha: _pressed ? 0.18 : 0.11),
                      const Color(0xFF111827),
                    ]
                  : [
                      accent.withValues(alpha: _pressed ? 0.14 : 0.08),
                      Colors.white,
                    ],
            ),
            border: Border.all(
              color: accent.withValues(alpha: _pressed ? 0.55 : 0.28),
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: _pressed ? 0.18 : 0.07),
                blurRadius: _pressed ? 20 : 14,
                offset: const Offset(0, 8),
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
              splashColor: accent.withValues(alpha: 0.12),
              highlightColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 43,
                          height: 43,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.17),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            widget.feature.icon,
                            color: accent,
                            size: 24,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.north_east_rounded,
                          color: accent.withValues(alpha: 0.72),
                          size: 18,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      widget.feature.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 15.5,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.feature.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 11.5,
                        height: 1.25,
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
  const _SafetyNote({required this.isDarkMode});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.verified_user_outlined,
          color: Color(0xFF35D399),
          size: 17,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'আপনার account ও ব্যক্তিগত তথ্য নিরাপদ রাখুন।',
            style: TextStyle(
              color: isDarkMode ? Colors.white38 : const Color(0xFF7A8493),
              fontSize: 11.5,
            ),
          ),
        ),
      ],
    );
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
