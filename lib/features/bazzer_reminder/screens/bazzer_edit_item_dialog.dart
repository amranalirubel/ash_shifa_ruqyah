import 'package:flutter/material.dart';

import '../models/bazzer_item_model.dart';
import '../utils/store_category.dart';

class BazzerItemEdit {
  const BazzerItemEdit({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
  });

  final String name;
  final double quantity;
  final String unit;
  final String category;
}

class BazzerEditItemDialog extends StatefulWidget {
  const BazzerEditItemDialog({super.key, required this.item});

  final BazzerItem item;

  @override
  State<BazzerEditItemDialog> createState() => _BazzerEditItemDialogState();
}

class _BazzerEditItemDialogState extends State<BazzerEditItemDialog> {
  late final TextEditingController _name;
  late final TextEditingController _quantity;
  late String _unit;
  late String _category;
  String? _error;

  static const units = [
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
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.item.name);
    _quantity = TextEditingController(text: widget.item.quantity.toString());
    _unit = widget.item.unit;
    _category = widget.item.category;
  }

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    final number = _quantity.text.trim().replaceAllMapped(
      RegExp(r'[০-৯]'),
      (match) => '০১২৩৪৫৬৭৮৯'.indexOf(match[0]!).toString(),
    );
    final quantity = double.tryParse(number);
    if (name.isEmpty ||
        name.length > 120 ||
        quantity == null ||
        quantity <= 0 ||
        quantity > 1000 ||
        (_unit == 'টা' && quantity % 1 != 0)) {
      setState(() => _error = 'সঠিক নাম ও ০ থেকে ১০০০-এর মধ্যে পরিমাণ লিখুন।');
      return;
    }
    Navigator.of(context).pop(
      BazzerItemEdit(
        name: name,
        quantity: quantity,
        unit: _unit,
        category: _category,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('নিজের জিনিস পরিবর্তন করুন'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'জিনিসের নাম'),
          ),
          TextField(
            controller: _quantity,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'পরিমাণ'),
          ),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _unit,
            decoration: const InputDecoration(labelText: 'একক'),
            items: [
              for (final unit in units)
                DropdownMenuItem(value: unit, child: Text(unit)),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _unit = value);
            },
          ),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'দোকান'),
            items: [
              for (final category in StoreCategory.all)
                DropdownMenuItem(value: category, child: Text(category)),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _category = value);
            },
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('বাতিল'),
      ),
      FilledButton(onPressed: _save, child: const Text('সংরক্ষণ করুন')),
    ],
  );
}
