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
    final edited = await showDialog<BazzerItem>(
      context: context,
      builder: (_) => _VoiceEditDialog(item: item),
    );
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

/// The dialog owns its controllers until its route is removed. Disposing them
/// as soon as Navigator.pop resolves can crash during the exit animation.
class _VoiceEditDialog extends StatefulWidget {
  const _VoiceEditDialog({required this.item});

  final BazzerItem item;

  @override
  State<_VoiceEditDialog> createState() => _VoiceEditDialogState();
}

class _VoiceEditDialogState extends State<_VoiceEditDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.item.name,
  );
  late final TextEditingController _quantity = TextEditingController(
    text: widget.item.quantity % 1 == 0
        ? widget.item.quantity.toInt().toString()
        : widget.item.quantity.toString(),
  );
  late String _category = widget.item.category;
  late String _unit = widget.item.unit;

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    super.dispose();
  }

  void _confirm() {
    final parsedQuantity = double.tryParse(
      VoiceParser.normalizeNumbers(_quantity.text.trim()),
    );
    if (_name.text.trim().isEmpty ||
        _name.text.trim().length > 120 ||
        parsedQuantity == null ||
        parsedQuantity <= 0 ||
        parsedQuantity > 1000 ||
        (_unit == 'টা' && parsedQuantity % 1 != 0)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('সঠিক নাম ও পরিমাণ দিন।')));
      return;
    }
    Navigator.of(context).pop(
      BazzerItem(
        id: widget.item.id,
        name: _name.text.trim(),
        quantity: parsedQuantity,
        unit: _unit,
        category: _category,
        createdAt: widget.item.createdAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('শোনা জিনিসটি ঠিক করুন'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            maxLength: 120,
            decoration: const InputDecoration(labelText: 'জিনিসের নাম'),
          ),
          TextField(
            controller: _quantity,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'পরিমাণ'),
          ),
          DropdownButtonFormField<String>(
            initialValue: _unit,
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
            onChanged: (value) => setState(() => _unit = value ?? _unit),
          ),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'দোকান'),
            items: [
              for (final value in StoreCategory.all)
                DropdownMenuItem(value: value, child: Text(value)),
            ],
            onChanged: (value) =>
                setState(() => _category = value ?? _category),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('বাতিল'),
      ),
      FilledButton(onPressed: _confirm, child: const Text('ঠিক আছে')),
    ],
  );
}
