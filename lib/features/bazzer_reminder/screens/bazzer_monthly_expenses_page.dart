import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/bazzer_expense.dart';
import '../repositories/bazzer_repository.dart';
import '../utils/bazzer_format.dart';

class BazzerMonthlyExpensesPage extends StatefulWidget {
  const BazzerMonthlyExpensesPage({
    super.key,
    required this.repository,
    required this.familyId,
    this.initialMonth,
  });
  final BazzerRepository repository;
  final String familyId;
  final String? initialMonth;
  @override
  State<BazzerMonthlyExpensesPage> createState() =>
      _BazzerMonthlyExpensesPageState();
}

class _BazzerMonthlyExpensesPageState extends State<BazzerMonthlyExpensesPage> {
  late final _auth = widget.repository.authStateChanges();
  late final _family = widget.repository.watchFamily(widget.familyId);
  final _members = <String, Stream<BazzerMember?>>{};

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('মাসিক খরচ')),
    body: SafeArea(
      child: StreamBuilder<User?>(
        stream: _auth,
        initialData: widget.repository.signedInUser,
        builder: (context, auth) {
          final user = auth.data;
          if (auth.hasError || user == null) {
            return const Center(child: Text('আগে লগইন করুন।'));
          }
          return StreamBuilder<BazzerFamily?>(
            key: ValueKey(user.uid),
            stream: _family,
            builder: (context, family) {
              if (family.hasError) return _denied();
              if (family.connectionState == ConnectionState.waiting) {
                return _loading();
              }
              if (family.data == null) return _denied();
              if (family.data!.ownerUid == user.uid) {
                return _history(user.uid, true);
              }
              return StreamBuilder<BazzerMember?>(
                stream: _members.putIfAbsent(
                  user.uid,
                  () => widget.repository.watchOwnMember(
                    widget.familyId,
                    user.uid,
                  ),
                ),
                builder: (context, member) {
                  if (member.hasError) return _denied();
                  if (member.connectionState == ConnectionState.waiting) {
                    return _loading();
                  }
                  if (member.data?.active != true) return _denied();
                  return _history(user.uid, member.data!.isAdmin);
                },
              );
            },
          );
        },
      ),
    ),
  );

  Widget _history(String uid, bool admin) => _MonthHistory(
    // Discard old private snapshots immediately when account/role changes.
    key: ValueKey('$uid/$admin'),
    repository: widget.repository,
    familyId: widget.familyId,
    admin: admin,
    initialMonth: widget.initialMonth,
  );
  Widget _denied() =>
      const Center(child: Text('এই পরিবারের হিসাব দেখার অনুমতি নেই।'));
  Widget _loading() => const Center(child: CircularProgressIndicator());
}

class _MonthHistory extends StatefulWidget {
  const _MonthHistory({
    super.key,
    required this.repository,
    required this.familyId,
    required this.admin,
    this.initialMonth,
  });
  final BazzerRepository repository;
  final String familyId;
  final bool admin;
  final String? initialMonth;
  @override
  State<_MonthHistory> createState() => _MonthHistoryState();
}

class _MonthHistoryState extends State<_MonthHistory> {
  late String _month =
      widget.initialMonth ?? bazzerDayKey(DateTime.now()).substring(0, 7);
  late Stream<List<BazzerExpense>> _expenses = _watch();
  Stream<List<BazzerExpense>> _watch() => widget.repository.watchExpenses(
    widget.familyId,
    _month,
    includeSecure: widget.admin,
  );

  void _move(int offset) {
    final date = DateTime.parse('$_month-01');
    final target = DateTime(date.year, date.month + offset);
    setState(() {
      _month =
          '${target.year.toString().padLeft(4, '0')}-${target.month.toString().padLeft(2, '0')}';
      _expenses = _watch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final currentMonth = bazzerDayKey(DateTime.now()).substring(0, 7);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              IconButton(
                tooltip: 'আগের মাস',
                onPressed: () => _move(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  bazzerDayLabel('$_month-01').split(' ').skip(1).join(' '),
                  key: const ValueKey('expense-month'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'পরের মাস',
                onPressed: _month.compareTo(currentMonth) < 0
                    ? () => _move(1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<BazzerExpense>>(
            key: ValueKey(_month),
            stream: _expenses,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'হিসাব পড়া যায়নি। সংযোগ ও অনুমতি দেখে আবার পেজটি খুলুন।',
                    ),
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              // A zero shared record clears an earlier save without revealing a
              // day containing only private items to ordinary members.
              final entries = (snapshot.data ?? [])
                  .where((entry) => entry.itemCount > 0)
                  .toList();
              final total = entries.fold(
                0,
                (sum, entry) => sum + entry.totalPaisa,
              );
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'মাসের সর্বমোট',
                          style: TextStyle(color: colors.onPrimaryContainer),
                        ),
                        Text(
                          bazzerMoney(total),
                          key: const ValueKey('monthly-total'),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          '${banglaNumber(entries.length)} দিনের সংরক্ষিত হিসাব',
                          style: TextStyle(color: colors.onPrimaryContainer),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      widget.admin
                          ? 'Save করা Normal ও Secure বাজারের হিসাব'
                          : 'Save করা সাধারণ বাজারের হিসাব',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (entries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'এই মাসে কোনো হিসাব সেভ করা হয়নি। বাজারের নিচে Save চাপলে এখানে দেখা যাবে।',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  for (final entry in entries)
                    Padding(
                      key: ValueKey('expense-${entry.day}'),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(bazzerDayLabel(entry.day)),
                                Text(
                                  '${banglaNumber(entry.itemCount)}টি আইটেম'
                                  '${entry.hasPendingWrites ? ' • সেভ নিশ্চিত হচ্ছে…' : ''}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              bazzerMoney(entry.totalPaisa),
                              key: ValueKey('expense-total-${entry.day}'),
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (entries.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text(
                        'দাম বদলালে বাজারের তালিকায় আবার Save করুন। একই দিনের হিসাব আপডেট হবে।',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
