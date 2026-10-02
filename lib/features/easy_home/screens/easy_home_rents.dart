import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../controllers/easy_home_controller.dart';
import '../models/easy_home_models.dart';
import '../utils/easy_home_format.dart';
import '../widgets/easy_home_widgets.dart';

class EasyHomeRents extends StatefulWidget {
  const EasyHomeRents({super.key, required this.controller});
  final EasyHomeController controller;
  @override
  State<EasyHomeRents> createState() => _EasyHomeRentsState();
}

class _EasyHomeRentsState extends State<EasyHomeRents> {
  String _month = monthKey(DateTime.now());
  String _status = 'all';
  EasyHomeController get c => widget.controller;
  Future<void> _payment(RentModel rent, {bool correction = false}) async {
    final paymentId = c.repository.newPaymentId();
    final homeId = c.homeId!;
    await showEasyForm(
      context,
      title: correction ? 'জমা সংশোধন' : 'ভাড়া জমা নিন',
      description:
          '${rent.flatCode} • ${monthText(rent.month)}\nবকেয়া ${money(rent.duePaisa)} • জমা ${money(rent.paidPaisa)}',
      fields: [
        EasyField(
          'amount',
          correction ? 'জমা থেকে কমাবেন (টাকা)' : 'জমার পরিমাণ (টাকা)',
          initial: correction ? '' : moneyInput(rent.duePaisa),
          keyboard: const TextInputType.numberWithOptions(decimal: true),
        ),
        if (!correction)
          const EasyField(
            'method',
            'জমার মাধ্যম',
            initial: 'cash',
            options: {
              'cash': 'নগদ',
              'bank': 'ব্যাংক',
              'mobile': 'মোবাইল ব্যাংকিং',
            },
          ),
        EasyField(
          'note',
          correction ? 'সংশোধনের কারণ' : 'নোট / লেনদেন নম্বর (ঐচ্ছিক)',
          optional: !correction,
          maxLength: 300,
          multiline: true,
        ),
      ],
      save: (v) {
        final amount = parsePaisa(v['amount']!);
        if (amount == null || amount == 0)
          throw ArgumentError('সঠিক পরিমাণ লিখুন।');
        return c.repository.recordPayment(
          homeId,
          rent,
          paymentId: paymentId,
          amountPaisa: correction ? -amount : amount,
          method: correction ? 'correction' : v['method']!,
          note: v['note']!,
        );
      },
    );
  }

  Future<void> _remind(RentModel rent) async {
    final flat = c.flats.where((f) => f.tenancyId == rent.tenantId).firstOrNull;
    if (flat == null) return;
    await showEasyForm(
      context,
      title: 'ভাড়ার নোটিশ',
      fields: [
        EasyField(
          'message',
          'বার্তা',
          initial:
              '${monthText(rent.month)} মাসের ভাড়ায় ${money(rent.duePaisa)} বকেয়া আছে। অনুগ্রহ করে হিসাব দেখে ভাড়া পরিশোধ করুন।',
          maxLength: 2000,
          multiline: true,
        ),
      ],
      description: '${flat.code}-এর বর্তমান ভাড়াটিয়ার নোটিশে দেখা যাবে।',
      save: (v) => c.repository.postNotice(
        c.homeId!,
        content: v['message']!,
        audience: 'tenant:${rent.tenantId}',
        emergency: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final months = {
      monthKey(DateTime.now()),
      ...c.rents.map((r) => r.month),
    }.toList()..sort((a, b) => b.compareTo(a));
    final selectedMonth = months.contains(_month) ? _month : months.first;
    final monthRents = c.rents.where((r) => r.month == selectedMonth).toList();
    final rents =
        monthRents
            .where(
              (r) =>
                  _status == 'all' ||
                  (_status == 'due' ? r.duePaisa > 0 : r.duePaisa == 0),
            )
            .toList()
          ..sort((a, b) => a.flatCode.compareTo(b.flatCode));
    final total = monthRents.fold(0, (int n, r) => n + r.amountPaisa);
    final paid = monthRents.fold(0, (int n, r) => n + r.paidPaisa);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const EasySectionTitle('ভাড়া ও জমার ইতিহাস'),
        if (!c.isLandlord)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'আপনার ফ্ল্যাটের হিসাব। জমা মালিক নিশ্চিত করলে এখানে দেখা যাবে।',
            ),
          ),
        DropdownButtonFormField<String>(
          key: ValueKey(selectedMonth),
          initialValue: selectedMonth,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'হিসাবের মাস',
            border: OutlineInputBorder(),
          ),
          items: months
              .map((m) => DropdownMenuItem(value: m, child: Text(monthText(m))))
              .toList(),
          onChanged: (v) => setState(() => _month = v!),
        ),
        const SizedBox(height: 16),
        EasyCard(
          child: Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              Text('মোট ভাড়া\n${money(total)}'),
              Text('জমা\n${money(paid)}'),
              Text('বকেয়া\n${money(total - paid)}'),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final entry in const {
              'all': 'সব',
              'due': 'বকেয়া',
              'paid': 'পরিশোধিত',
            }.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: _status == entry.key,
                onSelected: (_) => setState(() => _status = entry.key),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (rents.isEmpty)
          EasyEmpty(
            'এই তালিকায় কোনো বিল নেই',
            c.isLandlord
                ? 'ভাড়াটিয়া যোগ করলে মাসিক বিল তৈরি হবে।'
                : 'বাড়িওয়ালা বিল তৈরি করলে এখানে দেখা যাবে।',
            icon: Icons.receipt_long_outlined,
          ),
        for (final rent in rents)
          EasyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        rent.flatCode,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        rent.statusLabel,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: rent.duePaisa == 0
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
                if (c.isLandlord)
                  Text(
                    c.tenants
                            .where((t) => t.id == rent.tenantId)
                            .firstOrNull
                            ?.name ??
                        '',
                  ),
                const SizedBox(height: 8),
                Text(
                  'ভাড়া ${money(rent.amountPaisa)} • জমা ${money(rent.paidPaisa)}',
                ),
                Text(
                  'বকেয়া ${money(rent.duePaisa)} • শেষ তারিখ ${dateText(rent.dueDate)}',
                ),
                if (rent.overdue(DateTime.now()))
                  Text(
                    'পরিশোধের সময় পেরিয়েছে',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                Wrap(
                  spacing: 8,
                  children: [
                    if (c.isLandlord && rent.duePaisa > 0)
                      FilledButton(
                        onPressed: () => _payment(rent),
                        child: const Text('জমা নিন'),
                      ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => EasyHomeReceipts(
                            rent: rent,
                            homeName: c.home?.name ?? 'EasyHome',
                            payments: c.repository.watchPayments(
                              c.homeId!,
                              rent.id,
                            ),
                          ),
                        ),
                      ),
                      child: const Text('রসিদ / ইতিহাস'),
                    ),
                    if (c.isLandlord &&
                        rent.duePaisa > 0 &&
                        c.flats.any((f) => f.tenancyId == rent.tenantId))
                      TextButton(
                        onPressed: () => _remind(rent),
                        child: const Text('মনে করিয়ে দিন'),
                      ),
                    if (c.isLandlord && rent.paidPaisa > 0)
                      TextButton(
                        onPressed: () => _payment(rent, correction: true),
                        child: const Text('জমা সংশোধন'),
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

String rentReceipt(String homeName, RentModel rent, RentPayment payment) =>
    '$homeName\nভাড়া জমার রসিদ\nফ্ল্যাট: ${rent.flatCode}\nমাস: ${monthText(rent.month)}\n'
    'তারিখ: ${dateText(payment.createdAt)}\n${payment.amountPaisa < 0 ? 'সংশোধন' : 'জমা'}: ${money(payment.amountPaisa.abs())}\n'
    'এই জমার পর মোট: ${money(payment.balancePaisa)}\n'
    'মাধ্যম: ${const {'cash': 'নগদ', 'bank': 'ব্যাংক', 'mobile': 'মোবাইল ব্যাংকিং', 'correction': 'সংশোধন'}[payment.method] ?? payment.method}\n'
    '${payment.note.isEmpty ? '' : 'নোট: ${payment.note}\n'}রসিদ নম্বর: ${payment.id}\nEasyHome';

class EasyHomeReceipts extends StatelessWidget {
  const EasyHomeReceipts({
    super.key,
    required this.rent,
    required this.homeName,
    required this.payments,
  });
  final RentModel rent;
  final String homeName;
  final Stream<List<RentPayment>> payments;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('${rent.flatCode} • রসিদ')),
    body: StreamBuilder<List<RentPayment>>(
      stream: payments,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return EasyEmpty('রসিদ খোলা যায়নি', easyHomeError(snapshot.error!));
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final rows = [...snapshot.data!]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (rows.isEmpty)
          return const EasyEmpty(
            'এখনো জমা নেই',
            'ভাড়া জমা নেওয়ার পর রসিদ এখানে থাকবে।',
          );
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final payment in rows)
              EasyCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(rentReceipt(homeName, rent, payment)),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: () => Clipboard.setData(
                            ClipboardData(
                              text: rentReceipt(homeName, rent, payment),
                            ),
                          ),
                          icon: const Icon(Icons.copy),
                          label: const Text('কপি'),
                        ),
                        Builder(
                          builder: (buttonContext) => TextButton.icon(
                            onPressed: () async {
                              final box =
                                  buttonContext.findRenderObject()!
                                      as RenderBox;
                              try {
                                await SharePlus.instance.share(
                                  ShareParams(
                                    text: rentReceipt(homeName, rent, payment),
                                    sharePositionOrigin:
                                        box.localToGlobal(Offset.zero) &
                                        box.size,
                                  ),
                                );
                              } catch (_) {
                                if (context.mounted)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'শেয়ার করা যায়নি। কপি বাটন ব্যবহার করুন।',
                                      ),
                                    ),
                                  );
                              }
                            },
                            icon: const Icon(Icons.share_outlined),
                            label: const Text('শেয়ার'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    ),
  );
}
