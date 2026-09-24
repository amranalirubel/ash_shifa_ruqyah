import 'package:flutter/material.dart';

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
    required this.onSetPrice,
    required this.onCustomPrice,
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
  final void Function(BazzerItem, int) onSetPrice;
  final ValueChanged<BazzerItem> onCustomPrice;

  @override
  Widget build(BuildContext context) {
    final allNotes = BazzerDailyNote.group(items);
    final visible = <(BazzerDailyNote, BazzerDailyNote)>[];
    for (final note in allNotes) {
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
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 110),
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
    final totals = shown.runningTotals;
    final isWholeDay = all.items.length == shown.items.length;
    return Padding(
      key: ValueKey('note-${shown.day}-$bought'),
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_note_outlined,
                  color: colors.onPrimaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bazzerDayLabel(shown.day),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        '${shown.day == bazzerDayKey(DateTime.now()) ? 'আজ • ' : ''}'
                        '${banglaNumber(shown.items.length)}টি আইটেম'
                        '${shown.unpricedCount > 0 ? ' • দাম বাকি ${banglaNumber(shown.unpricedCount)}টি' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < shown.items.length; i++) ...[
            if (i == 0 ||
                shown.items[i].category != shown.items[i - 1].category)
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4, left: 4),
                child: Text(
                  '${shown.items[i].category} দোকান',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            _tile(context, shown.items[i], totals[i]),
          ],
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    Text(isWholeDay ? 'দিনের মোট' : 'দেখানো আইটেমের মোট'),
                    Text(
                      bazzerMoney(shown.totalPaisa),
                      key: ValueKey('total-${shown.day}-$bought'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
                if (shown.unpricedCount > 0)
                  Text(
                    '${banglaNumber(shown.unpricedCount)}টি আইটেমের দাম এখনো দেওয়া হয়নি।',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                if (!isWholeDay) ...[
                  const Divider(),
                  Text(
                    'দিনের সব বাজার: ${bazzerMoney(all.totalPaisa)} • '
                    '${banglaNumber(all.items.length)}টি আইটেম'
                    '${all.unpricedCount > 0 ? ' • দাম বাকি ${banglaNumber(all.unpricedCount)}টি' : ''}',
                    key: ValueKey('day-total-${shown.day}-$bought'),
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'কেনা ও বাকি, সব দোকান মিলিয়ে',
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, BazzerItem item, int runningTotal) =>
      Dismissible(
        key: ValueKey('${item.isSecure}/${item.id}'),
        direction: isAdmin
            ? DismissDirection.endToStart
            : DismissDirection.none,
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
          runningTotalPaisa: runningTotal,
          canMarkBought: isAdmin,
          canEdit: item.createdBy == currentUid,
          canSetPrice: isAdmin || item.createdBy == currentUid,
          onEdit: () => onEdit(item),
          onDelete: () => onDelete(item),
          onToggle: () => onToggle(item),
          onPriceSelected: (price) => onSetPrice(item, price),
          onCustomPrice: () => onCustomPrice(item),
        ),
      );
}
