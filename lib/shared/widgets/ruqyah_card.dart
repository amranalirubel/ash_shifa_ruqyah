import 'package:flutter/material.dart';

class RuqyahCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpansionChanged;

  const RuqyahCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
  });

  @override
  State<RuqyahCard> createState() => _RuqyahCardState();
}

class _RuqyahCardState extends State<RuqyahCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF111111),
            Color.fromARGB(255, 19, 88, 88),
            Color(0xFF111111),
          ],
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(8, 8), blurRadius: 20),
          BoxShadow(
            color: Color(0x0DFFFFFF),
            offset: Offset(-6, -6),
            blurRadius: 18,
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _isExpanded,
          onExpansionChanged: (expanded) {
            setState(() => _isExpanded = expanded);
            widget.onExpansionChanged?.call(expanded);
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          leading: Icon(widget.icon, color: Colors.orangeAccent),
          title: Text(
            widget.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          children: widget.children,
        ),
      ),
    );
  }
}
