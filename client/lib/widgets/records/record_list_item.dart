
import 'package:flutter/material.dart';

import '../../models/medical_record_model.dart';

class RecordListItem extends StatelessWidget {
  final MedicalRecordModel record;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const RecordListItem({
    super.key,
    required this.record,
    this.onTap,
    this.onDelete,
  });

  IconData _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'prescription':
        return Icons.medication;
      case 'lab report':
        return Icons.biotech;
      case 'scan':
        return Icons.document_scanner;
      case 'x-ray':
        return Icons.image;
      case 'discharge summary':
        return Icons.local_hospital;
      default:
        return Icons.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade50,
          child: Icon(
            _getIcon(record.recordType),
            color: Colors.teal,
          ),
        ),
        title: Text(
          record.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${record.recordType} • ${record.recordDate == null ? 'Date not available' : record.recordDate!.toLocal().toString().split(' ')[0]}',
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.red,
          ),
          onPressed: onDelete,
          tooltip: 'Delete record',
        ),
      ),
    );
  }
}
