import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Protects only the app's home route; child routes handle their own back action.
class ExitGuard extends StatefulWidget {
  const ExitGuard({super.key, required this.child});
  final Widget child;

  @override
  State<ExitGuard> createState() => _ExitGuardState();
}

class _ExitGuardState extends State<ExitGuard> {
  bool _asking = false;

  Future<void> _confirm() async {
    if (_asking) return;
    _asking = true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('অ্যাপ থেকে বের হবেন?'),
        content: const Text('আপনার সেভ করা তথ্য থাকবে।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('থাকুন'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('বের হোন'),
          ),
        ],
      ),
    );
    _asking = false;
    if (leave == true && mounted) await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _confirm();
    },
    child: widget.child,
  );
}
