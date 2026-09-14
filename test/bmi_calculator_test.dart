import 'package:flutter_test/flutter_test.dart';

import 'package:ash_shifa_ruqyah/features/health_tips/screens/bmi_calculator_screen.dart';

void main() {
  test('calculates a healthy-range adult BMI', () {
    final result = calculateAdultBmi(
      age: 30,
      heightMeters: 1.75,
      weightKg: 70,
    );

    expect(result.score, closeTo(22.86, 0.01));
    expect(result.category, AdultBmiCategory.healthyWeight);
  });

  test('uses CDC adult category boundaries', () {
    expect(_categoryFor(18.49), AdultBmiCategory.underweight);
    expect(_categoryFor(18.5), AdultBmiCategory.healthyWeight);
    expect(_categoryFor(24.99), AdultBmiCategory.healthyWeight);
    expect(_categoryFor(25), AdultBmiCategory.overweight);
    expect(_categoryFor(30), AdultBmiCategory.obesityClass1);
    expect(_categoryFor(35), AdultBmiCategory.obesityClass2);
    expect(_categoryFor(40), AdultBmiCategory.obesityClass3);
  });

  test('rejects child or teen use of the adult calculator', () {
    expect(
      () => calculateAdultBmi(
        age: 19,
        heightMeters: 1.7,
        weightKg: 65,
      ),
      throwsArgumentError,
    );
  });

  test('rejects non-physical input ranges', () {
    expect(
      () => calculateAdultBmi(
        age: 30,
        heightMeters: 0,
        weightKg: 65,
      ),
      throwsArgumentError,
    );
    expect(
      () => calculateAdultBmi(
        age: 30,
        heightMeters: 1.7,
        weightKg: double.nan,
      ),
      throwsArgumentError,
    );
  });
}

AdultBmiCategory _categoryFor(double targetBmi) {
  final result = calculateAdultBmi(
    age: 30,
    heightMeters: 2,
    weightKg: targetBmi * 4,
  );
  return result.category;
}
