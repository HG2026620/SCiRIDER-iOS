// lib/models/login_response.dart
import 'user_profile.dart';

class LoginResponse {
  final bool success;
  final String message;
  final String token;
  final DateTime? tokenExpiry;
  final UserProfile? user;

  LoginResponse({
    required this.success,
    required this.message,
    required this.token,
    required this.tokenExpiry,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      tokenExpiry: json['tokenExpiry'] != null
          ? DateTime.tryParse(json['tokenExpiry'].toString())
          : null,
      user: json['user'] != null
          ? UserProfile.fromJson(
              Map<String, dynamic>.from(json['user']),
            )
          : null,
    );
  }
}