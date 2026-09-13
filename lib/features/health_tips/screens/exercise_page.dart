// lib/features/health_tips/screens/exercise_page.dart
import 'package:flutter/material.dart';

import '../../../data/repositories/health_repository.dart';

class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  final HealthRepository repo = HealthRepository();
  List<Map<String, dynamic>> exercises = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    try {
      final data = await repo.getExercises();
      setState(() {
        exercises = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      // Handle error professionaly
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115), // Deep Modern Dark
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'ব্যায়াম ও মানসিক স্বাস্থ্য',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final ex = exercises[index];
                return _buildExerciseCard(ex);
              },
            ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> ex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1E2025), const Color(0xFF14161B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Icon Container with Value handling
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getIconData(ex['name'] ?? ''),
                color: Colors.cyanAccent,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),

            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ex['name'] ?? 'Unknown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ex['time'] ?? '--',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.flash_on,
                        size: 14,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ex['benefit']?.split(' ')[0] ??
                            'Health', // First word as tag
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Action Button
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white24,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Simple logic to set dynamic icons based on name
  IconData _getIconData(String name) {
    if (name.contains('মেডিটেশন') || name.contains('Meditation')) {
      return Icons.self_improvement;
    }

    if (name.contains('দৌড়') || name.contains('হাঁটা')) {
      return Icons.directions_run;
    }

    if (name.contains('প্লাঙ্ক')) {
      return Icons.timer;
    }

    return Icons.fitness_center;
  }
}
