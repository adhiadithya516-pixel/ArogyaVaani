import 'package:flutter/material.dart';

import '../../models/medical_record_model.dart';
import '../../widgets/records/document_preview.dart';

class RecordDetailScreen extends StatelessWidget {
  final MedicalRecordModel record;
  final VoidCallback? onDelete;

  const RecordDetailScreen({
    super.key,
    required this.record,
    this.onDelete,
  });

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Details'),
        actions: [
          if (onDelete != null)
            IconButton(
              tooltip: 'Delete Record',
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              record.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),

            Chip(
              avatar: const Icon(Icons.medical_information, size: 18),
              label: Text(record.recordType),
            ),
            const SizedBox(height: 16),

            _buildInfo(
              context,
              'Record Date',
             record.recordDate == null
                 ? 'Not available'
                 : _formatDate(record.recordDate!),
              Icons.calendar_today,
            ),
            const SizedBox(height: 12),

            _buildInfo(
              context,
              'Created On',
              record.createdAt == null
                ? 'Not available'
                : _formatDate(record.createdAt!),
              Icons.access_time,
            ),
            const SizedBox(height: 24),

            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            Text(
              record.description.isEmpty
                  ? 'No description available.'
                  : record.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),

            Text(
              'Medical Document',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),

            DocumentPreview(
  documentUrl: record.documentUrl,
  title: record.title,
  onTap: () {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Document opening will be added soon.'),
      ),
    );
  },
),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
