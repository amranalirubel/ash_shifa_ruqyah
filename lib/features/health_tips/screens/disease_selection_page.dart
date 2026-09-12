// lib/features/health_tips/screens/disease_selection_page.dart
import 'package:flutter/material.dart';
import '../../../data/repositories/health_repository.dart';
//import 'diet_detail_screen.dart';

class DiseaseSelectionPage extends StatefulWidget {
  const DiseaseSelectionPage({super.key});

  @override
  State<DiseaseSelectionPage> createState() => _DiseaseSelectionPageState();
}

class _DiseaseSelectionPageState extends State<DiseaseSelectionPage> {
  final HealthRepository repo = HealthRepository();
  Map<String, dynamic> diseaseMap = {};
  String? selectedDisease;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await repo.getDiseaseFoodMap();
    setState(() {
      diseaseMap = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final diseases = diseaseMap.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: const Text(
          "Health Companion",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildHeader(),
                  const SizedBox(height: 25),

                  const Text(
                    "আপনার সমস্যাটি নির্বাচন করুন",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 10),

                  // ================== DROPDOWN (আগের মতো) ==================
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1F26),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.greenAccent.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedDisease,
                        hint: const Text(
                          "যেমন: ডায়াবেটিস, উচ্চ রক্তচাপ...",
                          style: TextStyle(color: Colors.white38, fontSize: 15),
                        ),
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1C1F26),
                        icon: const Icon(
                          Icons.unfold_more,
                          color: Colors.greenAccent,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        items: diseases.map((disease) {
                          return DropdownMenuItem<String>(
                            value: disease,
                            child: Text(disease),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedDisease = value);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ================== CONTENT (Animated Inline Detail) ==================
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: selectedDisease == null
                        ? _buildQuickTipsSection()
                        : _buildDetailSection(selectedDisease!),
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "সুস্থ থাকুন,",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 18,
              ),
            ),
            const Text(
              "আপনার ডায়েট জানুন",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Spacer(),
        const CircleAvatar(
          backgroundColor: Color(0xFF1C1F26),
          child: Icon(Icons.health_and_safety, color: Colors.greenAccent),
        ),
      ],
    );
  }

  // ================== Quick Tips Grid (যখন কিছু সিলেক্ট না করা হয়) ==================
  Widget _buildQuickTipsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "স্বাস্থ্য টিপস আপনার জন্য",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          childAspectRatio: 1.1,
          children: [
            _quickTipCard(
              Icons.water_drop,
              "পানি",
              "দিনে অন্তত ৩ লিটার",
              Colors.blueAccent,
            ),
            _quickTipCard(
              Icons.directions_run,
              "ব্যায়াম",
              "প্রতিদিন ৩০ মিনিট",
              Colors.orangeAccent,
            ),
            _quickTipCard(
              Icons.bedtime,
              "সুনিদ্রা",
              "৭-৮ ঘণ্টা ঘুমান",
              Colors.purpleAccent,
            ),
            _quickTipCard(
              Icons.restaurant,
              "সুষম খাবার",
              "পরিমিত প্রোটিন",
              Colors.greenAccent,
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickTipCard(IconData icon, String title, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F26),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            sub,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ================== Detail Section (Inline - আগের মতো) ==================
  Widget _buildDetailSection(String disease) {
    final data = diseaseMap[disease]!;

    return Column(
      key: ValueKey(disease),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 5,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.greenAccent,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              disease,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _section(
          "✅ যা খাবেন",
          data["eat"] as List<dynamic>,
          Colors.greenAccent,
        ),
        const SizedBox(height: 15),
        _section(
          "❌ যা এড়িয়ে চলবেন",
          data["avoid"] as List<dynamic>,
          Colors.redAccent,
        ),
        if (data["extra"] != null) ...[
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb,
                  color: Colors.amberAccent,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    data["extra"] as String,
                    style: const TextStyle(color: Colors.white70, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 30),
        const Center(
          child: Text(
            "বি:দ্র: জরুরি প্রয়োজনে ডাক্তারের পরামর্শ নিন।",
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _section(String title, List<dynamic> items, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F26),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: Colors.white10, height: 20),
          ...items.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                "• $e",
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
