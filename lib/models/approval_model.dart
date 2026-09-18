class ApprovalModel {
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
  final DateTime? assignedDate;
  final DateTime? actionDate;
  final bool isCurrentLevel;
  final bool isFinalLevel;
  final bool isApproved;
  final bool isDelegated;
  final bool isEscalated;
  final String approvalMode;

  const ApprovalModel({
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
    required this.assignedDate,
    required this.actionDate,
    required this.isCurrentLevel,
    required this.isFinalLevel,
    required this.isApproved,
    required this.isDelegated,
    required this.isEscalated,
    required this.approvalMode,
  });

  // ============================================================
  // JSON
  // ============================================================

  factory ApprovalModel.fromJson(Map<String, dynamic> json) {
    return ApprovalModel(
      approvalTxnId: _toInt(
        json['approvalTxnId'] ??
            json['iApprovalTxnId'],
      ),
      module: _toString(
        json['module'] ??
            json['sModule'],
      ),
      requestType: _toString(
        json['requestType'] ??
            json['sRequestType'],
      ),
      sourceId: _toInt(
        json['sourceId'] ??
            json['iSourceId'],
      ),
      sourceNo: _toString(
        json['sourceNo'] ??
            json['sSourceNo'],
      ),
      approvalLevel: _toInt(
        json['approvalLevel'] ??
            json['iApprovalLevel'],
      ),
      roleId: _toInt(
        json['roleId'] ??
            json['iRoleId'],
      ),
      roleName: _toString(
        json['roleName'] ??
            json['sRoleName'],
      ),
      approverUserId: _toInt(
        json['approverUserId'] ??
            json['iApproverUserId'],
      ),
      approverName: _toString(
        json['approverName'] ??
            json['sApproverName'],
      ),
      approvalStatus: _toString(
        json['approvalStatus'] ??
            json['sApprovalStatus'],
      ),
      remark: _toString(
        json['remark'] ??
            json['sRemark'],
      ),
      assignedDate: _toDateTime(
        json['assignedDate'] ??
            json['dAssignedDate'],
      ),
      actionDate: _toDateTime(
        json['actionDate'] ??
            json['dActionDate'],
      ),
      isCurrentLevel: _toBool(
        json['isCurrentLevel'] ??
            json['bIsCurrentLevel'],
      ),
      isFinalLevel: _toBool(
        json['isFinalLevel'] ??
            json['bIsFinalLevel'],
      ),
      isApproved: _toBool(
        json['isApproved'] ??
            json['bIsApproved'],
      ),
      isDelegated: _toBool(
        json['isDelegated'] ??
            json['bIsDelegated'],
      ),
      isEscalated: _toBool(
        json['isEscalated'] ??
            json['bIsEscalated'] ??
            json['bEscalated'],
      ),
      approvalMode: _toString(
        json['approvalMode'] ??
            json['sApprovalMode'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'approvalTxnId': approvalTxnId,
      'module': module,
      'requestType': requestType,
      'sourceId': sourceId,
      'sourceNo': sourceNo,
      'approvalLevel': approvalLevel,
      'roleId': roleId,
      'roleName': roleName,
      'approverUserId': approverUserId,
      'approverName': approverName,
      'approvalStatus': approvalStatus,
      'remark': remark,
      'assignedDate': assignedDate?.toIso8601String(),
      'actionDate': actionDate?.toIso8601String(),
      'isCurrentLevel': isCurrentLevel,
      'isFinalLevel': isFinalLevel,
      'isApproved': isApproved,
      'isDelegated': isDelegated,
      'isEscalated': isEscalated,
      'approvalMode': approvalMode,
    };
  }

  // ============================================================
  // CONVENIENCE
  // ============================================================

  String get normalizedModule =>
      module.trim().toUpperCase();

  String get normalizedStatus =>
      approvalStatus.trim().toUpperCase();

  bool get isPO =>
      normalizedModule == 'PO';

  bool get isPR =>
      normalizedModule == 'PR';

  bool get isSR =>
      normalizedModule == 'SR';

  bool get isPRorSR =>
      normalizedModule == 'PR' ||
      normalizedModule == 'SR' ||
      normalizedModule == 'PRSR';

  bool get isNFA =>
      normalizedModule == 'NFA';

  bool get isPending =>
      normalizedStatus == 'PENDING' ||
      normalizedStatus == 'PENDING APPROVAL';

  bool get canTakeAction =>
      isPending &&
      isCurrentLevel &&
      !isApproved;

  ApprovalModel copyWith({
    int? approvalTxnId,
    String? module,
    String? requestType,
    int? sourceId,
    String? sourceNo,
    int? approvalLevel,
    int? roleId,
    String? roleName,
    int? approverUserId,
    String? approverName,
    String? approvalStatus,
    String? remark,
    DateTime? assignedDate,
    bool clearAssignedDate = false,
    DateTime? actionDate,
    bool clearActionDate = false,
    bool? isCurrentLevel,
    bool? isFinalLevel,
    bool? isApproved,
    bool? isDelegated,
    bool? isEscalated,
    String? approvalMode,
  }) {
    return ApprovalModel(
      approvalTxnId:
          approvalTxnId ?? this.approvalTxnId,
      module:
          module ?? this.module,
      requestType:
          requestType ?? this.requestType,
      sourceId:
          sourceId ?? this.sourceId,
      sourceNo:
          sourceNo ?? this.sourceNo,
      approvalLevel:
          approvalLevel ?? this.approvalLevel,
      roleId:
          roleId ?? this.roleId,
      roleName:
          roleName ?? this.roleName,
      approverUserId:
          approverUserId ?? this.approverUserId,
      approverName:
          approverName ?? this.approverName,
      approvalStatus:
          approvalStatus ?? this.approvalStatus,
      remark:
          remark ?? this.remark,
      assignedDate:
          clearAssignedDate
              ? null
              : assignedDate ?? this.assignedDate,
      actionDate:
          clearActionDate
              ? null
              : actionDate ?? this.actionDate,
      isCurrentLevel:
          isCurrentLevel ?? this.isCurrentLevel,
      isFinalLevel:
          isFinalLevel ?? this.isFinalLevel,
      isApproved:
          isApproved ?? this.isApproved,
      isDelegated:
          isDelegated ?? this.isDelegated,
      isEscalated:
          isEscalated ?? this.isEscalated,
      approvalMode:
          approvalMode ?? this.approvalMode,
    );
  }

  // ============================================================
  // SAFE CONVERTERS
  // ============================================================

  static String _toString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value.toString().trim(),
        ) ??
        0;
  }

  static bool _toBool(dynamic value) {
    if (value == null) return false;

    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final text =
        value.toString().trim().toUpperCase();

    return text == 'TRUE' ||
        text == '1' ||
        text == 'YES' ||
        text == 'Y';
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) {
      return value;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }

  @override
  String toString() {
    return 'ApprovalModel('
        'approvalTxnId: $approvalTxnId, '
        'module: $module, '
        'requestType: $requestType, '
        'sourceId: $sourceId, '
        'sourceNo: $sourceNo, '
        'approvalLevel: $approvalLevel, '
        'roleName: $roleName, '
        'approverUserId: $approverUserId, '
        'approverName: $approverName, '
        'approvalStatus: $approvalStatus, '
        'isCurrentLevel: $isCurrentLevel, '
        'isFinalLevel: $isFinalLevel'
        ')';
  }
}
