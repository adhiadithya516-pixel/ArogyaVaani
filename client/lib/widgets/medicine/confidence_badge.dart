import 'package:flutter/material.dart';

/// Shows the confidence value exactly as a finite number supplied by the API.
///
/// The value's scale is not inferred, and no percentage or probability symbol
/// is added. Invalid or non-finite inputs are represented as unavailable.
class ConfidenceBadge extends StatelessWidget {
  const ConfidenceBadge({super.key, required this.confidence});

  /// A numeric confidence value; other values are handled as unavailable.
  final Object? confidence;

  String get _displayValue {
    final value = confidence;
    if (value is! num || !value.isFinite) return 'Unavailable';
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final value = _displayValue;
    return Semantics(
      label: 'Confidence: $value',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          border: Border.all(color: const Color(0xFF123B5D), width: 2),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          'Confidence: $value',
          style: const TextStyle(
            color: Color(0xFF102A43),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}
