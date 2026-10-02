import 'package:flutter/material.dart';
import '../models/bazzer_item_model.dart';
import '../utils/bazzer_format.dart';

class BazzerItemTile extends StatelessWidget {
  const BazzerItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.canMarkBought,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
    required this.canSetPrice,
    required this.onSelect,
    required this.selected,
  });
  final BazzerItem item;
  final VoidCallback onToggle;
  final bool canMarkBought;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool canSetPrice;
  final VoidCallback onSelect;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final quantity = item.quantity % 1 == 0
        ? item.quantity.toInt().toString()
        : item.quantity.toString();
    return Semantics(
      selected: selected,
      child: Material(
        color: selected ? colors.primaryContainer : colors.surface,
        child: InkWell(
          key: ValueKey('select-price-${item.isSecure}-${item.id}'),
          onTap: canSetPrice ? onSelect : null,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  width: 3,
                  color: selected ? colors.primary : Colors.transparent,
                ),
                bottom: BorderSide(color: colors.outlineVariant),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Checkbox(
                    value: item.isBought,
                    onChanged: canMarkBought ? (_) => onToggle() : null,
                    semanticLabel: item.isBought
                        ? 'আবার তালিকায় রাখুন'
                        : 'কেনা হয়েছে',
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          decoration: item.isBought
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      Text(
                        '${banglaNumber(quantity)} ${item.unit} • ${item.addedBy}'
                        '${item.isSecure ? ' • Secure' : ''}'
                        '${item.hasPendingWrites ? ' • পাঠানোর অপেক্ষায়' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    child: Text(
                      item.pricePaisa == null
                          ? canSetPrice
                                ? 'দাম দিন'
                                : '—'
                          : bazzerMoney(item.pricePaisa!),
                      key: ValueKey('item-price-${item.isSecure}-${item.id}'),
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: canSetPrice ? colors.primary : colors.onSurface,
                      ),
                    ),
                  ),
                ),
                if (canEdit)
                  SizedBox(
                    width: 32,
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      tooltip: 'নিজের আইটেম পরিবর্তন বা মুছুন',
                      onSelected: (action) {
                        if (action == 'edit') onEdit();
                        if (action == 'delete') onDelete();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('পরিবর্তন করুন'),
                        ),
                        PopupMenuItem(value: 'delete', child: Text('মুছে দিন')),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
