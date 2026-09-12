// lib/features/ruqyah/screens/problem_swiper_screen.dart
import 'package:flutter/material.dart';
import '../../../data/models/problem_model.dart';

class ProblemSwiperScreen extends StatefulWidget {
  final List<ProblemModel> problems; // ← এখন Firebase থেকে আসবে
  final int initialIndex;

  const ProblemSwiperScreen({
    super.key,
    required this.problems,
    this.initialIndex = 0,
  });

  @override
  State<ProblemSwiperScreen> createState() => _ProblemSwiperScreenState();
}

class _ProblemSwiperScreenState extends State<ProblemSwiperScreen> {
  late final PageController _controller;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: currentIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: widget.problems.length,
                    onPageChanged: (index) =>
                        setState(() => currentIndex = index),
                    itemBuilder: (context, index) {
                      final problem = widget.problems[index];
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(
                              problem.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Expanded(
                              child: ListView.builder(
                                itemCount: problem.items.length,
                                itemBuilder: (context, i) {
                                  final item = problem.items[i];
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(25),
                                      color: Colors.white.withValues(
                                        alpha: 0.08,
                                      ),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          item.title,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          item.description,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
