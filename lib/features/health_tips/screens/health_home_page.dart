// lib/features/health_tips/screens/health_home_page.dart
import 'package:flutter/material.dart';

import 'bmi_calculator_screen.dart';
import 'daily_tips_page.dart';
import 'disease_selection_page.dart';
import 'exercise_page.dart';

class HealthHomePage extends StatelessWidget {
  const HealthHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: AppBar(
        title: const Text(
          'স্বাস্থ্য টিপস',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            _buildNeoCard(
              context,
              'আমার জন্য খাদ্য তালিকা',
              Icons.restaurant,
              Colors.greenAccent,
              const DiseaseSelectionPage(),
            ),
            const SizedBox(height: 16),
            _buildNeoCard(
              context,
              'BMI ক্যালকুলেটর + পরামর্শ',
              Icons.monitor_weight,
              Colors.orangeAccent,
              const BmiCalculatorScreen(),
            ),
            const SizedBox(height: 16),
            _buildNeoCard(
              context,
              'ব্যায়াম / মেডিটেশন',
              Icons.fitness_center,
              Colors.blueAccent,
              const ExercisePage(),
            ),
            const SizedBox(height: 16),
            _buildNeoCard(
              context,
              'দৈনন্দিন স্বাস্থ্য টিপস',
              Icons.lightbulb,
              Colors.purpleAccent,
              const DailyTipsPage(),
            ),
          ],
        ),
      ),
    );
  }

  // ================== New Version Neo Card Style ==================
  Widget _buildNeoCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Widget page,
  ) {
    return GestureDetector(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.18), Colors.transparent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              offset: Offset(8, 8),
              blurRadius: 20,
            ),
            BoxShadow(
              color: Color(0x0DFFFFFF),
              offset: Offset(-6, -6),
              blurRadius: 18,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color.withValues(alpha: 0.8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
