import 'package:flutter/material.dart';

import '../utils/easy_home_format.dart';

class EasyCard extends StatelessWidget {
  const EasyCard({super.key, required this.child, this.color});
  final Widget child;
  final Color? color;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    color: color,
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );
}

class EasyEmpty extends StatelessWidget {
  const EasyEmpty(
    this.title,
    this.message, {
    super.key,
    this.icon = Icons.home_work_outlined,
  });
  final String title, message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
    child: Column(
      children: [
        Icon(icon, size: 44, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 14),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
}

class EasyField {
  const EasyField(
    this.keyName,
    this.label, {
    this.initial = '',
    this.options,
    this.multiline = false,
    this.optional = false,
    this.date = false,
    this.keyboard,
    this.maxLength = 80,
  });
  final String keyName, label, initial;
  final Map<String, String>? options;
  final bool multiline, optional, date;
  final TextInputType? keyboard;
  final int maxLength;
}

Future<bool> showEasyForm(
  BuildContext context, {
  required String title,
  required List<EasyField> fields,
  required Future<void> Function(Map<String, String>) save,
  String? description,
  String submit = 'সেভ করুন',
}) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EasyForm(
        title: title,
        fields: fields,
        save: save,
        description: description,
        submit: submit,
      ),
    ) ??
    false;

class _EasyForm extends StatefulWidget {
  const _EasyForm({
    required this.title,
    required this.fields,
    required this.save,
    required this.submit,
    this.description,
  });
  final String title, submit;
  final String? description;
  final List<EasyField> fields;
  final Future<void> Function(Map<String, String>) save;
  @override
  State<_EasyForm> createState() => _EasyFormState();
}

class _EasyFormState extends State<_EasyForm> {
  final _form = GlobalKey<FormState>();
  late final _text = {
    for (final f in widget.fields)
      f.keyName: TextEditingController(text: f.initial),
  };
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.save({
        for (final e in _text.entries) e.key: e.value.text.trim(),
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = easyHomeError(e);
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      title: Text(widget.title),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.description != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(widget.description!),
                  ),
                for (final field in widget.fields)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _field(field),
                  ),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('বাতিল'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(_busy ? 'সেভ হচ্ছে…' : widget.submit),
        ),
      ],
    ),
  );
  Widget _field(EasyField field) {
    final controller = _text[field.keyName]!;
    if (field.options != null) {
      return DropdownButtonFormField<String>(
        key: ValueKey(field.keyName),
        isExpanded: true,
        initialValue: field.options!.containsKey(controller.text)
            ? controller.text
            : null,
        decoration: InputDecoration(
          labelText: field.label,
          border: const OutlineInputBorder(),
        ),
        items: field.options!.entries
            .map(
              (e) => DropdownMenuItem(
                value: e.key,
                child: Text(
                  e.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: _busy ? null : (v) => controller.text = v ?? '',
        validator: (v) => !field.optional && (v == null || v.isEmpty)
            ? 'নির্বাচন করুন'
            : null,
      );
    }
    return TextFormField(
      key: ValueKey(field.keyName),
      controller: controller,
      enabled: !_busy,
      readOnly: field.date,
      maxLines: field.multiline ? 4 : 1,
      maxLength: field.maxLength,
      keyboardType: field.keyboard,
      decoration: InputDecoration(
        labelText: field.label,
        border: const OutlineInputBorder(),
        counterText: '',
        suffixIcon: field.date ? const Icon(Icons.calendar_today) : null,
      ),
      validator: (v) => !field.optional && (v == null || v.trim().isEmpty)
          ? 'এই তথ্যটি দিন'
          : null,
      onTap: !field.date
          ? null
          : () async {
              final now = DateTime.now();
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.tryParse(controller.text) ?? now,
                firstDate: DateTime(2000),
                lastDate: now,
              );
              if (date != null && mounted) {
                controller.text =
                    '${monthKey(date)}-${date.day.toString().padLeft(2, '0')}';
              }
            },
    );
  }
}

Future<void> easyConfirm(
  BuildContext context,
  String title,
  String description,
  Future<void> Function() action,
) async {
  await showEasyForm(
    context,
    title: title,
    fields: const [],
    description: description,
    submit: 'নিশ্চিত করুন',
    save: (_) => action(),
  );
}

class EasySectionTitle extends StatelessWidget {
  const EasySectionTitle(this.title, {super.key, this.action});
  final String title;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        ?action,
      ],
    ),
  );
}
