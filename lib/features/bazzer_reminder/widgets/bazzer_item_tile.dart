import 'dart:math' as math;
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
    required this.onPriceSelected,
    required this.onAddFive,
    required this.onCustomPrice,
  });
  final BazzerItem item;
  final VoidCallback onToggle;
  final bool canMarkBought;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool canSetPrice;
  final ValueChanged<int> onPriceSelected;
  final VoidCallback onAddFive;
  final VoidCallback onCustomPrice;
  String get _key => '${item.isSecure}-${item.id}';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final quantity = item.quantity % 1 == 0
        ? item.quantity.toInt().toString()
        : item.quantity.toString();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
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
                        maxLines: 2,
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
                        '${banglaNumber(quantity)} ${item.unit} • ${item.addedBy}${item.isSecure ? ' • Secure' : ''}'
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
                Flexible(
                  child: TextButton(
                    key: ValueKey('custom-price-$_key'),
                    onPressed: canSetPrice ? onCustomPrice : null,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: const Size(36, 44),
                    ),
                    child: Text(
                      item.pricePaisa == null
                          ? 'দাম দিন'
                          : bazzerMoney(item.pricePaisa!),
                      key: ValueKey('item-price-$_key'),
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
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
            LayoutBuilder(
              builder: (context, constraints) {
                final scale = math.max(
                  1.0,
                  MediaQuery.textScalerOf(context).scale(12) / 12,
                );
                // Normal phones show every control; large text keeps one scrollable row.
                final width = math.max(constraints.maxWidth, 316 * scale);
                return SingleChildScrollView(
                  key: ValueKey('price-row-$_key'),
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: width,
                    child: Row(
                      children: [
                        for (final price in bazzerPricePresets)
                          Expanded(
                            child: _priceButton(
                              context,
                              key: 'price-$_key-$price',
                              label: banglaNumber(price),
                              selected: item.pricePaisa == price * 100,
                              onPressed: canSetPrice
                                  ? () => onPriceSelected(price * 100)
                                  : null,
                            ),
                          ),
                        SizedBox(
                          width: 38 * scale,
                          child: _priceButton(
                            context,
                            key: 'plus-five-$_key',
                            label: '+৫',
                            selected: false,
                            onPressed:
                                canSetPrice &&
                                    (item.pricePaisa ?? 0) <=
                                        bazzerMaxPricePaisa - 500
                                ? onAddFive
                                : null,
                          ),
                        ),
                        SizedBox(
                          width: 42 * scale,
                          child: _priceButton(
                            context,
                            key: 'reset-price-$_key',
                            label: 'Reset',
                            selected: false,
                            onPressed: canSetPrice
                                ? () => onPriceSelected(0)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceButton(
    BuildContext context, {
    required String key,
    required String label,
    required bool selected,
    required VoidCallback? onPressed,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: TextButton(
        key: ValueKey(key),
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: selected
              ? colors.primary
              : colors.surfaceContainerHighest,
          foregroundColor: selected ? colors.onPrimary : colors.onSurface,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
        child: Text(label),
      ),
    );
  }
}
