import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/bazzer_item_model.dart';
import '../repositories/bazzer_repository.dart';
import '../services/voice_service.dart';
import '../utils/store_category.dart';
import '../utils/voice_parser.dart';
import '../widgets/bazzer_item_tile.dart';
import 'bazzer_family_page.dart';
import 'voice_review_sheet.dart';

class BazzerReminderPage extends StatefulWidget {
  const BazzerReminderPage({super.key});

  @override
  State<BazzerReminderPage> createState() => _BazzerReminderPageState();
}

class _BazzerReminderPageState extends State<BazzerReminderPage> {
  final _repository = BazzerRepository();
  final _voice = VoiceService();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _searchController = TextEditingController();
  String _unit = 'টা';
  String? _manualStore;
  String? _filterStore;
  String _search = '';
  String _heard = '';
  bool _isListening = false;

  static const _units = [
    'টা',
    'কেজি',
    'গ্রাম',
    'লিটার',
    'মিলি',
    'আঁটি',
    'প্যাকেট',
    'বোতল',
    'হালি',
    'ডজন',
  ];

  @override
  void dispose() {
    unawaited(_voice.dispose());
    _nameController.dispose();
    _quantityController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _queueWrite(Future<void> operation) {
    unawaited(
      operation.catchError((Object error) {
        _message('পাঠানো যায়নি: $error। সংযোগ ও সদস্যের অনুমতি দেখুন।');
      }),
    );
  }

  void _addManual(String familyId) {
    final name = _nameController.text.trim();
    final number = _quantityController.text
        .trim()
        .replaceAll('০', '0')
        .replaceAll('১', '1')
        .replaceAll('২', '2')
        .replaceAll('৩', '3')
        .replaceAll('৪', '4')
        .replaceAll('৫', '5')
        .replaceAll('৬', '6')
        .replaceAll('৭', '7')
        .replaceAll('৮', '8')
        .replaceAll('৯', '9');
    final quantity = double.tryParse(number);
    if (name.isEmpty ||
        name.length > 120 ||
        quantity == null ||
        quantity <= 0 ||
        quantity > 1000 ||
        (_unit == 'টা' && quantity % 1 != 0)) {
      _message('সঠিক নাম ও ০ থেকে ১০০০-এর মধ্যে পরিমাণ লিখুন।');
      return;
    }
    final category = _manualStore ?? StoreCategory.guess(name);
    final item = BazzerItem(
      id: const Uuid().v4(),
      name: name,
      quantity: quantity,
      unit: _unit,
      category: category,
      createdAt: DateTime.now(),
    );
    _queueWrite(_repository.addItems(familyId, [item]));
    _nameController.clear();
    _quantityController.text = '1';
    setState(() => _manualStore = null);
    _message('তালিকায় যোগ হয়েছে। Offline হলে সংযোগ ফিরলে পাঠাবে।');
  }

  Future<void> _toggleVoice(String familyId) async {
    if (_isListening) {
      await _voice.stopListening();
      if (mounted) setState(() => _isListening = false);
      return;
    }
    try {
      await _voice.startListening(
        onFinalText: (text) {
          if (!mounted) return;
          setState(() {
            _heard = VoiceParser.fixBanglaText(text);
            _isListening = false;
          });
          unawaited(_reviewVoice(familyId, text));
        },
        onPartialText: (text) {
          if (mounted) setState(() => _heard = text);
        },
        onListeningChanged: (value) {
          if (mounted) setState(() => _isListening = value);
        },
        onError: _message,
      );
    } catch (error) {
      _message('Voice recognition চালু করা যায়নি: $error');
      if (mounted) setState(() => _isListening = false);
    }
  }

  Future<void> _reviewVoice(String familyId, String text) async {
    final parsed = VoiceParser.parsePreview(text);
    final chosen = await showModalBottomSheet<List<BazzerItem>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => VoiceReviewSheet(heard: text, parsed: parsed),
    );
    if (!mounted || chosen == null || chosen.isEmpty) return;
    _queueWrite(_repository.addItems(familyId, chosen));
    _message('${chosen.length}টি আইটেম তালিকায় যোগ হয়েছে।');
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, userSnapshot) {
      final user = userSnapshot.data ?? FirebaseAuth.instance.currentUser;
      if (user == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('বাজার তালিকা')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'পরিবারের বাজার তালিকা নিরাপদ রাখতে আগে নিজের account-এ লগইন করুন।',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        );
      }
      return StreamBuilder<String?>(
        stream: _repository.watchFamilyId(user.uid),
        builder: (context, linkSnapshot) {
          if (linkSnapshot.hasError) {
            return Scaffold(
              appBar: AppBar(title: const Text('বাজার তালিকা')),
              body: const Center(
                child: Text(
                  'পরিবারের তথ্য পড়া যাচ্ছে না। Firestore rules deploy করুন।',
                ),
              ),
            );
          }
          if (linkSnapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              appBar: AppBar(title: const Text('বাজার তালিকা')),
              body: const Center(child: CircularProgressIndicator()),
            );
          }
          final familyId = linkSnapshot.data;
          if (familyId == null || familyId.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: const Text('বাজার তালিকা')),
              body: BazzerFamilySetup(repository: _repository),
            );
          }
          return StreamBuilder<BazzerFamily?>(
            stream: _repository.watchFamily(familyId),
            builder: (context, familySnapshot) {
              if (familySnapshot.hasError) {
                return Scaffold(
                  appBar: AppBar(title: const Text('বাজার তালিকা')),
                  body: const Center(
                    child: Text(
                      'পরিবারের প্রবেশাধিকার নেই। মূল অ্যাকাউন্টের সঙ্গে যোগাযোগ করুন।',
                    ),
                  ),
                );
              }
              if (familySnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              final family = familySnapshot.data;
              if (family == null)
                return const Scaffold(
                  body: Center(child: Text('পরিবারটি পাওয়া যায়নি।')),
                );
              final owner = family.ownerUid == user.uid;
              if (owner) return _shoppingScreen(family, true);
              return StreamBuilder<BazzerMember?>(
                stream: _repository.watchOwnMember(family.id, user.uid),
                builder: (context, memberSnapshot) {
                  if (memberSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (memberSnapshot.hasError ||
                      memberSnapshot.data?.active != true) {
                    return Scaffold(
                      appBar: AppBar(title: const Text('বাজার তালিকা')),
                      body: const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'এই পরিবারে আপনার প্রবেশাধিকার বন্ধ হয়েছে। '
                            'মূল অ্যাকাউন্ট থেকে আবার যুক্ত করতে বলুন।',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  }
                  return _shoppingScreen(family, false);
                },
              );
            },
          );
        },
      );
    },
  );

  Widget _shoppingScreen(BazzerFamily family, bool owner) {
    final colors = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('পরিবারের বাজার'),
          actions: [
            if (owner)
              IconButton(
                tooltip: 'পরিবারের সদস্য ও কোড',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BazzerFamilyManagePage(
                      family: family,
                      repository: _repository,
                    ),
                  ),
                ),
                icon: const Icon(Icons.manage_accounts_rounded),
              ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.shopping_cart_outlined), text: 'কেনা বাকি'),
              Tab(icon: Icon(Icons.task_alt_rounded), text: 'কেনা হয়েছে'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _toggleVoice(family.id),
          icon: Icon(_isListening ? Icons.stop_rounded : Icons.mic_rounded),
          label: Text(_isListening ? 'শুনছি—থামুন' : 'বাংলায় বলুন'),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Column(
                  children: [
                    Card(
                      color: colors.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.family_restroom_rounded,
                              color: colors.onPrimaryContainer,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                owner
                                    ? 'মূল অ্যাকাউন্ট • সদস্যরা যোগ করবেন, আপনি বাজার সম্পন্ন করবেন'
                                    : 'পরিবারের সদস্য • আপনি তালিকায় যোগ করতে পারবেন',
                                style: TextStyle(
                                  color: colors.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_heard.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Text(
                          '🎤 $_heard',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _search = value.trim()),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded),
                        hintText: 'বাজারের জিনিস খুঁজুন',
                      ),
                    ),
                    ExpansionTile(
                      title: const Text('লিখে নতুন জিনিস যোগ করুন'),
                      leading: const Icon(Icons.add_circle_outline_rounded),
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 8),
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'জিনিসের নাম (যেমন কাঁচামরিচ)',
                          ),
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _quantityController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'পরিমাণ',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _unit,
                                decoration: const InputDecoration(
                                  labelText: 'একক',
                                ),
                                items: [
                                  for (final unit in _units)
                                    DropdownMenuItem(
                                      value: unit,
                                      child: Text(unit),
                                    ),
                                ],
                                onChanged: (value) {
                                  if (value != null)
                                    setState(() => _unit = value);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          key: ValueKey(_manualStore),
                          initialValue: _manualStore ?? '',
                          decoration: const InputDecoration(
                            labelText: 'কোন দোকান?',
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('নাম দেখে স্বয়ংক্রিয়'),
                            ),
                            for (final category in StoreCategory.all)
                              DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ),
                          ],
                          onChanged: (value) => setState(
                            () => _manualStore = value == '' ? null : value,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: () => _addManual(family.id),
                            icon: const Icon(Icons.add),
                            label: const Text('তালিকায় যোগ করুন'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _itemsTab(family.id, owner: owner, bought: false),
                    _itemsTab(family.id, owner: owner, bought: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemsTab(
    String familyId, {
    required bool owner,
    required bool bought,
  }) {
    return StreamBuilder<List<BazzerItem>>(
      stream: _repository.watchItems(familyId, isBought: bought),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return const Center(
            child: Text(
              'তালিকা পড়া যায়নি। সদস্যের অনুমতি ও rules পরীক্ষা করুন।',
            ),
          );
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final filtered = (snapshot.data ?? const <BazzerItem>[])
            .where(
              (item) => item.name.toLowerCase().contains(_search.toLowerCase()),
            )
            .toList();
        if (filtered.isEmpty) {
          return Center(
            child: Text(
              bought
                  ? 'এখনো কেনা হয়েছে এমন জিনিস নেই।'
                  : 'দোকান অনুযায়ী বাজার যোগ করুন।',
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 100),
          children: [
            if (!bought) _storeFilters(),
            for (final category in StoreCategory.all)
              if ((_filterStore == null ||
                      bought ||
                      _filterStore == category) &&
                  filtered.any((item) => item.category == category)) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Text(
                    '$category দোকান',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                for (final item in filtered.where(
                  (item) => item.category == category,
                ))
                  Dismissible(
                    key: ValueKey(item.id),
                    direction: owner
                        ? DismissDirection.endToStart
                        : DismissDirection.none,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 22),
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        bought ? Icons.undo_rounded : Icons.done_all_rounded,
                      ),
                    ),
                    confirmDismiss: (_) async {
                      if (owner) {
                        _queueWrite(
                          _repository.setBought(
                            familyId,
                            item.id,
                            !item.isBought,
                          ),
                        );
                      }
                      // Let the Firestore listener move the tile between tabs.
                      return false;
                    },
                    child: BazzerItemTile(
                      item: item,
                      canMarkBought: owner,
                      onToggle: () => _queueWrite(
                        _repository.setBought(
                          familyId,
                          item.id,
                          !item.isBought,
                        ),
                      ),
                    ),
                  ),
              ],
          ],
        );
      },
    );
  }

  Widget _storeFilters() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        ChoiceChip(
          label: const Text('সব দোকান'),
          selected: _filterStore == null,
          onSelected: (_) => setState(() => _filterStore = null),
        ),
        const SizedBox(width: 6),
        for (final category in StoreCategory.all) ...[
          ChoiceChip(
            label: Text(category),
            selected: _filterStore == category,
            onSelected: (_) => setState(() => _filterStore = category),
          ),
          const SizedBox(width: 6),
        ],
      ],
    ),
  );
}
