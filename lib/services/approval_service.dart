import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/approval_model.dart';
import '../models/document_model.dart';
import '../models/document_approval_history_model.dart';
import '../models/prsr_change_history_model.dart';
import '../storage/secure_storage_service.dart';
import 'api_service.dart';

class ApprovalService {
  final ApiService _apiService = ApiService();

  // ============================================================
  // 1. MY APPROVALS
  // ============================================================

  Future<List<ApprovalModel>> getMyApprovals({
    String? module,
    String? searchText,
  }) async {
    String url = ApiConfig.myApprovals;

    final queryParameters = <String, String>{};

    if (module != null &&
        module.trim().isNotEmpty &&
        module.trim().toUpperCase() != 'ALL') {
      queryParameters['module'] = module.trim().toUpperCase();
    }

    if (searchText != null && searchText.trim().isNotEmpty) {
      queryParameters['search'] = searchText.trim();
    }

    if (queryParameters.isNotEmpty) {
      url = Uri.parse(url).replace(queryParameters: queryParameters).toString();
    }

    final response = await _apiService.get(url);

    final dynamic rawData = response['data'] ?? response;

    if (rawData is! List) {
      return <ApprovalModel>[];
    }

    return rawData
        .whereType<Map>()
        .map((item) => ApprovalModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  // ============================================================
  // 2. MY APPROVAL COUNT
  // ============================================================

  Future<int> getMyApprovalCount() async {
    final response = await _apiService.get(ApiConfig.approvalCount);

    final dynamic rawData = response['data'] ?? response;

    if (rawData is int) {
      return rawData;
    }

    if (rawData is num) {
      return rawData.toInt();
    }

    if (rawData is Map) {
      final map = Map<String, dynamic>.from(rawData);

      final dynamic value =
          map['count'] ??
          map['approvalCount'] ??
          map['pendingCount'] ??
          map['total'];

      if (value is int) {
        return value;
      }

      if (value is num) {
        return value.toInt();
      }

      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return int.tryParse(rawData?.toString() ?? '') ?? 0;
  }

  // ============================================================
  // 3. CURRENT APPROVER / ME
  // ============================================================

  Future<Map<String, dynamic>> getApprovalMe() async {
    final response = await _apiService.get(ApiConfig.approvalMe);

    final dynamic rawData = response['data'] ?? response;

    if (rawData is Map) {
      return Map<String, dynamic>.from(rawData);
    }

    return <String, dynamic>{};
  }

  // ============================================================
  // 4. GENERIC APPROVAL DETAIL
  // ============================================================

  Future<Map<String, dynamic>> getApprovalDetail(int approvalTxnId) async {
    if (approvalTxnId <= 0) {
      return <String, dynamic>{};
    }

    final response = await _apiService.get(
      ApiConfig.approvalDetail(approvalTxnId),
    );

    final dynamic rawData = response['data'] ?? response;

    if (rawData is Map) {
      return Map<String, dynamic>.from(rawData);
    }

    return <String, dynamic>{};
  }

  // ============================================================
  // 5. PR DETAIL
  // ============================================================

  Future<Map<String, dynamic>> getPRDetail(int approvalTxnId) async {
    if (approvalTxnId <= 0) {
      return <String, dynamic>{};
    }

    final response = await _apiService.get(ApiConfig.prDetail(approvalTxnId));

    final dynamic rawData = response['data'] ?? response;

    if (rawData is Map) {
      return Map<String, dynamic>.from(rawData);
    }

    return <String, dynamic>{};
  }

  // ============================================================
  // 6. PO DETAIL
  // ============================================================

  Future<Map<String, dynamic>> getPODetail(int approvalTxnId) async {
    if (approvalTxnId <= 0) {
      return <String, dynamic>{};
    }

    final response = await _apiService.get(ApiConfig.poDetail(approvalTxnId));

    final dynamic rawData = response['data'] ?? response;

    if (rawData is Map) {
      return Map<String, dynamic>.from(rawData);
    }

    return <String, dynamic>{};
  }

  // ============================================================
  // 7. NFA DETAIL
  // ============================================================

  Future<Map<String, dynamic>> getNFADetail(int approvalTxnId) async {
    if (approvalTxnId <= 0) {
      return <String, dynamic>{};
    }

    final response = await _apiService.get(ApiConfig.nfaDetail(approvalTxnId));

    final dynamic rawData = response['data'] ?? response;

    if (rawData is Map) {
      return Map<String, dynamic>.from(rawData);
    }

    return <String, dynamic>{};
  }

  // ============================================================
  // 8. MODULE APPROVAL DETAIL
  // ============================================================

  Future<Map<String, dynamic>> getModuleApprovalDetail({
    required String module,
    required int approvalTxnId,
  }) async {
    if (approvalTxnId <= 0) {
      return <String, dynamic>{};
    }

    final cleanModule = module.trim().toUpperCase();

    switch (cleanModule) {
      case 'PR':
        return getPRDetail(approvalTxnId);

      case 'PO':
        return getPODetail(approvalTxnId);

      case 'NFA':
        return getNFADetail(approvalTxnId);

      default:
        return getApprovalDetail(approvalTxnId);
    }
  }

  // ============================================================
  // 9. ATTACHMENT
  // ============================================================

  Future<Map<String, dynamic>> getAttachment(int approvalTxnId) async {
    if (approvalTxnId <= 0) {
      return <String, dynamic>{};
    }

    final response = await _apiService.get(
      ApiConfig.approvalAttachment(approvalTxnId),
    );

    final dynamic rawData = response['data'] ?? response;

    if (rawData is Map) {
      return Map<String, dynamic>.from(rawData);
    }

    return <String, dynamic>{};
  }

  // ============================================================
  // 10. SAVE PR CHANGES
  // ============================================================

  Future<Map<String, dynamic>> savePRChanges(
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiService.post(ApiConfig.savePRChanges, payload);

    return Map<String, dynamic>.from(response);
  }

  // ============================================================
  // 11. APPROVE
  //
  // IMPORTANT:
  // DO NOT read FlutterSecureStorage directly here.
  //
  // ApiService already uses:
  //
  // SecureStorageService.getToken()
  //
  // This keeps GET / POST / Approve / Reject authentication
  // consistent.
  // ============================================================

  Future<Map<String, dynamic>> approve({
    required int approvalTxnId,
    String remark = '',
  }) async {
    if (approvalTxnId <= 0) {
      return <String, dynamic>{
        'success': false,
        'message': 'Invalid approval transaction.',
      };
    }

    final payload = <String, dynamic>{
      'approvalTxnId': approvalTxnId,
      'remark': remark.trim(),
    };

    debugPrint('');
    debugPrint('============================================================');
    debugPrint('SCIRIDER APPROVE THROUGH API SERVICE');
    debugPrint('============================================================');
    debugPrint('TXN ID  : $approvalTxnId');
    debugPrint('REMARK  : ${remark.trim()}');
    debugPrint('PAYLOAD : ${jsonEncode(payload)}');
    debugPrint('============================================================');

    try {
      final response = await _apiService.post(ApiConfig.approve, payload);

      debugPrint('');
      debugPrint(
        '============================================================',
      );
      debugPrint('SCIRIDER APPROVE RESULT');
      debugPrint(
        '============================================================',
      );
      debugPrint('$response');
      debugPrint(
        '============================================================',
      );

      return Map<String, dynamic>.from(response);
    } catch (e, stackTrace) {
      final message = e.toString().replaceFirst('Exception: ', '').trim();

      debugPrint('');
      debugPrint(
        '============================================================',
      );
      debugPrint('SCIRIDER APPROVE FAILED');
      debugPrint(
        '============================================================',
      );
      debugPrint('ERROR : $message');
      debugPrint('STACK : $stackTrace');
      debugPrint(
        '============================================================',
      );

      return <String, dynamic>{
        'success': false,
        'message': message.isEmpty ? 'Unable to approve document.' : message,
      };
    }
  }

  // ============================================================
  // 12. REJECT
  // ============================================================

  Future<Map<String, dynamic>> reject({
    required int approvalTxnId,
    required String remark,
  }) async {
    if (approvalTxnId <= 0) {
      return <String, dynamic>{
        'success': false,
        'message': 'Invalid approval transaction.',
      };
    }

    final cleanRemark = remark.trim();

    if (cleanRemark.isEmpty) {
      return <String, dynamic>{
        'success': false,
        'message': 'Rejection remark is required.',
      };
    }

    final payload = <String, dynamic>{
      'approvalTxnId': approvalTxnId,
      'remark': cleanRemark,
    };

    debugPrint('');
    debugPrint('============================================================');
    debugPrint('SCIRIDER REJECT THROUGH API SERVICE');
    debugPrint('============================================================');
    debugPrint('TXN ID  : $approvalTxnId');
    debugPrint('REMARK  : $cleanRemark');
    debugPrint('PAYLOAD : ${jsonEncode(payload)}');
    debugPrint('============================================================');

    try {
      final response = await _apiService.post(ApiConfig.reject, payload);

      debugPrint('');
      debugPrint(
        '============================================================',
      );
      debugPrint('SCIRIDER REJECT RESULT');
      debugPrint(
        '============================================================',
      );
      debugPrint('$response');
      debugPrint(
        '============================================================',
      );

      return Map<String, dynamic>.from(response);
    } catch (e, stackTrace) {
      final message = e.toString().replaceFirst('Exception: ', '').trim();

      debugPrint('');
      debugPrint(
        '============================================================',
      );
      debugPrint('SCIRIDER REJECT FAILED');
      debugPrint(
        '============================================================',
      );
      debugPrint('ERROR : $message');
      debugPrint('STACK : $stackTrace');
      debugPrint(
        '============================================================',
      );

      return <String, dynamic>{
        'success': false,
        'message': message.isEmpty ? 'Unable to reject document.' : message,
      };
    }
  }

  // ============================================================
  // 13. ALL DOCUMENTS
  // ============================================================

  Future<List<DocumentModel>> getDocuments({
    String module = 'ALL',
    String status = 'ALL',
    String search = '',
  }) async {
    String url = ApiConfig.documents;

    final queryParameters = <String, String>{};

    final cleanModule = module.trim().toUpperCase();
    final cleanStatus = status.trim().toUpperCase();
    final cleanSearch = search.trim();

    if (cleanModule.isNotEmpty && cleanModule != 'ALL') {
      queryParameters['module'] = cleanModule;
    }

    if (cleanStatus.isNotEmpty && cleanStatus != 'ALL') {
      queryParameters['status'] = cleanStatus;
    }

    if (cleanSearch.isNotEmpty) {
      queryParameters['search'] = cleanSearch;
    }

    if (queryParameters.isNotEmpty) {
      url = Uri.parse(url).replace(queryParameters: queryParameters).toString();
    }

    final response = await _apiService.get(url);

    final dynamic rawData = response['data'] ?? response;

    if (rawData is! List) {
      return <DocumentModel>[];
    }

    return rawData
        .whereType<Map>()
        .map((item) => DocumentModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  // ============================================================
  // 14. DOCUMENT APPROVAL HISTORY
  // ============================================================

  Future<List<DocumentApprovalHistoryModel>> getDocumentApprovalHistory({
    required String module,
    required int sourceId,
  }) async {
    final cleanModule = module.trim().toUpperCase();

    if (cleanModule.isEmpty) {
      return <DocumentApprovalHistoryModel>[];
    }

    if (sourceId <= 0) {
      return <DocumentApprovalHistoryModel>[];
    }

    final url = ApiConfig.documentHistory(cleanModule, sourceId);

    final response = await _apiService.get(url);

    final dynamic rawData = response['data'] ?? response;

    if (rawData is! List) {
      return <DocumentApprovalHistoryModel>[];
    }

    return rawData
        .whereType<Map>()
        .map(
          (item) => DocumentApprovalHistoryModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  // ============================================================
  // 15. PR/SR CHANGE HISTORY
  // ============================================================

  Future<List<PRSRChangeHistoryModel>> getPRSRChangeHistory({
    required String module,
    required int sourceId,
  }) async {
    final cleanModule = module.trim().toUpperCase();

    if (cleanModule != 'PR' && cleanModule != 'SR') {
      return <PRSRChangeHistoryModel>[];
    }

    if (sourceId <= 0) {
      return <PRSRChangeHistoryModel>[];
    }

    final url = ApiConfig.prsrChangeHistory(cleanModule, sourceId);

    final response = await _apiService.get(url);

    final dynamic rawData = response['data'] ?? response;

    if (rawData is! List) {
      return <PRSRChangeHistoryModel>[];
    }

    return rawData
        .whereType<Map>()
        .map(
          (item) =>
              PRSRChangeHistoryModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  // ============================================================
  // 16. DOCUMENT PDF
  //
  // IMPORTANT:
  // Uses the SAME SecureStorageService used by ApiService.
  // ============================================================

  Future<Uint8List> downloadDocumentPdf({
    required String module,
    required int sourceId,
  }) async {
    final cleanModule = module.trim().toUpperCase();

    if (sourceId <= 0) {
      throw Exception('Invalid document ID.');
    }

    if (cleanModule != 'PR' &&
        cleanModule != 'SR' &&
        cleanModule != 'NFA' &&
        cleanModule != 'PO') {
      throw Exception('PDF download is available only for PR, SR, NFA and PO.');
    }

    // ----------------------------------------------------------
    // SAME TOKEN SERVICE AS ApiService
    // ----------------------------------------------------------

    final token = await SecureStorageService.getToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception('Login session expired. Please login again.');
    }

    final String url = ApiConfig.documentPdf(cleanModule, sourceId);

    debugPrint('');
    debugPrint('============================================================');
    debugPrint('SCIRIDER PDF REQUEST');
    debugPrint('============================================================');
    debugPrint('MODULE : $cleanModule');
    debugPrint('ID     : $sourceId');
    debugPrint('URL    : $url');
    debugPrint('TOKEN  : YES');
    debugPrint('============================================================');

    final http.Response response;

    try {
      response = await http
          .get(
            Uri.parse(url),
            headers: <String, String>{
              'Authorization': 'Bearer ${token.trim()}',
              'Accept': 'application/pdf',
            },
          )
          .timeout(const Duration(seconds: 90));
    } catch (e) {
      debugPrint('SCIRIDER PDF ERROR: $e');

      throw Exception('Unable to connect to document download service.');
    }

    debugPrint('SCIRIDER PDF STATUS: ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.bodyBytes.isEmpty) {
        throw Exception('Downloaded PDF is empty.');
      }

      final contentType = response.headers['content-type']?.toLowerCase() ?? '';

      if (contentType.contains('text/html') ||
          _looksLikeHtml(response.bodyBytes)) {
        throw Exception('Server returned an HTML page instead of PDF.');
      }

      return Uint8List.fromList(response.bodyBytes);
    }

    final message = _extractErrorMessage(response);

    if (response.statusCode == 401) {
      throw Exception(
        message.isNotEmpty
            ? message
            : 'Login session expired. Please login again.',
      );
    }

    if (response.statusCode == 403) {
      throw Exception(
        message.isNotEmpty
            ? message
            : 'You do not have permission to download this document.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception(message.isNotEmpty ? message : 'Document PDF not found.');
    }

    throw Exception(
      message.isNotEmpty
          ? message
          : 'Unable to download document PDF. '
                'HTTP ${response.statusCode}.',
    );
  }

  // ============================================================
  // 17. CHECK PO DETAIL
  // ============================================================

  Future<bool> hasPODetail(int approvalTxnId) async {
    if (approvalTxnId <= 0) {
      return false;
    }

    try {
      final result = await getPODetail(approvalTxnId);

      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static List<Map<String, dynamic>> getMapList(dynamic value) {
    if (value is! List) {
      return <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static String getString(Map<String, dynamic> map, String key) {
    final value = map[key];

    if (value == null) {
      return '';
    }

    return value.toString();
  }

  static int getInt(Map<String, dynamic> map, String key) {
    final value = map[key];

    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  static double getDouble(Map<String, dynamic> map, String key) {
    final value = map[key];

    if (value == null) {
      return 0;
    }

    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  static bool getBool(Map<String, dynamic> map, String key) {
    final value = map[key];

    if (value == null) {
      return false;
    }

    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final text = value.toString().trim().toLowerCase();

    return text == 'true' || text == '1' || text == 'yes';
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  String _extractErrorMessage(http.Response response) {
    if (response.body.trim().isEmpty) {
      return '';
    }

    try {
      final dynamic decoded = jsonDecode(response.body);

      if (decoded is Map) {
        final map = Map<String, dynamic>.from(decoded);

        final dynamic message =
            map['message'] ?? map['Message'] ?? map['error'] ?? map['detail'];

        if (message != null && message.toString().trim().isNotEmpty) {
          return message.toString().trim();
        }

        final dynamic data = map['data'] ?? map['Data'];

        if (data is Map) {
          final dataMap = Map<String, dynamic>.from(data);

          final dynamic detail = dataMap['detail'] ?? dataMap['message'];

          if (detail != null && detail.toString().trim().isNotEmpty) {
            return detail.toString().trim();
          }
        }
      }
    } catch (_) {
      // Response was not JSON.
    }

    return response.body.trim();
  }

  // ============================================================
  // HTML DETECTION
  // ============================================================

  bool _looksLikeHtml(Uint8List bytes) {
    if (bytes.isEmpty) {
      return false;
    }

    final length = bytes.length > 300 ? 300 : bytes.length;

    try {
      final text = utf8
          .decode(bytes.sublist(0, length), allowMalformed: true)
          .trimLeft()
          .toLowerCase();

      return text.startsWith('<!doctype html') ||
          text.startsWith('<html') ||
          text.contains('<html');
    } catch (_) {
      return false;
    }
  }
}
