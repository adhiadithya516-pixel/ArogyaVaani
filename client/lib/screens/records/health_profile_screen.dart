
import 'package:flutter/material.dart';

import '../../providers/records_provider.dart';
import '../../widgets/records/health_profile_card.dart';

class HealthProfileScreen extends StatefulWidget {
  final RecordsProvider recordsProvider;

  const HealthProfileScreen({
    super.key,
    required this.recordsProvider,
  });

  @override
  State<HealthProfileScreen> createState() =>
      _HealthProfileScreenState();
}

class _HealthProfileScreenState extends State<HealthProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _bloodGroupController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _medicationsController = TextEditingController();

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    await widget.recordsProvider.loadData();

    if (!mounted) return;

    final profile = widget.recordsProvider.profile;

    if (profile != null) {
      _bloodGroupController.text = profile.bloodGroup;
      _heightController.text = profile.height?.toString() ?? '';
_weightController.text = profile.weight?.toString() ?? '';
      _allergiesController.text = profile.allergies.join(', ');
      _conditionsController.text =
          profile.existingConditions.join(', ');
      _medicationsController.text =
          profile.currentMedications.join(', ');
    }

    setState(() {
      _initialized = true;
    });
  }

  List<String> _parseList(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = widget.recordsProvider.profile;

    if (profile == null) return;

    final updatedProfile = profile.copyWith(
      bloodGroup: _bloodGroupController.text.trim(),
      height: double.tryParse(_heightController.text),
      weight: double.tryParse(_weightController.text),
      allergies: _parseList(_allergiesController.text),
      existingConditions: _parseList(_conditionsController.text),
      currentMedications: _parseList(_medicationsController.text),
    );

    await widget.recordsProvider.updateProfile(updatedProfile);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Health profile saved')),
    );
  }

  @override
  void dispose() {
    _bloodGroupController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    _medicationsController.dispose();
    super.dispose();
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.recordsProvider,
      builder: (context, child) {
        if (!_initialized || widget.recordsProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final profile = widget.recordsProvider.profile;

        if (profile == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Health Profile')),
            body: Center(
              child: Text(
                widget.recordsProvider.error ??
                    'Unable to load health profile',
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Health Profile'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HealthProfileCard(
                    profile: profile,
                    onEdit: () {
                      _formKey.currentState?.validate();
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Personal Health Details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildField('Blood Group', _bloodGroupController),
                  _buildField(
                    'Height (cm)',
                    _heightController,
                    keyboardType: TextInputType.number,
                  ),
                  _buildField(
                    'Weight (kg)',
                    _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Medical Information',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    'Allergies (comma separated)',
                    _allergiesController,
                  ),
                  _buildField(
                    'Existing Conditions (comma separated)',
                    _conditionsController,
                  ),
                  _buildField(
                    'Current Medications (comma separated)',
                    _medicationsController,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveProfile,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Health Profile'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
