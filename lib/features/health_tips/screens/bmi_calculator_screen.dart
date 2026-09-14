import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/health_content_catalog.dart';
import '../widgets/health_source_sheet.dart';

enum AdultBmiCategory {
  underweight,
  healthyWeight,
  overweight,
  obesityClass1,
  obesityClass2,
  obesityClass3,
}

extension AdultBmiCategoryText on AdultBmiCategory {
  String get label => switch (this) {
    AdultBmiCategory.underweight => 'কম ওজনের range',
    AdultBmiCategory.healthyWeight => 'Healthy-weight range',
    AdultBmiCategory.overweight => 'Overweight range',
    AdultBmiCategory.obesityClass1 => 'Obesity class 1 range',
    AdultBmiCategory.obesityClass2 => 'Obesity class 2 range',
    AdultBmiCategory.obesityClass3 => 'Obesity class 3 range',
  };

  String get guidance => switch (this) {
    AdultBmiCategory.underweight =>
      'কম BMI-এর কারণ ও পুষ্টির প্রয়োজন বুঝতে healthcare professional-এর সঙ্গে কথা বলুন।',
    AdultBmiCategory.healthyWeight =>
      'BMI একটি screening measure মাত্র; ঘুম, activity, diet, blood pressure ও অন্যান্য বিষয়ও গুরুত্বপূর্ণ।',
    AdultBmiCategory.overweight =>
      'BMI-এর পাশাপাশি waist, medical history ও laboratory result বিবেচনায় clinician ঝুঁকি মূল্যায়ন করেন।',
    AdultBmiCategory.obesityClass1 ||
    AdultBmiCategory.obesityClass2 ||
    AdultBmiCategory.obesityClass3 =>
      'Stigma নয়—person-first care গুরুত্বপূর্ণ। নিরাপদ ও ব্যক্তিগত পরিকল্পনার জন্য qualified clinician-এর সহায়তা নিন।',
  };
}

class AdultBmiResult {
  const AdultBmiResult({required this.score, required this.category});

  final double score;
  final AdultBmiCategory category;
}

AdultBmiResult calculateAdultBmi({
  required int age,
  required double heightMeters,
  required double weightKg,
}) {
  if (age < 20 || age > 120) {
    throw ArgumentError.value(age, 'age', 'Adult BMI requires age 20–120.');
  }
  if (!heightMeters.isFinite || heightMeters < 1.2 || heightMeters > 2.5) {
    throw ArgumentError.value(
      heightMeters,
      'heightMeters',
      'Height must be between 1.2 and 2.5 metres.',
    );
  }
  if (!weightKg.isFinite || weightKg < 25 || weightKg > 350) {
    throw ArgumentError.value(
      weightKg,
      'weightKg',
      'Weight must be between 25 and 350 kg.',
    );
  }

  final score = weightKg / (heightMeters * heightMeters);
  final category = switch (score) {
    < 18.5 => AdultBmiCategory.underweight,
    < 25 => AdultBmiCategory.healthyWeight,
    < 30 => AdultBmiCategory.overweight,
    < 35 => AdultBmiCategory.obesityClass1,
    < 40 => AdultBmiCategory.obesityClass2,
    _ => AdultBmiCategory.obesityClass3,
  };

  return AdultBmiResult(score: score, category: category);
}

class BmiCalculatorScreen extends StatefulWidget {
  const BmiCalculatorScreen({super.key});

  @override
  State<BmiCalculatorScreen> createState() => _BmiCalculatorScreenState();
}

class _BmiCalculatorScreenState extends State<BmiCalculatorScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _ageController = TextEditingController(
    text: '25',
  );
  final TextEditingController _feetController = TextEditingController(
    text: '5',
  );
  final TextEditingController _inchController = TextEditingController(
    text: '6',
  );
  final TextEditingController _weightController = TextEditingController(
    text: '65',
  );

  AdultBmiResult? _result;

  @override
  void dispose() {
    _ageController.dispose();
    _feetController.dispose();
    _inchController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  String? _wholeNumberValidator(
    String? value, {
    required int min,
    required int max,
    required String label,
  }) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null) return label + ' সঠিকভাবে লিখুন';
    if (parsed < min || parsed > max) {
      return label + ' ' + min.toString() + '–' + max.toString() + ' দিন';
    }
    return null;
  }

  String? _decimalValidator(
    String? value, {
    required double min,
    required double max,
    required String label,
  }) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || !parsed.isFinite) {
      return label + ' সঠিকভাবে লিখুন';
    }
    if (parsed < min || parsed > max) {
      return label +
          ' ' +
          min.toStringAsFixed(0) +
          '–' +
          max.toStringAsFixed(0) +
          ' দিন';
    }
    return null;
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    final age = int.parse(_ageController.text.trim());
    final feet = double.parse(_feetController.text.trim());
    final inches = double.parse(_inchController.text.trim());
    final weight = double.parse(_weightController.text.trim());
    final heightMeters = ((feet * 30.48) + (inches * 2.54)) / 100;

    setState(() {
      _result = calculateAdultBmi(
        age: age,
        heightMeters: heightMeters,
        weightKg: weight,
      );
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adult BMI screening'),
        centerTitle: true,
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(17, 8, 17, 30),
        children: [
          const HealthSafetyNotice(
            title: 'BMI diagnosis নয়',
            message:
                'এটি শুধু ২০ বছর বা তার বেশি বয়সী প্রাপ্তবয়স্কদের screening tool। শিশু-কিশোর, pregnancy, খুব muscular body বা বিশেষ medical condition-এ সরাসরি এই interpretation ব্যবহার করবেন না।',
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: colors.outline.withValues(alpha: 0.55)),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'আপনার তথ্য',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _NumberField(
                    controller: _ageController,
                    label: 'বয়স',
                    suffix: 'বছর',
                    icon: Icons.calendar_today_outlined,
                    validator: (value) => _wholeNumberValidator(
                      value,
                      min: 20,
                      max: 120,
                      label: 'বয়স',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _NumberField(
                          controller: _feetController,
                          label: 'উচ্চতা',
                          suffix: 'ফুট',
                          icon: Icons.height_rounded,
                          validator: (value) => _wholeNumberValidator(
                            value,
                            min: 3,
                            max: 8,
                            label: 'ফুট',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _NumberField(
                          controller: _inchController,
                          label: 'ইঞ্চি',
                          suffix: 'ইঞ্চি',
                          icon: Icons.straighten_rounded,
                          validator: (value) => _decimalValidator(
                            value,
                            min: 0,
                            max: 11.9,
                            label: 'ইঞ্চি',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _NumberField(
                    controller: _weightController,
                    label: 'ওজন',
                    suffix: 'কেজি',
                    icon: Icons.monitor_weight_outlined,
                    validator: (value) => _decimalValidator(
                      value,
                      min: 25,
                      max: 350,
                      label: 'ওজন',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _calculate,
                    icon: const Icon(Icons.calculate_outlined),
                    label: const Text('BMI হিসাব করুন'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            _BmiResultCard(result: _result!),
          ],
          const SizedBox(height: 14),
          const _BmiRangeCard(),
          const SizedBox(height: 12),
          const Center(child: HealthEvidenceButton(sourceIds: ['cdc_bmi'])),
          const SizedBox(height: 8),
          Text(
            'শরীর নিয়ে নেতিবাচক ধারণা তৈরি নয়—BMI-কে অন্য health information-এর সঙ্গে বিবেচনা করুন।',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.icon,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final IconData icon;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixText: suffix,
      ),
    );
  }
}

class _BmiResultCard extends StatelessWidget {
  const _BmiResultCard({required this.result});

  final AdultBmiResult result;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = _categoryColor(context, result.category);

    return Semantics(
      liveRegion: true,
      label:
          'BMI ' +
          result.score.toStringAsFixed(1) +
          '. ' +
          result.category.label,
      child: Container(
        padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent.withValues(alpha: 0.18), colors.surface],
          ),
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: accent.withValues(alpha: 0.38)),
        ),
        child: Column(
          children: [
            Text(
              'আপনার BMI',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              result.score.toStringAsFixed(1),
              style: TextStyle(
                color: accent,
                fontSize: 48,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              result.category.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              result.category.guidance,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                height: 1.45,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BmiRangeCard extends StatelessWidget {
  const _BmiRangeCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const rows = <(String, String)>[
      ('< 18.5', 'কম ওজনের range'),
      ('18.5–24.9', 'Healthy-weight range'),
      ('25.0–29.9', 'Overweight range'),
      ('30.0–34.9', 'Obesity class 1'),
      ('35.0–39.9', 'Obesity class 2'),
      ('≥ 40.0', 'Obesity class 3'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline.withValues(alpha: 0.52)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CDC adult BMI ranges',
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(
                      row.$1,
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.$2,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
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

Color _categoryColor(BuildContext context, AdultBmiCategory category) {
  final raw = switch (category) {
    AdultBmiCategory.underweight => const Color(0xFF38BDF8),
    AdultBmiCategory.healthyWeight => const Color(0xFF22C55E),
    AdultBmiCategory.overweight => const Color(0xFFF59E0B),
    AdultBmiCategory.obesityClass1 => const Color(0xFFFB923C),
    AdultBmiCategory.obesityClass2 => const Color(0xFFF87171),
    AdultBmiCategory.obesityClass3 => const Color(0xFFEF4444),
  };

  return Theme.of(context).brightness == Brightness.dark
      ? raw
      : Color.lerp(raw, Colors.black, 0.30)!;
}
