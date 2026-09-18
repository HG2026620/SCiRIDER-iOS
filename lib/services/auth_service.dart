// lib/services/auth_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../storage/secure_storage_service.dart';

class AuthService {
  Future<LoginResponse> login({
    required String loginId,
    required String password,
  }) async {
    final request = LoginRequest(
      loginId: loginId,
      password: password,
    );

    final response = await http.post(
      Uri.parse(ApiConfig.login),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );

    Map<String, dynamic> data;

    try {
      data = Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    } catch (_) {
      throw Exception('Invalid response from API.');
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final result = LoginResponse.fromJson(data);

      if (result.success && result.token.isNotEmpty) {
        await SecureStorageService.saveToken(result.token);
      }

      return result;
    }

    throw Exception(
      data['message']?.toString() ?? 'Login failed.',
    );
  }

  Future<void> logout() async {
    await SecureStorageService.clearToken();
  }
}