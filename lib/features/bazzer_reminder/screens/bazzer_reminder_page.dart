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
import 'bazzer_edit_item_dialog.dart';
import 'voice_review_sheet.dart';

class BazzerReminderPage extends StatefulWidget {
  const BazzerReminderPage({super.key, this.repository, this.voice});

  final BazzerRepository? repository;
  final VoiceService? voice;

  @override
  State<BazzerReminderPage> createState() => _BazzerReminderPageState();
}

class _BazzerReminderPageState extends State<BazzerReminderPage> {
  late final _repository = widget.repository ?? BazzerRepository();
  late final _voice = widget.voice ?? VoiceService();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _searchController = TextEditingController();
  late final Stream<User?> _authStream = _repository.authStateChanges();
  final Map<String, Stream<String?>> _linkStreams = {};
  final Map<String, Stream<BazzerFamily?>> _familyStreams = {};
  final Map<String, Stream<BazzerMember?>> _memberStreams = {};
  final Map<String, Stream<List<BazzerItem>>> _itemStreams = {};
  bool _secureNewItem = false;
  String _unit = 'টা';
  String? _manualStore;
  String? _filterStore;
  String _search = '';
  String _heard = '';
  bool _isListening = false;
  bool _voiceStarting = false;
  bool _reviewingVoice = false;

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

  Stream<String?> _linkStream(String uid) =>
      _linkStreams.putIfAbsent(uid, () => _repository.watchFamilyId(uid));

  Stream<BazzerFamily?> _familyStream(String id) =>
      _familyStreams.putIfAbsent(id, () => _repository.watchFamily(id));

  Stream<BazzerMember?> _memberStream(String id, String uid) => _memberStreams
      .putIfAbsent('$id/$uid', () => _repository.watchOwnMember(id, uid));

  Stream<List<BazzerItem>> _itemsStream(
    String id, {
    required bool bought,
    bool secure = false,
    String? authorUid,
  }) => _itemStreams.putIfAbsent(
    '$id/$bought/$secure/${authorUid ?? ''}',
    () => secure
        ? _repository.watchSecureItems(
            id,
            isBought: bought,
            authorUid: authorUid,
          )
        : _repository.watchItems(id, isBought: bought),
  );

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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _queueWrite(Future<void> operation) {
    unawaited(
      operation.catchError((Object error) {
        _message('পাঠানো যায়নি: $error। সংযোগ ও সদস্যের অনুমতি দেখুন।');
      }),
    );
  }

  void _addManual(
    String familyId, {
    required bool secure,
    required String addedBy,
  }) {
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
      isSecure: secure,
    );
    _queueWrite(_repository.addItems(familyId, [item], addedBy: addedBy));
    _nameController.clear();
    _quantityController.text = '1';
    setState(() => _manualStore = null);
    _message('তালিকায় যোগ হয়েছে। Offline হলে সংযোগ ফিরলে পাঠাবে।');
  }

  Future<void> _toggleVoice(
    String familyId, {
    required bool secure,
    required String addedBy,
  }) async {
    if (_voiceStarting || _reviewingVoice) return;
    if (_isListening) {
      await _voice.stopListening();
      if (mounted) setState(() => _isListening = false);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _voiceStarting = true;
      _heard = '';
    });
    try {
      await _voice.startListening(
        onFinalText: (text) {
          if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
          setState(() {
            _heard = VoiceParser.fixBanglaText(text);
            _isListening = false;
          });
          unawaited(
            _reviewVoice(familyId, text, secure: secure, addedBy: addedBy),
          );
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
    } finally {
      if (mounted) setState(() => _voiceStarting = false);
    }
  }

  Future<void> _reviewVoice(
    String familyId,
    String text, {
    required bool secure,
    required String addedBy,
  }) async {
    if (_reviewingVoice) return;
    _reviewingVoice = true;
    final parsed = VoiceParser.parsePreview(text);
    final chosen = await showModalBottomSheet<List<BazzerItem>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => VoiceReviewSheet(heard: text, parsed: parsed),
    );
    _reviewingVoice = false;
    if (!mounted || chosen == null || chosen.isEmpty) return;
    _queueWrite(
      _repository.addItems(
        familyId,
        chosen.map((item) => item.copyWith(isSecure: secure)).toList(),
        addedBy: addedBy,
      ),
    );
    _message('${chosen.length}টি আইটেম তালিকায় যোগ হয়েছে।');
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: _authStream,
    initialData: _repository.signedInUser,
    builder: (context, userSnapshot) {
      final user = userSnapshot.data;
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
        key: ValueKey(user.uid),
        stream: _linkStream(user.uid),
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
            stream: _familyStream(familyId),
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
              if (family == null) {
                return const Scaffold(
                  body: Center(child: Text('পরিবারটি পাওয়া যায়নি।')),
                );
              }
              final owner = family.ownerUid == user.uid;
              if (owner) {
                return _shoppingScreen(
                  family,
                  BazzerMember(
                    uid: user.uid,
                    name: user.displayName ?? 'মূল অ্যাকাউন্ট',
                    active: true,
                    isOwner: true,
                  ),
                );
              }
              return StreamBuilder<BazzerMember?>(
                stream: _memberStream(family.id, user.uid),
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
                  return _shoppingScreen(family, memberSnapshot.data!);
                },
              );
            },
          );
        },
      );
    },
  );

  Future<void> _openFamily(BazzerFamily family, BazzerMember member) async {
    FocusScope.of(context).unfocus();
    unawaited(_voice.dispose());
    setState(() => _isListening = false);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => member.isAdmin
            ? BazzerFamilyManagePage(
                family: family,
                repository: _repository,
                currentUid: member.uid,
              )
            : BazzerFamilyInfoPage(
                family: family,
                member: member,
                repository: _repository,
              ),
      ),
    );
  }

  Widget _shoppingScreen(BazzerFamily family, BazzerMember member) {
    final colors = Theme.of(context).colorScheme;
    final admin = member.isAdmin;
    final secure = member.secure || (admin && _secureNewItem);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('পরিবারের বাজার'),
          actions: [
            IconButton(
              tooltip: admin ? 'পরিবারের সদস্য ও কোড' : 'আমার পরিবারের তথ্য',
              onPressed: () => _openFamily(family, member),
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
          onPressed: _voiceStarting
              ? null
              : () => _toggleVoice(
                  family.id,
                  secure: secure,
                  addedBy: member.name,
                ),
          icon: Icon(_isListening ? Icons.stop_rounded : Icons.mic_rounded),
          label: Text(
            _voiceStarting
                ? 'চালু হচ্ছে…'
                : _isListening
                ? 'শুনছি—থামুন'
                : 'বাংলায় বলুন',
          ),
        ),
        body: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Column(
                    children: [
                      Card(
                        color: colors.primaryContainer,
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          key: const ValueKey('bazzer-family-button'),
                          onTap: () => _openFamily(family, member),
                          leading: Icon(
                            Icons.family_restroom_rounded,
                            color: colors.onPrimaryContainer,
                          ),
                          title: Text(
                            member.isOwner
                                ? 'মূল অ্যাকাউন্ট • Admin'
                                : admin
                                ? 'Admin'
                                : member.secure
                                ? 'পরিবারের সদস্য • Secure'
                                : 'পরিবারের সদস্য',
                            style: TextStyle(color: colors.onPrimaryContainer),
                          ),
                          subtitle: Text(
                            admin
                                ? 'সদস্য ও কোড পরিচালনা করতে চাপুন'
                                : 'আপনার নাম ও পরিবারের তথ্য দেখতে চাপুন',
                            style: TextStyle(color: colors.onPrimaryContainer),
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: colors.onPrimaryContainer,
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
                      if (admin)
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'নতুন আইটেম Secure তালিকায় যোগ করুন',
                          ),
                          value: _secureNewItem,
                          onChanged: (value) =>
                              setState(() => _secureNewItem = value),
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
                                    if (value != null) {
                                      setState(() => _unit = value);
                                    }
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
                              onPressed: () => _addManual(
                                family.id,
                                secure: secure,
                                addedBy: member.name,
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text('তালিকায় যোগ করুন'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              children: [
                _itemsTab(family.id, member: member, bought: false),
                _itemsTab(family.id, member: member, bought: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _itemsTab(
    String familyId, {
    required BazzerMember member,
    required bool bought,
  }) {
    return StreamBuilder<List<BazzerItem>>(
      stream: _itemsStream(familyId, bought: bought),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'তালিকা পড়া যায়নি। সদস্যের অনুমতি ও rules পরীক্ষা করুন।',
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // Every writer keeps access to their own older secure items after an
        // admin changes their account back to normal.
        return StreamBuilder<List<BazzerItem>>(
          key: ValueKey('${member.uid}/${member.isAdmin}'),
          stream: _itemsStream(
            familyId,
            bought: bought,
            secure: true,
            authorUid: member.isAdmin ? null : member.uid,
          ),
          builder: (context, secureSnapshot) {
            if (secureSnapshot.hasError) {
              return const Center(
                child: Text(
                  'Secure তালিকা পড়া যায়নি। Firebase rules পরীক্ষা করুন।',
                ),
              );
            }
            return _itemList(
              familyId,
              member: member,
              bought: bought,
              items: [...?snapshot.data, ...?secureSnapshot.data],
            );
          },
        );
      },
    );
  }

  Widget _itemList(
    String familyId, {
    required BazzerMember member,
    required bool bought,
    required List<BazzerItem> items,
  }) {
    final filtered = items
        .where(
          (item) => item.name.toLowerCase().contains(_search.toLowerCase()),
        )
        .toList();
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 100),
      children: [
        if (!bought) _storeFilters(),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                bought
                    ? 'এখনো কেনা হয়েছে এমন জিনিস নেই।'
                    : 'দোকান অনুযায়ী বাজার যোগ করুন।',
              ),
            ),
          ),
        for (final category in StoreCategory.all)
          if ((_filterStore == null || bought || _filterStore == category) &&
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
                key: ValueKey('${item.isSecure}/${item.id}'),
                direction: member.isAdmin
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
                  if (member.isAdmin) {
                    _queueWrite(
                      _repository.setBought(familyId, item, !item.isBought),
                    );
                  }
                  // Let the Firestore listener move the tile between tabs.
                  return false;
                },
                child: BazzerItemTile(
                  item: item,
                  canMarkBought: member.isAdmin,
                  canEdit: item.createdBy == member.uid,
                  onEdit: () => _editItem(familyId, item),
                  onDelete: () => _deleteItem(familyId, item),
                  onToggle: () => _queueWrite(
                    _repository.setBought(familyId, item, !item.isBought),
                  ),
                ),
              ),
          ],
      ],
    );
  }

  Future<void> _editItem(String familyId, BazzerItem item) async {
    final edited = await showDialog<BazzerItemEdit>(
      context: context,
      builder: (_) => BazzerEditItemDialog(item: item),
    );
    if (!mounted || edited == null) return;
    _queueWrite(
      _repository.editItem(
        familyId,
        item,
        name: edited.name,
        quantity: edited.quantity,
        unit: edited.unit,
        category: edited.category,
      ),
    );
  }

  Future<void> _deleteItem(String familyId, BazzerItem item) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('তালিকা থেকে মুছবেন?'),
        content: Text('${item.name} মুছে দিলে পরিবারের তালিকা থেকেও সরে যাবে।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('মুছে দিন'),
          ),
        ],
      ),
    );
    if (mounted && approved == true) {
      _queueWrite(_repository.deleteItem(familyId, item));
    }
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
