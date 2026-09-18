class DocumentModel {
  final String module;
  final String requestType;
  final int sourceId;
  final String sourceNo;
  final int approvalLevel;
  final String documentStatus;
  final DateTime? documentDate;
  final bool userInApprovalHistory;
  final bool isActionable;

  const DocumentModel({
    required this.module,
    required this.requestType,
    required this.sourceId,
    required this.sourceNo,
    required this.approvalLevel,
    required this.documentStatus,
    required this.documentDate,
    required this.userInApprovalHistory,
    required this.isActionable,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
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
      documentStatus: _toString(
        json['documentStatus'] ??
            json['DocumentStatus'] ??
            json['sDocumentStatus'],
      ),
      documentDate: _toDateTime(
        json['documentDate'] ?? json['DocumentDate'] ?? json['dDocumentDate'],
      ),
      userInApprovalHistory: _toBool(
        json['userInApprovalHistory'] ??
            json['UserInApprovalHistory'] ??
            json['bUserInApprovalHistory'],
      ),
      isActionable: _toBool(
        json['isActionable'] ?? json['IsActionable'] ?? json['bIsActionable'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'module': module,
    'requestType': requestType,
    'sourceId': sourceId,
    'sourceNo': sourceNo,
    'approvalLevel': approvalLevel,
    'documentStatus': documentStatus,
    'documentDate': documentDate?.toIso8601String(),
    'userInApprovalHistory': userInApprovalHistory,
    'isActionable': isActionable,
  };

  String get displayModule =>
      module.trim().isEmpty ? '-' : module.trim().toUpperCase();
  String get displayRequestType =>
      requestType.trim().isEmpty ? '-' : requestType.trim();
  String get displaySourceNo => sourceNo.trim().isEmpty ? '-' : sourceNo.trim();

  String get displayStatus {
    switch (documentStatus.trim().toUpperCase()) {
      case 'APPROVED':
        return 'Approved';
      case 'PENDING':
        return 'Pending';
      case 'REJECTED':
        return 'Rejected';
      case 'IN PROCESS':
      case 'INPROCESS':
      case 'IN_PROCESS':
        return 'In Process';
      case 'WAITING':
        return 'Waiting';
      default:
        return documentStatus.trim().isEmpty ? '-' : documentStatus.trim();
    }
  }

  String get displayDate {
    final d = documentDate;
    if (d == null) return '-';
    return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
  }

  bool get isApproved => documentStatus.trim().toUpperCase() == 'APPROVED';
  bool get isPending => documentStatus.trim().toUpperCase() == 'PENDING';
  bool get isRejected => documentStatus.trim().toUpperCase() == 'REJECTED';
  bool get isReadOnly => !isActionable;

  static String _toString(dynamic value) =>
      value == null ? '' : value.toString().trim();

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value.toString().trim().toLowerCase();
    return text == 'true' || text == '1' || text == 'yes' || text == 'y';
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }
}
