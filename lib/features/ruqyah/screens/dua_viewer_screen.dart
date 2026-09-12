import 'dart:async';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/models/dua_model.dart';

class DuaViewerScreen extends StatefulWidget {
  final List<DuaModel> duaList;
  final int initialIndex;

  const DuaViewerScreen({
    super.key,
    required this.duaList,
    this.initialIndex = 0,
  });

  @override
  State<DuaViewerScreen> createState() => _DuaViewerScreenState();
}

class _DuaViewerScreenState extends State<DuaViewerScreen> {
  late final PageController _pageController;
  late int currentIndex;
  Timer? _autoTimer;
  bool isAutoPlay = false;
  bool isBookmarked = false;

  static const Duration autoDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: currentIndex);
  }

  void _toggleAutoPlay() {
    setState(() => isAutoPlay = !isAutoPlay);
    if (isAutoPlay) {
      _startAutoTimer();
    } else {
      _autoTimer?.cancel();
    }
  }

  void _startAutoTimer() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(autoDuration, (_) {
      final next = currentIndex + 1;
      if (next < widget.duaList.length) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _toggleBookmark() => setState(() => isBookmarked = !isBookmarked);

  void _shareCurrent() {
    final dua = widget.duaList[currentIndex];
    SharePlus.instance.share(
      ShareParams(text: "${dua.title}\n\n${dua.arabic}\n\n${dua.translation}"),
    );
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
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
                colors: [Color(0xFF141E30), Color(0xFF243B55)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: SelectionContainer.disabled(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.duaList.length,
                onPageChanged: (index) => setState(() => currentIndex = index),
                itemBuilder: (context, index) {
                  final dua = widget.duaList[index];
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(35),
                          color: Colors.white.withValues(alpha: 0.08),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              dua.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 30),
                            Text(
                              dua.arabic,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 28,
                                height: 1.6,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              dua.translation,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            bottom: 35,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: _toggleBookmark,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.share,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: _shareCurrent,
                  ),
                  IconButton(
                    icon: Icon(
                      isAutoPlay
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: _toggleAutoPlay,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
