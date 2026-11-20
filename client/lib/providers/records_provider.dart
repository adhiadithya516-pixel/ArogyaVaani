
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/health_profile_model.dart';
import '../models/medical_record_model.dart';
import '../services/records_service.dart';

class RecordsProvider extends ChangeNotifier {
  final RecordsService _service;

  RecordsProvider({required this._service});

  HealthProfileModel? _profile;
  List<MedicalRecordModel> _records = [];

  bool _isLoading = false;
  String? _error;

  HealthProfileModel? get profile => _profile;
  List<MedicalRecordModel> get records => List.unmodifiable(_records);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _service.getProfile();
      _records = await _service.getRecords();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(HealthProfileModel profile) async {
    try {
      _error = null;
      await _service.updateProfile(profile);
      _profile = profile;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<String> uploadDocument(File file) async {
    try {
      _error = null;
      return await _service.uploadDocument(file);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addRecord(MedicalRecordModel record) async {
    try {
      _error = null;
      await _service.createRecord(record);
      _records = await _service.getRecords();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteRecord(String id) async {
    try {
      _error = null;
      await _service.deleteRecord(id);
      _records.removeWhere((record) => record.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
