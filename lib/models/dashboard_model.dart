class DashboardModel {
  final int userId;
  final String fullName;
  final String designation;

  final int companyId;
  final String companyName;

  final int projectId;
  final String projectName;

  final int departmentId;
  final String departmentName;

  final String financialYear;

  final bool isAdmin;

  final int pendingApprovals;
  final int pendingPRSR;
  final int pendingNFA;
  final int pendingVendorComparison;
  final int pendingPO;
  final int pendingVendorPayment;

  const DashboardModel({
    this.userId = 0,
    this.fullName = '',
    this.designation = '',
    this.companyId = 0,
    this.companyName = '',
    this.projectId = 0,
    this.projectName = '',
    this.departmentId = 0,
    this.departmentName = '',
    this.financialYear = '',
    this.isAdmin = false,
    this.pendingApprovals = 0,
    this.pendingPRSR = 0,
    this.pendingNFA = 0,
    this.pendingVendorComparison = 0,
    this.pendingPO = 0,
    this.pendingVendorPayment = 0,
  });

  // ============================================================
  // HELPERS
  // ============================================================

  static String _string(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (!json.containsKey(key)) {
        continue;
      }

      final value = json[key];

      if (value == null) {
        continue;
      }

      final text = value.toString().trim();

      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }

    return '';
  }

  static int _int(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (!json.containsKey(key)) {
        continue;
      }

      final value = json[key];

      if (value == null) {
        continue;
      }

      if (value is int) {
        return value;
      }

      if (value is num) {
        return value.toInt();
      }

      final parsed = int.tryParse(value.toString());

      if (parsed != null) {
        return parsed;
      }
    }

    return 0;
  }

  static bool _bool(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (!json.containsKey(key)) {
        continue;
      }

      final value = json[key];

      if (value == null) {
        continue;
      }

      if (value is bool) {
        return value;
      }

      if (value is num) {
        return value != 0;
      }

      final text = value.toString().trim().toLowerCase();

      if (text == 'true' || text == '1' || text == 'yes' || text == 'y') {
        return true;
      }

      if (text == 'false' || text == '0' || text == 'no' || text == 'n') {
        return false;
      }
    }

    return false;
  }

  // ============================================================
  // FROM JSON
  // ============================================================

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      userId: _int(json, ['userId', 'iUserId']),

      fullName: _string(json, [
        'fullName',
        'sFullName',
        'userName',
        'sUserName',
      ]),

      designation: _string(json, [
        'designation',
        'sDesignation',
        'designationName',
        'sDesignationName',
      ]),

      // ========================================================
      // ORGANIZATION
      // ========================================================
      companyId: _int(json, ['companyId', 'iCompanyId']),

      companyName: _string(json, [
        'companyName',
        'sCompanyName',
        'defaultCompanyName',
        'sDefaultCompanyName',
      ]),

      projectId: _int(json, ['projectId', 'iProjectId']),

      projectName: _string(json, [
        'projectName',
        'sProjectName',
        'defaultProjectName',
        'sDefaultProjectName',
      ]),

      departmentId: _int(json, ['departmentId', 'iDepartmentId']),

      departmentName: _string(json, [
        'departmentName',
        'sDepartmentName',
        'defaultDepartmentName',
        'sDefaultDepartmentName',
      ]),

      financialYear: _string(json, [
        'financialYear',
        'sFinancialYear',
        'defaultFinancialYear',
        'sDefaultFinancialYear',
      ]),

      isAdmin: _bool(json, ['isAdmin', 'bIsAdmin']),

      // ========================================================
      // COUNTS
      // ========================================================
      pendingApprovals: _int(json, [
        'pendingApprovals',
        'pendingApproval',
        'totalPendingApprovals',
        'iPendingApprovals',
      ]),

      pendingPRSR: _int(json, [
        'pendingPRSR',
        'pendingPrSr',
        'pendingPR',
        'iPendingPRSR',
      ]),

      pendingNFA: _int(json, ['pendingNFA', 'pendingNfa', 'iPendingNFA']),

      pendingVendorComparison: _int(json, [
        'pendingVendorComparison',
        'pendingComparison',
        'iPendingVendorComparison',
      ]),

      pendingPO: _int(json, ['pendingPO', 'pendingPo', 'iPendingPO']),

      pendingVendorPayment: _int(json, [
        'pendingVendorPayment',
        'iPendingVendorPayment',
      ]),
    );
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  DashboardModel copyWith({
    int? userId,
    String? fullName,
    String? designation,
    int? companyId,
    String? companyName,
    int? projectId,
    String? projectName,
    int? departmentId,
    String? departmentName,
    String? financialYear,
    bool? isAdmin,
    int? pendingApprovals,
    int? pendingPRSR,
    int? pendingNFA,
    int? pendingVendorComparison,
    int? pendingPO,
    int? pendingVendorPayment,
  }) {
    return DashboardModel(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      designation: designation ?? this.designation,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      financialYear: financialYear ?? this.financialYear,
      isAdmin: isAdmin ?? this.isAdmin,
      pendingApprovals: pendingApprovals ?? this.pendingApprovals,
      pendingPRSR: pendingPRSR ?? this.pendingPRSR,
      pendingNFA: pendingNFA ?? this.pendingNFA,
      pendingVendorComparison:
          pendingVendorComparison ?? this.pendingVendorComparison,
      pendingPO: pendingPO ?? this.pendingPO,
      pendingVendorPayment: pendingVendorPayment ?? this.pendingVendorPayment,
    );
  }
}
