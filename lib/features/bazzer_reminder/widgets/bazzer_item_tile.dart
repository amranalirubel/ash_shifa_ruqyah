import 'package:flutter/material.dart';

import '../models/bazzer_item_model.dart';

class BazzerItemTile extends StatelessWidget {
  const BazzerItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.canMarkBought,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

  final BazzerItem item;
  final VoidCallback onToggle;
  final bool canMarkBought;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final quantity = item.quantity % 1 == 0
        ? item.quantity.toInt().toString()
        : item.quantity.toString();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      color: colors.surface,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        leading: Checkbox(
          value: item.isBought,
          onChanged: canMarkBought ? (_) => onToggle() : null,
          semanticLabel: item.isBought ? 'আবার তালিকায় রাখুন' : 'কেনা হয়েছে',
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
          '$quantity ${item.unit} • ${item.category} • ${item.addedBy}'
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
                  PopupMenuItem(value: 'edit', child: Text('পরিবর্তন করুন')),
                  PopupMenuItem(value: 'delete', child: Text('মুছে দিন')),
                ],
              )
            : null,
      ),
    );
  }
}
