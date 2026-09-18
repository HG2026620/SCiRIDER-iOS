import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../models/dashboard_model.dart';
import 'api_service.dart';

class DashboardService {
  final ApiService _apiService = ApiService();

  Future<DashboardModel> getDashboard() async {
    // ============================================================
    // DEBUG - CONFIRM WHICH API FLUTTER IS CALLING
    // ============================================================

    debugPrint('============================================================');

    debugPrint('SCiRIDER DASHBOARD URL: ${ApiConfig.dashboard}');

    // ============================================================
    // CALL API
    // ============================================================

    final Map<String, dynamic> response = await _apiService.get(
      ApiConfig.dashboard,
    );

    // ============================================================
    // DEBUG - RAW RESPONSE
    // ============================================================

    debugPrint('SCiRIDER DASHBOARD RAW RESPONSE: $response');

    // ============================================================
    // HANDLE WRAPPED / UNWRAPPED RESPONSE
    // ============================================================

    Map<String, dynamic> data = response;

    if (response.containsKey('data') && response['data'] != null) {
      final dynamic responseData = response['data'];

      if (responseData is Map) {
        data = Map<String, dynamic>.from(responseData);
      }
    }

    debugPrint('SCiRIDER DASHBOARD DATA: $data');

    // ============================================================
    // PARSE MODEL
    // ============================================================

    final DashboardModel dashboard = DashboardModel.fromJson(data);

    // ============================================================
    // DEBUG - PARSED ORGANIZATION
    // ============================================================

    debugPrint('SCiRIDER DASHBOARD PARSED:');

    debugPrint(
      'Company     : ${dashboard.companyId} / ${dashboard.companyName}',
    );

    debugPrint(
      'Project     : ${dashboard.projectId} / ${dashboard.projectName}',
    );

    debugPrint(
      'Department  : ${dashboard.departmentId} / ${dashboard.departmentName}',
    );

    debugPrint('FY          : ${dashboard.financialYear}');

    debugPrint('============================================================');

    return dashboard;
  }
}
