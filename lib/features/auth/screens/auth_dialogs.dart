import 'package:flutter/material.dart';

Future<bool> showLogoutConfirmation(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (_) => const _LogoutConfirmationDialog(),
  );
  return result ?? false;
}

Future<String?> showEditNameDialog(
  BuildContext context, {
  required String initialName,
}) {
  return showDialog<String>(
    context: context,
    useRootNavigator: true,
    builder: (_) => _EditNameDialog(initialName: initialName),
  );
}

class _LogoutConfirmationDialog extends StatelessWidget {
  const _LogoutConfirmationDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Logout করবেন?'),
      content: const Text('এই ডিভাইসে আপনার বর্তমান session বন্ধ হবে।'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop(false);
          },
          child: const Text('বাতিল'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop(true);
          },
          child: const Text('Logout'),
        ),
      ],
    );
  }
}

class _EditNameDialog extends StatefulWidget {
  const _EditNameDialog({required this.initialName});

  final String initialName;

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context, rootNavigator: true).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('নাম পরিবর্তন'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          maxLength: 120,
          decoration: const InputDecoration(
            labelText: 'পূর্ণ নাম',
            hintText: 'আপনার নাম লিখুন',
          ),
          validator: (value) {
            final name = value?.trim() ?? '';
            if (name.length < 2) {
              return 'নাম কমপক্ষে ২ অক্ষরের হতে হবে।';
            }
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
          },
          child: const Text('বাতিল'),
        ),
        FilledButton(onPressed: _submit, child: const Text('সংরক্ষণ')),
      ],
    );
  }
}
