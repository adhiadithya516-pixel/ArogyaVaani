import 'package:flutter/material.dart';

/// Displays the medicine information supplied by a lookup response.
///
/// Values are shown as provided. This widget does not infer missing details or
/// provide dosage recommendations or medical advice.
class MedicineInfoCard extends StatelessWidget {
  const MedicineInfoCard({super.key, required this.medicineInfo});

  final Map<String, dynamic> medicineInfo;

  @override
  Widget build(BuildContext context) {
    final entries = _visibleEntries(medicineInfo);

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF263238), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Semantics(
          container: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Medicine information',
                style: TextStyle(
                  color: Color(0xFF102A43),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (entries.isEmpty)
                const Text(
                  'No medicine information available.',
                  style: TextStyle(
                    color: Color(0xFF263238),
                    fontSize: 18,
                    height: 1.5,
                  ),
                )
              else
                ...entries.map((entry) => _buildEntry(entry.key, entry.value)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntry(String key, dynamic value) {
    final label = _formatLabel(key);
    if (value is Map) {
      final nestedEntries = _visibleEntries(value);
      if (nestedEntries.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF102A43),
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: nestedEntries
                    .map((entry) => _buildEntry(entry.key, entry.value))
                    .toList(),
              ),
            ),
          ],
        ),
      );
    }

    final displayValue = _displayValue(value);
    if (displayValue == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Semantics(
        label: '$label: $displayValue',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF263238),
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              displayValue,
              style: const TextStyle(
                color: Color(0xFF102A43),
                fontSize: 18,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<MapEntry<String, dynamic>> _visibleEntries(Map<dynamic, dynamic> map) {
    return map.entries
        .where((entry) => entry.key is String && _hasContent(entry.value))
        .map((entry) => MapEntry(entry.key as String, entry.value))
        .toList();
  }

  bool _hasContent(dynamic value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is Map) return _visibleEntries(value).isNotEmpty;
    if (value is Iterable) return value.any(_hasContent);
    return true;
  }

  String? _displayValue(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (value is Iterable) {
      final items = value.map(_displayValue).whereType<String>().toList();
      return items.isEmpty ? null : items.join(', ');
    }
    if (value is Map) return null;
    return value.toString();
  }

  String _formatLabel(String key) {
    final words = key
        .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (match) => '${match[1]} ${match[2]}')
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .trim()
        .split(RegExp(r'\s+'));
    return words
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}
