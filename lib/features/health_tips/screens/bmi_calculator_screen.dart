import 'package:flutter/material.dart';

class BmiResult {
  final double score;
  final String category;
  final String message;
  final String food;
  final String exercise;
  final String adjustment;
  final Color color;

  BmiResult({
    required this.score,
    required this.category,
    required this.message,
    required this.food,
    required this.exercise,
    required this.adjustment,
    required this.color,
  });
}

class BmiCalculatorScreen extends StatefulWidget {
  const BmiCalculatorScreen({super.key});

  @override
  State<BmiCalculatorScreen> createState() => _BmiCalculatorScreenState();
}

class _BmiCalculatorScreenState extends State<BmiCalculatorScreen> {
  static const Color bgColor = Color(0xFF0F1115);
  static const Color cardColor = Color(0xFF1C1F26);
  static const Color accentColor = Color(0xFF00E676);

  String selectedGender = "male";
  final ageCtrl = TextEditingController(text: "25");
  final feetCtrl = TextEditingController(text: "5");
  final inchCtrl = TextEditingController(text: "10");
  final weightCtrl = TextEditingController(text: "72");

  BmiResult? result;

  @override
  void dispose() {
    ageCtrl.dispose();
    feetCtrl.dispose();
    inchCtrl.dispose();
    weightCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final double? f = double.tryParse(feetCtrl.text);
    final double? i = double.tryParse(inchCtrl.text);
    final double? w = double.tryParse(weightCtrl.text);
    final int? a = int.tryParse(ageCtrl.text);

    if (a == null || a < 2 || f == null || w == null) {
      _showError("সব তথ্য সঠিকভাবে দিন");
      return;
    }

    final double heightM = ((f * 30.48) + ((i ?? 0) * 2.54)) / 100;
    final double bmiVal = w / (heightM * heightM);
    final double minW = 18.5 * (heightM * heightM);
    final double maxW = 24.9 * (heightM * heightM);

    setState(() {
      result = _getResultModel(bmiVal, w, minW, maxW);
    });
  }

  BmiResult _getResultModel(
    double bmi,
    double currentW,
    double minW,
    double maxW,
  ) {
    if (bmi < 18.5) {
      return BmiResult(
        score: bmi,
        category: "UNDERWEIGHT",
        message: "🎯 ওজন বাড়ানো প্রয়োজন",
        food: "• প্রোটিন ও কার্বোহাইড্রেট বাড়ান\n• বাদাম, ডিম ও দুধ খান",
        exercise: "• স্ট্রেন্থ ট্রেনিং ও যোগব্যায়াম",
        adjustment:
            "আরও ${(minW - currentW).toStringAsFixed(1)} কেজি ওজন প্রয়োজন।",
        color: Colors.lightBlueAccent,
      );
    } else if (bmi < 25) {
      return BmiResult(
        score: bmi,
        category: "NORMAL",
        message: "🎉 আপনি একদম ফিট আছেন!",
        food: "• সুষম খাদ্য ও পর্যাপ্ত পানি",
        exercise: "• নিয়মিত হাঁটা ও কার্ডিও",
        adjustment: "আদর্শ ওজন সীমার মধ্যেই আছেন।",
        color: accentColor,
      );
    } else {
      return BmiResult(
        score: bmi,
        category: bmi < 30 ? "OVERWEIGHT" : "OBESE",
        message: bmi < 30
            ? "⚠️ ওজন নিয়ন্ত্রণ করুন"
            : "🛑 স্বাস্থ্য ঝুঁকি রয়েছে",
        food: "• চিনি ও ফাস্টফুড বর্জন করুন",
        exercise: "• দৈনিক ৪০ মিনিট ব্যায়াম",
        adjustment:
            "${(currentW - maxW).toStringAsFixed(1)} কেজি ওজন কমানো প্রয়োজন।",
        color: bmi < 30 ? Colors.orangeAccent : Colors.redAccent,
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          "BMI EXPERT",
          style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          children: [
            Row(
              children: [
                _genderCard("male", Icons.male, "পুরুষ", Colors.blue),
                const SizedBox(width: 16),
                _genderCard("female", Icons.female, "মহিলা", Colors.pink),
              ],
            ),
            const SizedBox(height: 24),
            _buildInputSection(),
            const SizedBox(height: 32),
            _buildCalculateButton(),
            if (result != null) ...[
              const SizedBox(height: 32),
              _buildResultCard(),
              const SizedBox(height: 16),
              _suggestionCard("🍎 ডায়েট টিপস", result!.food, result!.color),
              const SizedBox(height: 12),
              _suggestionCard("🏋️ ব্যায়াম", result!.exercise, result!.color),
            ],
          ],
        ),
      ),
    );
  }

  // ✅ No RadioListTile anymore → No deprecation

  Widget _genderCard(String val, IconData icon, String label, Color color) {
    bool isSelected = selectedGender == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedGender = val),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : Colors.white.withValues(alpha: 0.05),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.white30, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Column(
      children: [
        _customField("আপনার বয়স", ageCtrl, Icons.calendar_today, "বছর"),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _customField("উচ্চতা", feetCtrl, Icons.height, "ফিট"),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _customField("ইঞ্চি", inchCtrl, Icons.straighten, "ইঞ্চি"),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _customField("আপনার ওজন", weightCtrl, Icons.scale_outlined, "কেজি"),
      ],
    );
  }

  Widget _customField(
    String label,
    TextEditingController ctrl,
    IconData icon,
    String suffix,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: accentColor),
          suffixText: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(18),
        ),
      ),
    );
  }

  Widget _buildCalculateButton() {
    return ElevatedButton(
      onPressed: _calculate,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 55),
        backgroundColor: accentColor,
        foregroundColor: Colors.black,
      ),
      child: const Text("RESULT ➔"),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: result!.color.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(result!.category, style: TextStyle(color: result!.color)),
          Text(
            result!.score.toStringAsFixed(1),
            style: TextStyle(fontSize: 50, color: result!.color),
          ),
          Text(result!.message),
        ],
      ),
    );
  }

  Widget _suggestionCard(String title, String content, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
