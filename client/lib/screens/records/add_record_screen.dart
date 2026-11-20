import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/medical_record_model.dart';
import '../../providers/records_provider.dart';

class AddRecordScreen extends StatefulWidget {
  final RecordsProvider recordsProvider;

  const AddRecordScreen({
    super.key,
    required this.recordsProvider,
  });

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _recordType = 'Prescription';
  DateTime _recordDate = DateTime.now();
  bool _isSaving = false;
  File? _selectedFile;

  final List<String> _recordTypes = [
    'Prescription',
    'Lab Report',
    'Medical Report',
    'Scan',
    'Vaccination',
    'Other',
  ];
   
  Future<void> _pickDocument() async {
  final files = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
  );

  if (files.isNotEmpty && files.first.path != null) {
    setState(() {
      _selectedFile = File(files.first.path!);
    });
  }
}
  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _recordDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      setState(() {
        _recordDate = selectedDate;
      });
    }
  }

  
Future<void> _saveRecord() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    _isSaving = true;
  });

  try {
    // Upload document if one was selected.
    String documentUrl = '';

    if (_selectedFile != null) {
      documentUrl = await widget.recordsProvider.uploadDocument(
        _selectedFile!,
      );
    }

    // Create medical record with uploaded document URL.
    final record = MedicalRecordModel(
      title: _titleController.text.trim(),
      recordType: _recordType,
      description: _descriptionController.text.trim(),
      documentUrl: documentUrl,
      recordDate: _recordDate,
      createdAt: DateTime.now(),
    );

    await widget.recordsProvider.addRecord(record);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Medical record added successfully'),
      ),
    );

    Navigator.pop(context);
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to add record: $e')),
    );
  } finally {
    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }
}


  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medical Record'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Record Title',
                  hintText: 'Example: Blood Test Report',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a record title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                initialValue: _recordType,
                decoration: const InputDecoration(
                  labelText: 'Record Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _recordTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _recordType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter details about this medical record',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

OutlinedButton.icon(
  onPressed: _pickDocument,
  icon: const Icon(Icons.attach_file),
  label: const Text('Choose Document'),
),

if (_selectedFile != null) ...[
  const SizedBox(height: 8),
  Text(
    'Selected: ${_selectedFile!.path.split(Platform.pathSeparator).last}',
    style: const TextStyle(color: Colors.green),
  ),
],
              const SizedBox(height: 20),

              const Text(
                'Record Date',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              OutlinedButton.icon(
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  '${_recordDate.day}/${_recordDate.month}/${_recordDate.year}',
                ),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveRecord,
                  icon: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _isSaving ? 'Saving...' : 'Save Medical Record',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
