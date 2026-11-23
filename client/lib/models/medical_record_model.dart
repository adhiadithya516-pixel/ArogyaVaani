
// Medical Record Data Model
// Owner: Member 2
// Collection: medical_records

class MedicalRecordModel {
  final String? id;
  final String title;
  final String recordType;
  final String description;
  final String documentUrl;
  final DateTime? recordDate;
  final DateTime? createdAt;

  MedicalRecordModel({
    this.id,
    required this.title,
    required this.recordType,
    this.description = '',
    this.documentUrl = '',
    this.recordDate,
    this.createdAt,
  });

  factory MedicalRecordModel.fromJson(
    Map<String, dynamic> json, {
    String? id,
  }) {
    return MedicalRecordModel(
      id: id ?? json['id'] as String?,
      title: json['title'] as String? ?? '',
      recordType: json['recordType'] as String? ?? 'Other',
      description: json['description'] as String? ?? '',
      documentUrl: json['documentUrl'] as String? ?? '',
      recordDate: _parseDate(json['recordDate']),
      createdAt: _parseDate(json['createdAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is Map && value['_seconds'] is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        (value['_seconds'] as num) * 1000 ~/ 1,
      );
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'recordType': recordType,
        'description': description,
        'documentUrl': documentUrl,
        'recordDate': recordDate?.toIso8601String(),
      };
}
