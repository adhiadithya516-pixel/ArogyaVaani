import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/health_profile_model.dart';
import '../models/medical_record_model.dart';

class RecordsService {
  final String baseUrl;
  final Future<String?> Function() getToken;

  RecordsService({
    required this.baseUrl,
    required this.getToken,
  });

  Future<Map<String, String>> _headers() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('User is not authenticated');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<HealthProfileModel> getProfile() async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/records/profile'),
    headers: await _headers(),
  );
  debugPrint('PROFILE STATUS: ${response.statusCode}');
debugPrint('PROFILE RESPONSE: ${response.body}');

  if (response.statusCode != 200) {
    throw Exception(
      'Failed to load health profile. '
      'Status: ${response.statusCode}. '
      'Response: ${response.body}',
    );
  }

  final data = jsonDecode(response.body);

  return HealthProfileModel.fromJson(data['profile']);
}

  Future<void> updateProfile(HealthProfileModel profile) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/records/profile'),
      headers: await _headers(),
      body: jsonEncode(profile.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update health profile');
    }
  }

  Future<List<MedicalRecordModel>> getRecords() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/records'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load medical records');
    }

    final data = jsonDecode(response.body);
    final List records = data['records'] ?? [];

    return records.map((record) {
      return MedicalRecordModel.fromJson(
        Map<String, dynamic>.from(record),
      );
    }).toList();
  }

  Future<String> createRecord(MedicalRecordModel record) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/records'),
      headers: await _headers(),
      body: jsonEncode(record.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create medical record');
    }

    final data = jsonDecode(response.body);
    return data['id'];
  }

  Future<String> uploadDocument(File file) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('User is not authenticated');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/records/documents'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(
      await http.MultipartFile.fromPath(
        'document',
        file.path,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception('Failed to upload document');
    }

    final data = jsonDecode(response.body);

    final documentUrl = data['documentUrl'];

    if (documentUrl == null || documentUrl.toString().isEmpty) {
      throw Exception('Document URL missing from server response');
    }

    return documentUrl.toString();
  }


  Future<void> deleteRecord(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/records/$id'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete medical record');
    }
  }

}
