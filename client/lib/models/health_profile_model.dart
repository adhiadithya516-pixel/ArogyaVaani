
// Health Profile Data Model
// Owner: Member 2
// Collection: health_profiles/{userId}

class HealthProfileModel {
  final String userId;
  final String bloodGroup;
  final double? height;
  final double? weight;
  final List<String> allergies;
  final List<String> existingConditions;
  final List<String> currentMedications;

  HealthProfileModel({
    required this.userId,
    this.bloodGroup = '',
    this.height,
    this.weight,
    this.allergies = const [],
    this.existingConditions = const [],
    this.currentMedications = const [],
  });

  factory HealthProfileModel.fromJson(Map<String, dynamic> json) {
    return HealthProfileModel(
      userId: json['userId'] as String? ?? '',
      bloodGroup: json['bloodGroup'] as String? ?? '',
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      allergies: List<String>.from(json['allergies'] ?? []),
      existingConditions:
          List<String>.from(json['existingConditions'] ?? []),
      currentMedications:
          List<String>.from(json['currentMedications'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'bloodGroup': bloodGroup,
        'height': height,
        'weight': weight,
        'allergies': allergies,
        'existingConditions': existingConditions,
        'currentMedications': currentMedications,
      };

  HealthProfileModel copyWith({
    String? bloodGroup,
    double? height,
    double? weight,
    List<String>? allergies,
    List<String>? existingConditions,
    List<String>? currentMedications,
  }) {
    return HealthProfileModel(
      userId: userId,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      allergies: allergies ?? this.allergies,
      existingConditions:
          existingConditions ?? this.existingConditions,
      currentMedications:
          currentMedications ?? this.currentMedications,
    );
  }

  bool get isEmpty => bloodGroup.isEmpty && allergies.isEmpty;

  double? get bmi {
    if (height == null || weight == null || height! <= 0) {
      return null;
    }

    final heightInMeters = height! / 100;
    return weight! / (heightInMeters * heightInMeters);
  }

  String get bmiCategory {
    final bmiValue = bmi;

    if (bmiValue == null) return 'Unknown';
    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25.0) return 'Normal';
    if (bmiValue < 30.0) return 'Overweight';

    return 'Obese';
  }
}
