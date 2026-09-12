// lib/features/health_tips/screens/diet_detail_screen.dart
import 'package:flutter/material.dart';

class DietDetailScreen extends StatelessWidget {
  final String diseaseName;
  final Map<String, dynamic> data;

  const DietDetailScreen({
    super.key,
    required this.diseaseName,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: AppBar(title: Text(diseaseName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _section(
              '✅ খাবেন',
              data['eat'] as List<dynamic>,
              Colors.greenAccent,
            ),
            const SizedBox(height: 20),
            _section(
              '❌ এড়িয়ে চলবেন',
              data['avoid'] as List<dynamic>,
              Colors.redAccent,
            ),
            const SizedBox(height: 30),

            if (data['extra'] != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  data['extra'] as String,
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),

            const SizedBox(height: 40),
            const Text(
              'এটি শুধু সচেতনতার জন্য • ডাক্তারের পরামর্শ নিন',
              style: TextStyle(color: Colors.white60, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<dynamic> items, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          ...items.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Text(
                "• $e",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
