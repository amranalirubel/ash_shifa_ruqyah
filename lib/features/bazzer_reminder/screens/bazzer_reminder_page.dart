import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/bazzer_item_model.dart';
import '../repositories/bazzer_repository.dart';
import '../services/voice_service.dart';
import '../utils/store_category.dart';
import '../utils/voice_parser.dart';
import '../utils/bazzer_receipt.dart';
import '../widgets/bazzer_daily_list.dart';
import 'bazzer_family_page.dart';
import 'bazzer_edit_item_dialog.dart';
import 'voice_review_sheet.dart';
import 'bazzer_price_dialog.dart';

class BazzerReminderPage extends StatefulWidget {
  const BazzerReminderPage({super.key, this.repository, this.voice});

  final BazzerRepository? repository;
  final VoiceService? voice;

  @override
  State<BazzerReminderPage> createState() => _BazzerReminderPageState();
}

class _BazzerReminderPageState extends State<BazzerReminderPage>
    with SingleTickerProviderStateMixin {
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
  late final _tabs = TabController(length: 2, vsync: this);
  final _priceEdits = <String, (int?, int)>{};
  int _priceRevision = 0;
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
    bool secure = false,
    String? authorUid,
  }) => _itemStreams.putIfAbsent(
    '$id/$secure/${authorUid ?? ''}',
    () => secure
        ? _repository.watchSecureItems(id, authorUid: authorUid)
        : _repository.watchItems(id),
  );

  @override
  void dispose() {
    unawaited(_voice.dispose());
    _nameController.dispose();
    _quantityController.dispose();
    _searchController.dispose();
    _tabs.dispose();
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
    _revealNewItems();
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
    final now = DateTime.now();
    _revealNewItems();
    _queueWrite(
      _repository.addItems(
        familyId,
        chosen
            .map(
              (item) => item.copyWith(
                isSecure: secure,
                createdAt: now,
                noteDate: bazzerDayKey(now),
              ),
            )
            .toList(),
        addedBy: addedBy,
      ),
    );
    _message('${chosen.length}টি আইটেম তালিকায় যোগ হয়েছে।');
  }

  void _revealNewItems() {
    _searchController.clear();
    setState(() {
      _search = '';
      _filterStore = null;
    });
    _tabs.animateTo(0);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('পরিবারের বাজার'),
        actions: [
          IconButton(
            tooltip: admin ? 'পরিবারের সদস্য ও কোড' : 'পরিবারের কোড ও তথ্য',
            onPressed: () => _openFamily(family, member),
            icon: const Icon(Icons.manage_accounts_rounded),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.shopping_cart_outlined), text: 'কেনা বাকি'),
            Tab(icon: Icon(Icons.task_alt_rounded), text: 'কেনা হয়েছে'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _voiceStarting
            ? null
            : () =>
                  _toggleVoice(family.id, secure: secure, addedBy: member.name),
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
                              : 'পরিবারের কোড দেখতে ও কপি করতে চাপুন',
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
                        title: const Text('নতুন আইটেম Secure তালিকায় যোগ করুন'),
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
                                isExpanded: true,
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
                          isExpanded: true,
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
          body: _itemsTabs(family.id, member: member),
        ),
      ),
    );
  }

  Widget _itemsTabs(String familyId, {required BazzerMember member}) =>
      StreamBuilder<List<BazzerItem>>(
        stream: _itemsStream(familyId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('তালিকা পড়া যায়নি। আবার চেষ্টা করুন।'),
            );
          }
          // Start both subscriptions together. Both tabs share the same
          // permitted documents, so the daily total survives bought/undo.
          return StreamBuilder<List<BazzerItem>>(
            key: ValueKey('${member.uid}/${member.isAdmin}'),
            stream: _itemsStream(
              familyId,
              secure: true,
              authorUid: member.isAdmin ? null : member.uid,
            ),
            builder: (context, secureSnapshot) {
              if (secureSnapshot.hasError) {
                return const Center(
                  child: Text(
                    'Secure তালিকা পড়া যায়নি। Admin-এর সঙ্গে যোগাযোগ করুন।',
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting ||
                  secureSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = [...?snapshot.data, ...?secureSnapshot.data].map((
                item,
              ) {
                final edit = _priceEdits[_priceKey(familyId, member, item)];
                return edit == null
                    ? item
                    : item.copyWith(
                        pricePaisa: edit.$1,
                        clearPrice: edit.$1 == null,
                        hasPendingWrites: true,
                      );
              }).toList();
              return TabBarView(
                controller: _tabs,
                children: [
                  for (final bought in [false, true])
                    BazzerDailyList(
                      items: items,
                      bought: bought,
                      currentUid: member.uid,
                      isAdmin: member.isAdmin,
                      search: _search,
                      filterStore: bought ? null : _filterStore,
                      filters: bought ? null : _storeFilters(),
                      onEdit: (item) => _editItem(familyId, item),
                      onDelete: (item) => _deleteItem(familyId, item),
                      onToggle: (item) => _queueWrite(
                        _repository.setBought(familyId, item, !item.isBought),
                      ),
                      onSetPrice: (item, price) =>
                          _setPrice(familyId, member, item, price),
                      onCustomPrice: (item) =>
                          _customPrice(familyId, member, item),
                    ),
                ],
              );
            },
          );
        },
      );

  String _priceKey(String familyId, BazzerMember member, BazzerItem item) =>
      '$familyId/${member.uid}/${item.isSecure}/${item.id}';

  void _setPrice(
    String familyId,
    BazzerMember member,
    BazzerItem item,
    int? price,
  ) {
    if (!member.isAdmin && item.createdBy != member.uid) return;
    final key = _priceKey(familyId, member, item);
    final previous = _priceEdits.containsKey(key)
        ? _priceEdits[key]!.$1
        : item.pricePaisa;
    if (previous == price) return;
    final revision = ++_priceRevision;
    setState(() => _priceEdits[key] = (price, revision));
    unawaited(
      _repository
          .setPrice(familyId, item, price)
          .then((_) {
            if (mounted && _priceEdits[key]?.$2 == revision) {
              setState(() => _priceEdits.remove(key));
            }
          })
          .catchError((Object error) {
            if (mounted && _priceEdits[key]?.$2 == revision) {
              setState(() => _priceEdits.remove(key));
              _message('দাম রাখা যায়নি। সংযোগ ও অনুমতি দেখে আবার চেষ্টা করুন।');
            }
          }),
    );
  }

  Future<void> _customPrice(
    String familyId,
    BazzerMember member,
    BazzerItem item,
  ) async {
    final result = await showDialog<BazzerPriceEdit>(
      context: context,
      builder: (_) => BazzerPriceDialog(item: item),
    );
    if (!mounted || result == null) return;
    _setPrice(familyId, member, item, result.paisa);
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
