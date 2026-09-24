import 'package:flutter/material.dart';

import '../models/bazzer_item_model.dart';
import '../utils/bazzer_format.dart';

class BazzerPriceEdit {
  const BazzerPriceEdit(this.paisa);
  final int? paisa;
}

class BazzerPriceDialog extends StatefulWidget {
  const BazzerPriceDialog({super.key, required this.item});
  final BazzerItem item;

  @override
  State<BazzerPriceDialog> createState() => _BazzerPriceDialogState();
}

class _BazzerPriceDialogState extends State<BazzerPriceDialog> {
  late final _controller = TextEditingController(
    text: widget.item.pricePaisa == null
        ? ''
        : bazzerMoney(widget.item.pricePaisa!).replaceFirst('৳ ', ''),
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final price = parseBazzerPrice(_controller.text);
    if (price == null) {
      setState(() => _error = '০–১০,০০,০০০ টাকা লিখুন; সর্বোচ্চ দুই ঘর পয়সা।');
      return;
    }
    Navigator.of(context).pop(BazzerPriceEdit(price));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('${widget.item.name} — দাম'),
    content: SingleChildScrollView(
      child: TextField(
        key: const ValueKey('bazzer-custom-price'),
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
        decoration: InputDecoration(
          labelText: 'এই আইটেমের মোট দাম (টাকা)',
          helperText: 'যতটুকু কিনবেন তার পুরো দাম লিখুন।',
          errorText: _error,
          errorMaxLines: 3,
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('বাতিল'),
      ),
      if (widget.item.pricePaisa != null)
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(const BazzerPriceEdit(null)),
          child: const Text('দাম মুছুন'),
        ),
      FilledButton(onPressed: _save, child: const Text('দাম রাখুন')),
    ],
  );
}
