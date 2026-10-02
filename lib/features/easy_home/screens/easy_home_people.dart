import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/easy_home_controller.dart';
import '../models/easy_home_models.dart';
import '../utils/easy_home_format.dart';
import '../widgets/easy_home_widgets.dart';

class EasyHomePeople extends StatefulWidget {
  const EasyHomePeople({super.key, required this.controller});
  final EasyHomeController controller;
  @override
  State<EasyHomePeople> createState() => _EasyHomePeopleState();
}

class _EasyHomePeopleState extends State<EasyHomePeople> {
  final _search = TextEditingController();
  bool _history = false;
  EasyHomeController get c => widget.controller;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _flat() async {
    await showEasyForm(
      context,
      title: 'নতুন ফ্ল্যাট',
      description:
          'যেমন: তলা ২, ইউনিট B → 2B-K9X4। খালি পুরোনো ফ্ল্যাট যোগ করলে পুনরায় চালু হবে।',
      fields: const [
        EasyField('floor', 'তলা (G, ১, ২…)', maxLength: 3),
        EasyField('unit', 'ইউনিট (A, B…)', maxLength: 2),
      ],
      save: (v) => c.repository.addFlat(c.homeId!, v['floor']!, v['unit']!),
    );
  }

  Future<void> _tenant([TenantModel? tenant]) async {
    final choices = {
      for (final f in c.visibleFlats.where(
        (f) => !f.occupied || f.id == tenant?.flatId,
      ))
        f.id: f.code,
    };
    if (choices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('আগে একটি খালি ফ্ল্যাট যোগ করুন।')),
      );
      return;
    }
    final today = DateTime.now();
    await showEasyForm(
      context,
      title: tenant == null ? 'ভাড়াটিয়া যোগ করুন' : 'ভাড়াটিয়ার তথ্য',
      description:
          'প্রথম ও শেষ মাসে পুরো মাসের ভাড়া ধরা হবে। ভাড়া বদলালে ইতিমধ্যে তৈরি বিল অপরিবর্তিত থাকবে।',
      fields: [
        if (tenant == null)
          EasyField(
            'flat',
            'ফ্ল্যাট',
            options: choices,
            initial: choices.keys.first,
          ),
        EasyField('name', 'নাম', initial: tenant?.name ?? ''),
        EasyField(
          'phone',
          'মোবাইল নম্বর',
          initial: tenant?.phone ?? '',
          maxLength: 16,
          keyboard: TextInputType.phone,
        ),
        EasyField(
          'rent',
          'মাসিক ভাড়া (টাকা)',
          initial: tenant == null ? '' : moneyInput(tenant.rentPaisa),
          keyboard: const TextInputType.numberWithOptions(decimal: true),
        ),
        if (tenant == null)
          EasyField(
            'start',
            'ভাড়া শুরুর তারিখ',
            initial:
                '${monthKey(today)}-${today.day.toString().padLeft(2, '0')}',
            date: true,
          ),
        EasyField(
          'day',
          'মাসের কত তারিখে ভাড়া দেবেন',
          initial: '${tenant?.dueDay ?? 5}',
          options: {for (var day = 1; day <= 28; day++) '$day': bn(day)},
        ),
      ],
      save: (v) {
        final amount = parsePaisa(v['rent']!);
        if (amount == null || amount == 0)
          throw ArgumentError('সঠিক ভাড়ার পরিমাণ লিখুন।');
        return c.repository.saveTenant(
          c.homeId!,
          tenantId: tenant?.id,
          flat: c.flats.firstWhere(
            (f) => f.id == (tenant?.flatId ?? v['flat']),
          ),
          name: v['name']!,
          phone: v['phone']!,
          rentPaisa: amount,
          startDate: tenant?.startDate ?? DateTime.parse(v['start']!),
          dueDay: int.parse(v['day']!),
        );
      },
    );
  }

  Future<void> _approve(HomeRequest request) async {
    final eligible = c.tenants.where(
      (t) => t.active && (t.userId.isEmpty || t.userId == request.id),
    );
    if (request.role == UserRole.tenant && eligible.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('আগে এই ব্যক্তির ভাড়াটিয়া রেকর্ড যোগ করুন।'),
        ),
      );
      return;
    }
    await showEasyForm(
      context,
      title: 'সদস্য অনুমোদন',
      description:
          '${request.name}\n${request.phone}\n${request.role.label} হিসেবে যুক্ত হবেন। সঠিক ব্যক্তির ফ্ল্যাট নির্বাচন করুন।',
      fields: [
        if (request.role == UserRole.tenant)
          EasyField(
            'tenant',
            'ভাড়াটিয়া ও ফ্ল্যাট',
            options: {
              for (final t in eligible) t.id: '${t.flatCode} • ${t.name}',
            },
          ),
      ],
      save: (v) => c.repository.approveRequest(
        c.homeId!,
        request,
        tenant: request.role == UserRole.tenant
            ? c.tenants.firstWhere((t) => t.id == v['tenant'])
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.toLowerCase();
    final flats = c.visibleFlats
        .where((f) => f.code.toLowerCase().contains(query))
        .toList();
    final tenants = c.tenants
        .where(
          (t) =>
              (_history || t.active) &&
              '${t.name} ${t.phone} ${t.flatCode}'.toLowerCase().contains(
                query,
              ),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        EasySectionTitle(
          c.isLandlord ? 'ফ্ল্যাট ও ভাড়াটিয়া' : 'বাড়ির ফ্ল্যাটসমূহ',
        ),
        if (c.isLandlord)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _flat,
                icon: const Icon(Icons.add_home_outlined),
                label: const Text('ফ্ল্যাট যোগ'),
              ),
              OutlinedButton.icon(
                onPressed: () => _tenant(),
                icon: const Icon(Icons.person_add_alt),
                label: const Text('ভাড়াটিয়া যোগ'),
              ),
            ],
          ),
        const SizedBox(height: 12),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: c.isLandlord
                ? 'নাম, ফোন বা ফ্ল্যাট খুঁজুন'
                : 'ফ্ল্যাট কোড খুঁজুন',
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        if (c.isLandlord) ...[
          for (final r in c.requests.where((r) => r.status == 'pending'))
            EasyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'যোগ দেওয়ার আবেদন • ${r.role.label}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Text('${r.name}\n${r.phone}'),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton(
                        onPressed: () => _approve(r),
                        child: const Text('অনুমোদন'),
                      ),
                      TextButton(
                        onPressed: () => easyConfirm(
                          context,
                          'আবেদন বাতিল?',
                          r.name,
                          () => c.repository.rejectRequest(c.homeId!, r.id),
                        ),
                        child: const Text('প্রত্যাখ্যান'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('পুরোনো ভাড়াটিয়াও দেখান'),
            value: _history,
            onChanged: (v) => setState(() => _history = v),
          ),
        ],
        for (final t in tenants)
          EasyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.flatCode,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text('${t.name}\n${t.phone}'),
                Text(
                  '${money(t.rentPaisa)} / মাস • ${bn(t.dueDay)} তারিখের মধ্যে',
                ),
                Text(
                  'শুরু: ${dateText(t.startDate)}${t.active ? '' : ' • বসবাস শেষ'}',
                ),
                if (c.isLandlord)
                  Wrap(
                    spacing: 8,
                    children: [
                      if (t.active)
                        TextButton.icon(
                          onPressed: () => _tenant(t),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('এডিট'),
                        ),
                      TextButton.icon(
                        onPressed: () =>
                            Clipboard.setData(ClipboardData(text: t.phone)),
                        icon: const Icon(Icons.copy),
                        label: const Text('ফোন কপি'),
                      ),
                      if (t.active)
                        TextButton(
                          onPressed: () => easyConfirm(
                            context,
                            'বসবাস শেষ করবেন?',
                            '${t.name} • ${t.flatCode}\nআগের বিল ও জমার ইতিহাস থাকবে। এই মাসের পুরো ভাড়া প্রযোজ্য। যুক্ত অ্যাকাউন্টের বাড়িতে প্রবেশ বন্ধ হবে।',
                            () => c.repository.endTenancy(c.homeId!, t),
                          ),
                          child: const Text('বসবাস শেষ'),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        if (flats.isEmpty && tenants.isEmpty)
          const EasyEmpty(
            'কোনো ফ্ল্যাট পাওয়া যায়নি',
            'ফ্ল্যাট যোগ করুন অথবা খোঁজার শব্দ বদলান।',
          ),
        for (final f in flats)
          EasyCard(
            child: Row(
              children: [
                const Icon(Icons.apartment_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.code),
                      if (c.isLandlord)
                        Text(f.occupied ? 'ভাড়াটিয়া আছেন' : 'খালি ফ্ল্যাট'),
                    ],
                  ),
                ),
                if (c.isLandlord && !f.occupied)
                  IconButton(
                    tooltip: 'ফ্ল্যাট আর্কাইভ',
                    icon: const Icon(Icons.archive_outlined),
                    onPressed: () => easyConfirm(
                      context,
                      'খালি ফ্ল্যাট আর্কাইভ?',
                      '${f.code}\nইতিহাস থাকবে। একই তলা ও ইউনিট যোগ করে ফিরিয়ে আনা যাবে।',
                      () => c.repository.archiveFlat(c.homeId!, f),
                    ),
                  ),
              ],
            ),
          ),
        if (c.isLandlord) ...[
          const EasySectionTitle('যুক্ত অ্যাকাউন্ট'),
          for (final m in c.members.where((m) => m.active))
            EasyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${m.name} • ${m.role.label}'),
                  Text(m.phone),
                  if (m.role != UserRole.landlord)
                    TextButton(
                      onPressed: () => easyConfirm(
                        context,
                        'অ্যাকাউন্ট বিচ্ছিন্ন করবেন?',
                        'এই অ্যাকাউন্ট বাড়ির তথ্য দেখতে পারবে না। ভাড়াটিয়ার বিল ও বসবাসের রেকর্ড থাকবে।',
                        () => c.repository.removeMember(c.homeId!, m),
                      ),
                      child: const Text('প্রবেশ বন্ধ করুন'),
                    ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}
