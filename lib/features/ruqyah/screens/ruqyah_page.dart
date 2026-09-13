// lib/features/ruqyah/screens/ruqyah_page.dart
import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../data/repositories/ruqyah_repository.dart';
import '../../../data/models/problem_model.dart';
import '../../../data/models/dua_model.dart';
import 'audio_ruqyah_screen.dart';
import 'content_viewer_screen.dart';
import 'dua_viewer_screen.dart';
import 'forty_days_challenge_screen.dart';
import 'problem_swiper_screen.dart';
import '../../query/screens/query_form_screen.dart';

class RuqyahPage extends StatefulWidget {
  const RuqyahPage({super.key});
  @override
  State<RuqyahPage> createState() => _RuqyahPageState();
}

class _RuqyahPageState extends State<RuqyahPage> {
  final RuqyahRepository repo = RuqyahRepository();
  bool _isLoading = true;

  List<DuaModel> _duaList = [];
  List<ProblemModel> _problems = [];
  List<ProblemModel> _basicsOfRuqyah = [];
  List<ProblemModel> _dailyAdhkarList = [];
  List<ProblemModel> _stepByStepList = [];
  List<ProblemModel> _faqList = [];
  List<ProblemModel> _diagnosisList = [];
  List<Map<String, dynamic>> _freeAudioList = [];
  List<Map<String, dynamic>> _paidAudioList = [];

  int _openCardIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      final results = await Future.wait([
        repo.getDuaList(),
        repo.getProblems(),
        repo.getBasicsOfRuqyah(),
        repo.getDailyAdhkarList(),
        repo.getStepByStepList(),
        repo.getFaqList(),
        repo.getDiagnosisList(),
        repo.getFreeAudioList(),
        repo.getPaidAudioList(),
      ]);

      _duaList = results[0] as List<DuaModel>;
      _problems = results[1] as List<ProblemModel>;
      _basicsOfRuqyah = results[2] as List<ProblemModel>;
      _dailyAdhkarList = results[3] as List<ProblemModel>;
      _stepByStepList = results[4] as List<ProblemModel>;
      _faqList = results[5] as List<ProblemModel>;
      _diagnosisList = results[6] as List<ProblemModel>;
      _freeAudioList = results[7] as List<Map<String, dynamic>>;
      _paidAudioList = results[8] as List<Map<String, dynamic>>;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ক্লাউড কনটেন্ট লোড করা যায়নি। ইন্টারনেট ও Firebase setup পরীক্ষা করুন।',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ================== Navigation Helpers ==================
  void _openDuaViewer(BuildContext context, int startIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DuaViewerScreen(duaList: _duaList, initialIndex: startIndex),
      ),
    );
  }

  void _openProblemSwiper(BuildContext context, int startIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProblemSwiperScreen(problems: _problems, initialIndex: startIndex),
      ),
    );
  }

  void _openContentViewer(
    BuildContext context,
    List<ProblemModel> list,
    String title, [
    int initialIndex = 0,
  ]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContentViewerScreen(
          contentList: list,
          initialIndex: initialIndex,
          screenTitle: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.amberAccent),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryapp,
        centerTitle: true,
        title: const Text(
          "Ash-Shifa Ruqyah",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 1. Basics of Ruqyah
            // ================== 🔥 Basics of Ruqyah - FINAL UPDATED ==================
            _buildManagedCard(
              0,
              Icons.auto_stories_rounded,
              "Basics of Ruqyah\nরুকইয়াহের মৌলিক বিষয়সমূহ",
              [
                _buildSubItem(
                  context,
                  "১. রুকইয়াহ কী?",
                  () => _openContentViewer(
                    context,
                    _basicsOfRuqyah,
                    "রুকইয়াহ কী?",
                    0,
                  ),
                ),

                _buildSubItem(
                  context,
                  "২. উৎপত্তি ও ইতিহাস",
                  () => _openContentViewer(
                    context,
                    _basicsOfRuqyah,
                    "উৎপত্তি ও ইতিহাস",
                    1,
                  ),
                ),

                _buildSubItem(
                  context,
                  "৩. রুকইয়াহের মৌলিক বিষয়সমূহ",
                  () => _openContentViewer(
                    context,
                    _basicsOfRuqyah,
                    "রুকইয়াহের মৌলিক বিষয়সমূহ",
                    2,
                  ),
                ),

                _buildSubItem(
                  context,
                  "৪. রুকইয়াহর শর্তাবলি ও শিরক থেকে সতর্কতা",
                  () => _openContentViewer(
                    context,
                    _basicsOfRuqyah,
                    "রুকইয়াহর শর্তাবলি ও শিরক থেকে সতর্কতা",
                    3,
                  ),
                ),

                _buildSubItem(
                  context,
                  "৫. কুরআন-সুন্নাহভিত্তিক রুকইয়াহ",
                  () => _openContentViewer(
                    context,
                    _basicsOfRuqyah,
                    "কুরআন-সুন্নাহভিত্তিক রুকইয়াহ",
                    4,
                  ),
                ),

                _buildSubItem(
                  context,
                  "৬. গুরুত্বপূর্ণ আয়াত ও মাসনূন দোয়া",
                  () => _openContentViewer(
                    context,
                    _basicsOfRuqyah,
                    "গুরুত্বপূর্ণ আয়াত ও মাসনূন দোয়া",
                    5,
                  ),
                ),

                _buildSubItem(
                  context,
                  "৭. প্রচলিত ভুল ধারণা ও তার সংশোধন",
                  () => _openContentViewer(
                    context,
                    _basicsOfRuqyah,
                    "প্রচলিত ভুল ধারণা ও তার সংশোধন",
                    6,
                  ),
                ),
              ],
            ),
            // =====================================================================

            // 2. Diagnosis
            _buildManagedCard(
              1,
              Icons.health_and_safety_rounded,
              "Diagnosis & Self Test\nরোগ নির্ণয় ও আত্মপরীক্ষা",
              [
                _buildSubItem(
                  context,
                  "লক্ষণসমূহ (Sihr, Ain, Jinn)",
                  () => _openContentViewer(
                    context,
                    _diagnosisList,
                    "লক্ষণসমূহ",
                    0,
                  ),
                ),
                _buildSubItem(
                  context,
                  "Self-Test Quiz",
                  () => _openContentViewer(
                    context,
                    _diagnosisList,
                    "Self Test",
                    1,
                  ),
                ),
              ],
            ),

            // 3. Audio Ruqyah
            _buildManagedCard(
              2,
              Icons.settings_voice_rounded,
              "Audio Ruqyah\nঅডিও রুকইয়াহ",
              [
                _buildAudioExpansionTile("Free Audio Ruqyah", [
                  const Color(0xFF00ACC1),
                  Colors.black,
                ], _freeAudioList),
                const SizedBox(height: 10),
                _buildAudioExpansionTile("Special Audio Ruqyah", [
                  const Color(0xFF37D456),
                  Colors.black,
                ], _paidAudioList),
              ],
            ),

            // 4. Specific Problems
            _buildManagedCard(
              3,
              Icons.healing_rounded,
              "Specific Problems & Solutions\nনির্দিষ্ট সমস্যা ও প্রতিকার",
              _problems
                  .asMap()
                  .entries
                  .map(
                    (e) => _buildSubItem(
                      context,
                      e.value.title,
                      () => _openProblemSwiper(context, e.key),
                    ),
                  )
                  .toList(),
            ),

            // 5. Daily Adhkar
            _buildManagedCard(
              4,
              Icons.wb_sunny_rounded,
              "Daily Adhkar\nপ্রতিদিনের যিকির",
              [
                _buildSubItem(
                  context,
                  "সকাল-সন্ধ্যার মাসনুন দোয়া",
                  () => _openContentViewer(
                    context,
                    _dailyAdhkarList,
                    "সকাল-সন্ধ্যার দোয়া",
                    0,
                  ),
                ),
                _buildSubItem(
                  context,
                  "ফরজ সালাত পরবর্তী জিকির",
                  () => _openContentViewer(
                    context,
                    _dailyAdhkarList,
                    "ফরজ সালাত পরবর্তী জিকির",
                    1,
                  ),
                ),
                _buildSubItem(
                  context,
                  "মাগরিব সালাত পরবর্তী জিকির",
                  () => _openContentViewer(
                    context,
                    _dailyAdhkarList,
                    "মাগরিব সালাত পরবর্তী জিকির",
                    2,
                  ),
                ),
                _buildSubItem(
                  context,
                  "ঘুমানোর দোয়া",
                  () => _openContentViewer(
                    context,
                    _dailyAdhkarList,
                    "ঘুমানোর দোয়া",
                    3,
                  ),
                ),
                _buildCustomExpansionTile(
                  "কুরআনে বর্ণিত সকল দোয়া",
                  [const Color(0xFFA63636), Colors.black],
                  [
                    _buildSubItem(
                      context,
                      "হেদায়েতের উপর স্থির থাকার দোয়া",
                      () => _openDuaViewer(context, 0),
                    ),
                    _buildSubItem(
                      context,
                      "ঘুমানোর আগে",
                      () => _openDuaViewer(context, 1),
                    ),
                    _buildSubItem(
                      context,
                      "বাড়ি থেকে বের হওয়ার দুয়া",
                      () => _openDuaViewer(context, 2),
                    ),
                    _buildSubItem(
                      context,
                      "খাবার শুরু করার দুয়া",
                      () => _openDuaViewer(context, 3),
                    ),
                  ],
                ),
              ],
            ),

            // 6. Step-by-Step Guide
            _buildManagedCard(
              5,
              Icons.format_list_numbered_rtl_rounded,
              "Step-by-Step Guide\nপর্যায়ক্রমিক নির্দেশিকা",
              [
                _buildSubItem(
                  context,
                  "কিভাবে রুকইয়াহ করবেন — সম্পূর্ণ গাইড",
                  () =>
                      _openContentViewer(context, _stepByStepList, "Guide", 0),
                ),
              ],
            ),

            // 7. 40 Days Challenge
            _buildManagedCard(
              6,
              Icons.emoji_events_rounded,
              "40 Days Recovery Challenge\n৪০ দিনের রিকভারি চ্যালেঞ্জ",
              [
                _buildSubItem(
                  context,
                  "চ্যালেঞ্জ শুরু করুন",
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FortyDaysChallengeScreen(),
                    ),
                  ),
                ),
              ],
            ),

            // 8. FAQ
            _buildManagedCard(
              7,
              Icons.question_answer_rounded,
              "FAQ\nসাধারণ প্রশ্নোত্তর",
              [
                _buildSubItem(
                  context,
                  "সাধারণ প্রশ্ন ও উত্তর",
                  () => _openContentViewer(context, _faqList, "FAQ"),
                ),
                _buildSubItem(
                  context,
                  "আপনার জিজ্ঞাসা",
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QueryFormScreen()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ================== Card Management ==================
  Widget _buildManagedCard(
    int index,
    IconData icon,
    String title,
    List<Widget> children,
  ) {
    return RuqyahCard(
      icon: icon,
      title: title,
      initiallyExpanded: _openCardIndex == index,
      onExpansionChanged: (expanded) =>
          setState(() => _openCardIndex = expanded ? index : -1),
      children: children,
    );
  }

  // ================== Sub Item ==================
  Widget _buildSubItem(
    BuildContext context,
    String title, [
    VoidCallback? onTap,
  ]) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.blueGrey.shade900,
          child: InkWell(
            onTap: onTap,
            child: ListTile(
              dense: true,
              title: Text(
                title,
                style: const TextStyle(fontSize: 15, color: Colors.white),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================== Audio Expansion Tile (Free/Paid) ==================
  Widget _buildAudioExpansionTile(
    String title,
    List<Color> colors,
    List<Map<String, dynamic>> audioList,
  ) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        children: audioList.asMap().entries.map((e) {
          return _buildSubItem(context, e.value['title'], () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AudioRuqyahScreen(playlist: audioList, initialIndex: e.key),
              ),
            );
          });
        }).toList(),
      ),
    );
  }

  // ================== Custom Expansion Tile (দোয়া, জিকির ইত্যাদির জন্য) ==================
  Widget _buildCustomExpansionTile(
    String title,
    List<Color> colors,
    List<Widget> children,
  ) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        children: children,
      ),
    );
  }
}

// ================== RuqyahCard ==================
class RuqyahCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpansionChanged;

  const RuqyahCard({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E272E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          onExpansionChanged: onExpansionChanged,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amberAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.amberAccent, size: 24),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconColor: Colors.amberAccent,
          collapsedIconColor: Colors.white70,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: children,
        ),
      ),
    );
  }
}
