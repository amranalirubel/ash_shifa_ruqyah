import 'package:flutter/material.dart';

import '../models/bazzer_item_model.dart';

class BazzerItemTile extends StatelessWidget {
  final BazzerItem item;
  final VoidCallback onToggle;

  const BazzerItemTile({super.key, required this.item, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white10,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onToggle,
        leading: Checkbox(
          value: item.isBought,
          onChanged: (_) => onToggle(),
          activeColor: Colors.amberAccent,
          checkColor: Colors.black,
        ),
        title: Text(
          item.name,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            decoration: item.isBought ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item.quantity} ${item.unit} • ${item.category}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            // 🔥 AddedBy দেখানো হচ্ছে
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 14,
                  color: Colors.amberAccent,
                ),
                const SizedBox(width: 4),
                Text(
                  item.addedBy,
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: Colors.white24,
        ),
      ),
    );
  }
}
