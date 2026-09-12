import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioRuqyahScreen extends StatefulWidget {
  final List<Map<String, dynamic>> playlist;
  final int initialIndex;

  const AudioRuqyahScreen({
    super.key,
    required this.playlist,
    this.initialIndex = 0,
  });

  @override
  State<AudioRuqyahScreen> createState() => _AudioRuqyahScreenState();
}

class _AudioRuqyahScreenState extends State<AudioRuqyahScreen> {
  late final AudioPlayer _player;
  bool isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = true;
  String? _errorMessage;

  late int currentIndex;
  late List<Map<String, dynamic>> playlist;

  static const Color mySelectedColor = Color.fromARGB(255, 99, 214, 204);

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    playlist = widget.playlist;
    _player = AudioPlayer();
    _loadCurrentAudio();
  }

  Future<void> _loadCurrentAudio() async {
    setState(() => _isLoading = true);
    try {
      await _player.setAsset(playlist[currentIndex]['asset'] as String);
      _player.durationStream.listen((d) {
        if (d != null && mounted) setState(() => _duration = d);
      });
      _player.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      _player.playingStream.listen((playing) {
        if (mounted) setState(() => isPlaying = playing);
      });
      if (mounted) setState(() => _isLoading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'অডিও লোড করতে সমস্যা হয়েছে।';
          _isLoading = false;
        });
      }
    }
  }

  void _togglePlayPause() {
    isPlaying ? _player.pause() : _player.play();
  }

  void _playNext() {
    setState(() {
      currentIndex = (currentIndex + 1) % playlist.length;
    });
    _loadCurrentAudio();
    _player.play();
  }

  void _playPrevious() {
    setState(() {
      currentIndex = (currentIndex - 1 + playlist.length) % playlist.length;
    });
    _loadCurrentAudio();
    _player.play();
  }

  String get currentTitle => playlist[currentIndex]['title'] as String;

  @override
  void dispose() {
    _player.dispose();
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
                  Color(0xFF0F1C2E),
                  Color(0xFF1A2A44),
                  Color(0xFF203A43),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: mySelectedColor),
                  )
                : _errorMessage != null
                ? Center(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  )
                : Column(
                    children: [
                      _buildAppBar(context),
                      const Spacer(),
                      _buildArtwork(),
                      const SizedBox(height: 40),
                      _buildTitleSection(),
                      const SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: ProgressBar(
                          progress: _position,
                          total: _duration,
                          onSeek: (d) => _player.seek(d),
                          barHeight: 5,
                          thumbRadius: 8,
                          baseBarColor: Colors.white10,
                          progressBarColor: mySelectedColor.withValues(
                            alpha: 0.7,
                          ),
                          thumbColor: mySelectedColor.withValues(alpha: 0.8),
                          bufferedBarColor: mySelectedColor.withValues(
                            alpha: 0.2,
                          ),
                          timeLabelTextStyle: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildControls(),
                      const Spacer(flex: 2),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Now Playing',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildArtwork() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.05),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: mySelectedColor.withValues(alpha: 0.1),
              ),
            ),
            const Icon(
              Icons.health_and_safety_rounded,
              size: 100,
              color: mySelectedColor,
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: Icon(
                Icons.audiotrack_rounded,
                size: 30,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            currentTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Ruqyah Healing Audio',
            style: TextStyle(fontSize: 16, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(
              Icons.skip_previous_rounded,
              size: 45,
              color: mySelectedColor.withValues(alpha: 0.7),
            ),
            onPressed: _playPrevious,
          ),
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              height: 65,
              width: 65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: mySelectedColor.withValues(alpha: 0.7),
                boxShadow: [
                  BoxShadow(
                    color: mySelectedColor.withValues(alpha: 0.3),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 50,
                color: Colors.black,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.skip_next_rounded,
              size: 45,
              color: mySelectedColor.withValues(alpha: 0.7),
            ),
            onPressed: _playNext,
          ),
        ],
      ),
    );
  }
}
