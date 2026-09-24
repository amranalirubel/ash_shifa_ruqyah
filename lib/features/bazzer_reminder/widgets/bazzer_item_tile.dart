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
    required this.runningTotalPaisa,
    required this.canSetPrice,
    required this.onPriceSelected,
    required this.onCustomPrice,
  });

  final BazzerItem item;
  final VoidCallback onToggle;
  final bool canMarkBought;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final int runningTotalPaisa;
  final bool canSetPrice;
  final ValueChanged<int> onPriceSelected;
  final VoidCallback onCustomPrice;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final quantity = item.quantity % 1 == 0
        ? item.quantity.toInt().toString()
        : item.quantity.toString();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      color: colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 3,
            ),
            leading: Checkbox(
              value: item.isBought,
              onChanged: canMarkBought ? (_) => onToggle() : null,
              semanticLabel: item.isBought
                  ? 'আবার তালিকায় রাখুন'
                  : 'কেনা হয়েছে',
            ),
            title: Text(
              item.name,
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
                decoration: item.isBought ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
              '${banglaNumber(quantity)} ${item.unit} • ${item.addedBy}'
              '${item.isSecure ? ' • Secure' : ''}'
              '${item.hasPendingWrites ? ' • পাঠানোর অপেক্ষায়' : ''}',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
            trailing: canEdit
                ? PopupMenuButton<String>(
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
                  )
                : null,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.pricePaisa == null
                            ? 'দাম দিন (পুরো পরিমাণের)'
                            : 'এই আইটেম: ${bazzerMoney(item.pricePaisa!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      Wrap(
                        spacing: 4,
                        children: [
                          for (final price in bazzerPricePresets)
                            ChoiceChip(
                              key: ValueKey(
                                'price-${item.isSecure}-${item.id}-$price',
                              ),
                              label: Text(banglaNumber(price)),
                              labelStyle: const TextStyle(fontSize: 12),
                              labelPadding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              showCheckmark: false,
                              selected: item.pricePaisa == price * 100,
                              onSelected: canSetPrice
                                  ? (_) => onPriceSelected(price * 100)
                                  : null,
                            ),
                          TextButton(
                            onPressed: canSetPrice ? onCustomPrice : null,
                            child: const Text('অন্য দাম'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 88,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'এ পর্যন্ত',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          bazzerMoney(runningTotalPaisa),
                          key: ValueKey('running-${item.isSecure}-${item.id}'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
