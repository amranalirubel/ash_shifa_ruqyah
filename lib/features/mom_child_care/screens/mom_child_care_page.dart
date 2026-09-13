import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/app_colors.dart';
import '../../../data/models/problem_model.dart';
import '../../../data/repositories/mom_child_care_repository.dart';
import '../../../services/notification_service.dart';
import '../../ruqyah/screens/content_viewer_screen.dart';

class MomChildCarePage extends StatefulWidget {
  const MomChildCarePage({super.key});

  @override
  State<MomChildCarePage> createState() => _MomChildCarePageState();
}

class _MomChildCarePageState extends State<MomChildCarePage> {
  final PageController _quoteController = PageController();
  Timer? _quoteTimer;
  int _quoteIndex = 0;

  // আগের auto-slide টেক্সট অপরিবর্তিত
  final List<String> _quotes = const [
    'মায়ের স্বাস্থ্যই শিশুর সবচেয়ে বড় সম্পদ।',
    'প্রথম ১০০০ দিন শিশুর ভবিষ্যৎ গড়ে দেয়।',
    'সঠিক পুষ্টি মেধা ও শারীরিক বিকাশের চাবিকাঠি।',
    'নিয়মিত ঘুম ও খেলা শিশুকে সুস্থ রাখে।',
    'মা-শিশুর বন্ধন সবচেয়ে শক্তিশালী সম্পর্ক।',
    'বিজ্ঞান বলে: মায়ের স্পর্শ শিশুর মস্তিষ্ক বিকশিত করে।',
  ];

  @override
  void initState() {
    super.initState();
    _quoteTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_quoteController.hasClients) return;
      final next = (_quoteIndex + 1) % _quotes.length;
      _quoteController.animateToPage(
        next,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOut,
      );
    });
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
        SizedBox(
          height: 92,
          child: PageView.builder(
            controller: _quoteController,
            itemCount: _quotes.length,
            onPageChanged: (i) => setState(() => _quoteIndex = i),
            itemBuilder: (_, i) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  _quotes[i],
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
            _quotes.length,
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

// ================================================================
// 1 + 2. সমস্যা সমাধান / প্যারেন্টিং গাইড — FULL FIREBASE VERSION
// ================================================================

enum _ContentType {
  problems('problems'),
  parenting('parenting_guide');

  const _ContentType(this.documentId);

  final String documentId;
}

class _FirebaseContentPage extends StatefulWidget {
  final String title;
  final _ContentType type;

  const _FirebaseContentPage({required this.title, required this.type});

  @override
  State<_FirebaseContentPage> createState() => _FirebaseContentPageState();
}

class _FirebaseContentPageState extends State<_FirebaseContentPage> {
  final _repo = MomChildCareRepository();
  final _search = TextEditingController();

  bool _loading = false;
  MomChildCloudStatus _cloudStatus = MomChildCloudStatus.checking;
  String? _error;
  String _query = '';
  Map<String, dynamic> _document = const {};

  @override
  void initState() {
    super.initState();
    _document = _repo.getBundledDocument(widget.type.documentId);
    unawaited(_load(showLoading: _document.isEmpty));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (mounted && showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final result = await _repo.getResolvedContentDocument(
        widget.type.documentId,
      );

      if (!mounted) return;

      if (result.data.isNotEmpty) {
        _document = result.data;
        _cloudStatus = result.cloudStatus;
        _error = null;
      } else if (_document.isEmpty) {
        _error =
            'Firebase-এ এই বিভাগের পূর্ণ কনটেন্ট পাওয়া যায়নি। '
            'Firestore path পরীক্ষা করুন: '
            'mom_child_care/${widget.type.documentId}';
      }
    } catch (_) {
      if (!mounted) return;
      _cloudStatus = MomChildCloudStatus.unavailable;
      if (_document.isEmpty) {
        _error =
            'কনটেন্ট লোড করা যায়নি। Firestore rules, project এবং internet '
            'connection পরীক্ষা করুন।';
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<Map<String, dynamic>> _mapList(dynamic raw) {
    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<Map<String, dynamic>> get _sections {
    final source = _mapList(_document['sections']);
    if (_query.trim().isEmpty) return source;

    final q = _query.trim().toLowerCase();
    final filtered = <Map<String, dynamic>>[];

    for (final section in source) {
      final topics = _mapList(section['topics']).where((topic) {
        final buffer = StringBuffer(
          topic['title']?.toString().toLowerCase() ?? '',
        );

        for (final item in _mapList(topic['items'])) {
          buffer
            ..write(' ')
            ..write(item['title']?.toString().toLowerCase() ?? '')
            ..write(' ')
            ..write(item['description']?.toString().toLowerCase() ?? '');
        }

        return buffer.toString().contains(q);
      }).toList();

      if (topics.isNotEmpty) {
        final copy = Map<String, dynamic>.from(section);
        copy['topics'] = topics;
        filtered.add(copy);
      }
    }

    return filtered;
  }

  List<Map<String, dynamic>> get _footerSections =>
      _mapList(_document['footerSections']);

  int get _topicCount => _mapList(_document['sections']).fold<int>(
    0,
    (total, section) => total + _mapList(section['topics']).length,
  );

  void _openTopic(Map<String, dynamic> topic) {
    final model = ProblemModel(
      title: topic['title']?.toString() ?? widget.title,
      items: _mapList(topic['items'])
          .map(
            (item) => SubItem(
              title: item['title']?.toString() ?? '',
              description: item['description']?.toString() ?? '',
            ),
          )
          .toList(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ContentViewerScreen(contentList: [model], screenTitle: model.title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.primaryapp,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(showLoading: false),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.amberAccent),
                ),
              )
            else if (_error != null)
              _firebaseMessage(_error!)
            else ...[
              _buildIntroCard(),
              const SizedBox(height: 14),
              _buildSearchField(),
              const SizedBox(height: 10),
              _buildCountRow(),
              const SizedBox(height: 14),
              if (_sections.isEmpty)
                _firebaseMessage('কোনো মিল পাওয়া যায়নি।')
              else
                ..._sections.map(_buildCategoryCard),
              if (_query.trim().isEmpty && _footerSections.isNotEmpty) ...[
                const SizedBox(height: 6),
                ..._footerSections.map(_buildFooterCard),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    final intro = _document['intro']?.toString().trim() ?? '';
    if (intro.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF22C55E).withValues(alpha: 0.12),
            const Color(0xFF192129),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF22C55E).withValues(alpha: 0.16),
        ),
      ),
      child: Text(
        intro,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          height: 1.65,
        ),
      ),
    );
  }

  Widget _buildSearchField() => TextField(
    controller: _search,
    onChanged: (value) => setState(() => _query = value),
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      hintText: 'বিষয় বা সমস্যার নাম খুঁজুন...',
      hintStyle: const TextStyle(color: Colors.white38),
      prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
      suffixIcon: _query.isEmpty
          ? null
          : IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white54),
              onPressed: () {
                _search.clear();
                setState(() => _query = '');
              },
            ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF4ADE80), width: 1.3),
      ),
    ),
  );

  Widget _buildCountRow() {
    final categoryCount = _mapList(_document['sections']).length;

    return Row(
      children: [
        const Icon(
          Icons.cloud_done_rounded,
          color: Color(0xFF4ADE80),
          size: 17,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            '${_momChildSourceLabel(_cloudStatus)} • '
            '$_topicCountটি বিষয় • $categoryCountটি বিভাগ',
            style: const TextStyle(color: Color(0x73FFFFFF), fontSize: 12.5),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> section) {
    final topics = _mapList(section['topics']);
    final title = section['title']?.toString() ?? '';
    final description = section['description']?.toString().trim() ?? '';
    final searching = _query.trim().isNotEmpty;

    return Container(
      key: ValueKey('$title|$_query'),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF18212A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: searching,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.folder_copy_rounded,
              color: Colors.amberAccent,
              size: 23,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            '${topics.length}টি বিষয়',
            style: const TextStyle(color: Color(0x73FFFFFF), fontSize: 12),
          ),
          iconColor: Colors.amberAccent,
          collapsedIconColor: Colors.white38,
          children: [
            if (description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                child: Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white54,
                    height: 1.5,
                    fontSize: 13,
                  ),
                ),
              ),
            ...topics.map(_buildTopicTile),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicTile(Map<String, dynamic> topic) => Container(
    margin: const EdgeInsets.only(top: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.045),
      borderRadius: BorderRadius.circular(15),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      leading: CircleAvatar(
        radius: 17,
        backgroundColor: const Color(0xFF4ADE80).withValues(alpha: 0.11),
        child: const Icon(
          Icons.article_outlined,
          color: Color(0xFF4ADE80),
          size: 18,
        ),
      ),
      title: Text(
        topic['title']?.toString() ?? '',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        color: Colors.white30,
        size: 13,
      ),
      onTap: () => _openTopic(topic),
    ),
  );

  Widget _buildFooterCard(Map<String, dynamic> footer) {
    final title = footer['title']?.toString() ?? '';
    final body = footer['body']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.065),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.amberAccent,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white70,
              height: 1.65,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _firebaseMessage(String text) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.white60, height: 1.5),
    ),
  );
}

// ================================================================
// 3. স্মার্ট টুলসমূহ
// ================================================================

class _SmartToolsPage extends StatelessWidget {
  const _SmartToolsPage();

  @override
  Widget build(BuildContext context) {
    final tools = [
      _Tool(
        'টিকাদান সময়সূচি',
        'টিকার তালিকা ও সম্পন্ন অবস্থা',
        Icons.vaccines_rounded,
        const Color(0xFF22C55E),
        const _VaccinationPage(),
      ),
      _Tool(
        'বৃদ্ধি পর্যবেক্ষণ',
        'ওজন ও উচ্চতার ইতিহাস',
        Icons.monitor_weight_rounded,
        const Color(0xFF38BDF8),
        const _GrowthPage(),
      ),
      _Tool(
        'বিকাশের মাইলফলক',
        'বয়স অনুযায়ী দক্ষতা যাচাই',
        Icons.psychology_alt_rounded,
        const Color(0xFFA78BFA),
        const _MilestonePage(),
      ),
      _Tool(
        'পুষ্টি ও খাবার পরিকল্পনা',
        'বয়স অনুযায়ী খাবারের পরিকল্পনা',
        Icons.restaurant_menu_rounded,
        const Color(0xFFF59E0B),
        const _NutritionPage(),
      ),
      _Tool(
        'ওষুধ স্মরণ',
        'চিকিৎসকের দেওয়া ওষুধের সময়',
        Icons.medication_rounded,
        const Color(0xFFFB7185),
        const _MedicinePage(),
      ),
      _Tool(
        'শিশু স্বাস্থ্য রেকর্ড',
        'অ্যালার্জি ও স্বাস্থ্য ইতিহাস',
        Icons.folder_shared_rounded,
        const Color(0xFF2DD4BF),
        const _HealthRecordPage(),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('স্মার্ট টুলসমূহ'),
        backgroundColor: AppColors.primaryapp,
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tools.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 13,
          crossAxisSpacing: 13,
          childAspectRatio: 0.88,
        ),
        itemBuilder: (_, i) {
          final t = tools[i];
          return InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => t.page),
            ),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    t.color.withValues(alpha: 0.16),
                    const Color(0xFF171D24),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: t.color.withValues(alpha: 0.22)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: t.color.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(t.icon, color: t.color),
                  ),
                  const Spacer(),
                  Text(
                    t.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    t.subtitle,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Tool {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget page;

  const _Tool(this.title, this.subtitle, this.icon, this.color, this.page);
}

// -------------------- টিকাদান --------------------

class _VaccinationPage extends StatefulWidget {
  const _VaccinationPage();

  @override
  State<_VaccinationPage> createState() => _VaccinationPageState();
}

class _VaccinationPageState extends State<_VaccinationPage> {
  static const _doneKey = 'mom_child_completed_vaccines';

  final _repo = MomChildCareRepository();
  bool _loading = true;
  List<Map<String, dynamic>> _schedule = [];
  Set<String> _done = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _done = (prefs.getStringList(_doneKey) ?? const []).toSet();

    try {
      _schedule = await _repo.getVaccinationSchedule();
    } catch (_) {
      _schedule = [];
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggle(String id, bool value) async {
    value ? _done.add(id) : _done.remove(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_doneKey, _done.toList());
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _SimpleScaffold(
      title: 'টিকাদান সময়সূচি',
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF22C55E)),
            )
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                _InfoBox(
                  text:
                      'টিকার তালিকা Firebase থেকে লোড হয়, তাই জাতীয় সময়সূচি বদলালে '
                      'অ্যাপ আপডেট ছাড়াই তথ্য পরিবর্তন করা যাবে।',
                  color: const Color(0xFF22C55E),
                ),
                const SizedBox(height: 16),
                if (_schedule.isEmpty)
                  const _EmptyBox(
                    'Firebase → mom_child_care/smart_tools ডকুমেন্টের '
                    'vaccinationSchedule তালিকায় যাচাইকৃত, দেশভিত্তিক তথ্য যোগ করুন।\n\n'
                    'প্রতি আইটেম: id, title, age, dose, description',
                  )
                else
                  ..._schedule.asMap().entries.map((entry) {
                    final item = entry.value;
                    final id =
                        item['id']?.toString() ??
                        '${item['title']}_${entry.key}';
                    final done = _done.contains(id);

                    return Card(
                      color: const Color(0xFF192129),
                      child: CheckboxListTile(
                        value: done,
                        activeColor: const Color(0xFF22C55E),
                        checkColor: Colors.black,
                        onChanged: (v) => _toggle(id, v ?? false),
                        title: Text(
                          item['title']?.toString() ?? 'টিকা',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            decoration: done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: Text(
                          [item['age'], item['dose'], item['description']]
                              .where(
                                (e) =>
                                    e != null && e.toString().trim().isNotEmpty,
                              )
                              .join(' • '),
                          style: const TextStyle(
                            color: Colors.white54,
                            height: 1.4,
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}

// -------------------- বৃদ্ধি --------------------

class _GrowthPage extends StatefulWidget {
  const _GrowthPage();

  @override
  State<_GrowthPage> createState() => _GrowthPageState();
}

class _GrowthPageState extends State<_GrowthPage> {
  static const _key = 'mom_child_growth_records';

  final _weight = TextEditingController();
  final _height = TextEditingController();
  List<Map<String, dynamic>> _records = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      _records = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    if (mounted) setState(() {});
  }

  Future<void> _add() async {
    final w = double.tryParse(_weight.text.trim());
    final h = double.tryParse(_height.text.trim());

    if (w == null || h == null || w <= 0 || h <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('সঠিক ওজন ও উচ্চতা লিখুন।')));
      return;
    }

    _records.insert(0, {
      'date': DateTime.now().toIso8601String(),
      'weight': w,
      'height': h,
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_records));

    _weight.clear();
    _height.clear();
    if (mounted) setState(() {});
  }

  Future<void> _remove(int index) async {
    _records.removeAt(index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_records));
    if (mounted) setState(() {});
  }

  String _date(String raw) {
    final d = DateTime.tryParse(raw);
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return _SimpleScaffold(
      title: 'বৃদ্ধি পর্যবেক্ষণ',
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text('নতুন মাপ যোগ করুন', style: _Styles.head),
          const SizedBox(height: 6),
          const Text(
            'একটি মাপ নয়—সময়ের সঙ্গে পরিবর্তন দেখুন।',
            style: _Styles.sub,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _NumberField(
                  controller: _weight,
                  label: 'ওজন',
                  suffix: 'কেজি',
                  icon: Icons.monitor_weight_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NumberField(
                  controller: _height,
                  label: 'উচ্চতা',
                  suffix: 'সেমি',
                  icon: Icons.height_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.add_rounded),
            label: const Text('মাপ সংরক্ষণ করুন'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.black,
            ),
          ),
          const SizedBox(height: 26),
          const Text('মাপের ইতিহাস', style: _Styles.headSmall),
          const SizedBox(height: 10),
          if (_records.isEmpty)
            const _EmptyBox('এখনো কোনো মাপ যোগ করা হয়নি।')
          else
            ..._records.asMap().entries.map(
              (e) => Card(
                color: const Color(0xFF192129),
                child: ListTile(
                  title: Text(
                    '${e.value['weight']} কেজি • ${e.value['height']} সেমি',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    _date(e.value['date']?.toString() ?? ''),
                    style: const TextStyle(color: Colors.white54),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white38,
                    ),
                    onPressed: () => _remove(e.key),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 14),
          const _InfoBox(
            text:
                'এটি শুধু মাপ সংরক্ষণ করে। শিশুকে adult BMI দিয়ে বিচার করা হবে না। '
                'WHO বয়স ও লিঙ্গভিত্তিক growth standard যোগ করতে হলে যাচাইকৃত '
                'dataset দিয়ে আলাদা হিসাব করতে হবে।',
            color: Colors.amber,
          ),
        ],
      ),
    );
  }
}

// -------------------- মাইলফলক --------------------

class _MilestonePage extends StatefulWidget {
  const _MilestonePage();

  @override
  State<_MilestonePage> createState() => _MilestonePageState();
}

class _MilestonePageState extends State<_MilestonePage> {
  final _repo = MomChildCareRepository();
  bool _loading = true;
  List<Map<String, dynamic>> _groups = [];
  int _selected = 0;
  final Set<String> _checked = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _groups = await _repo.getMilestones();
    } catch (_) {
      _groups = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  List<dynamic> get _items {
    if (_groups.isEmpty) return const [];
    return _groups[_selected]['items'] as List<dynamic>? ?? const [];
  }

  @override
  Widget build(BuildContext context) {
    return _SimpleScaffold(
      title: 'বিকাশের মাইলফলক',
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFA78BFA)),
            )
          : _groups.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(22),
              child: _EmptyBox(
                'Firebase → mom_child_care/smart_tools ডকুমেন্টের '
                'milestones তালিকায় বয়সভিত্তিক তথ্য যোগ করুন।',
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                const Text('বয়স নির্বাচন করুন', style: _Styles.headSmall),
                const SizedBox(height: 10),
                SizedBox(
                  height: 42,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _groups.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          _groups[i]['title']?.toString() ?? '${i + 1}',
                        ),
                        selected: i == _selected,
                        onSelected: (_) => setState(() {
                          _selected = i;
                          _checked.clear();
                        }),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ..._items.asMap().entries.map((e) {
                  final raw = e.value;
                  final map = raw is Map
                      ? Map<String, dynamic>.from(raw)
                      : <String, dynamic>{};
                  final text =
                      map['title']?.toString() ??
                      map['description']?.toString() ??
                      raw.toString();
                  final id = '${_selected}_${e.key}';

                  return Card(
                    color: const Color(0xFF192129),
                    child: CheckboxListTile(
                      value: _checked.contains(id),
                      activeColor: const Color(0xFFA78BFA),
                      onChanged: (v) => setState(() {
                        if (v ?? false) {
                          _checked.add(id);
                        } else {
                          _checked.remove(id);
                        }
                      }),
                      title: Text(
                        text,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                Text(
                  '${_checked.length}টি দক্ষতা লক্ষ্য করেছেন।',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                const _InfoBox(
                  text:
                      'মাইলফলক চেকলিস্ট কোনো রোগ নির্ণয় বা আনুষ্ঠানিক '
                      'developmental screening-এর বিকল্প নয়। আগে পারত এমন '
                      'দক্ষতা হারালে বা উদ্বেগ থাকলে শিশু বিশেষজ্ঞের সঙ্গে কথা বলুন।',
                  color: Colors.amber,
                ),
              ],
            ),
    );
  }
}

// -------------------- পুষ্টি --------------------

class _NutritionPage extends StatefulWidget {
  const _NutritionPage();

  @override
  State<_NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<_NutritionPage> {
  String _age = '৬–৮ মাস';
  final Set<String> _today = {};

  final Map<String, List<String>> _plans = const {
    '০–৬ মাস': [
      'শিশুর খাওয়ানো নিয়ে ব্যক্তিগত পরিস্থিতি থাকলে চিকিৎসক বা প্রশিক্ষিত স্বাস্থ্যকর্মীর পরামর্শ অনুসরণ করুন।',
      'খাওয়ানোর সময় শিশুর ক্ষুধা ও তৃপ্তির সংকেত লক্ষ্য করুন।',
    ],
    '৬–৮ মাস': [
      'বয়সোপযোগী নরম খাবার অল্প পরিমাণ দিয়ে শুরু করুন।',
      'ধীরে ধীরে বিভিন্ন পুষ্টিকর খাবারের সঙ্গে পরিচয় করান।',
      'জোর করে খাওয়াবেন না।',
    ],
    '৯–১১ মাস': [
      'নরম ও কুচানো খাবার দিন।',
      'বয়সোপযোগী হাতে ধরার নিরাপদ খাবার যোগ করতে পারেন।',
      'খাবারে বৈচিত্র্য বাড়ান।',
    ],
    '১২–২৩ মাস': [
      'পরিবারের পুষ্টিকর খাবার বয়সোপযোগীভাবে দিন।',
      'প্রয়োজন অনুযায়ী পুষ্টিকর নাস্তা দিন।',
    ],
    '২ বছর+': [
      'প্রতিদিন বিভিন্ন খাদ্যগোষ্ঠী রাখুন।',
      'পানি, ফল, শাকসবজি, প্রোটিন ও শস্যে ভারসাম্য রাখুন।',
      'খাবারকে শাস্তি বা ঘুষ হিসেবে ব্যবহার করবেন না।',
    ],
  };

  final List<String> _groups = const [
    'শস্য/ভাত/রুটি',
    'ডাল/বাদামজাত',
    'ডিম',
    'মাছ/মাংস',
    'দুধ/দুগ্ধজাত',
    'শাকসবজি',
    'ফল',
  ];

  @override
  Widget build(BuildContext context) {
    return _SimpleScaffold(
      title: 'পুষ্টি ও খাবার পরিকল্পনা',
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text('বয়স নির্বাচন করুন', style: _Styles.headSmall),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _age,
            dropdownColor: const Color(0xFF192129),
            items: _plans.keys
                .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _age = v ?? _age),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: const Color(0xFF192129),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_age বয়সের সাধারণ নির্দেশনা',
                  style: const TextStyle(
                    color: Color(0xFFF59E0B),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 9),
                ...(_plans[_age] ?? const []).map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Text(
                      '• $e',
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text('আজ কী কী খাদ্যগোষ্ঠী ছিল?', style: _Styles.headSmall),
          const SizedBox(height: 8),
          ..._groups.map(
            (g) => CheckboxListTile(
              value: _today.contains(g),
              activeColor: const Color(0xFFF59E0B),
              onChanged: (v) => setState(() {
                if (v ?? false) {
                  _today.add(g);
                } else {
                  _today.remove(g);
                }
              }),
              title: Text(g, style: const TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 10),
          _InfoBox(
            text:
                'আজ ${_today.length} ধরনের খাদ্যগোষ্ঠী নির্বাচন করেছেন। '
                'একটি দিনের সংখ্যা দিয়ে পুষ্টি বিচার করবেন না; কয়েকদিনের বৈচিত্র্য '
                'ও শিশুর বৃদ্ধি একসঙ্গে দেখুন।',
            color: const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }
}

// -------------------- ওষুধ স্মরণ --------------------

class _MedicinePage extends StatefulWidget {
  const _MedicinePage();

  @override
  State<_MedicinePage> createState() => _MedicinePageState();
}

class _MedicinePageState extends State<_MedicinePage> {
  static const _key = 'mom_child_medicine_reminders';

  final _name = TextEditingController();
  final _dose = TextEditingController();
  TimeOfDay _time = TimeOfDay.now();
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _dose.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      _items = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    if (mounted) setState(() {});
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_items));
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null && mounted) {
      setState(() => _time = picked);
    }
  }

  Future<void> _add() async {
    if (_name.text.trim().isEmpty || _dose.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ওষুধের নাম ও চিকিৎসকের নির্দেশিত পরিমাণ লিখুন।'),
        ),
      );
      return;
    }

    final id = DateTime.now().millisecondsSinceEpoch.remainder(2147483647);

    _items.add({
      'id': id,
      'name': _name.text.trim(),
      'dose': _dose.text.trim(),
      'hour': _time.hour,
      'minute': _time.minute,
    });
    await _persist();

    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      _time.hour,
      _time.minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await NotificationService.instance.scheduleDailyReminder(
      id: id,
      title: 'ওষুধের সময় হয়েছে',
      body: '${_name.text.trim()} • ${_dose.text.trim()}',
      scheduledDate: scheduled,
      channelId: 'medicine_reminder_channel',
      channelName: 'Medicine Reminder',
      channelDescription: 'Child medicine reminder notifications',
      payload: 'medicine:$id',
    );

    _name.clear();
    _dose.clear();
    if (mounted) setState(() {});
  }

  Future<void> _remove(Map<String, dynamic> item) async {
    final id = item['id'] as int;
    await NotificationService.instance.cancel(id);
    _items.removeWhere((e) => e['id'] == id);
    await _persist();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _SimpleScaffold(
      title: 'ওষুধ স্মরণ',
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const _InfoBox(
            text:
                'শুধু চিকিৎসক বা যোগ্য স্বাস্থ্যকর্মীর দেওয়া ওষুধ ও পরিমাণ লিখুন। '
                'অ্যাপ নিজে ওষুধ বা ডোজ নির্ধারণ করে না।',
            color: Colors.amber,
          ),
          const SizedBox(height: 16),
          _TextField(
            controller: _name,
            label: 'ওষুধের নাম',
            icon: Icons.medication_rounded,
          ),
          const SizedBox(height: 10),
          _TextField(
            controller: _dose,
            label: 'চিকিৎসকের নির্দেশিত পরিমাণ',
            icon: Icons.straighten_rounded,
          ),
          const SizedBox(height: 10),
          ListTile(
            tileColor: Colors.white.withValues(alpha: 0.06),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            leading: const Icon(
              Icons.schedule_rounded,
              color: Color(0xFFFB7185),
            ),
            title: const Text(
              'স্মরণ করার সময়',
              style: TextStyle(color: Colors.white),
            ),
            trailing: Text(
              _time.format(context),
              style: const TextStyle(
                color: Color(0xFFFB7185),
                fontWeight: FontWeight.w800,
              ),
            ),
            onTap: _pickTime,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.notifications_active_rounded),
            label: const Text('রিমাইন্ডার যোগ করুন'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: const Color(0xFFFB7185),
            ),
          ),
          const SizedBox(height: 24),
          const Text('চলমান রিমাইন্ডার', style: _Styles.headSmall),
          const SizedBox(height: 8),
          if (_items.isEmpty)
            const _EmptyBox('কোনো ওষুধ রিমাইন্ডার নেই।')
          else
            ..._items.map(
              (item) => Card(
                color: const Color(0xFF192129),
                child: ListTile(
                  title: Text(
                    item['name']?.toString() ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '${item['dose']} • '
                    '${TimeOfDay(hour: item['hour'], minute: item['minute']).format(context)}',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white38,
                    ),
                    onPressed: () => _remove(item),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// -------------------- স্বাস্থ্য রেকর্ড --------------------

class _HealthRecordPage extends StatefulWidget {
  const _HealthRecordPage();

  @override
  State<_HealthRecordPage> createState() => _HealthRecordPageState();
}

class _HealthRecordPageState extends State<_HealthRecordPage> {
  static const _key = 'mom_child_health_record';

  final _name = TextEditingController();
  final _dob = TextEditingController();
  final _blood = TextEditingController();
  final _allergy = TextEditingController();
  final _condition = TextEditingController();
  final _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_name, _dob, _blood, _allergy, _condition, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;

    final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    _name.text = map['name']?.toString() ?? '';
    _dob.text = map['dob']?.toString() ?? '';
    _blood.text = map['blood']?.toString() ?? '';
    _allergy.text = map['allergy']?.toString() ?? '';
    _condition.text = map['condition']?.toString() ?? '';
    _notes.text = map['notes']?.toString() ?? '';
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'name': _name.text.trim(),
        'dob': _dob.text.trim(),
        'blood': _blood.text.trim(),
        'allergy': _allergy.text.trim(),
        'condition': _condition.text.trim(),
        'notes': _notes.text.trim(),
      }),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('স্বাস্থ্য রেকর্ড সংরক্ষণ হয়েছে।')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SimpleScaffold(
      title: 'শিশু স্বাস্থ্য রেকর্ড',
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text('গুরুত্বপূর্ণ স্বাস্থ্য তথ্য', style: _Styles.head),
          const SizedBox(height: 6),
          const Text(
            'চিকিৎসকের কাছে গেলে প্রয়োজনীয় তথ্য দ্রুত দেখাতে সাহায্য করবে।',
            style: _Styles.sub,
          ),
          const SizedBox(height: 16),
          _TextField(
            controller: _name,
            label: 'শিশুর নাম',
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 10),
          _TextField(
            controller: _dob,
            label: 'জন্মতারিখ',
            icon: Icons.cake_outlined,
          ),
          const SizedBox(height: 10),
          _TextField(
            controller: _blood,
            label: 'রক্তের গ্রুপ',
            icon: Icons.bloodtype_outlined,
          ),
          const SizedBox(height: 10),
          _TextField(
            controller: _allergy,
            label: 'পরিচিত অ্যালার্জি',
            icon: Icons.warning_amber_rounded,
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          _TextField(
            controller: _condition,
            label: 'দীর্ঘমেয়াদি রোগ/বিশেষ অবস্থা',
            icon: Icons.health_and_safety_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          _TextField(
            controller: _notes,
            label: 'চিকিৎসকের গুরুত্বপূর্ণ নোট',
            icon: Icons.description_outlined,
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_rounded),
            label: const Text('রেকর্ড সংরক্ষণ করুন'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
              backgroundColor: const Color(0xFF2DD4BF),
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// 4. বয়সভিত্তিক যত্ন
// ================================================================

class _AgeBasedCarePage extends StatelessWidget {
  const _AgeBasedCarePage();

  static const List<Map<String, dynamic>> data = [
    {
      'title': '০–৬ মাস',
      'items': [
        [
          'শারীরিক বৃদ্ধি',
          'ওজন, দৈর্ঘ্য ও সাধারণ শারীরিক পরিবর্তন নিয়মিত পর্যবেক্ষণ করুন।',
        ],
        [
          'মানসিক বৃদ্ধি',
          'মুখ, কণ্ঠ ও পরিচিত মানুষের প্রতি প্রতিক্রিয়া লক্ষ্য করুন।',
        ],
        ['খাওয়া', 'বয়স অনুযায়ী নিরাপদ খাওয়ানোর নির্দেশনা অনুসরণ করুন।'],
        ['ঘুম', 'নিরাপদ ঘুমের পরিবেশ ও রুটিন বজায় রাখুন।'],
        ['খেলাধুলা', 'নিরাপদ স্পর্শ, কথা ও মুখোমুখি মিথস্ক্রিয়া দিন।'],
        ['শেখা', 'কথা বলুন, গান করুন এবং শিশুর সাড়ায় সাড়া দিন।'],
        [
          'সতর্কতা',
          'খাওয়া কমে যাওয়া, শ্বাসকষ্ট, নিস্তেজতা বা বিকাশ নিয়ে উদ্বেগে চিকিৎসকের পরামর্শ নিন।',
        ],
      ],
    },
    {
      'title': '৬–১২ মাস',
      'items': [
        [
          'শারীরিক বৃদ্ধি',
          'নড়াচড়া, বসা, দাঁড়ানোর চেষ্টা ও হাতের দক্ষতা পর্যবেক্ষণ করুন।',
        ],
        [
          'মানসিক বৃদ্ধি',
          'পরিচিত মানুষ, ইশারা ও শব্দে প্রতিক্রিয়া লক্ষ্য করুন।',
        ],
        ['খাওয়া', 'বয়সোপযোগী পরিপূরক খাবারের বৈচিত্র্য ধীরে বাড়ান।'],
        ['ঘুম', 'একটি নিয়মিত রাতের রুটিন গড়ে তুলুন।'],
        ['খেলাধুলা', 'নিরাপদ মেঝেতে অনুসন্ধান ও নড়াচড়ার সুযোগ দিন।'],
        ['শেখা', 'নাম ধরে জিনিস দেখান, শব্দ অনুকরণ করুন ও ছবি দেখান।'],
        [
          'সতর্কতা',
          'আগে পারা দক্ষতা হারানো বা বিকাশ নিয়ে উদ্বেগ হলে মূল্যায়ন করান।',
        ],
      ],
    },
    {
      'title': '১–৩ বছর',
      'items': [
        [
          'শারীরিক বৃদ্ধি',
          'হাঁটা, দৌড় ও হাতের সূক্ষ্ম কাজের অগ্রগতি লক্ষ্য করুন।',
        ],
        ['মানসিক বৃদ্ধি', 'আবেগ প্রকাশ ও সীমিত স্বাধীন সিদ্ধান্তের সুযোগ দিন।'],
        ['খাওয়া', 'পরিবারের পুষ্টিকর খাবার থেকে বয়সোপযোগী অংশ দিন।'],
        ['ঘুম', 'একই সময়ে ঘুম ও ওঠার অভ্যাস রাখুন।'],
        ['খেলাধুলা', 'স্বাধীন খেলা ও অভিভাবকের সঙ্গে খেল—দুটিই রাখুন।'],
        ['শেখা', 'কথা, ছবি, ছড়া ও সহজ সমস্যা সমাধানের খেলা দিন।'],
        [
          'সতর্কতা',
          'ভাষা, হাঁটা, শ্রবণ বা সামাজিক যোগাযোগ নিয়ে উদ্বেগে বিশেষজ্ঞের সঙ্গে কথা বলুন।',
        ],
      ],
    },
    {
      'title': '৩–৫ বছর',
      'items': [
        ['শারীরিক বৃদ্ধি', 'দৌড়, লাফ, ভারসাম্য ও হাতের দক্ষতার সুযোগ দিন।'],
        ['মানসিক বৃদ্ধি', 'অনুভূতির নাম শেখান ও সামাজিক খেলার সুযোগ দিন।'],
        ['খাওয়া', 'নিয়মিত খাবার ও পুষ্টিকর নাস্তার রুটিন রাখুন।'],
        ['ঘুম', 'শোয়ার আগে শান্ত রুটিন বজায় রাখুন।'],
        ['খেলাধুলা', 'কল্পনামূলক, সৃজনশীল ও শারীরিক খেলা উৎসাহ দিন।'],
        ['শেখা', 'গল্প, রং, সংখ্যা, ছড়া ও প্রশ্নের মাধ্যমে শেখান।'],
        [
          'সতর্কতা',
          'দক্ষতা হারানো বা দৈনন্দিন কাজে বড় সমস্যা হলে মূল্যায়ন প্রয়োজন।',
        ],
      ],
    },
    {
      'title': '৫–৮ বছর',
      'items': [
        ['শারীরিক বৃদ্ধি', 'নিয়মিত সক্রিয় খেলা ও বৃদ্ধি পর্যবেক্ষণ করুন।'],
        [
          'মানসিক বৃদ্ধি',
          'আত্মবিশ্বাস, বন্ধুত্ব ও আবেগ নিয়ন্ত্রণে সাহায্য করুন।',
        ],
        ['খাওয়া', 'সুষম খাবার ও স্বাস্থ্যকর পারিবারিক খাদ্যাভ্যাস রাখুন।'],
        ['ঘুম', 'স্কুল ও ঘুমের সময়ে নিয়মিততা রাখুন।'],
        ['খেলাধুলা', 'প্রতিদিন নড়াচড়া ও বাইরের খেলার সুযোগ দিন।'],
        ['শেখা', 'পড়া, লেখা, সমস্যা সমাধান ও আগ্রহভিত্তিক শেখা উৎসাহ দিন।'],
        [
          'সতর্কতা',
          'স্কুলে হঠাৎ সমস্যা বা আচরণের বড় পরিবর্তন গুরুত্ব দিয়ে দেখুন।',
        ],
      ],
    },
    {
      'title': '৮–১২ বছর',
      'items': [
        [
          'শারীরিক বৃদ্ধি',
          'বয়ঃসন্ধির আগের পরিবর্তন নিয়ে বয়সোপযোগীভাবে কথা বলুন।',
        ],
        [
          'মানসিক বৃদ্ধি',
          'আত্মমর্যাদা, বন্ধুত্ব ও ব্যক্তিগত সীমারেখায় সহায়তা দিন।',
        ],
        ['খাওয়া', 'বৈচিত্র্যময় সুষম খাবার বজায় রাখুন।'],
        ['ঘুম', 'রাত জাগা ও অনিয়ন্ত্রিত স্ক্রিন ব্যবহারে সীমা রাখুন।'],
        ['খেলাধুলা', 'নিয়মিত শারীরিক কার্যক্রমে উৎসাহ দিন।'],
        ['শেখা', 'পড়াশোনার পাশাপাশি শখ, সৃজনশীলতা ও বাস্তব দক্ষতা রাখুন।'],
        ['সতর্কতা', 'দীর্ঘ মন খারাপ, স্কুল এড়িয়ে চলা বা বুলিংয়ে সাহায্য নিন।'],
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return _CloudBackedStaticListPage(
      documentId: 'age_based_care',
      title: 'বয়সভিত্তিক যত্ন',
      intro:
          'শিশুর বয়স অনুযায়ী বৃদ্ধি, মানসিক বিকাশ, খাবার, ঘুম, খেলা, শেখা ও সতর্কতা দেখুন।',
      icon: Icons.child_care_rounded,
      color: const Color(0xFFF472B6),
      fallbackData: data,
    );
  }
}

// ================================================================
// 5. শেখা ও বিকাশ
// ================================================================

class _LearningDevelopmentPage extends StatelessWidget {
  const _LearningDevelopmentPage();

  static const List<Map<String, dynamic>> data = [
    {
      'title': 'কথা ও ভাষা শেখা',
      'items': [
        [
          'মূল নীতি',
          'শিশুর সঙ্গে নিয়মিত কথা বলুন, তার শব্দ ও ইশারায় সাড়া দিন এবং বইয়ের ছবি নিয়ে আলোচনা করুন।',
        ],
        [
          'করণীয়',
          'শিশু যা দেখছে তার নাম বলুন, ছোট প্রশ্ন করুন এবং উত্তর দেওয়ার সময় দিন।',
        ],
      ],
    },
    {
      'title': 'মস্তিষ্ক ও শেখার বিকাশ',
      'items': [
        [
          'মূল নীতি',
          'নিরাপদ সম্পর্ক, ঘুম, পুষ্টি, খেলা ও প্রতিক্রিয়াশীল কথোপকথন শেখার ভিত্তি তৈরি করে।',
        ],
        [
          'করণীয়',
          'অনুসন্ধান, বাস্তব কাজ ও বয়সোপযোগী সমস্যার সমাধানের সুযোগ দিন।',
        ],
      ],
    },
    {
      'title': 'মনোযোগ ও সমস্যা সমাধানের দক্ষতা',
      'items': [
        [
          'মূল নীতি',
          'বয়স অনুযায়ী ছোট কাজ, ধাঁধা ও ধাপে ধাপে নির্দেশ মনোযোগ অনুশীলনে সাহায্য করে।',
        ],
        ['করণীয়', 'একবারে একটি কাজ দিন এবং অপ্রয়োজনীয় বিভ্রান্তি কমান।'],
      ],
    },
    {
      'title': 'ভালো অভ্যাস তৈরি',
      'items': [
        [
          'মূল নীতি',
          'একই রুটিন, বড়দের উদাহরণ ও নির্দিষ্ট প্রশংসা অভ্যাস গড়ে তুলতে সাহায্য করে।',
        ],
        ['করণীয়', 'একটি ছোট অভ্যাস দিয়ে শুরু করে নিয়মিত অনুশীলন করুন।'],
      ],
    },
    {
      'title': 'বই পড়ার অভ্যাস',
      'items': [
        [
          'মূল নীতি',
          'বয়সোপযোগী বই একসঙ্গে পড়া ভাষা, কল্পনা ও সম্পর্কের জন্য উপকারী।',
        ],
        [
          'করণীয়',
          'প্রতিদিন অল্প নির্দিষ্ট সময় বইয়ের জন্য রাখুন এবং শিশুকে বই বেছে নিতে দিন।',
        ],
      ],
    },
    {
      'title': 'সৃজনশীলতা',
      'items': [
        [
          'মূল নীতি',
          'অঙ্কন, নির্মাণ, গল্প বানানো ও খোলা ধরনের খেলায় একাধিক সঠিক উত্তর থাকতে পারে।',
        ],
        ['করণীয়', 'নিখুঁত ফলের চেয়ে নতুনভাবে চেষ্টা করার প্রশংসা করুন।'],
      ],
    },
    {
      'title': 'খেলার মাধ্যমে শেখা',
      'items': [
        [
          'মূল নীতি',
          'খেলা ভাষা, সামাজিক যোগাযোগ, কল্পনা, নড়াচড়া ও সমস্যা সমাধানের স্বাভাবিক মাধ্যম।',
        ],
        ['করণীয়', 'স্বাধীন খেলা ও বড়দের সঙ্গে পালাক্রমে খেলা—দুটিই রাখুন।'],
      ],
    },
    {
      'title': 'ইসলামিক শিক্ষা ও নৈতিকতা',
      'items': [
        [
          'মূল নীতি',
          'বয়স অনুযায়ী আদব, সত্যবাদিতা, দয়া, দায়িত্ব ও ইবাদতের পরিচয় ভালোবাসা ও উদাহরণের মাধ্যমে দিন।',
        ],
        [
          'করণীয়',
          'সালাম, কৃতজ্ঞতা, ছোট দোয়া, শেয়ার করা ও ভালো আচরণ দৈনন্দিনভাবে অনুশীলন করান।',
        ],
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return _CloudBackedStaticListPage(
      documentId: 'learning_development',
      title: 'শেখা ও বিকাশ',
      intro:
          'শেখা শুধু বই নয়—ভাষা, মনোযোগ, অভ্যাস, সৃজনশীলতা, খেলা ও নৈতিক বিকাশও গুরুত্বপূর্ণ।',
      icon: Icons.psychology_alt_rounded,
      color: const Color(0xFFA78BFA),
      fallbackData: data,
    );
  }
}

// ================================================================
// 6. তাৎক্ষণিক চিকিৎসা
// ================================================================

class _InstantCarePage extends StatelessWidget {
  const _InstantCarePage();

  static const List<Map<String, dynamic>> data = [
    {
      'title': 'জ্বর',
      'items': [
        [
          'প্রথমে যা দেখবেন',
          'শিশুর বয়স, তাপমাত্রা, খাওয়া-পানি, সচেতনতা ও অন্য গুরুতর লক্ষণ আছে কি না লক্ষ্য করুন।',
        ],
        [
          'কখন দ্রুত চিকিৎসা নেবেন',
          'খুব ছোট শিশুর জ্বর, শ্বাসকষ্ট, খিঁচুনি, অস্বাভাবিক নিস্তেজতা বা পানিশূন্যতার লক্ষণ থাকলে দ্রুত চিকিৎসা নিন।',
        ],
      ],
    },
    {
      'title': 'শ্বাসকষ্ট',
      'items': [
        [
          'প্রথম করণীয়',
          'শিশুকে আরামদায়ক অবস্থায় রাখুন এবং শ্বাসের কষ্টকে গুরুত্ব দিন।',
        ],
        [
          'জরুরি সতর্কতা',
          'ঠোঁট নীলচে হওয়া, বুক খুব দেবে যাওয়া, কথা/কান্না করতে না পারা বা নিস্তেজতা জরুরি লক্ষণ।',
        ],
      ],
    },
    {
      'title': 'বমি বা পাতলা পায়খানা',
      'items': [
        [
          'প্রথমে যা দেখবেন',
          'তরল নিতে পারছে কি না, প্রস্রাব কমেছে কি না এবং বারবার বমি হচ্ছে কি না দেখুন।',
        ],
        [
          'জরুরি সতর্কতা',
          'তরল রাখতে না পারা, খুব কম প্রস্রাব, অস্বাভাবিক ঘুমঘুম ভাব বা রক্ত দেখা গেলে চিকিৎসা নিন।',
        ],
      ],
    },
    {
      'title': 'খিঁচুনি',
      'items': [
        [
          'প্রথম করণীয়',
          'শিশুকে নিরাপদ সমতল জায়গায় কাত করে রাখুন, আশপাশের শক্ত বস্তু সরান এবং সময় লক্ষ্য করুন।',
        ],
        [
          'যা করবেন না',
          'মুখে কিছু ঢোকাবেন না এবং জোর করে হাত-পা চেপে ধরবেন না। জরুরি চিকিৎসা নিন।',
        ],
      ],
    },
    {
      'title': 'পোড়া বা দগ্ধ হওয়া',
      'items': [
        [
          'প্রথম করণীয়',
          'তাপের উৎস থেকে সরিয়ে আক্রান্ত স্থান ঠান্ডা প্রবাহমান পানির নিচে রাখুন।',
        ],
        [
          'যা করবেন না',
          'বরফ, টুথপেস্ট, তেল বা অজানা ঘরোয়া পদার্থ লাগাবেন না। গুরুতর পোড়ায় চিকিৎসা নিন।',
        ],
      ],
    },
    {
      'title': 'আঘাত বা পড়ে যাওয়া',
      'items': [
        [
          'প্রথমে যা দেখবেন',
          'রক্তপাত, অচেতনতা, বারবার বমি, অস্বাভাবিক আচরণ বা নড়াচড়ায় সমস্যা আছে কি না দেখুন।',
        ],
        [
          'জরুরি সতর্কতা',
          'অচেতনতা, খিঁচুনি, তীব্র রক্তপাত, শ্বাসকষ্ট বা মাথায় গুরুতর আঘাতের লক্ষণে দ্রুত চিকিৎসা নিন।',
        ],
      ],
    },
    {
      'title': 'অজানা কিছু খেয়ে ফেলা',
      'items': [
        [
          'প্রথম করণীয়',
          'কী খেয়েছে, কতটা এবং কখন—সম্ভব হলে প্যাকেটসহ তথ্য সংরক্ষণ করুন এবং দ্রুত চিকিৎসা পরামর্শ নিন।',
        ],
        [
          'যা করবেন না',
          'নিজে থেকে বমি করানোর চেষ্টা করবেন না বা অজানা ঘরোয়া প্রতিকার দেবেন না।',
        ],
      ],
    },
    {
      'title': 'তীব্র অ্যালার্জির লক্ষণ',
      'items': [
        [
          'জরুরি লক্ষণ',
          'শ্বাসকষ্ট, মুখ বা জিহ্বা ফুলে যাওয়া, অস্বাভাবিক দুর্বলতা বা দ্রুত ছড়িয়ে পড়া প্রতিক্রিয়া জরুরি হতে পারে।',
        ],
        [
          'করণীয়',
          'আগে থেকে চিকিৎসকের জরুরি পরিকল্পনা থাকলে সেটি অনুসরণ করুন এবং জরুরি চিকিৎসা নিন।',
        ],
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return _CloudBackedStaticListPage(
      documentId: 'instant_care',
      title: 'তাৎক্ষণিক চিকিৎসা',
      intro:
          'প্রাথমিক করণীয় বোঝার জন্য। এটি রোগ নির্ণয় বা জরুরি চিকিৎসার বিকল্প নয়। শিশুর অবস্থা গুরুতর মনে হলে দ্রুত চিকিৎসা নিন।',
      icon: Icons.emergency_rounded,
      color: const Color(0xFFFB7185),
      fallbackData: data,
      warning: true,
    );
  }
}

// ================================================================
// Reusable UI
// ================================================================

class _CloudBackedStaticListPage extends StatefulWidget {
  const _CloudBackedStaticListPage({
    required this.documentId,
    required this.title,
    required this.intro,
    required this.icon,
    required this.color,
    required this.fallbackData,
    this.warning = false,
  });

  final String documentId;
  final String title;
  final String intro;
  final IconData icon;
  final Color color;
  final List<Map<String, dynamic>> fallbackData;
  final bool warning;

  @override
  State<_CloudBackedStaticListPage> createState() =>
      _CloudBackedStaticListPageState();
}

class _CloudBackedStaticListPageState
    extends State<_CloudBackedStaticListPage> {
  final _repository = MomChildCareRepository();

  late List<Map<String, dynamic>> _data;
  late String _intro;
  MomChildCloudStatus _cloudStatus = MomChildCloudStatus.checking;

  @override
  void initState() {
    super.initState();
    _data = widget.fallbackData;
    _intro = widget.intro;
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    try {
      final result = await _repository.getResolvedContentDocument(
        widget.documentId,
      );
      final document = result.data;
      final raw = document['sections'];
      final rawSections = raw is List ? raw : const [];
      final sections = rawSections
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);

      if (!mounted || sections.isEmpty) return;

      setState(() {
        _data = sections;
        _intro = document['intro']?.toString().trim().isNotEmpty == true
            ? document['intro'].toString()
            : widget.intro;
        _cloudStatus = result.cloudStatus;
      });
    } catch (error) {
      // The bundled content remains visible offline or when rules/network are
      // temporarily unavailable. Pulling cloud content is an enhancement, not
      // a blocking dependency for these informational screens.
      debugPrint('${widget.documentId} cloud refresh skipped: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _StaticListPage(
      title: widget.title,
      intro: _intro,
      icon: widget.icon,
      color: widget.color,
      data: _data,
      sourceLabel: _momChildSourceLabel(_cloudStatus),
      warning: widget.warning,
    );
  }
}

String _momChildSourceLabel(MomChildCloudStatus status) {
  return switch (status) {
    MomChildCloudStatus.current => 'Cloud content',
    MomChildCloudStatus.missing => 'Built-in content • Cloud document missing',
    MomChildCloudStatus.invalid => 'Built-in content • Cloud repair needed',
    MomChildCloudStatus.unavailable => 'Built-in content • Offline',
    MomChildCloudStatus.checking => 'Built-in content • Checking cloud',
  };
}

class _StaticListPage extends StatelessWidget {
  final String title;
  final String intro;
  final IconData icon;
  final Color color;
  final List<Map<String, dynamic>> data;
  final String? sourceLabel;
  final bool warning;

  const _StaticListPage({
    required this.title,
    required this.intro,
    required this.icon,
    required this.color,
    required this.data,
    this.sourceLabel,
    this.warning = false,
  });

  void _open(BuildContext context, Map<String, dynamic> item) {
    final raw = item['items'];
    final rawItems = raw is List ? raw : const [];
    final model = ProblemModel(
      title: item['title']?.toString() ?? title,
      items: rawItems.map((raw) {
        if (raw is List && raw.length >= 2) {
          return SubItem(
            title: raw[0].toString(),
            description: raw[1].toString(),
          );
        }
        if (raw is Map) {
          return SubItem(
            title: raw['title']?.toString() ?? '',
            description: raw['description']?.toString() ?? '',
          );
        }
        return SubItem(title: '', description: raw.toString());
      }).toList(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ContentViewerScreen(contentList: [model], screenTitle: model.title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SimpleScaffold(
      title: title,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (warning ? Colors.redAccent : color).withValues(
                alpha: 0.08,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: (warning ? Colors.redAccent : color).withValues(
                  alpha: 0.18,
                ),
              ),
            ),
            child: Text(
              intro,
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
          ),
          if (sourceLabel != null) ...[
            const SizedBox(height: 9),
            Text(
              sourceLabel!,
              style: TextStyle(
                color: color.withValues(alpha: 0.78),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 18),
          ...data.map(
            (item) => Card(
              color: const Color(0xFF192129),
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 7,
                ),
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(icon, color: color),
                ),
                title: Text(
                  item['title']?.toString() ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white38,
                  size: 15,
                ),
                onTap: () => _open(context, item),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const _SimpleScaffold({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primaryapp,
        centerTitle: true,
      ),
      body: child,
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;
  final Color color;

  const _InfoBox({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white60,
          height: 1.5,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String text;

  const _EmptyBox(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white54, height: 1.5),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final IconData icon;

  const _NumberField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        prefixIcon: Icon(icon, color: const Color(0xFF38BDF8)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;

  const _TextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: maxLines,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2DD4BF)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _Styles {
  static const head = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.w800,
  );

  static const headSmall = TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.w800,
  );

  static const sub = TextStyle(color: Colors.white54, height: 1.45);
}
