// lib/models/login_request.dart
class LoginRequest {
  final String loginId;
  final String password;

  LoginRequest({
    required this.loginId,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'loginId': loginId,
      'password': password,
    };
  }
}