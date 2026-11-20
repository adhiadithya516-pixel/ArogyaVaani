
import 'package:flutter/material.dart';

import '../../models/health_profile_model.dart';

class HealthProfileCard extends StatelessWidget {
  final HealthProfileModel profile;
  final VoidCallback? onEdit;

  const HealthProfileCard({
    super.key,
    required this.profile,
    this.onEdit,
  });

  Widget _buildItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.teal, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Health Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, color: Colors.teal),
                  tooltip: 'Edit profile',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildItem(
                  'Blood Group',
                  profile.bloodGroup.isEmpty
                      ? 'Not set'
                      : profile.bloodGroup,
                  Icons.bloodtype,
                ),
                _buildItem(
                  'Height',
                  profile.height == null
                      ? 'Not set'
                      : '${profile.height} cm',
                  Icons.height,
                ),
                _buildItem(
                  'Weight',
                  profile.weight == null
                      ? 'Not set'
                      : '${profile.weight} kg',
                  Icons.monitor_weight,
                ),
              ],
            ),
            if (profile.bmi != null) ...[
              const SizedBox(height: 20),
              const Divider(),
              Text(
                'BMI: ${profile.bmi!.toStringAsFixed(1)} (${profile.bmiCategory})',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
