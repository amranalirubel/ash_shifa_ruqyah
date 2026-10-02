import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../auth/screens/login_page.dart';
import '../controllers/easy_home_controller.dart';
import '../data/repositories/easy_home_repository.dart';
import '../models/easy_home_models.dart';
import '../services/easy_home_reminders.dart';
import '../utils/easy_home_format.dart';
import '../widgets/easy_home_widgets.dart';
import 'easy_home_people.dart';
import 'easy_home_rents.dart';
import 'easy_home_messages.dart';

class EasyHomePage extends StatefulWidget {
  const EasyHomePage({super.key, this.controller});
  final EasyHomeController? controller;
  @override
  State<EasyHomePage> createState() => _EasyHomePageState();
}

class _EasyHomePageState extends State<EasyHomePage>
    with WidgetsBindingObserver {
  late final EasyHomeController c;
  int _tab = 0;
  Timer? _monthTimer;
  @override
  void initState() {
    super.initState();
    c = widget.controller ?? EasyHomeController(EasyHomeRepository());
    c.start();
    if (widget.controller == null) EasyHomeReminders.instance.bind();
    WidgetsBinding.instance.addObserver(this);
    _monthTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => c.ensureRents(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(c.ensureRents(force: true));
    }
  }

  @override
  void dispose() {
    _monthTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (widget.controller == null) c.dispose();
    super.dispose();
  }

  Future<void> _setup(bool create) async {
    await showEasyForm(
      context,
      title: create ? 'আপনার বাড়ি তৈরি করুন' : 'বাড়িতে যোগ দিন',
      description: create
          ? 'আপনি বাড়িওয়ালা হিসেবে বাড়ির হিসাব ও সদস্য নিয়ন্ত্রণ করবেন।'
          : 'মালিকের কাছ থেকে বাড়ির কোড নিন। তিনি অনুমোদন দিলে যোগ হতে পারবেন।',
      fields: [
        EasyField(
          create ? 'home' : 'code',
          create ? 'বাড়ির নাম' : '১২ অক্ষরের বাড়ির কোড',
          maxLength: create ? 80 : 16,
        ),
        EasyField('name', 'আপনার নাম', initial: c.repository.displayName),
        const EasyField(
          'phone',
          'মোবাইল নম্বর',
          keyboard: TextInputType.phone,
          maxLength: 16,
        ),
        if (!create)
          const EasyField(
            'role',
            'আপনি',
            initial: 'tenant',
            options: {'tenant': 'ভাড়াটিয়া', 'caretaker': 'কেয়ারটেকার'},
          ),
      ],
      save: (v) => create
          ? c.repository.createHome(v['home']!, v['name']!, v['phone']!)
          : c.repository.requestJoin(
              v['code']!,
              v['name']!,
              v['phone']!,
              UserRole.values.byName(v['role']!),
            ),
    );
  }

  Future<void> _settings() async {
    final home = c.home;
    if (home == null) return;
    await showEasyForm(
      context,
      title: 'বাড়ির সেটিংস',
      fields: [
        EasyField('name', 'বাড়ির নাম', initial: home.name),
        EasyField(
          'joining',
          'নতুন আবেদন',
          initial: home.joiningEnabled ? 'yes' : 'no',
          options: const {'yes': 'চালু', 'no': 'বন্ধ'},
        ),
      ],
      save: (v) =>
          c.repository.updateHome(home.id, v['name']!, v['joining'] == 'yes'),
    );
  }

  Future<void> _reminder() async {
    await showEasyForm(
      context,
      title: 'মাসিক ভাড়ার স্মরণ',
      description:
          'এই ফোনে প্রতি মাসের নির্বাচিত দিনে সকাল ৯টায় স্মরণ। সময় বাংলাদেশ অনুযায়ী; ফোনের সেটিংসের কারণে কিছুটা দেরি হতে পারে।',
      fields: [
        EasyField(
          'day',
          'কত তারিখে',
          initial: '5',
          options: {
            'off': 'স্মরণ বন্ধ',
            for (var i = 1; i <= 28; i++) '$i': bn(i),
          },
        ),
      ],
      save: (v) => v['day'] == 'off'
          ? EasyHomeReminders.instance.disable()
          : EasyHomeReminders.instance.setDay(int.parse(v['day']!)),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: c,
    builder: (context, _) {
      final sections = <(String, IconData)>[
        ('সারসংক্ষেপ', Icons.home_outlined),
        ('ফ্ল্যাট', Icons.apartment_outlined),
        if (c.member?.role != UserRole.caretaker)
          ('ভাড়া', Icons.receipt_long_outlined),
        ('নোটিশ', Icons.notifications_none),
        ('অভিযোগ', Icons.support_agent),
      ];
      final tab = _tab < sections.length ? _tab : 0;
      Widget content;
      if (c.loading) {
        content = const Center(child: CircularProgressIndicator());
      } else if (c.error != null) {
        content = ListView(
          padding: const EdgeInsets.all(24),
          children: [
            EasyEmpty('তথ্য খোলা যায়নি', c.error!),
            FilledButton(
              onPressed: c.retry,
              child: const Text('আবার চেষ্টা করুন'),
            ),
          ],
        );
      } else if (c.uid == null) {
        content = ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const EasyEmpty(
              'EasyHome ব্যবহার করতে লগইন করুন',
              'বাড়ির হিসাব ও ব্যক্তিগত তথ্য আপনার অ্যাকাউন্টের সাথে নিরাপদে থাকবে।',
            ),
            FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const LoginPage()),
              ),
              child: const Text('লগইন করুন'),
            ),
          ],
        );
      } else if (c.homeId == null) {
        content = ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const EasyEmpty(
              'বাড়ির সব হিসাব এক জায়গায়',
              'ভাড়া, ভাড়াটিয়া, বাড়ির নোটিশ ও সমস্যার সমাধান।',
            ),
            FilledButton.icon(
              onPressed: () => _setup(true),
              icon: const Icon(Icons.add_home_outlined),
              label: const Text('বাড়িওয়ালা • বাড়ি তৈরি'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _setup(false),
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('ভাড়াটিয়া / কেয়ারটেকার • যোগ দিন'),
            ),
          ],
        );
      } else if (!c.active) {
        content = ListView(
          padding: const EdgeInsets.all(24),
          children: [
            EasyEmpty(
              c.request?.status == 'pending'
                  ? 'মালিকের অনুমোদনের অপেক্ষায়'
                  : 'বাড়ির সদস্যপদ সক্রিয় নয়',
              c.request?.status == 'pending'
                  ? 'আপনার আবেদন পাঠানো হয়েছে। অনুমোদন হলে এই পেজে বাড়ির তথ্য দেখা যাবে।'
                  : 'বাড়িওয়ালার সাথে যোগাযোগ করুন অথবা বাড়ির কোড দিয়ে আবার আবেদন করুন।',
            ),
            OutlinedButton(
              onPressed: () => easyConfirm(
                context,
                'এই সংযোগ থেকে বের হবেন?',
                'আবেদন বা হিসাব মুছবে না। অন্য কোড দিয়ে সংযুক্ত হতে পারবেন।',
                c.repository.disconnect,
              ),
              child: const Text('অন্য বাড়িতে যুক্ত হোন'),
            ),
          ],
        );
      } else if (c.home == null || !c.ready) {
        content = const Center(child: CircularProgressIndicator());
      } else {
        content = switch (sections[tab].$1) {
          'ফ্ল্যাট' => EasyHomePeople(
            key: ValueKey('${c.homeId}/${c.member!.accessKey}/people'),
            controller: c,
          ),
          'ভাড়া' => EasyHomeRents(
            key: ValueKey('${c.homeId}/${c.member!.accessKey}/rents'),
            controller: c,
          ),
          'নোটিশ' => EasyHomeNotices(controller: c),
          'অভিযোগ' => EasyHomeComplaints(
            key: ValueKey('${c.homeId}/${c.member!.accessKey}/complaints'),
            controller: c,
          ),
          _ => _dashboard(sections),
        };
      }
      return Scaffold(
        appBar: AppBar(
          title: const Text('ইজি হোম'),
          actions: [
            if (c.isLandlord)
              IconButton(
                tooltip: 'বাড়ির সেটিংস',
                onPressed: _settings,
                icon: const Icon(Icons.settings_outlined),
              ),
            IconButton(
              tooltip: 'আবার লোড করুন',
              onPressed: c.retry,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (c.active && c.cached)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: const Text(
                    'ডিভাইসে সংরক্ষিত তথ্য • পরিবর্তন করতে ইন্টারনেট প্রয়োজন',
                    textAlign: TextAlign.center,
                  ),
                ),
              if (c.generating) const LinearProgressIndicator(),
              if (c.billingError != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('কিছু মাসের বিল তৈরি হয়নি। ${c.billingError}'),
                      TextButton(
                        onPressed: () => c.ensureRents(force: true),
                        child: const Text('আবার তৈরি করুন'),
                      ),
                    ],
                  ),
                ),
              Expanded(child: content),
            ],
          ),
        ),
        bottomNavigationBar: c.active && c.error == null
            ? NavigationBar(
                selectedIndex: tab,
                onDestinationSelected: (v) => setState(() => _tab = v),
                labelBehavior:
                    NavigationDestinationLabelBehavior.onlyShowSelected,
                destinations: [
                  for (final section in sections)
                    NavigationDestination(
                      icon: Icon(section.$2),
                      label: section.$1,
                    ),
                ],
              )
            : null,
      );
    },
  );
  Widget _dashboard(List<(String, IconData)> sections) {
    final colors = Theme.of(context).colorScheme;
    final month = monthKey(DateTime.now());
    final currentRents = c.rents.where((r) => r.month == month);
    final collected = currentRents.fold(
      0,
      (int value, r) => value + r.paidPaisa,
    );
    final pending = c.complaints
        .where((v) => v.status != ComplaintStatus.resolved)
        .length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        EasyCard(
          color: colors.primaryContainer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.home_work_rounded,
                size: 36,
                color: colors.onPrimaryContainer,
              ),
              const SizedBox(height: 8),
              Text(
                c.home!.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colors.onPrimaryContainer,
                ),
              ),
              Text(
                '${c.member!.name} • ${c.member!.role.label}',
                style: TextStyle(color: colors.onPrimaryContainer),
              ),
              if (c.isLandlord) ...[
                const SizedBox(height: 12),
                SelectableText(
                  'বাড়ির কোড: ${c.home!.inviteCode}',
                  style: TextStyle(color: colors.onPrimaryContainer),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: c.home!.inviteCode),
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('বাড়ির কোড কপি হয়েছে।')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('কোড কপি করুন'),
                ),
                Text(
                  c.home!.joiningEnabled
                      ? 'নতুন আবেদন চালু'
                      : 'নতুন আবেদন বন্ধ',
                  style: TextStyle(color: colors.onPrimaryContainer),
                ),
              ],
            ],
          ),
        ),
        if (c.member!.role != UserRole.caretaker)
          EasyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.isLandlord ? 'সব মাস মিলিয়ে বকেয়া' : 'আপনার মোট বকেয়া'),
                Text(
                  money(c.totalDue),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('${monthText(month)} • জমা ${money(collected)}'),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => setState(
                    () => _tab = sections.indexWhere((s) => s.$1 == 'ভাড়া'),
                  ),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('ভাড়ার হিসাব খুলুন'),
                ),
                if (EasyHomeReminders.instance.supported)
                  TextButton.icon(
                    onPressed: _reminder,
                    icon: const Icon(Icons.alarm),
                    label: const Text('মাসিক স্মরণ সেট করুন'),
                  ),
              ],
            ),
          ),
        EasyCard(
          child: Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              Text('ফ্ল্যাট\n${bn(c.visibleFlats.length)}'),
              if (c.isLandlord)
                Text(
                  'ভাড়াটিয়া\n${bn(c.tenants.where((t) => t.active).length)}',
                ),
              Text('অমীমাংসিত অভিযোগ\n${bn(pending)}'),
              if (c.isLandlord)
                Text(
                  'নতুন আবেদন\n${bn(c.requests.where((r) => r.status == 'pending').length)}',
                ),
            ],
          ),
        ),
        for (var i = 1; i < sections.length; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Icon(sections[i].$2, color: colors.primary),
              title: Text(switch (sections[i].$1) {
                'ফ্ল্যাট' =>
                  c.isLandlord
                      ? 'ফ্ল্যাট, ভাড়াটিয়া ও সদস্য'
                      : 'বাড়ির ফ্ল্যাটসমূহ',
                'ভাড়া' => 'মাসিক ভাড়া ও রসিদ',
                'নোটিশ' => 'সাধারণ ও জরুরি নোটিশ',
                _ => 'অভিযোগ ও সমাধান',
              }),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => setState(() => _tab = i),
            ),
          ),
        if (!c.isLandlord)
          TextButton(
            onPressed: () => easyConfirm(
              context,
              'এই বাড়ি থেকে বের হবেন?',
              'আবার যুক্ত হতে মালিকের অনুমোদন লাগবে। ভাড়া ও অভিযোগের ইতিহাস মুছবে না।',
              () => c.repository.leaveHome(c.homeId!, c.member!),
            ),
            child: const Text('বাড়ি থেকে বের হোন'),
          ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'ব্যক্তিগত তথ্য সুরক্ষিত। ভাড়াটিয়া অন্য ভাড়াটিয়ার নাম, ফোন বা ভাড়ার হিসাব দেখতে পারেন না।',
          ),
        ),
      ],
    );
  }
}
