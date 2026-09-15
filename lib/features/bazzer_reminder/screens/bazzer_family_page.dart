import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../repositories/bazzer_repository.dart';

class BazzerFamilySetup extends StatefulWidget {
  const BazzerFamilySetup({super.key, required this.repository});

  final BazzerRepository repository;

  @override
  State<BazzerFamilySetup> createState() => _BazzerFamilySetupState();
}

class _BazzerFamilySetupState extends State<BazzerFamilySetup> {
  final _codeController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() work) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await work();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('পরিবারে যুক্ত করা যায়নি: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Icon(
              Icons.family_restroom_rounded,
              color: colors.primary,
              size: 54,
            ),
            const SizedBox(height: 12),
            Text(
              'এক পরিবারের একটি বাজার তালিকা',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'মূল অ্যাকাউন্ট একটি নিরাপদ কোড তৈরি করবে। পরিবারের অন্য সদস্যরা '
              'নিজ নিজ account দিয়ে সেই কোডে যুক্ত হবে।',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                      await widget.repository.createFamily();
                    }),
              icon: const Icon(Icons.add_home_work_outlined),
              label: const Text('নতুন পরিবার তৈরি করুন (মূল অ্যাকাউন্ট)'),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 14,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z2-9-]')),
              ],
              decoration: const InputDecoration(
                labelText: 'পরিবারের ১২ অক্ষরের কোড',
                prefixIcon: Icon(Icons.key_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () => _run(
                      () => widget.repository.joinFamily(_codeController.text),
                    ),
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('এই কোড দিয়ে সদস্য হিসেবে যুক্ত হোন'),
            ),
            const SizedBox(height: 18),
            Text(
              'কোড তৈরি/যোগ দেওয়া internet ছাড়া সম্ভব নয়। যুক্ত হওয়ার পর '
              'ফোনে আগে দেখা তালিকা offline দেখা যায় এবং নতুন আইটেম '
              'সংযোগ ফিরলে পরিবারের সবার ফোনে পৌঁছায়।',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class BazzerFamilyManagePage extends StatelessWidget {
  const BazzerFamilyManagePage({
    super.key,
    required this.family,
    required this.repository,
  });

  final BazzerFamily family;
  final BazzerRepository repository;

  void _message(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _toggleJoin(BuildContext context, bool enabled) async {
    try {
      await repository.setJoiningEnabled(family.id, enabled);
      if (context.mounted) {
        _message(
          context,
          enabled
              ? 'নতুন সদস্য যোগ করা চালু হয়েছে।'
              : 'নতুন সদস্য যোগ করা বন্ধ হয়েছে।',
        );
      }
    } catch (error) {
      if (context.mounted) _message(context, 'পরিবর্তন করা যায়নি: $error');
    }
  }

  Future<void> _setActive(
    BuildContext context,
    BazzerMember member,
    bool active,
  ) async {
    if (!active) {
      final approved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('এই সদস্যকে বাদ দেবেন?'),
          content: Text(
            '${member.name} আর নতুন বাজারের list দেখতে বা যোগ করতে পারবে না। '
            'আগে offline-এ দেখা তথ্য তার ফোন থেকে দূর থেকে মুছে ফেলা যাবে না।',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('বাতিল'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('বাদ দিন'),
            ),
          ],
        ),
      );
      if (approved != true || !context.mounted) return;
    }
    try {
      await repository.setMemberActive(family.id, member.uid, active);
      if (context.mounted)
        _message(
          context,
          active
              ? 'সদস্য আবার যুক্ত হয়েছে।'
              : 'সদস্যের প্রবেশাধিকার বন্ধ হয়েছে।',
        );
    } catch (error) {
      if (context.mounted)
        _message(context, 'সদস্য পরিবর্তন করা যায়নি: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('পরিবার পরিচালনা')),
      body: StreamBuilder<BazzerFamily?>(
        stream: repository.watchFamily(family.id),
        builder: (context, familySnapshot) {
          final current = familySnapshot.data ?? family;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'পরিবারের কোড',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        current.inviteCode,
                        style: const TextStyle(
                          fontSize: 22,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: current.inviteCode),
                          );
                          if (context.mounted)
                            _message(context, 'কোড কপি হয়েছে।');
                        },
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('কপি করুন'),
                      ),
                      Text(
                        'শুধু পরিচিত পরিবারের সদস্যদের কোড দিন।',
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              SwitchListTile.adaptive(
                title: const Text('নতুন সদস্য যুক্ত হতে পারবে'),
                subtitle: const Text(
                  'বন্ধ করলে পুরোনো সদস্যরা থাকবেন, নতুন কেউ কোডে যুক্ত হবে না।',
                ),
                value: current.joiningEnabled,
                onChanged: (enabled) => _toggleJoin(context, enabled),
              ),
              const Divider(),
              Text(
                'পরিবারের সদস্য',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              StreamBuilder<List<BazzerMember>>(
                stream: repository.watchMembers(family.id),
                builder: (context, snapshot) {
                  if (snapshot.hasError)
                    return const Text(
                      'সদস্য দেখানো যায়নি। Firestore rules পরীক্ষা করুন।',
                    );
                  final members = snapshot.data ?? const <BazzerMember>[];
                  return Column(
                    children: [
                      const ListTile(
                        leading: Icon(Icons.admin_panel_settings_outlined),
                        title: Text('মূল অ্যাকাউন্ট'),
                        subtitle: Text('বাজার করা হয়েছে চিহ্নিত করতে পারে'),
                      ),
                      for (final member in members)
                        ListTile(
                          leading: Icon(
                            member.active
                                ? Icons.person_rounded
                                : Icons.person_off_outlined,
                          ),
                          title: Text(member.name),
                          subtitle: Text(
                            member.active
                                ? 'তালিকা দেখতে ও যোগ করতে পারে'
                                : 'বাদ দেওয়া হয়েছে • আগের তথ্য রাখা আছে',
                          ),
                          trailing: TextButton(
                            onPressed: () =>
                                _setActive(context, member, !member.active),
                            child: Text(
                              member.active ? 'বাদ দিন' : 'ফিরিয়ে নিন',
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                'সদস্য বাদ দিলে নতুন access সঙ্গে সঙ্গে server-এ বন্ধ হয়; '
                'offline ফোনে আগের cache মুছে যাবে—এমন প্রতিশ্রুতি দেওয়া যায় না।',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }
}
