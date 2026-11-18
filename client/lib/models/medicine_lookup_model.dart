/// The response returned by the medicine identification API.
///
/// [confidence] is retained as reported by the API and is not assigned any
/// probability or percentage interpretation here.
class MedicineLookupModel {
  MedicineLookupModel({
    required this.identifiedMedicine,
    required this.confidence,
    required Map<String, dynamic> medicineInfo,
    required this.disclaimer,
  }) : medicineInfo = Map<String, dynamic>.unmodifiable(medicineInfo);

  final String identifiedMedicine;
  final double confidence;
  final Map<String, dynamic> medicineInfo;
  final String disclaimer;

  factory MedicineLookupModel.fromJson(Map<String, dynamic> json) {
    final identifiedMedicine = json['identifiedMedicine'];
    if (identifiedMedicine is! String) {
      throw const FormatException(
        'Invalid medicine lookup JSON: "identifiedMedicine" is required and must be a string.',
      );
    }

    final confidence = json['confidence'];
    if (confidence is! num || !confidence.toDouble().isFinite) {
      throw const FormatException(
        'Invalid medicine lookup JSON: "confidence" is required and must be a finite number.',
      );
    }

    final medicineInfo = json['medicineInfo'];
    if (medicineInfo is! Map) {
      throw const FormatException(
        'Invalid medicine lookup JSON: "medicineInfo" is required and must be an object.',
      );
    }
    if (medicineInfo.keys.any((key) => key is! String)) {
      throw const FormatException(
        'Invalid medicine lookup JSON: "medicineInfo" must have string keys.',
      );
    }

    final disclaimer = json['disclaimer'];
    if (disclaimer is! String) {
      throw const FormatException(
        'Invalid medicine lookup JSON: "disclaimer" is required and must be a string.',
      );
    }

    return MedicineLookupModel(
      identifiedMedicine: identifiedMedicine,
      confidence: confidence.toDouble(),
      medicineInfo: Map<String, dynamic>.from(medicineInfo),
      disclaimer: disclaimer,
    );
  }

  Map<String, dynamic> toJson() => {
        'identifiedMedicine': identifiedMedicine,
        'confidence': confidence,
        'medicineInfo': Map<String, dynamic>.from(medicineInfo),
        'disclaimer': disclaimer,
      };
}
