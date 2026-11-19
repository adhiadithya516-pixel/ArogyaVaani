
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  AuthService({
    this.baseUrl = 'http://localhost:5000',
  });

  // Register a new user through the backend.
  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw Exception(
        data['error']?['message'] ?? 'Registration failed',
      );
    }

    // Sign in after backend registration.
    return login(email: email, password: password);
  }

  // Sign in an existing user through Firebase.
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Get Firebase ID token for protected API requests.
  Future<String?> getToken() async {
    return _firebaseAuth.currentUser?.getIdToken();
  }

  // Sign out the current user.
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }
}
