import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ash_shifa_ruqyah/core/app_colors.dart';

// সব পেজ ইমপোর্ট
import 'package:ash_shifa_ruqyah/features/prayer_reminder/prayer_reminder_page.dart';
import 'package:ash_shifa_ruqyah/features/health_tips/screens/health_home_page.dart';
import 'package:ash_shifa_ruqyah/features/ruqyah/screens/ruqyah_page.dart';
import 'package:ash_shifa_ruqyah/features/mom_child_care/screens/mom_child_care_page.dart';
import 'package:ash_shifa_ruqyah/features/bazzer_reminder/screens/bazzer_reminder_page.dart'; // পাথ চেক করুন
import 'package:ash_shifa_ruqyah/features/easy_home/screens/easy_home_page.dart';

import 'profile_page.dart';

class HomePage extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback toggleTheme;

  const HomePage({
    super.key,
    required this.isDarkMode,
    required this.toggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Home",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primaryapp,
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
              tooltip: isDarkMode ? 'Light mode' : 'Dark mode',
              onPressed: toggleTheme,
            ),
            if (user != null)
              IconButton(
                icon: const Icon(Icons.account_circle_outlined),
                tooltip: 'প্রোফাইল',
                onPressed: () => _navigateTo(context, const ProfilePage()),
              ),
            if (user != null)
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Logout',
                onPressed: () => _confirmLogout(context),
              ),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset("assets/banner.png", fit: BoxFit.cover),
            ),
            Container(color: Colors.black.withValues(alpha: 0.35)),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ListView(
                  children: [
                    _buildCard(
                      context,
                      "Prayer Reminder",
                      Icons.access_time,
                      onTap: () =>
                          _navigateTo(context, const PrayerReminderPage()),
                    ),
                    const SizedBox(height: 22),
                    _buildCard(
                      context,
                      "Health Tips",
                      Icons.health_and_safety,
                      onTap: () => _navigateTo(context, const HealthHomePage()),
                    ),
                    const SizedBox(height: 22),
                    _buildCard(
                      context,
                      "Mom & Child Care",
                      Icons.child_care,
                      onTap: () =>
                          _navigateTo(context, const MomChildCarePage()),
                    ),
                    const SizedBox(height: 22),
                    _buildCard(
                      context,
                      "EasyHome",
                      Icons.home,
                      onTap: () => _navigateTo(context, const EasyHomePage()),
                    ),
                    const SizedBox(height: 22),
                    _buildCard(
                      context,
                      "Ruqyah",
                      Icons.menu_book,
                      onTap: () => _navigateTo(context, const RuqyahPage()),
                    ),
                    const SizedBox(height: 22),
                    _buildCard(
                      context,
                      "Bazar Reminder",
                      Icons.shopping_cart,
                      onTap: () =>
                          _navigateTo(context, const BazzerReminderPage()),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout করবেন?'),
        content: const Text('এই ডিভাইসে আপনার বর্তমান session বন্ধ হবে।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

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

  // নেভিগেশন হেল্পার
  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Widget _buildCard(
    BuildContext context,
    String title,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF111111),
            Color.fromARGB(130, 48, 194, 126),
            Color(0xFF111111),
          ],
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(8, 8), blurRadius: 20),
          BoxShadow(
            color: Color(0x0DFFFFFF),
            offset: Offset(-6, -6),
            blurRadius: 18,
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          splashColor: Colors.white24,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            child: Row(
              children: [
                Icon(icon, color: Colors.orangeAccent, size: 28),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white24,
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
