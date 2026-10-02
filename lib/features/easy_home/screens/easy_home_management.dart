import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../controllers/easy_home_controller.dart';
import '../models/easy_home_models.dart';
import '../utils/easy_home_format.dart';
import '../utils/easy_home_reports.dart';
import '../widgets/easy_home_widgets.dart';

/// Keeps private reports and tools hidden immediately after access changes.
class EasyHomeManagement extends StatelessWidget {
  const EasyHomeManagement({
    super.key,
    required this.controller,
    required this.homeId,
    required this.viewerKey,
    this.utility = false,
  });
  final EasyHomeController controller;
  final String homeId, viewerKey;
  final bool utility;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final allowed =
          controller.active &&
          controller.isLandlord &&
          controller.homeId == homeId &&
          controller.member?.accessKey == viewerKey &&
          controller.error == null &&
          controller.ready;
      return Scaffold(
        appBar: AppBar(
          title: Text(utility ? 'ইউটিলিটি বিল ভাগ' : 'খরচ ও মাসিক রিপোর্ট'),
        ),
        body: SafeArea(
          child: !allowed
              ? const EasyEmpty(
                  'হিসাব দেখার অনুমতি নেই',
                  'বাড়ির পেজে ফিরে আবার খুলুন।',
                )
              : utility
              ? _UtilityTool(controller: controller)
              : _Accounts(controller: controller),
        ),
      );
    },
  );
}

class _Accounts extends StatefulWidget {
  const _Accounts({required this.controller});
  final EasyHomeController controller;
  @override
  State<_Accounts> createState() => _AccountsState();
}

class _AccountsState extends State<_Accounts> {
  EasyHomeController get c => widget.controller;
  String _month = monthKey(DateTime.now());
  bool _showVoided = false;

  Future<void> _add() async {
    final homeId = c.homeId!;
    final id = c.repository.newExpenseId(homeId);
    await showEasyForm(
      context,
      title: 'পরিশোধিত খরচ যোগ',
      description:
          'যে খরচের টাকা ইতিমধ্যে দিয়েছেন, শুধু সেটি লিখুন। ভাড়াটিয়ার বিল এখানে যোগ হবে না।',
      fields: [
        const EasyField('title', 'কীসের খরচ', maxLength: 100),
        const EasyField(
          'category',
          'খাত',
          initial: 'repair',
          options: expenseCategories,
        ),
        const EasyField(
          'amount',
          'পরিমাণ (টাকা)',
          keyboard: TextInputType.numberWithOptions(decimal: true),
        ),
        EasyField(
          'date',
          'টাকা দেওয়ার তারিখ',
          initial: isoDay(DateTime.now()),
          date: true,
        ),
        const EasyField(
          'reference',
          'রসিদ / লেনদেন নম্বর (ঐচ্ছিক)',
          optional: true,
          maxLength: 100,
        ),
        const EasyField(
          'note',
          'বিবরণ (ঐচ্ছিক)',
          optional: true,
          maxLength: 500,
          multiline: true,
        ),
      ],
      save: (v) async {
        final amount = parsePaisa(v['amount']!);
        if (amount == null || amount == 0) {
          throw ArgumentError('সঠিক টাকার পরিমাণ দিন।');
        }
        await c.repository.addExpense(
          homeId,
          HomeExpense(
            id: id,
            title: v['title']!,
            category: v['category']!,
            amountPaisa: amount,
            date: v['date']!,
            reference: v['reference']!,
            note: v['note']!,
          ),
        );
      },
    );
  }

  Future<void> _void(HomeExpense expense) => showEasyForm(
    context,
    title: 'খরচ বাতিল করুন',
    description: 'মূল এন্ট্রি ইতিহাসে থাকবে। সঠিক খরচ নতুন করে যোগ করুন।',
    fields: const [
      EasyField('reason', 'বাতিলের কারণ', maxLength: 300, multiline: true),
    ],
    save: (v) => c.repository.voidExpense(c.homeId!, expense.id, v['reason']!),
  ).then((_) {});

  Future<void> _export(
    BuildContext buttonContext,
    HomeMonthReport report,
  ) async {
    final box = buttonContext.findRenderObject()! as RenderBox;
    final csv = homeReportCsv(_month, report, cached: c.cached);
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              Uint8List.fromList(utf8.encode(csv)),
              mimeType: 'text/csv',
            ),
          ],
          fileNameOverrides: ['easyhome-$_month.csv'],
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ফাইল শেয়ার হয়নি। রিপোর্ট কপি করে নিতে পারেন।'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final months = {
      monthKey(DateTime.now()),
      _month,
      ...c.rents.map((r) => r.month),
      ...c.expenses.map((e) => e.month),
    }.toList()..sort((a, b) => b.compareTo(a));
    final report = HomeMonthReport(_month, c.rents, c.expenses);
    final expenses =
        c.expenses
            .where((e) => e.month == _month && (_showVoided || !e.voided))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (c.cached)
          const Text('ডিভাইসে সংরক্ষিত তথ্য • সর্বশেষ নাও হতে পারে'),
        DropdownButtonFormField<String>(
          initialValue: _month,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'রিপোর্টের মাস',
            border: OutlineInputBorder(),
          ),
          items: months
              .map((m) => DropdownMenuItem(value: m, child: Text(monthText(m))))
              .toList(),
          onChanged: (m) => setState(() => _month = m!),
        ),
        const SizedBox(height: 16),
        EasyCard(
          child: Wrap(
            spacing: 20,
            runSpacing: 12,
            children: [
              Text('ভাড়ার বিল\n${money(report.billed)}'),
              Text('এই বিলগুলোর জমা\n${money(report.collected)}'),
              Text('বকেয়া\n${money(report.due)}'),
              Text('পরিশোধিত বাড়ির খরচ\n${money(report.spent)}'),
            ],
          ),
        ),
        const Text(
          'জমা ভাড়ার বিলের মাস অনুযায়ী; হাতে টাকা আসার মাস অনুযায়ী নয়। এটি লাভ বা ক্যাশ-ফ্লো রিপোর্ট নয়।',
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(
                    text: homeReportText(
                      c.home!.name,
                      _month,
                      report,
                      cached: c.cached,
                    ),
                  ),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('রিপোর্ট কপি হয়েছে।')),
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('রিপোর্ট কপি'),
            ),
            Builder(
              builder: (ctx) => TextButton.icon(
                onPressed: () => _export(ctx, report),
                icon: const Icon(Icons.table_view_outlined),
                label: const Text('Excel-এর জন্য CSV'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const EasySectionTitle('খরচের খাত'),
        for (final entry in report.byCategory.entries.where((e) => e.value > 0))
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(expenseCategories[entry.key]!),
            trailing: Text(money(entry.value)),
          ),
        FilledButton.icon(
          onPressed: _add,
          icon: const Icon(Icons.add),
          label: const Text('খরচ যোগ করুন'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('বাতিলের ইতিহাস দেখুন'),
          value: _showVoided,
          onChanged: (v) => setState(() => _showVoided = v),
        ),
        if (expenses.isEmpty)
          const EasyEmpty(
            'এই মাসে খরচ নেই',
            'মেরামত, পানি, বিদ্যুৎ ও অন্যান্য পরিশোধিত খরচ যোগ করুন।',
          ),
        for (final e in expenses)
          EasyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.title, style: Theme.of(context).textTheme.titleMedium),
                Text('${expenseCategories[e.category]} • ${bn(e.date)}'),
                Text(
                  money(e.amountPaisa),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (e.reference.isNotEmpty) Text('রেফারেন্স: ${e.reference}'),
                if (e.note.isNotEmpty) Text(e.note),
                if (e.voided)
                  Text('বাতিল: ${e.voidReason}')
                else
                  TextButton(
                    onPressed: () => _void(e),
                    child: const Text('ভুল এন্ট্রি বাতিল'),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _UtilityTool extends StatefulWidget {
  const _UtilityTool({required this.controller});
  final EasyHomeController controller;
  @override
  State<_UtilityTool> createState() => _UtilityToolState();
}

class _UtilityToolState extends State<_UtilityTool> {
  final _amount = TextEditingController();
  final _label = TextEditingController(text: 'পানি / বিদ্যুৎ / সার্ভিস চার্জ');
  final _weights = <String, TextEditingController>{};
  final _excluded = <String>{};
  bool _weighted = false;
  String? _error;
  Map<String, int>? _shares;
  String? _resultText;
  String _flatSignature = '';
  void _invalidate() {
    _shares = null;
    _resultText = null;
    _error = null;
  }

  @override
  void dispose() {
    _amount.dispose();
    _label.dispose();
    for (final text in _weights.values) {
      text.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flats = widget.controller.visibleFlats;
    final signature = flats
        .map((f) => '${f.id}/${f.code}/${f.tenancyId}')
        .join('|');
    if (signature != _flatSignature) {
      _invalidate();
      _flatSignature = signature;
    }
    for (final f in flats) {
      _weights.putIfAbsent(f.id, () => TextEditingController(text: '1'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'সমান ভাগে অথবা ব্যবহারের অনুপাতে হিসাব করুন। খালি ফ্ল্যাটসহ কাদের ভাগে আসবে, নিজে নির্বাচন করুন। এটি খসড়া হিসাব—ভাড়ার বিলে যোগ বা টাকা আদায় হবে না।',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _label,
          maxLength: 100,
          decoration: const InputDecoration(labelText: 'বিলের নাম / মাস'),
          onChanged: (_) => setState(_invalidate),
        ),
        TextField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'মোট বিল (টাকা)'),
          onChanged: (_) => setState(_invalidate),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('ব্যবহার / ইউনিট অনুযায়ী ভাগ'),
          subtitle: const Text('বন্ধ থাকলে নির্বাচিত ফ্ল্যাটে সমান ভাগ'),
          value: _weighted,
          onChanged: (v) => setState(() {
            _weighted = v;
            _invalidate();
          }),
        ),
        for (final f in flats)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Checkbox(
                  value: !_excluded.contains(f.id),
                  onChanged: (v) => setState(() {
                    v == true ? _excluded.remove(f.id) : _excluded.add(f.id);
                    _invalidate();
                  }),
                ),
                Expanded(
                  child: Text(
                    '${f.code}${f.tenancyId.isEmpty ? ' • খালি' : ''}',
                  ),
                ),
                if (_weighted)
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _weights[f.id],
                      enabled: !_excluded.contains(f.id),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'পূর্ণ ইউনিট',
                      ),
                      onChanged: (_) => setState(_invalidate),
                    ),
                  ),
              ],
            ),
          ),
        if (flats.isEmpty)
          const EasyEmpty(
            'আগে ফ্ল্যাট যোগ করুন',
            'তারপর ফ্ল্যাট অনুযায়ী বিল ভাগ করতে পারবেন।',
          ),
        FilledButton(
          onPressed: flats.isEmpty
              ? null
              : () => setState(() {
                  _invalidate();
                  try {
                    final amount = parsePaisa(_amount.text);
                    if (amount == null) {
                      throw ArgumentError('সঠিক মোট বিল লিখুন।');
                    }
                    final weights = <String, int>{};
                    for (final f in flats.where(
                      (f) => !_excluded.contains(f.id),
                    )) {
                      final value = _weighted
                          ? int.tryParse(latinDigits(_weights[f.id]!.text))
                          : 1;
                      if (value == null) {
                        throw ArgumentError('ব্যবহার পূর্ণ সংখ্যায় লিখুন।');
                      }
                      weights[f.id] = value;
                    }
                    _shares = splitUtility(amount, weights);
                    _resultText =
                        '${widget.controller.home!.name}\n${_label.text.trim()}\nখসড়া বিল ভাগ • মোট ${money(amount)}\n'
                        '${_weighted ? 'ব্যবহারের অনুপাতে' : 'সমান ভাগে'}\n'
                        '${flats.where((f) => _shares!.containsKey(f.id)).map((f) => '${f.code}: ${money(_shares![f.id]!)}').join('\n')}\n'
                        'পয়সার অবশিষ্ট অংশ মিলিয়ে মোট অক্ষুণ্ণ রাখা হয়েছে। এটি জমার রসিদ নয়।';
                  } catch (e) {
                    _error = easyHomeError(e);
                  }
                }),
          child: const Text('ভাগ হিসাব করুন'),
        ),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (_shares != null) ...[
          const SizedBox(height: 16),
          EasyCard(child: SelectableText(_resultText!)),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _resultText!));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('হিসাব কপি হয়েছে।')),
                );
              }
            },
            icon: const Icon(Icons.copy),
            label: const Text('ভাগের হিসাব কপি'),
          ),
        ],
      ],
    );
  }
}
