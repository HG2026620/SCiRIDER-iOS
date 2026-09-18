class PRSRChangeHistoryModel {
  final int changeLogId;
  final int prsrId;
  final int? approvalTxnId;
  final int approvalLevel;
  final String changeType;
  final int? prsrDetailId;
  final String fieldName;
  final String fieldCaption;
  final String oldValue;
  final String newValue;
  final int changedBy;
  final String changedByName;
  final DateTime? changedOn;
  final String action;
  final String remarks;
  final String changeArea;

  const PRSRChangeHistoryModel({
    required this.changeLogId,
    required this.prsrId,
    required this.approvalTxnId,
    required this.approvalLevel,
    required this.changeType,
    required this.prsrDetailId,
    required this.fieldName,
    required this.fieldCaption,
    required this.oldValue,
    required this.newValue,
    required this.changedBy,
    required this.changedByName,
    required this.changedOn,
    required this.action,
    required this.remarks,
    required this.changeArea,
  });

  factory PRSRChangeHistoryModel.fromJson(Map<String, dynamic> json) {
    return PRSRChangeHistoryModel(
      changeLogId: _toInt(json['changeLogId']),
      prsrId: _toInt(json['prsrId']),
      approvalTxnId: _toNullableInt(json['approvalTxnId']),
      approvalLevel: _toInt(json['approvalLevel']),
      changeType: _toString(json['changeType']),
      prsrDetailId: _toNullableInt(json['prsrDetailId']),
      fieldName: _toString(json['fieldName']),
      fieldCaption: _toString(json['fieldCaption']),
      oldValue: _toString(json['oldValue']),
      newValue: _toString(json['newValue']),
      changedBy: _toInt(json['changedBy']),
      changedByName: _toString(json['changedByName']),
      changedOn: _toDateTime(json['changedOn']),
      action: _toString(json['action']),
      remarks: _toString(json['remarks']),
      changeArea: _toString(json['changeArea']),
    );
  }

  String get displayFieldCaption {
    if (fieldCaption.trim().isNotEmpty) {
      return fieldCaption.trim();
    }
    if (fieldName.trim().isNotEmpty) {
      return fieldName.trim();
    }
    return 'Field';
  }

  String get displayOldValue =>
      oldValue.trim().isEmpty ? '(blank)' : oldValue.trim();

  String get displayNewValue =>
      newValue.trim().isEmpty ? '(blank)' : newValue.trim();

  String get displayChangedBy {
    if (changedByName.trim().isNotEmpty) {
      return changedByName.trim();
    }
    return changedBy > 0 ? 'User #$changedBy' : '-';
  }

  String get displayChangeArea =>
      changeArea.trim().isEmpty ? 'CHANGE' : changeArea.trim().toUpperCase();

  String get displayChangedOn => _formatDateTime(changedOn);

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static String _toString(dynamic value) => value?.toString() ?? '';

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  static String _formatDateTime(DateTime? value) {
    if (value == null) return '-';

    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = _monthName(local.month);
    final year = local.year.toString();
    final hour24 = local.hour;
    final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';

    return '$day $month $year ${hour12.toString().padLeft(2, '0')}:$minute $period';
  }

  static String _monthName(int month) {
    const months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }
}
