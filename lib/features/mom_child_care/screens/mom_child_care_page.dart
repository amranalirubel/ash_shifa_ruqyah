import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/app_colors.dart';
import '../../../data/models/problem_model.dart';
import '../../../data/repositories/mom_child_care_repository.dart';
import '../../../services/notification_service.dart';
import '../../../utils/mom_child_content_catalog.dart';
import '../../ruqyah/screens/content_viewer_screen.dart';

part 'mom_child_care_detail_pages.dart';

class MomChildCarePage extends StatefulWidget {
  const MomChildCarePage({super.key});

  @override
  State<MomChildCarePage> createState() => _MomChildCarePageState();
}

class _MomChildCarePageState extends State<MomChildCarePage> {
  final PageController _quoteController = PageController();
  final MomChildCareRepository _repository = MomChildCareRepository();
  Timer? _quoteTimer;
  int _quoteIndex = 0;

  List<String> _dailyTips = List<String>.from(defaultMomChildDailyTips);

  @override
  void initState() {
    super.initState();
    unawaited(_loadDailyTips());
    _quoteTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_quoteController.hasClients || _dailyTips.isEmpty) {
        return;
      }
      final next = (_quoteIndex + 1) % _dailyTips.length;
      _quoteController.animateToPage(
        next,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _loadDailyTips() async {
    final tips = await _repository.getDailyTips();
    if (!mounted || tips.isEmpty || _sameTips(tips, _dailyTips)) return;

    if (_quoteController.hasClients) {
      _quoteController.jumpToPage(0);
    }
    setState(() {
      _dailyTips = tips;
      _quoteIndex = 0;
    });
  }

  bool _sameTips(List<String> first, List<String> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    _quoteController.dispose();
    super.dispose();
  }

  void _open(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final modules = [
      _Module(
        'সমস্যা সমাধান',
        'আচরণ, ঘুম, খাবার, প্রযুক্তি ও মানসিক সমস্যার করণীয়',
        Icons.healing_rounded,
        const Color(0xFF4ADE80),
        () => _open(
          const _FirebaseContentPage(
            title: 'সমস্যা সমাধান',
            type: _ContentType.problems,
          ),
        ),
      ),
      _Module(
        'প্যারেন্টিং গাইড',
        'যোগাযোগ, শাসন, সম্পর্ক ও পারিবারিক পরিবেশের সঠিক পদ্ধতি',
        Icons.family_restroom_rounded,
        const Color(0xFFFFB74D),
        () => _open(
          const _FirebaseContentPage(
            title: 'প্যারেন্টিং গাইড',
            type: _ContentType.parenting,
          ),
        ),
      ),
      _Module(
        'স্মার্ট টুলসমূহ',
        'টিকা, বৃদ্ধি, মাইলফলক, পুষ্টি, ওষুধ ও স্বাস্থ্য রেকর্ড',
        Icons.health_and_safety_rounded,
        const Color(0xFF60A5FA),
        () => _open(const _SmartToolsPage()),
      ),
      _Module(
        'বয়সভিত্তিক যত্ন',
        '০–১২ বছর: বৃদ্ধি, খাবার, ঘুম, খেলা, শেখা ও সতর্কতা',
        Icons.child_care_rounded,
        const Color(0xFFF472B6),
        () => _open(const _AgeBasedCarePage()),
      ),
      _Module(
        'শেখা ও বিকাশ',
        'ভাষা, মনোযোগ, অভ্যাস, বই, সৃজনশীলতা ও নৈতিকতা',
        Icons.psychology_alt_rounded,
        const Color(0xFFA78BFA),
        () => _open(const _LearningDevelopmentPage()),
      ),
      _Module(
        'তাৎক্ষণিক চিকিৎসা',
        'অসুস্থতা বা জরুরি পরিস্থিতিতে প্রাথমিক করণীয় ও সতর্কতা',
        Icons.emergency_rounded,
        const Color(0xFFFB7185),
        () => _open(const _InstantCarePage()),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryapp,
        centerTitle: true,
        title: const Text(
          'মা ও শিশু যত্ন',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 21),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
        physics: const BouncingScrollPhysics(),
        children: [
          _hero(),
          const SizedBox(height: 28),
          const Text(
            'প্রধান বিভাগসমূহ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'আপনার প্রয়োজন অনুযায়ী একটি বিভাগ নির্বাচন করুন',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ...modules.map(_moduleCard),
          const SizedBox(height: 4),
          _safety(),
        ],
      ),
    );
  }

  Widget _hero() => Container(
    padding: const EdgeInsets.fromLTRB(22, 25, 22, 22),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(
        colors: [Color(0xFF0F2C22), Color(0xFF1E4A3A), Color(0xFF2C6A52)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.22),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      children: [
        const Row(
          children: [
            _HeroIcon(),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'মা ও শিশুর যত্ন',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'বিজ্ঞানভিত্তিক • প্রফেশনাল • সহজ',
                    style: TextStyle(color: Colors.white70, fontSize: 13.5),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Row(
          children: [
            Icon(
              Icons.lightbulb_outline_rounded,
              color: Colors.amberAccent,
              size: 18,
            ),
            SizedBox(width: 7),
            Text(
              'প্রতিদিনের মা ও শিশু টিপস',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 92,
          child: PageView.builder(
            controller: _quoteController,
            itemCount: _dailyTips.length,
            onPageChanged: (i) => setState(() => _quoteIndex = i),
            itemBuilder: (_, i) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  _dailyTips[i],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _dailyTips.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: _quoteIndex == i ? 18 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: _quoteIndex == i ? Colors.amberAccent : Colors.white24,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _moduleCard(_Module m) => Container(
    margin: const EdgeInsets.only(bottom: 13),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: LinearGradient(
        colors: [
          m.color.withValues(alpha: 0.16),
          const Color(0xFF171D24),
          const Color(0xFF11161C),
        ],
      ),
      border: Border.all(color: m.color.withValues(alpha: 0.22)),
    ),
    clipBehavior: Clip.antiAlias,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: m.onTap,
        splashColor: m.color.withValues(alpha: 0.12),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: m.color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(m.icon, color: m.color, size: 29),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      m.description,
                      style: const TextStyle(
                        color: Colors.white60,
                        height: 1.4,
                        fontSize: 12.7,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white30,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _safety() => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.amber.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(17),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, color: Colors.amberAccent, size: 20),
        SizedBox(width: 9),
        Expanded(
          child: Text(
            'স্বাস্থ্যসংক্রান্ত তথ্য সচেতনতা ও পর্যবেক্ষণের জন্য। '
            'গুরুতর বা হঠাৎ অসুস্থতায় চিকিৎসকের মূল্যায়ন প্রয়োজন।',
            style: TextStyle(
              color: Colors.white60,
              height: 1.45,
              fontSize: 12.3,
            ),
          ),
        ),
      ],
    ),
  );
}

class _HeroIcon extends StatelessWidget {
  const _HeroIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(17),
      ),
      child: const Icon(
        Icons.family_restroom_rounded,
        color: Colors.amberAccent,
        size: 32,
      ),
    );
  }
}

class _Module {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _Module(
    this.title,
    this.description,
    this.icon,
    this.color,
    this.onTap,
  );
}
