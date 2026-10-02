import 'package:flutter/material.dart';
import '../models/bazzer_expense.dart';
import '../models/bazzer_item_model.dart';
import '../utils/bazzer_receipt.dart';
import 'bazzer_item_tile.dart';

class BazzerDailyList extends StatelessWidget {
  const BazzerDailyList({
    super.key,
    required this.items,
    required this.bought,
    required this.currentUid,
    required this.isAdmin,
    required this.search,
    this.filterStore,
    this.filters,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
    required this.onSelectPrice,
    this.selectedPriceKey,
    this.onSave,
    this.savingDays = const {},
    this.savedSignatures = const {},
  });
  final List<BazzerItem> items;
  final bool bought;
  final String currentUid;
  final bool isAdmin;
  final String search;
  final String? filterStore;
  final Widget? filters;
  final ValueChanged<BazzerItem> onEdit;
  final ValueChanged<BazzerItem> onDelete;
  final ValueChanged<BazzerItem> onToggle;
  final ValueChanged<BazzerItem> onSelectPrice;
  final String? selectedPriceKey;
  final ValueChanged<BazzerDailyNote>? onSave;
  final Set<String> savingDays;
  final Map<String, String> savedSignatures;

  @override
  Widget build(BuildContext context) {
    final visible = <(BazzerDailyNote, BazzerDailyNote)>[];
    for (final note in BazzerDailyNote.group(items)) {
      final shown = note.items.where(
        (item) =>
            item.isBought == bought &&
            (filterStore == null || item.category == filterStore) &&
            item.name.toLowerCase().contains(search.toLowerCase()),
      );
      if (shown.isNotEmpty) {
        visible.add((note, BazzerDailyNote(note.day, shown)));
      }
    }
    return ListView(
      key: PageStorageKey('bazzer-daily-$bought'),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      children: [
        ?filters,
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                search.isNotEmpty || filterStore != null
                    ? 'এই খোঁজে কোনো আইটেম পাওয়া যায়নি।'
                    : bought
                    ? 'এখনো কেনা হয়েছে এমন জিনিস নেই।'
                    : 'দোকান অনুযায়ী বাজার যোগ করুন।',
              ),
            ),
          ),
        for (final pair in visible) _note(context, pair.$1, pair.$2),
      ],
    );
  }

  Widget _note(
    BuildContext context,
    BazzerDailyNote all,
    BazzerDailyNote shown,
  ) {
    final colors = Theme.of(context).colorScheme;
    final pending = all.items.any((item) => item.hasPendingWrites);
    final ready = all.unpricedCount == 0 && !pending;
    final saved =
        ready &&
        savedSignatures[all.day] == BazzerExpenseDraft.fromNote(all).signature;
    final saving = savingDays.contains(all.day);
    return Padding(
      key: ValueKey('note-${shown.day}-$bought'),
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${bazzerDayLabel(shown.day)} • ${banglaNumber(shown.items.length)}টি',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colors.onPrimaryContainer,
              ),
            ),
          ),
          for (var i = 0; i < shown.items.length; i++) ...[
            if (i == 0 ||
                shown.items[i].category != shown.items[i - 1].category)
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 2, left: 4),
                child: Text(
                  '${shown.items[i].category} দোকান',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            _tile(context, shown.items[i]),
          ],
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('সর্বমোট', style: TextStyle(fontSize: 12)),
                          Text(
                            bazzerMoney(all.totalPaisa),
                            key: ValueKey('total-${all.day}-$bought'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      key: ValueKey('save-${all.day}-$bought'),
                      onPressed:
                          isAdmin &&
                              ready &&
                              !saving &&
                              !saved &&
                              onSave != null
                          ? () => onSave!(all)
                          : null,
                      icon: Icon(
                        saved ? Icons.check : Icons.save_outlined,
                        size: 18,
                      ),
                      label: Text(
                        saving
                            ? 'সেভ হচ্ছে…'
                            : saved
                            ? 'Saved'
                            : 'Save',
                      ),
                    ),
                  ],
                ),
                if (all.items.length != shown.items.length)
                  const Text(
                    'এই দিনের সব দোকান • কেনা ও বাকি মিলিয়ে',
                    style: TextStyle(fontSize: 11),
                  ),
                if (all.unpricedCount > 0)
                  Text(
                    'Save করতে ${banglaNumber(all.unpricedCount)}টি আইটেমের দাম দিন।',
                    style: const TextStyle(fontSize: 11),
                  )
                else if (pending)
                  const Text(
                    'দাম পাঠানো হচ্ছে। সংযোগ ফিরলে Save করুন।',
                    style: TextStyle(fontSize: 11),
                  )
                else if (saving)
                  const Text(
                    'সেভ নিশ্চিত করতে ইন্টারনেট সংযোগ রাখুন।',
                    style: TextStyle(fontSize: 11),
                  )
                else if (!isAdmin)
                  const Text(
                    'পরিবারের Admin চূড়ান্ত হিসাব Save করবেন।',
                    style: TextStyle(fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, BazzerItem item) => Dismissible(
    key: ValueKey('${item.isSecure}/${item.id}'),
    direction: isAdmin ? DismissDirection.endToStart : DismissDirection.none,
    background: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 22),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Icon(bought ? Icons.undo_rounded : Icons.done_all_rounded),
    ),
    confirmDismiss: (_) async {
      if (isAdmin) onToggle(item);
      return false;
    },
    child: BazzerItemTile(
      item: item,
      canMarkBought: isAdmin,
      canEdit: item.createdBy == currentUid,
      canSetPrice: isAdmin || item.createdBy == currentUid,
      onEdit: () => onEdit(item),
      onDelete: () => onDelete(item),
      onToggle: () => onToggle(item),
      onSelect: () => onSelectPrice(item),
      selected: selectedPriceKey == '${item.isSecure}/${item.id}',
    ),
  );
}
