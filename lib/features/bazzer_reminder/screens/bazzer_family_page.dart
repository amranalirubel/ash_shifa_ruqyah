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

/// Active members can already read the family document, including its code.
/// Reuse its code and joining state without querying the admin-only directory.
class _FamilyCodeCard extends StatelessWidget {
  const _FamilyCodeCard({required this.family});

  final BazzerFamily family;

  Future<void> _copyCode(BuildContext context) async {
    try {
      await Clipboard.setData(ClipboardData(text: family.inviteCode));
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('কোড কপি হয়েছে।')));
      }
    } on PlatformException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('কপি হয়নি। কোডটি চেপে ধরে কপি করুন।')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('পরিবারের কোড', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SelectableText(
            family.inviteCode,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              fontSize: 22,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const ValueKey('bazzer-copy-family-code'),
            onPressed: () => _copyCode(context),
            icon: const Icon(Icons.copy_rounded),
            label: const Text('কোড কপি করুন'),
          ),
          const SizedBox(height: 8),
          Text(
            family.joiningEnabled
                ? 'নতুন সদস্য যুক্ত করা চালু আছে।'
                : 'নতুন সদস্য যুক্ত করা বন্ধ আছে। Admin চালু করলে এই কোড ব্যবহার করা যাবে।',
            key: const ValueKey('bazzer-family-joining-status'),
          ),
          const SizedBox(height: 8),
          const Text(
            'শুধু পরিবারের সদস্যকে কোড দিন। তিনি নিজের অ্যাকাউন্টে '
            'লগইন করে পরিবারের বাজার খুলে এই কোড দিয়ে যুক্ত হবেন।',
          ),
        ],
      ),
    ),
  );
}

/// Members can copy the family code and inspect their live role without
/// querying the private member directory, which is reserved for admins.
class BazzerFamilyInfoPage extends StatefulWidget {
  const BazzerFamilyInfoPage({
    super.key,
    required this.family,
    required this.member,
    required this.repository,
  });

  final BazzerFamily family;
  final BazzerMember member;
  final BazzerRepository repository;

  @override
  State<BazzerFamilyInfoPage> createState() => _BazzerFamilyInfoPageState();
}

class _BazzerFamilyInfoPageState extends State<BazzerFamilyInfoPage> {
  late final _familyStream = widget.repository.watchFamily(widget.family.id);
  late final _memberStream = widget.repository.watchOwnMember(
    widget.family.id,
    widget.member.uid,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('আমার পরিবার')),
    body: StreamBuilder<BazzerMember?>(
      stream: _memberStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('পরিবারের তথ্য পাওয়া যায়নি। আবার খুলে দেখুন।'),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final member = snapshot.data;
        if (member == null || !member.active) {
          return const Center(
            child: Text(
              'আপনার সদস্যপদ এখন সক্রিয় নেই। পরিবারের Admin-এর সঙ্গে যোগাযোগ করুন।',
            ),
          );
        }
        return StreamBuilder<BazzerFamily?>(
          stream: _familyStream,
          builder: (context, familySnapshot) {
            if (familySnapshot.hasError) {
              return const Center(
                child: Text('পরিবারের তথ্য পাওয়া যায়নি। আবার খুলে দেখুন।'),
              );
            }
            if (familySnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final family = familySnapshot.data;
            if (family == null) {
              return const Center(child: Text('পরিবার পাওয়া যায়নি।'));
            }
            return _familyDetails(context, family, member);
          },
        );
      },
    ),
  );

  Widget _familyDetails(
    BuildContext context,
    BazzerFamily family,
    BazzerMember member,
  ) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(family.name, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 16),
      _FamilyCodeCard(family: family),
      const SizedBox(height: 8),
      ListTile(
        leading: const Icon(Icons.person_outline),
        title: Text(member.name),
        subtitle: Text(member.isAdmin ? 'Admin' : 'পরিবারের সদস্য'),
      ),
      ListTile(
        leading: Icon(
          member.secure ? Icons.lock_outline : Icons.group_outlined,
        ),
        title: Text(member.secure ? 'Secure' : 'Normal'),
        subtitle: Text(
          member.secure
              ? 'আপনার নতুন বাজারের আইটেম শুধু আপনি ও পরিবারের Admin দেখবেন।'
              : 'আপনার নতুন বাজারের আইটেম পরিবারের সক্রিয় সদস্যরা দেখবেন।',
        ),
      ),
      const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'নিজের লেখা আইটেম পরিবর্তন বা মুছতে তালিকার পাশে তিন বিন্দু চাপুন।',
        ),
      ),
      if (member.isAdmin)
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => BazzerFamilyManagePage(
                family: family,
                repository: widget.repository,
                currentUid: member.uid,
              ),
            ),
          ),
          icon: const Icon(Icons.manage_accounts_outlined),
          label: const Text('পরিবার পরিচালনা'),
        )
      else
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'আপনি এই পরিবারের সদস্য হিসেবে যুক্ত আছেন। সদস্যের নাম, '
            'Admin-এর অধিকার ও Normal/Secure পরিবর্তন করেন পরিবারের Admin। '
            'যে অ্যাকাউন্ট দিয়ে পরিবার তৈরি হয়েছিল, সেই অ্যাকাউন্টে '
            'লগইন করলে পরিচালনার বাটন পাবেন। Admin আপনাকে অধিকার '
            'দিলেও এখানেই পরিচালনার বাটন দেখাবে।',
          ),
        ),
    ],
  );
}

class BazzerFamilyManagePage extends StatefulWidget {
  const BazzerFamilyManagePage({
    super.key,
    required this.family,
    required this.repository,
    required this.currentUid,
  });

  final BazzerFamily family;
  final BazzerRepository repository;
  final String currentUid;

  @override
  State<BazzerFamilyManagePage> createState() => _BazzerFamilyManagePageState();
}

class _BazzerFamilyManagePageState extends State<BazzerFamilyManagePage> {
  BazzerFamily get family => widget.family;
  BazzerRepository get repository => widget.repository;
  String get currentUid => widget.currentUid;
  late final _familyStream = repository.watchFamily(family.id);
  late final _membersStream = repository.watchMembers(family.id);
  late final _ownMemberStream = family.ownerUid == currentUid
      ? null
      : repository.watchOwnMember(family.id, currentUid);

  void _message(BuildContext context, String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

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
      if (context.mounted) {
        _message(
          context,
          active
              ? 'সদস্য আবার যুক্ত হয়েছে।'
              : 'সদস্যের প্রবেশাধিকার বন্ধ হয়েছে।',
        );
      }
    } catch (error) {
      if (context.mounted) {
        _message(context, 'সদস্য পরিবর্তন করা যায়নি: $error');
      }
    }
  }

  Future<void> _rename(BuildContext context, BazzerMember member) async {
    var editedName = member.name;
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('সদস্যের নাম পরিবর্তন'),
        content: TextFormField(
          initialValue: member.name,
          onChanged: (value) => editedName = value,
          maxLength: 80,
          decoration: const InputDecoration(labelText: 'সদস্যের নতুন নাম'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(editedName),
            child: const Text('সংরক্ষণ করুন'),
          ),
        ],
      ),
    );
    if (name == null || !context.mounted) return;
    try {
      await repository.renameMember(family.id, member.uid, name);
      if (context.mounted) _message(context, 'সদস্যের নাম পরিবর্তন হয়েছে।');
    } catch (error) {
      if (context.mounted) _message(context, 'নাম পরিবর্তন করা যায়নি: $error');
    }
  }

  Future<void> _setAdmin(BuildContext context, BazzerMember member) async {
    if (!member.isAdmin) {
      final approved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('নতুন Admin করবেন?'),
          content: Text(
            '${member.name} অন্য সদস্য পরিচালনা, Secure তালিকা দেখা '
            'ও বাজার সম্পন্ন করার অধিকার পাবেন।',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('বাতিল'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Admin করুন'),
            ),
          ],
        ),
      );
      if (approved != true || !context.mounted) return;
    }
    try {
      await repository.setMemberAdmin(family.id, member.uid, !member.isAdmin);
      if (context.mounted) _message(context, 'Admin-এর অনুমতি পরিবর্তন হয়েছে।');
    } catch (error) {
      if (context.mounted) {
        _message(context, 'Admin পরিবর্তন করা যায়নি: $error');
      }
    }
  }

  Future<void> _setSecure(BuildContext context, BazzerMember member) async {
    try {
      await repository.setMemberSecure(family.id, member.uid, !member.secure);
      if (context.mounted) {
        _message(
          context,
          member.secure
              ? 'Normal করা হয়েছে; আগের Secure আইটেম গোপন থাকবে।'
              : 'Secure করা হয়েছে; নতুন আইটেম অন্য সদস্যরা দেখবে না।',
        );
      }
    } catch (error) {
      if (context.mounted) {
        _message(context, 'Secure পরিবর্তন করা যায়নি: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ownMemberStream == null) return _managementScreen(context);
    return StreamBuilder<BazzerMember?>(
      stream: _ownMemberStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('পরিবার পরিচালনা')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError ||
            snapshot.data?.active != true ||
            snapshot.data?.isAdmin != true) {
          return Scaffold(
            appBar: AppBar(title: const Text('পরিবার পরিচালনা')),
            body: const Center(
              child: Text(
                'পরিবার পরিচালনার জন্য সক্রিয় Admin-এর অধিকার প্রয়োজন।',
              ),
            ),
          );
        }
        return _managementScreen(context);
      },
    );
  }

  Widget _managementScreen(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('পরিবার পরিচালনা')),
      body: StreamBuilder<BazzerFamily?>(
        stream: _familyStream,
        builder: (context, familySnapshot) {
          if (familySnapshot.hasError) {
            return const Center(
              child: Text(
                'পরিবারের তথ্য পড়ার অনুমতি নেই। মূল Admin-এর সঙ্গে যোগাযোগ করুন।',
              ),
            );
          }
          final current = familySnapshot.data ?? family;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _FamilyCodeCard(family: current),
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
                stream: _membersStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text(
                      'সদস্য দেখানো যায়নি। Firestore rules পরীক্ষা করুন।',
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final members = snapshot.data ?? const <BazzerMember>[];
                  return Column(
                    children: [
                      const ListTile(
                        leading: Icon(Icons.admin_panel_settings_outlined),
                        title: Text('মূল অ্যাকাউন্ট • Admin'),
                        subtitle: Text('সদস্য ও বাজার পরিচালনার স্থায়ী অধিকার'),
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
                            [
                              if (member.isAdmin) 'Admin',
                              member.secure ? 'Secure' : 'Normal',
                              member.active ? 'যুক্ত আছেন' : 'বাদ দেওয়া হয়েছে',
                            ].join(' • '),
                          ),
                          trailing: member.uid == currentUid
                              ? null
                              : PopupMenuButton<String>(
                                  tooltip: '${member.name} পরিচালনা',
                                  onSelected: (choice) {
                                    if (choice == 'name') {
                                      _rename(context, member);
                                    }
                                    if (choice == 'admin') {
                                      _setAdmin(context, member);
                                    }
                                    if (choice == 'secure') {
                                      _setSecure(context, member);
                                    }
                                    if (choice == 'active') {
                                      _setActive(
                                        context,
                                        member,
                                        !member.active,
                                      );
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    if (member.uid != currentUid)
                                      const PopupMenuItem(
                                        value: 'name',
                                        child: Text('নাম পরিবর্তন'),
                                      ),
                                    if (member.active &&
                                        member.uid != currentUid)
                                      PopupMenuItem(
                                        value: 'admin',
                                        child: Text(
                                          member.isAdmin
                                              ? 'Admin সরিয়ে দিন'
                                              : 'Admin করুন',
                                        ),
                                      ),
                                    if (member.active &&
                                        member.uid != currentUid)
                                      PopupMenuItem(
                                        value: 'secure',
                                        child: Text(
                                          member.secure
                                              ? 'Normal করুন'
                                              : 'Secure করুন',
                                        ),
                                      ),
                                    if (member.uid != currentUid)
                                      PopupMenuItem(
                                        value: 'active',
                                        child: Text(
                                          member.active
                                              ? 'সদস্য বাদ দিন'
                                              : 'আবার যুক্ত করুন',
                                        ),
                                      ),
                                  ],
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
