import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FortyDaysChallengeScreen extends StatefulWidget {
  const FortyDaysChallengeScreen({super.key});

  @override
  State<FortyDaysChallengeScreen> createState() =>
      _FortyDaysChallengeScreenState();
}

class _FortyDaysChallengeScreenState extends State<FortyDaysChallengeScreen> {
  int _daysLeft = 40;
  DateTime? _lastCompletionTime;
  bool _isLoading = true;

  final List<String> _tasks = [
    'হারাম থেকে বাঁচা',
    'ফরজ নামাজ পড়া',
    'রুকিয়াহ গোসল',
    'সকাল সন্ধ্যার দোয়া',
  ];
  List<bool> _taskCompleted = List.generate(4, (_) => false);

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _daysLeft = prefs.getInt('challenge_days_left') ?? 40;
      final lastMillis = prefs.getInt('challenge_last_completion');
      if (lastMillis != null) {
        _lastCompletionTime = DateTime.fromMillisecondsSinceEpoch(lastMillis);
      }
      _isLoading = false;
    });
    _checkForReset();
  }

  void _checkForReset() {
    if (_lastCompletionTime == null) {
      return;
    }
    final diffHours = DateTime.now().difference(_lastCompletionTime!).inHours;
    if (diffHours >= 24) {
      setState(() {
        _daysLeft = 40;
        _lastCompletionTime = null;
      });
      _saveProgress();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⛔ স্ট্রিক রিসেট হয়েছে!'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('challenge_days_left', _daysLeft);
    if (_lastCompletionTime != null) {
      await prefs.setInt(
        'challenge_last_completion',
        _lastCompletionTime!.millisecondsSinceEpoch,
      );
    }
  }

  bool get _allTasksCompleted => _taskCompleted.every((e) => e);
  bool get _canConfirmToday =>
      _lastCompletionTime == null ||
      DateTime.now().difference(_lastCompletionTime!).inHours >= 24;

  Future<void> _confirmCompletion() async {
    if (!_allTasksCompleted || !_canConfirmToday) {
      return;
    }
    setState(() {
      _daysLeft = (_daysLeft - 1).clamp(0, 40);
      _lastCompletionTime = DateTime.now();
      _taskCompleted = List.filled(4, false);
    });
    await _saveProgress();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 অসাধারণ! বাকি: $_daysLeft দিন'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F2027),
                  Color(0xFF203A43),
                  Color(0xFF2C5364),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.amberAccent),
                  )
                : Column(
                    children: [
                      _buildAppBar(),
                      const SizedBox(height: 20),
                      _buildDaysLeftCard(),
                      const SizedBox(height: 30),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _tasks.length,
                          itemBuilder: (context, index) {
                            return CheckboxListTile(
                              title: Text(
                                _tasks[index],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              value: _taskCompleted[index],
                              onChanged: (v) => setState(
                                () => _taskCompleted[index] = v ?? false,
                              ),
                              activeColor: Colors.amberAccent,
                              checkColor: Colors.black,
                            );
                          },
                        ),
                      ),
                      _buildConfirmButton(),
                      const SizedBox(height: 20),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              '40 Days Recovery Challenge',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildDaysLeftCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Text(
            '$_daysLeft',
            style: const TextStyle(
              color: Colors.amberAccent,
              fontSize: 60,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'দিন বাকি',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    final canConfirm = _allTasksCompleted && _canConfirmToday;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: canConfirm ? _confirmCompletion : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canConfirm ? Colors.green : Colors.white10,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          canConfirm
              ? '✅ আজকের চ্যালেঞ্জ Complete করুন'
              : 'সব টাস্ক সম্পন্ন করুন',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
