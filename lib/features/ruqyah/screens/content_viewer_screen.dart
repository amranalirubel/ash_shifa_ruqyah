import 'package:flutter/material.dart';

import '../../../data/models/problem_model.dart';

class ContentViewerScreen extends StatefulWidget {
  final List<ProblemModel> contentList;
  final int initialIndex;
  final String screenTitle;

  const ContentViewerScreen({
    super.key,
    required this.contentList,
    this.initialIndex = 0,
    this.screenTitle = "Ash-Shifa Ruqyah",
  });

  @override
  State<ContentViewerScreen> createState() => _ContentViewerScreenState();
}

class _ContentViewerScreenState extends State<ContentViewerScreen> {
  late PageController _controller;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.contentList.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, widget.contentList.length - 1).toInt();
    _controller = PageController(initialPage: currentIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (currentIndex < widget.contentList.length - 1) {
      _controller.animateToPage(
        currentIndex + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (currentIndex > 0) {
      _controller.animateToPage(
        currentIndex - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: List.generate(widget.contentList.length, (index) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 4,
              decoration: BoxDecoration(
                color: index < currentIndex
                    ? Colors.white
                    : index == currentIndex
                    ? Colors.amberAccent
                    : Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.contentList.isEmpty) {
      return _EmptyContentScaffold(title: widget.screenTitle);
    }

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
                _buildProgressBar(),
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTapDown: (details) {
                      final double screenWidth = MediaQuery.of(
                        context,
                      ).size.width;
                      if (details.globalPosition.dx < screenWidth / 2) {
                        _previousPage();
                      } else {
                        _nextPage();
                      }
                    },
                    child: PageView.builder(
                      controller: _controller,
                      physics: const BouncingScrollPhysics(),
                      itemCount: widget.contentList.length,
                      onPageChanged: (index) =>
                          setState(() => currentIndex = index),
                      itemBuilder: (context, index) {
                        final section = widget.contentList[index];
                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Text(
                                section.title,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 25),
                              ...section.items.map(
                                (sub) => Container(
                                  margin: const EdgeInsets.only(bottom: 18),
                                  padding: const EdgeInsets.all(22),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sub.title,
                                        style: const TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amberAccent,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        sub.description,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          height: 1.7,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
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

class _EmptyContentScaffold extends StatelessWidget {
  const _EmptyContentScaffold({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'এই কনটেন্টটি এখনো পাওয়া যায়নি। কিছুক্ষণ পরে আবার চেষ্টা করুন।',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
