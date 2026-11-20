
import 'package:flutter/material.dart';

class AllergyChip extends StatelessWidget {
  final String allergy;
  final VoidCallback? onDeleted;

  const AllergyChip({
    super.key,
    required this.allergy,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(
        Icons.warning_amber_rounded,
        color: Colors.deepOrange,
        size: 18,
      ),
      label: Text(allergy),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: onDeleted,
      backgroundColor: Colors.orange.shade50,
      side: BorderSide(
        color: Colors.orange.shade200,
      ),
      labelStyle: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
