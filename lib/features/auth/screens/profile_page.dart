import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../data/user_profile_repository.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserProfileRepository _profiles = UserProfileRepository();

  User? _user;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
  }

  Future<void> _editName() async {
    final user = _user;
    if (user == null || _isSaving) return;

    final controller = TextEditingController(text: user.displayName);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('নাম পরিবর্তন'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          maxLength: 120,
          decoration: const InputDecoration(
            labelText: 'পূর্ণ নাম',
            hintText: 'আপনার নাম লিখুন',
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('সংরক্ষণ'),
          ),
        ],
      ),
    );
    controller.dispose();

    final trimmedName = name?.trim();
    if (trimmedName == null) return;
    if (trimmedName.length < 2) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('নাম কমপক্ষে ২ অক্ষরের হতে হবে।')),
        );
      }
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _profiles.updateName(user: user, name: trimmedName);
      await user.reload();
      if (mounted) {
        setState(() => _user = FirebaseAuth.instance.currentUser);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('প্রোফাইল আপডেট হয়েছে।')),
        );
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'প্রোফাইল আপডেট করা যায়নি (${error.code})। আবার চেষ্টা করুন।',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _logout() async {
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
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logout করা যায়নি। আবার চেষ্টা করুন।')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(
          child: Text(
            'প্রোফাইল দেখতে Login করুন।',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final name = user.displayName?.trim();
    final visibleName = name != null && name.isNotEmpty ? name : 'ব্যবহারকারী';
    final phone = user.phoneNumber?.trim();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('প্রোফাইল'),
        centerTitle: true,
        backgroundColor: AppColors.primaryapp,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          const CircleAvatar(
            radius: 42,
            backgroundColor: Color(0xFF214C3A),
            child: Icon(Icons.person_rounded, color: Colors.white, size: 46),
          ),
          const SizedBox(height: 16),
          Text(
            visibleName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            user.email ?? 'ইমেইল পাওয়া যায়নি',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 28),
          _ProfileRow(
            icon: Icons.badge_outlined,
            label: 'নাম',
            value: visibleName,
          ),
          _ProfileRow(
            icon: Icons.email_outlined,
            label: 'ইমেইল',
            value: user.email ?? 'যোগ করা হয়নি',
          ),
          if (phone != null && phone.isNotEmpty)
            _ProfileRow(
              icon: Icons.phone_outlined,
              label: 'ফোন',
              value: phone,
            ),
          _ProfileRow(
            icon: user.emailVerified
                ? Icons.verified_outlined
                : Icons.info_outline_rounded,
            label: 'ইমেইল স্ট্যাটাস',
            value: user.emailVerified ? 'Verified' : 'Not verified',
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _isSaving ? null : _editName,
            icon: _isSaving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.edit_outlined),
            label: const Text('নাম পরিবর্তন'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'এখন শুধু প্রয়োজনীয় account তথ্য রাখা হয়েছে। ঠিকানা, জন্মতারিখ '
            'বা অন্যান্য তথ্য প্রয়োজন হলে পরে যোগ করা যাবে।',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, height: 1.4, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.greenAccent.shade400),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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
