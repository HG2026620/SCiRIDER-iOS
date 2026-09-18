import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../storage/secure_storage_service.dart';

class ApiService {
  // ============================================================
  // TIMEOUT
  // ============================================================

  static const Duration _timeout = Duration(seconds: 60);

  // ============================================================
  // GET
  // ============================================================

  Future<Map<String, dynamic>> get(String url) async {
    final token = await SecureStorageService.getToken();

    _printRequest(
      method: 'GET',
      url: url,
      tokenAvailable: token != null && token.trim().isNotEmpty,
    );

    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: <String, String>{
              'Accept': 'application/json',

              if (token != null && token.trim().isNotEmpty)
                'Authorization': 'Bearer ${token.trim()}',
            },
          )
          .timeout(_timeout);

      _printResponse(method: 'GET', url: url, response: response);

      return _processResponse(response);
    } on TimeoutException {
      debugPrint('SCIRIDER GET TIMEOUT: $url');

      throw Exception('Request timed out. Please try again.');
    } catch (e) {
      debugPrint('SCIRIDER GET EXCEPTION: $e');

      rethrow;
    }
  }

  // ============================================================
  // POST
  // ============================================================

  Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> body,
  ) async {
    final token = await SecureStorageService.getToken();

    final bool tokenAvailable = token != null && token.trim().isNotEmpty;

    _printRequest(
      method: 'POST',
      url: url,
      tokenAvailable: tokenAvailable,
      body: body,
    );

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Accept': 'application/json',

              if (tokenAvailable) 'Authorization': 'Bearer ${token!.trim()}',
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      _printResponse(method: 'POST', url: url, response: response);

      return _processResponse(response);
    } on TimeoutException {
      debugPrint('SCIRIDER POST TIMEOUT: $url');

      throw Exception('Request timed out. Please try again.');
    } catch (e) {
      debugPrint('SCIRIDER POST EXCEPTION: $e');

      rethrow;
    }
  }

  // ============================================================
  // PUT
  // ============================================================

  Future<Map<String, dynamic>> put(
    String url,
    Map<String, dynamic> body,
  ) async {
    final token = await SecureStorageService.getToken();

    final bool tokenAvailable = token != null && token.trim().isNotEmpty;

    _printRequest(
      method: 'PUT',
      url: url,
      tokenAvailable: tokenAvailable,
      body: body,
    );

    try {
      final response = await http
          .put(
            Uri.parse(url),
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Accept': 'application/json',

              if (tokenAvailable) 'Authorization': 'Bearer ${token!.trim()}',
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      _printResponse(method: 'PUT', url: url, response: response);

      return _processResponse(response);
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } catch (e) {
      debugPrint('SCIRIDER PUT EXCEPTION: $e');

      rethrow;
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<Map<String, dynamic>> delete(String url) async {
    final token = await SecureStorageService.getToken();

    final bool tokenAvailable = token != null && token.trim().isNotEmpty;

    _printRequest(method: 'DELETE', url: url, tokenAvailable: tokenAvailable);

    try {
      final response = await http
          .delete(
            Uri.parse(url),
            headers: <String, String>{
              'Accept': 'application/json',

              if (tokenAvailable) 'Authorization': 'Bearer ${token!.trim()}',
            },
          )
          .timeout(_timeout);

      _printResponse(method: 'DELETE', url: url, response: response);

      return _processResponse(response);
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } catch (e) {
      debugPrint('SCIRIDER DELETE EXCEPTION: $e');

      rethrow;
    }
  }

  // ============================================================
  // PROCESS RESPONSE
  // ============================================================

  Map<String, dynamic> _processResponse(http.Response response) {
    Map<String, dynamic> data = <String, dynamic>{};

    // ----------------------------------------------------------
    // PARSE RESPONSE
    // ----------------------------------------------------------

    if (response.body.trim().isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(response.body);

        if (decoded is Map) {
          data = Map<String, dynamic>.from(decoded);
        } else {
          debugPrint('SCIRIDER: Response is JSON but not an object.');
        }
      } catch (e) {
        debugPrint('SCIRIDER JSON PARSE ERROR: $e');

        debugPrint('SCIRIDER RAW RESPONSE: ${response.body}');

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return <String, dynamic>{
            'success': true,
            'message': response.body.trim(),
          };
        }

        throw Exception(
          response.body.trim().isNotEmpty
              ? response.body.trim()
              : 'Invalid response from server.',
        );
      }
    }

    // ----------------------------------------------------------
    // HTTP SUCCESS
    // ----------------------------------------------------------

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    // ----------------------------------------------------------
    // EXTRACT SERVER MESSAGE
    // ----------------------------------------------------------

    final String serverMessage = _extractMessage(data);

    // ----------------------------------------------------------
    // 400
    // ----------------------------------------------------------

    if (response.statusCode == 400) {
      throw Exception(
        serverMessage.isNotEmpty ? serverMessage : 'Invalid request.',
      );
    }

    // ----------------------------------------------------------
    // 401
    // ----------------------------------------------------------

    if (response.statusCode == 401) {
      throw Exception(
        serverMessage.isNotEmpty
            ? serverMessage
            : 'Session expired. Please login again.',
      );
    }

    // ----------------------------------------------------------
    // 403
    // ----------------------------------------------------------

    if (response.statusCode == 403) {
      throw Exception(
        serverMessage.isNotEmpty
            ? serverMessage
            : 'You are not authorized to perform this action.',
      );
    }

    // ----------------------------------------------------------
    // 404
    // ----------------------------------------------------------

    if (response.statusCode == 404) {
      throw Exception(
        serverMessage.isNotEmpty
            ? serverMessage
            : 'Requested resource was not found.',
      );
    }

    // ----------------------------------------------------------
    // 409
    // ----------------------------------------------------------

    if (response.statusCode == 409) {
      throw Exception(
        serverMessage.isNotEmpty
            ? serverMessage
            : 'The document has already been processed '
                  'or its status has changed.',
      );
    }

    // ----------------------------------------------------------
    // 500+
    // ----------------------------------------------------------

    if (response.statusCode >= 500) {
      throw Exception(
        serverMessage.isNotEmpty
            ? serverMessage
            : 'Server error. Please try again.',
      );
    }

    // ----------------------------------------------------------
    // OTHER
    // ----------------------------------------------------------

    throw Exception(
      serverMessage.isNotEmpty
          ? serverMessage
          : 'Request failed. HTTP ${response.statusCode}',
    );
  }

  // ============================================================
  // EXTRACT API MESSAGE
  // ============================================================

  String _extractMessage(Map<String, dynamic> data) {
    dynamic message =
        data['message'] ??
        data['Message'] ??
        data['error'] ??
        data['Error'] ??
        data['detail'] ??
        data['Detail'] ??
        data['title'];

    if (message != null && message.toString().trim().isNotEmpty) {
      return message.toString().trim();
    }

    // ----------------------------------------------------------
    // CHECK NESTED DATA
    // ----------------------------------------------------------

    final dynamic nestedData = data['data'] ?? data['Data'];

    if (nestedData is Map) {
      final map = Map<String, dynamic>.from(nestedData);

      message =
          map['message'] ??
          map['Message'] ??
          map['error'] ??
          map['Error'] ??
          map['detail'];

      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString().trim();
      }
    }

    // ----------------------------------------------------------
    // ASP.NET VALIDATION ERRORS
    // ----------------------------------------------------------

    final dynamic errors = data['errors'];

    if (errors is Map) {
      final List<String> messages = <String>[];

      errors.forEach((dynamic key, dynamic value) {
        if (value is List) {
          for (final item in value) {
            if (item != null && item.toString().trim().isNotEmpty) {
              messages.add(item.toString().trim());
            }
          }
        } else if (value != null && value.toString().trim().isNotEmpty) {
          messages.add(value.toString().trim());
        }
      });

      if (messages.isNotEmpty) {
        return messages.join(' ');
      }
    }

    return '';
  }

  // ============================================================
  // DEBUG REQUEST
  //
  // IMPORTANT:
  // Never print the actual JWT.
  // ============================================================

  void _printRequest({
    required String method,
    required String url,
    required bool tokenAvailable,
    Map<String, dynamic>? body,
  }) {
    debugPrint('');
    debugPrint('============================================================');

    debugPrint('SCIRIDER API REQUEST');

    debugPrint('============================================================');

    debugPrint('METHOD       : $method');

    debugPrint('URL          : $url');

    debugPrint('AUTH TOKEN   : ${tokenAvailable ? "YES" : "NO"}');

    if (body != null) {
      debugPrint('REQUEST BODY : ${jsonEncode(body)}');
    }

    debugPrint('============================================================');
  }

  // ============================================================
  // DEBUG RESPONSE
  // ============================================================

  void _printResponse({
    required String method,
    required String url,
    required http.Response response,
  }) {
    debugPrint('');
    debugPrint('============================================================');

    debugPrint('SCIRIDER API RESPONSE');

    debugPrint('============================================================');

    debugPrint('METHOD      : $method');

    debugPrint('URL         : $url');

    debugPrint('STATUS CODE : ${response.statusCode}');

    debugPrint('CONTENT TYPE: ${response.headers['content-type'] ?? "-"}');

    debugPrint('RESPONSE    : ${response.body}');

    debugPrint('============================================================');
  }
}
