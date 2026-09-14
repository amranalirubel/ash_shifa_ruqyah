import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/user_profile_repository.dart';
import 'auth_dialogs.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserProfileRepository _profiles = UserProfileRepository();

  User? _user;
  bool _isSaving = false;
  bool _isSendingVerification = false;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    unawaited(_refreshUser());
  }

  Future<void> _refreshUser() async {
    try {
      await _user?.reload();
      if (mounted) {
        setState(() => _user = FirebaseAuth.instance.currentUser);
      }
    } on FirebaseAuthException {
      // Cached Auth data remains usable while offline.
    }
  }

  Future<void> _editName() async {
    final user = _user;
    if (user == null || _isSaving) return;

    final name = await showEditNameDialog(
      context,
      initialName: user.displayName ?? '',
    );
    final trimmedName = name?.trim();
    if (trimmedName == null) return;

    setState(() => _isSaving = true);
    try {
      await _profiles.updateName(user: user, name: trimmedName);
      await user.reload();
      if (mounted) {
        setState(() => _user = FirebaseAuth.instance.currentUser);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('প্রোফাইল আপডেট হয়েছে।')));
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

  Future<void> _sendVerificationEmail() async {
    final user = _user;
    if (user == null || user.emailVerified || _isSendingVerification) return;

    setState(() => _isSendingVerification = true);
    try {
      await user.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email পাঠানো হয়েছে। Inbox ও Spam দেখুন।'),
          ),
        );
      }
    } on FirebaseAuthException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email পাঠানো যায়নি। আবার চেষ্টা করুন।'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingVerification = false);
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showLogoutConfirmation(context);
    if (!shouldLogout || !mounted) return;

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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('প্রোফাইল')),
        body: Center(
          child: Text(
            'প্রোফাইল দেখতে Login করুন।',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ),
      );
    }

    final name = user.displayName?.trim();
    final visibleName = name != null && name.isNotEmpty ? name : 'ব্যবহারকারী';
    final phone = user.phoneNumber?.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('প্রোফাইল'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        children: [
          _ProfileHeader(
            name: visibleName,
            email: user.email ?? 'ইমেইল পাওয়া যায়নি',
          ),
          const SizedBox(height: 18),
          Text(
            'Account information',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
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
            _ProfileRow(icon: Icons.phone_outlined, label: 'ফোন', value: phone),
          _ProfileRow(
            icon: user.emailVerified
                ? Icons.verified_rounded
                : Icons.info_outline_rounded,
            label: 'ইমেইল স্ট্যাটাস',
            value: user.emailVerified ? 'Verified' : 'Not verified',
            statusColor: user.emailVerified ? colors.primary : colors.secondary,
          ),
          const SizedBox(height: 12),
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
          if (!user.emailVerified) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _isSendingVerification
                  ? null
                  : _sendVerificationEmail,
              icon: _isSendingVerification
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.mark_email_read_outlined),
              label: const Text('Verification email পাঠান'),
            ),
          ],
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.error,
              side: BorderSide(color: colors.error),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'এখন শুধু প্রয়োজনীয় account তথ্য রাখা হয়েছে। ঠিকানা, জন্মতারিখ '
            'বা অন্যান্য তথ্য প্রয়োজন হলে পরে যোগ করা যাবে।',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              height: 1.45,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outline.withValues(alpha: 0.62)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.22
                  : 0.07,
            ),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 41,
            backgroundColor: colors.primaryContainer,
            child: Icon(
              Icons.person_rounded,
              color: colors.onPrimaryContainer,
              size: 45,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            email,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
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
    this.statusColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? statusColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = statusColor ?? colors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline.withValues(alpha: 0.58)),
      ),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
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
