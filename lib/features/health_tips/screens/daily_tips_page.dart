// lib/features/health_tips/screens/daily_tips_page.dart
import 'package:flutter/material.dart';

import '../../../data/repositories/health_repository.dart';

class DailyTipsPage extends StatefulWidget {
  const DailyTipsPage({super.key});

  @override
  State<DailyTipsPage> createState() => _DailyTipsPageState();
}

class _DailyTipsPageState extends State<DailyTipsPage> {
  final HealthRepository repo = HealthRepository();
  List<String> allTips = [];
  bool isLoading = true;

  // ✅ ফিক্সড লাইন (এখন কোনো ওয়ার্নিং আসবে না)
  final Set<String> completedTips = <String>{};

  @override
  void initState() {
    super.initState();
    _fetchTips();
  }

  Future<void> _fetchTips() async {
    final data = await repo.getDailyHealthTips();
    setState(() {
      allTips = data;
      isLoading = false;
    });
  }

  // বাকি টিপস (যেগুলো hide হয়নি)
  List<String> get remainingTips =>
      allTips.where((tip) => !completedTips.contains(tip)).toList();

  @override
  Widget build(BuildContext context) {
    final completedCount = completedTips.length;
    final total = allTips.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: AppBar(
        title: const Text(
          'দৈনন্দিন স্বাস্থ্য টিপস',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // প্রোগ্রেস হেডার
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.greenAccent,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "$completedCount/$total টিপস সম্পন্ন",
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (completedCount == total)
                          const Text(
                            "🎉 অসাধারণ!",
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (remainingTips.isEmpty)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            color: Colors.greenAccent,
                            size: 80,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "আজকের সব টিপস সম্পন্ন হয়েছে!",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "কাল আবার নতুন করে শুরু করুন 🌟",
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    )
                  else
                    ...remainingTips.map((tip) => _buildTipCard(tip)),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // ✅ নতুন কার্ড — সত্যিকারের Checkbox + সুন্দর ডিজাইন
  Widget _buildTipCard(String tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: false, // কারণ এই কার্ডটা শুধু বাকি টিপস দেখায়
            onChanged: (bool? value) {
              if (value == true) {
                setState(() {
                  completedTips.add(tip);
                });
              }
            },
            activeColor: Colors.greenAccent,
            checkColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
