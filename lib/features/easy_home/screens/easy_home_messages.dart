import 'package:flutter/material.dart';

import '../controllers/easy_home_controller.dart';
import '../models/easy_home_models.dart';
import '../utils/easy_home_format.dart';
import '../widgets/easy_home_widgets.dart';

class EasyHomeNotices extends StatelessWidget {
  const EasyHomeNotices({super.key, required this.controller});
  final EasyHomeController controller;
  Future<void> _post(BuildContext context) async {
    final c = controller;
    await showEasyForm(
      context,
      title: 'নোটিশ পাঠান',
      fields: [
        EasyField(
          'audience',
          'কার জন্য',
          initial: 'all',
          options: {
            'all': 'বাড়ির সবাই',
            for (final floor in c.visibleFlats.map((f) => f.floor).toSet())
              'floor:$floor': '${bn(floor)} তলার সবাই',
            for (final flat in c.visibleFlats) 'flat:${flat.id}': flat.code,
          },
        ),
        const EasyField(
          'urgent',
          'ধরন',
          initial: 'no',
          options: {'no': 'সাধারণ নোটিশ', 'yes': 'জরুরি নোটিশ'},
        ),
        const EasyField(
          'content',
          'নোটিশের লেখা',
          multiline: true,
          maxLength: 2000,
        ),
      ],
      save: (v) => c.repository.postNotice(
        c.homeId!,
        content: v['content']!,
        audience: v['audience']!,
        emergency: v['urgent'] == 'yes',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final notices = [...c.notices]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        EasySectionTitle(
          'বাড়ির নোটিশ',
          action: c.canManage
              ? IconButton(
                  tooltip: 'নতুন নোটিশ',
                  icon: const Icon(Icons.add),
                  onPressed: () => _post(context),
                )
              : null,
        ),
        if (c.canManage)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FilledButton.icon(
              onPressed: () => _post(context),
              icon: const Icon(Icons.campaign_outlined),
              label: const Text('নোটিশ পাঠান'),
            ),
          ),
        if (notices.isEmpty)
          const EasyEmpty(
            'এখনো কোনো নোটিশ নেই',
            'আপনার জন্য পাঠানো নোটিশ এখানে দেখা যাবে।',
            icon: Icons.notifications_none,
          ),
        for (final n in notices)
          EasyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      n.emergency
                          ? Icons.warning_amber
                          : Icons.campaign_outlined,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        n.emergency ? 'জরুরি নোটিশ' : 'নোটিশ',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SelectableText(n.content),
                const SizedBox(height: 10),
                Text(dateText(n.createdAt)),
                if (c.canManage) Text(_audience(c, n.audience)),
                if (c.isLandlord || n.senderId == c.uid)
                  TextButton(
                    onPressed: () => easyConfirm(
                      context,
                      'নোটিশ মুছবেন?',
                      n.content,
                      () => c.repository.deleteNotice(c.homeId!, n.id),
                    ),
                    child: const Text('মুছে দিন'),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  String _audience(EasyHomeController c, String audience) {
    if (audience == 'all') return 'বাড়ির সবাই';
    if (audience.startsWith('tenant:')) return 'নির্দিষ্ট ভাড়াটিয়া';
    if (audience.startsWith('floor:')) {
      return '${bn(audience.substring(6))} তলা';
    }
    return c.flats
            .where((f) => f.id == audience.substring(5))
            .firstOrNull
            ?.code ??
        'নির্দিষ্ট ফ্ল্যাট';
  }
}

class EasyHomeComplaints extends StatefulWidget {
  const EasyHomeComplaints({super.key, required this.controller});
  final EasyHomeController controller;
  @override
  State<EasyHomeComplaints> createState() => _EasyHomeComplaintsState();
}

class _EasyHomeComplaintsState extends State<EasyHomeComplaints> {
  bool _includeResolved = false;
  EasyHomeController get c => widget.controller;
  Future<void> _edit([ComplaintModel? complaint]) async {
    await showEasyForm(
      context,
      title: complaint == null ? 'সমস্যা জানান' : 'অভিযোগ এডিট',
      fields: [
        EasyField(
          'title',
          'সমস্যার শিরোনাম',
          initial: complaint?.title ?? '',
          maxLength: 100,
        ),
        EasyField(
          'description',
          'বিস্তারিত লিখুন',
          initial: complaint?.description ?? '',
          multiline: true,
          maxLength: 2000,
        ),
        EasyField(
          'priority',
          'গুরুত্ব',
          initial: complaint?.priority.name ?? 'medium',
          options: const {
            'low': 'সাধারণ',
            'medium': 'প্রয়োজনীয়',
            'urgent': 'জরুরি',
          },
        ),
      ],
      save: (v) => c.repository.saveComplaint(
        c.homeId!,
        complaintId: complaint?.id,
        title: v['title']!,
        description: v['description']!,
        priority: Priority.values.byName(v['priority']!),
        flatCode:
            c.flats.where((f) => f.id == c.member?.flatId).firstOrNull?.code ??
            'সাধারণ এলাকা',
      ),
    );
  }

  Future<void> _respond(ComplaintModel complaint) async {
    await showEasyForm(
      context,
      title: 'অভিযোগের অগ্রগতি',
      fields: [
        EasyField(
          'status',
          'অবস্থা',
          initial: complaint.status.name,
          options: const {
            'pending': 'অপেক্ষায়',
            'inProgress': 'কাজ চলছে',
            'resolved': 'সমাধান হয়েছে',
          },
        ),
        EasyField(
          'response',
          'উত্তর / করণীয়',
          initial: complaint.response,
          multiline: true,
          maxLength: 1000,
          optional: true,
        ),
      ],
      save: (v) => c.repository.updateComplaint(
        c.homeId!,
        complaint.id,
        ComplaintStatus.values.byName(v['status']!),
        v['response']!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final complaints =
        c.complaints
            .where(
              (r) => _includeResolved || r.status != ComplaintStatus.resolved,
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const EasySectionTitle('অভিযোগ ও সমাধান'),
        FilledButton.icon(
          onPressed: () => _edit(),
          icon: const Icon(Icons.add_comment_outlined),
          label: const Text('সমস্যা জানান'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _includeResolved,
          onChanged: (v) => setState(() => _includeResolved = v),
          title: const Text('সমাধান হওয়া অভিযোগও দেখান'),
        ),
        if (complaints.isEmpty)
          const EasyEmpty(
            'কোনো অভিযোগ নেই',
            'নতুন সমস্যা জানাতে উপরের বাটন ব্যবহার করুন।',
            icon: Icons.task_alt,
          ),
        for (final complaint in complaints)
          EasyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  complaint.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${complaint.flatCode} • ${complaint.statusLabel}${complaint.priority == Priority.urgent ? ' • জরুরি' : ''}',
                ),
                const SizedBox(height: 8),
                Text(complaint.description),
                if (complaint.response.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text('উত্তর: ${complaint.response}'),
                  ),
                Text(dateText(complaint.createdAt)),
                Wrap(
                  spacing: 8,
                  children: [
                    if (c.canManage)
                      TextButton(
                        onPressed: () => _respond(complaint),
                        child: const Text('অবস্থা / উত্তর'),
                      ),
                    if (complaint.authorUid == c.uid &&
                        complaint.status == ComplaintStatus.pending) ...[
                      TextButton(
                        onPressed: () => _edit(complaint),
                        child: const Text('এডিট'),
                      ),
                      TextButton(
                        onPressed: () => easyConfirm(
                          context,
                          'অভিযোগ মুছবেন?',
                          complaint.title,
                          () => c.repository.deleteComplaint(
                            c.homeId!,
                            complaint.id,
                          ),
                        ),
                        child: const Text('মুছে দিন'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
