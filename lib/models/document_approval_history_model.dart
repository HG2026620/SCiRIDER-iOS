class DocumentApprovalHistoryModel {
  final int approvalTxnId;
  final String module;
  final String requestType;
  final int sourceId;
  final String sourceNo;
  final int approvalLevel;
  final int roleId;
  final String roleName;
  final int approverUserId;
  final String approverName;
  final String approvalStatus;
  final String remark;
  final String approvalRemark;
  final DateTime? assignedDate;
  final DateTime? actionDate;
  final bool isCurrentLevel;
  final bool isFinalLevel;
  final bool isApproved;
  final String approvalMode;

  const DocumentApprovalHistoryModel({
    required this.approvalTxnId,
    required this.module,
    required this.requestType,
    required this.sourceId,
    required this.sourceNo,
    required this.approvalLevel,
    required this.roleId,
    required this.roleName,
    required this.approverUserId,
    required this.approverName,
    required this.approvalStatus,
    required this.remark,
    required this.approvalRemark,
    required this.assignedDate,
    required this.actionDate,
    required this.isCurrentLevel,
    required this.isFinalLevel,
    required this.isApproved,
    required this.approvalMode,
  });

  factory DocumentApprovalHistoryModel.fromJson(Map<String, dynamic> json) {
    return DocumentApprovalHistoryModel(
      approvalTxnId: _toInt(
        json['approvalTxnId'] ??
            json['ApprovalTxnId'] ??
            json['iApprovalTxnId'],
      ),
      module: _toString(json['module'] ?? json['Module'] ?? json['sModule']),
      requestType: _toString(
        json['requestType'] ?? json['RequestType'] ?? json['sRequestType'],
      ),
      sourceId: _toInt(
        json['sourceId'] ?? json['SourceId'] ?? json['iSourceId'],
      ),
      sourceNo: _toString(
        json['sourceNo'] ?? json['SourceNo'] ?? json['sSourceNo'],
      ),
      approvalLevel: _toInt(
        json['approvalLevel'] ??
            json['ApprovalLevel'] ??
            json['iApprovalLevel'],
      ),
      roleId: _toInt(json['roleId'] ?? json['RoleId'] ?? json['iRoleId']),
      roleName: _toString(
        json['roleName'] ?? json['RoleName'] ?? json['sRoleName'],
      ),
      approverUserId: _toInt(
        json['approverUserId'] ??
            json['ApproverUserId'] ??
            json['iApproverUserId'],
      ),
      approverName: _toString(
        json['approverName'] ?? json['ApproverName'] ?? json['sApproverName'],
      ),
      approvalStatus: _toString(
        json['approvalStatus'] ??
            json['ApprovalStatus'] ??
            json['sApprovalStatus'],
      ),
      remark: _toString(json['remark'] ?? json['Remark'] ?? json['sRemark']),
      approvalRemark: _toString(
        json['approvalRemark'] ??
            json['ApprovalRemark'] ??
            json['sApprovalRemark'],
      ),
      assignedDate: _toDateTime(
        json['assignedDate'] ?? json['AssignedDate'] ?? json['dAssignedDate'],
      ),
      actionDate: _toDateTime(
        json['actionDate'] ?? json['ActionDate'] ?? json['dActionDate'],
      ),
      isCurrentLevel: _toBool(
        json['isCurrentLevel'] ??
            json['IsCurrentLevel'] ??
            json['bIsCurrentLevel'],
      ),
      isFinalLevel: _toBool(
        json['isFinalLevel'] ?? json['IsFinalLevel'] ?? json['bIsFinalLevel'],
      ),
      isApproved: _toBool(
        json['isApproved'] ?? json['IsApproved'] ?? json['bIsApproved'],
      ),
      approvalMode: _toString(
        json['approvalMode'] ?? json['ApprovalMode'] ?? json['sApprovalMode'],
      ),
    );
  }

  String get displayStatus {
    switch (approvalStatus.trim().toUpperCase()) {
      case 'APPROVED':
        return 'Approved';
      case 'PENDING':
        return 'Pending';
      case 'REJECTED':
        return 'Rejected';
      case 'WAITING':
        return 'Waiting';
      default:
        return approvalStatus.trim().isEmpty ? '-' : approvalStatus.trim();
    }
  }

  String get displayAssignedDate => _formatDateTime(assignedDate);

  String get displayActionDate => _formatDateTime(actionDate);

  static String _formatDateTime(DateTime? value) {
    if (value == null) {
      return '-';
    }

    final dd = value.day.toString().padLeft(2, '0');

    final mm = value.month.toString().padLeft(2, '0');

    final yyyy = value.year.toString();

    final hh = value.hour.toString().padLeft(2, '0');

    final min = value.minute.toString().padLeft(2, '0');

    return '$dd-$mm-$yyyy $hh:$min';
  }

  static String _toString(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  static int _toInt(dynamic value) {
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

  static bool _toBool(dynamic value) {
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

    return text == 'true' || text == '1' || text == 'yes' || text == 'y';
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }
}
