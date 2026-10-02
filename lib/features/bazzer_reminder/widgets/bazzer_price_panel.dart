import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/bazzer_item_model.dart';
import '../utils/bazzer_format.dart';

/// One price editor for the active shopping screen, outside both item lists.
class BazzerPricePanel extends StatelessWidget {
  const BazzerPricePanel({
    super.key,
    required this.item,
    required this.hasEditableItems,
    required this.voiceLabel,
    required this.listening,
    required this.onVoice,
    this.onPriceSelected,
    this.onAddFive,
    this.onCustomPrice,
    this.onClearSelection,
  });
  final BazzerItem? item;
  final bool hasEditableItems;
  final String voiceLabel;
  final bool listening;
  final VoidCallback? onVoice;
  final ValueChanged<int>? onPriceSelected;
  final VoidCallback? onAddFive;
  final VoidCallback? onCustomPrice;
  final VoidCallback? onClearSelection;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selected = item;
    final quantity = selected == null
        ? ''
        : banglaNumber(
            selected.quantity % 1 == 0
                ? selected.quantity.toInt()
                : selected.quantity,
          );
    return Material(
      key: const ValueKey('bazzer-price-panel'),
      elevation: 8,
      color: colors.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calculate_outlined,
                    size: 18,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'দাম নির্ধারণ',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onVoice,
                    icon: Icon(
                      listening ? Icons.stop_rounded : Icons.mic_rounded,
                      size: 20,
                    ),
                    label: Text(voiceLabel),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      child: Tooltip(
                        message: selected?.name ?? 'তালিকার আইটেম বেছে নিন',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selected?.name ?? 'আইটেম বেছে নিন',
                              key: const ValueKey('price-panel-selected'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              selected == null
                                  ? hasEditableItems
                                        ? 'তালিকার নাম বা দামে চাপুন'
                                        : 'দাম দেওয়ার জন্য নিজের আইটেম যোগ করুন'
                                  : '$quantity ${selected.unit} • ${bazzerDayLabel(selected.dayKey)}'
                                        '${selected.isSecure ? ' • Secure' : ''}',
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
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Tooltip(
                      message: 'নিজের মতো দাম লিখুন',
                      child: TextButton.icon(
                        key: const ValueKey('price-panel-custom'),
                        onPressed: selected == null ? null : onCustomPrice,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: Text(
                          selected == null
                              ? '—'
                              : selected.pricePaisa == null
                              ? 'দাম দিন'
                              : bazzerMoney(selected.pricePaisa!),
                          key: const ValueKey('price-panel-amount'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'নির্বাচন বাতিল',
                    onPressed: selected == null ? null : onClearSelection,
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LayoutBuilder(
                builder: (context, constraints) {
                  final scale = math.max(
                    1.0,
                    MediaQuery.textScalerOf(context).scale(12) / 12,
                  );
                  return SingleChildScrollView(
                    key: const ValueKey('price-controls'),
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: math.max(constraints.maxWidth, 316 * scale),
                      child: Row(
                        children: [
                          for (final price in bazzerPricePresets)
                            Expanded(
                              child: _button(
                                context,
                                key: 'price-preset-$price',
                                label: banglaNumber(price),
                                selected: selected?.pricePaisa == price * 100,
                                onPressed:
                                    selected == null || onPriceSelected == null
                                    ? null
                                    : () => onPriceSelected!(price * 100),
                              ),
                            ),
                          SizedBox(
                            width: 38 * scale,
                            child: _button(
                              context,
                              key: 'price-plus-five',
                              label: '+৫',
                              selected: false,
                              onPressed:
                                  selected == null ||
                                      (selected.pricePaisa ?? 0) >
                                          bazzerMaxPricePaisa - 500
                                  ? null
                                  : onAddFive,
                            ),
                          ),
                          SizedBox(
                            width: 42 * scale,
                            child: _button(
                              context,
                              key: 'price-reset',
                              label: 'Reset',
                              selected: false,
                              onPressed:
                                  selected == null || onPriceSelected == null
                                  ? null
                                  : () => onPriceSelected!(0),
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
      ),
    );
  }

  Widget _button(
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
          minimumSize: const Size(0, 44),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: selected
              ? colors.primary
              : colors.surfaceContainerHighest,
          foregroundColor: selected ? colors.onPrimary : colors.onSurface,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label),
      ),
    );
  }
}
