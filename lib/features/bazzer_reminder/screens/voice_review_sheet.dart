import 'package:flutter/material.dart';

import '../models/bazzer_item_model.dart';
import '../utils/store_category.dart';
import '../utils/voice_parser.dart';

class VoiceReviewSheet extends StatefulWidget {
  const VoiceReviewSheet({
    super.key,
    required this.heard,
    required this.parsed,
  });

  final String heard;
  final VoiceParseResult parsed;

  @override
  State<VoiceReviewSheet> createState() => _VoiceReviewSheetState();
}

class _VoiceReviewSheetState extends State<VoiceReviewSheet> {
  late final List<BazzerItem> _items = [...widget.parsed.items];

  Future<void> _edit(int index) async {
    final item = _items[index];
    final name = TextEditingController(text: item.name);
    final quantity = TextEditingController(
      text: item.quantity % 1 == 0
          ? item.quantity.toInt().toString()
          : item.quantity.toString(),
    );
    String category = item.category;
    String unit = item.unit;
    final edited = await showDialog<BazzerItem>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('শোনা জিনিসটি ঠিক করুন'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  maxLength: 120,
                  decoration: const InputDecoration(labelText: 'জিনিসের নাম'),
                ),
                TextField(
                  controller: quantity,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'পরিমাণ'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: unit,
                  decoration: const InputDecoration(labelText: 'একক'),
                  items: [
                    for (final value in [
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
                    ])
                      DropdownMenuItem(value: value, child: Text(value)),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => unit = value ?? unit),
                ),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'দোকান'),
                  items: [
                    for (final value in StoreCategory.all)
                      DropdownMenuItem(value: value, child: Text(value)),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => category = value ?? category),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('বাতিল'),
            ),
            FilledButton(
              onPressed: () {
                final parsedQuantity = double.tryParse(
                  VoiceParser.normalizeNumbers(quantity.text.trim()),
                );
                if (name.text.trim().isEmpty ||
                    parsedQuantity == null ||
                    parsedQuantity <= 0 ||
                    parsedQuantity > 1000 ||
                    (unit == 'টা' && parsedQuantity % 1 != 0)) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('সঠিক নাম ও পরিমাণ দিন।')),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop(
                  BazzerItem(
                    id: item.id,
                    name: name.text.trim(),
                    quantity: parsedQuantity,
                    unit: unit,
                    category: category,
                    createdAt: item.createdAt,
                  ),
                );
              },
              child: const Text('ঠিক আছে'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    quantity.dispose();
    if (edited != null && mounted) setState(() => _items[index] = edited);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 14,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.77,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'বাংলা Voice • যোগ করার আগে যাচাই করুন',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'শুনেছে: ${widget.heard}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (var i = 0; i < _items.length; i++)
                      Card(
                        child: ListTile(
                          leading: Icon(
                            Icons.edit_outlined,
                            color: colors.primary,
                          ),
                          title: Text(_items[i].name),
                          subtitle: Text(
                            '${_items[i].quantity} ${_items[i].unit} • ${_items[i].category}',
                          ),
                          onTap: () => _edit(i),
                          trailing: IconButton(
                            tooltip: 'এই জিনিসটি বাদ দিন',
                            onPressed: () => setState(() => _items.removeAt(i)),
                            icon: const Icon(Icons.close),
                          ),
                        ),
                      ),
                    if (widget.parsed.needsReview.isNotEmpty)
                      Card(
                        color: colors.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'যা আলাদা করা যায়নি (যোগ হবে না): '
                            '${widget.parsed.needsReview.join(', ')}\n'
                            'এগুলো লিখে যোগ করুন বা আবার পরিষ্কার করে বলুন।',
                            style: TextStyle(color: colors.onErrorContainer),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('বাতিল'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _items.isEmpty
                          ? null
                          : () => Navigator.of(context).pop(_items),
                      child: Text('${_items.length}টি যোগ করুন'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
