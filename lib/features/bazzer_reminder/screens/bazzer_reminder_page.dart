import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../services/voice_service.dart';
import '../utils/voice_parser.dart';
import '../widgets/bazzer_item_tile.dart';
import '../models/bazzer_item_model.dart';
import '../repositories/bazzer_repository.dart';

class BazzerReminderPage extends StatefulWidget {
  const BazzerReminderPage({super.key});

  @override
  State<BazzerReminderPage> createState() => _BazzerReminderPageState();
}

class _BazzerReminderPageState extends State<BazzerReminderPage> {
  final repo = BazzerRepository();
  final voiceService = VoiceService();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _qtyCtrl = TextEditingController();

  bool _isListening = false;
  String _lastVoiceText = '';
  String _searchQuery = '';

  @override
  void dispose() {
    voiceService.dispose();
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleVoice() async {
    if (_isListening) {
      await voiceService.stopListening();
      setState(() => _isListening = false);
    } else {
      await voiceService.startListening(
        onFinalText: (text) {
          final items = VoiceParser.parseVoice(text);
          if (items.isNotEmpty) {
            repo.addItems(items);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${items.length}টি আইটেম যোগ হয়েছে ✅')),
            );
          }
          setState(() {
            _lastVoiceText = VoiceParser.fixBanglaText(text);
          });
        },
        onListeningChanged: (listening) =>
            setState(() => _isListening = listening),
        onError: (msg) =>
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(msg))),
      );
    }
  }

  void _addManualItem() {
    if (_nameCtrl.text.isEmpty) return;

    final qty = double.tryParse(_qtyCtrl.text) ?? 1.0;

    repo.addItem(
      BazzerItem(
        id: const Uuid().v4(), // ← সরাসরি ব্যবহার করা হয়েছে (no local variable)
        name: _nameCtrl.text.trim(),
        quantity: qty,
        unit: 'টা',
        category: 'নিত্যপণ্য',
        createdAt: DateTime.now(),
        addedBy: 'ম্যানুয়াল',
      ),
    );

    _nameCtrl.clear();
    _qtyCtrl.clear();
    setState(() {});
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('✅ আইটেম যোগ হয়েছে')));
  }

  @override
  Widget build(BuildContext context) {
    final items = repo
        .getItems()
        .where(
          (item) =>
              item.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: AppBar(
        title: const Text(
          'বাজার রিমাইন্ডার',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'কেনা আইটেম মুছুন',
            onPressed: () {
              repo.clearBoughtItems();
              setState(() {});
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleVoice,
        icon: Icon(_isListening ? Icons.mic_off : Icons.mic, size: 28),
        label: Text(_isListening ? 'শুনছি...' : 'ভয়েস দিয়ে যোগ করুন'),
        backgroundColor: _isListening ? Colors.redAccent : Colors.amberAccent,
      ),
      body: Column(
        children: [
          // Family note
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.amber.withValues(alpha: 0.1),
            child: const Text(
              '👨‍👩‍👧 পরিবারের সবাই বাংলায় বলুন → সবাই দেখবে',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.amberAccent, fontSize: 13),
            ),
          ),

          // --- আপডেট করা ভয়েস রেজাল্ট সেকশন ---
          if (_lastVoiceText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amberAccent, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🎤 শুনেছে:',
                      style: TextStyle(color: Colors.amberAccent, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _lastVoiceText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Search + Manual Add
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'আইটেম খুঁজুন...',
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          hintText: 'আইটেমের নাম',
                          filled: true,
                          fillColor: Colors.white10,
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'পরিমাণ',
                          filled: true,
                          fillColor: Colors.white10,
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle,
                        color: Colors.amberAccent,
                        size: 32,
                      ),
                      onPressed: _addManualItem,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Colors.white10),

          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      "🎤 ভয়েস বাটন চাপুন\nঅথবা উপরে ম্যানুয়ালি যোগ করুন",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: items.length,
                    padding: const EdgeInsets.only(
                      bottom: 80,
                    ), // FAB এর জন্য নিচে জায়গা
                    itemBuilder: (_, i) {
                      final item = items[i];
                      return BazzerItemTile(
                        item: item,
                        onToggle: () {
                          repo.toggleItem(item.id);
                          setState(() {});
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
