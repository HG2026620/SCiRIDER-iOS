class PODetailModel {
  final int approvalTxnId;
  final int orderId;

  final String orderNo;
  final String orderType;
  final String financialYear;

  final int? nfaId;
  final String nfaNo;

  final int companyId;
  final int projectId;
  final int departmentId;
  final int vendorId;

  final DateTime? orderDate;
  final DateTime? deliveryDate;
  final DateTime? expectedDate;

  final String vendorCode;
  final String vendorName;
  final String vendorAddress;
  final String vendorGSTNo;
  final String vendorPANNo;
  final String vendorPhoneNo;
  final String vendorEmail;

  final String companyName;
  final String projectName;
  final String departmentName;

  final String subject;
  final String reference;
  final String poReference;
  final String remark;
  final String note;

  final String currency;
  final String currencyName;

  final String paymentTerms;
  final String warrantyTerms;
  final String deliveryTerms;
  final String cartageTerms;
  final String invoiceTerms;
  final String modeOfPaymentName;
  final String priceBasisName;
  final String poValidityName;

  final String billToCompanyName;
  final String billToCompanyAddress;
  final String billToGSTNo;

  final String shipToCompanyName;
  final String shipToCompanyAddress;
  final String shipToGSTNo;

  final String deliveryAddress;
  final String siteDetails;

  final double basicTotal;
  final double discountAmount;
  final double taxAmount;
  final double otherCharges;
  final double totalAmount;
  final double grandTotal;
  final double poAmount;

  final String status;
  final String approvalStatus;

  final int currentApprovalLevel;

  final bool isLocked;
  final bool isApproved;
  final bool isRejected;
  final bool isClosed;
  final bool isCancelled;

  final int approvalLevel;
  final int? roleId;
  final String roleName;

  final int? approverUserId;
  final String approverName;

  final String currentApprovalStatus;

  final bool isCurrentLevel;
  final bool isFinalLevel;
  final bool currentLevelApproved;

  final String approvalRemark;
  final String approvalActionRemark;

  final DateTime? assignedDate;
  final DateTime? actionDate;

  final String approvalMode;

  final List<POItemModel> items;
  final List<POApprovalHistoryModel> approvalHistory;

  PODetailModel({
    required this.approvalTxnId,
    required this.orderId,
    required this.orderNo,
    required this.orderType,
    required this.financialYear,
    this.nfaId,
    required this.nfaNo,
    required this.companyId,
    required this.projectId,
    required this.departmentId,
    required this.vendorId,
    this.orderDate,
    this.deliveryDate,
    this.expectedDate,
    required this.vendorCode,
    required this.vendorName,
    required this.vendorAddress,
    required this.vendorGSTNo,
    required this.vendorPANNo,
    required this.vendorPhoneNo,
    required this.vendorEmail,
    required this.companyName,
    required this.projectName,
    required this.departmentName,
    required this.subject,
    required this.reference,
    required this.poReference,
    required this.remark,
    required this.note,
    required this.currency,
    required this.currencyName,
    required this.paymentTerms,
    required this.warrantyTerms,
    required this.deliveryTerms,
    required this.cartageTerms,
    required this.invoiceTerms,
    required this.modeOfPaymentName,
    required this.priceBasisName,
    required this.poValidityName,
    required this.billToCompanyName,
    required this.billToCompanyAddress,
    required this.billToGSTNo,
    required this.shipToCompanyName,
    required this.shipToCompanyAddress,
    required this.shipToGSTNo,
    required this.deliveryAddress,
    required this.siteDetails,
    required this.basicTotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.otherCharges,
    required this.totalAmount,
    required this.grandTotal,
    required this.poAmount,
    required this.status,
    required this.approvalStatus,
    required this.currentApprovalLevel,
    required this.isLocked,
    required this.isApproved,
    required this.isRejected,
    required this.isClosed,
    required this.isCancelled,
    required this.approvalLevel,
    this.roleId,
    required this.roleName,
    this.approverUserId,
    required this.approverName,
    required this.currentApprovalStatus,
    required this.isCurrentLevel,
    required this.isFinalLevel,
    required this.currentLevelApproved,
    required this.approvalRemark,
    required this.approvalActionRemark,
    this.assignedDate,
    this.actionDate,
    required this.approvalMode,
    required this.items,
    required this.approvalHistory,
  });

  factory PODetailModel.fromJson(Map<String, dynamic> json) {
    return PODetailModel(
      approvalTxnId: _toInt(json['approvalTxnId']),
      orderId: _toInt(json['orderId']),

      orderNo: _toString(json['orderNo']),
      orderType: _toString(json['orderType']),
      financialYear: _toString(json['financialYear']),

      nfaId: _toNullableInt(json['nfaId']),
      nfaNo: _toString(json['nfaNo']),

      companyId: _toInt(json['companyId']),
      projectId: _toInt(json['projectId']),
      departmentId: _toInt(json['departmentId']),
      vendorId: _toInt(json['vendorId']),

      orderDate: _toDate(json['orderDate']),
      deliveryDate: _toDate(json['deliveryDate']),
      expectedDate: _toDate(json['expectedDate']),

      vendorCode: _toString(json['vendorCode']),
      vendorName: _toString(json['vendorName']),
      vendorAddress: _toString(json['vendorAddress']),
      vendorGSTNo: _toString(json['vendorGSTNo']),
      vendorPANNo: _toString(json['vendorPANNo']),
      vendorPhoneNo: _toString(json['vendorPhoneNo']),
      vendorEmail: _toString(json['vendorEmail']),

      companyName: _toString(json['companyName']),
      projectName: _toString(json['projectName']),
      departmentName: _toString(json['departmentName']),

      subject: _toString(json['subject']),
      reference: _toString(json['reference']),
      poReference: _toString(json['poReference']),
      remark: _toString(json['remark']),
      note: _toString(json['note']),

      currency: _toString(json['currency']),
      currencyName: _toString(json['currencyName']),

      paymentTerms: _toString(json['paymentTerms']),
      warrantyTerms: _toString(json['warrantyTerms']),
      deliveryTerms: _toString(json['deliveryTerms']),
      cartageTerms: _toString(json['cartageTerms']),
      invoiceTerms: _toString(json['invoiceTerms']),
      modeOfPaymentName: _toString(json['modeOfPaymentName']),
      priceBasisName: _toString(json['priceBasisName']),
      poValidityName: _toString(json['poValidityName']),

      billToCompanyName: _toString(json['billToCompanyName']),
      billToCompanyAddress: _toString(json['billToCompanyAddress']),
      billToGSTNo: _toString(json['billToGSTNo']),

      shipToCompanyName: _toString(json['shipToCompanyName']),
      shipToCompanyAddress: _toString(json['shipToCompanyAddress']),
      shipToGSTNo: _toString(json['shipToGSTNo']),

      deliveryAddress: _toString(json['deliveryAddress']),
      siteDetails: _toString(json['siteDetails']),

      basicTotal: _toDouble(json['basicTotal']),
      discountAmount: _toDouble(json['discountAmount']),
      taxAmount: _toDouble(json['taxAmount']),
      otherCharges: _toDouble(json['otherCharges']),
      totalAmount: _toDouble(json['totalAmount']),
      grandTotal: _toDouble(json['grandTotal']),
      poAmount: _toDouble(json['poAmount']),

      status: _toString(json['status']),
      approvalStatus: _toString(json['approvalStatus']),

      currentApprovalLevel: _toInt(json['currentApprovalLevel']),

      isLocked: _toBool(json['isLocked']),
      isApproved: _toBool(json['isApproved']),
      isRejected: _toBool(json['isRejected']),
      isClosed: _toBool(json['isClosed']),
      isCancelled: _toBool(json['isCancelled']),

      approvalLevel: _toInt(json['approvalLevel']),
      roleId: _toNullableInt(json['roleId']),
      roleName: _toString(json['roleName']),

      approverUserId: _toNullableInt(json['approverUserId']),
      approverName: _toString(json['approverName']),

      currentApprovalStatus: _toString(json['currentApprovalStatus']),

      isCurrentLevel: _toBool(json['isCurrentLevel']),
      isFinalLevel: _toBool(json['isFinalLevel']),
      currentLevelApproved: _toBool(json['currentLevelApproved']),

      approvalRemark: _toString(json['approvalRemark']),
      approvalActionRemark: _toString(json['approvalActionRemark']),

      assignedDate: _toDate(json['assignedDate']),
      actionDate: _toDate(json['actionDate']),

      approvalMode: _toString(json['approvalMode']),

      items: (json['items'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => POItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),

      approvalHistory: (json['approvalHistory'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (e) =>
                POApprovalHistoryModel.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
    );
  }
}

class POItemModel {
  final int orderDetailId;
  final int orderId;
  final int itemId;

  final String itemCode;
  final String itemName;
  final String description;
  final String uom;
  final String hsnCode;
  final String make;
  final String specification;

  final double qty;
  final double rate;
  final double basicAmount;

  final double discountPer;
  final double discountAmount;
  final double rateAfterDiscount;

  final double cgstPer;
  final double cgstAmount;

  final double sgstPer;
  final double sgstAmount;

  final double igstPer;
  final double igstAmount;

  final double taxAmount;
  final double lineTotal;

  final String remark;
  final String lineStatus;

  POItemModel({
    required this.orderDetailId,
    required this.orderId,
    required this.itemId,
    required this.itemCode,
    required this.itemName,
    required this.description,
    required this.uom,
    required this.hsnCode,
    required this.make,
    required this.specification,
    required this.qty,
    required this.rate,
    required this.basicAmount,
    required this.discountPer,
    required this.discountAmount,
    required this.rateAfterDiscount,
    required this.cgstPer,
    required this.cgstAmount,
    required this.sgstPer,
    required this.sgstAmount,
    required this.igstPer,
    required this.igstAmount,
    required this.taxAmount,
    required this.lineTotal,
    required this.remark,
    required this.lineStatus,
  });

  factory POItemModel.fromJson(Map<String, dynamic> json) {
    return POItemModel(
      orderDetailId: _toInt(json['orderDetailId']),
      orderId: _toInt(json['orderId']),
      itemId: _toInt(json['itemId']),

      itemCode: _toString(json['itemCode']),
      itemName: _toString(json['itemName']),
      description: _toString(json['description']),
      uom: _toString(json['uom']),
      hsnCode: _toString(json['hsnCode']),
      make: _toString(json['make']),
      specification: _toString(json['specification']),

      qty: _toDouble(json['qty']),
      rate: _toDouble(json['rate']),
      basicAmount: _toDouble(json['basicAmount']),

      discountPer: _toDouble(json['discountPer']),
      discountAmount: _toDouble(json['discountAmount']),
      rateAfterDiscount: _toDouble(json['rateAfterDiscount']),

      cgstPer: _toDouble(json['cgstPer']),
      cgstAmount: _toDouble(json['cgstAmount']),

      sgstPer: _toDouble(json['sgstPer']),
      sgstAmount: _toDouble(json['sgstAmount']),

      igstPer: _toDouble(json['igstPer']),
      igstAmount: _toDouble(json['igstAmount']),

      taxAmount: _toDouble(json['taxAmount']),
      lineTotal: _toDouble(json['lineTotal']),

      remark: _toString(json['remark']),
      lineStatus: _toString(json['lineStatus']),
    );
  }
}

class POApprovalHistoryModel {
  final int approvalTxnId;
  final int approvalLevel;

  final int? roleId;
  final String roleName;

  final int? approverUserId;
  final String approverName;

  final String approvalStatus;
  final String remark;
  final String approvalRemark;

  final DateTime? assignedDate;
  final DateTime? actionDate;

  final bool isCurrentLevel;
  final bool isFinalLevel;
  final bool isApproved;

  final bool isDelegated;
  final bool isEscalated;
  final bool isForceAction;

  final String approvalMode;

  POApprovalHistoryModel({
    required this.approvalTxnId,
    required this.approvalLevel,
    this.roleId,
    required this.roleName,
    this.approverUserId,
    required this.approverName,
    required this.approvalStatus,
    required this.remark,
    required this.approvalRemark,
    this.assignedDate,
    this.actionDate,
    required this.isCurrentLevel,
    required this.isFinalLevel,
    required this.isApproved,
    required this.isDelegated,
    required this.isEscalated,
    required this.isForceAction,
    required this.approvalMode,
  });

  factory POApprovalHistoryModel.fromJson(Map<String, dynamic> json) {
    return POApprovalHistoryModel(
      approvalTxnId: _toInt(json['approvalTxnId']),
      approvalLevel: _toInt(json['approvalLevel']),

      roleId: _toNullableInt(json['roleId']),
      roleName: _toString(json['roleName']),

      approverUserId: _toNullableInt(json['approverUserId']),
      approverName: _toString(json['approverName']),

      approvalStatus: _toString(json['approvalStatus']),
      remark: _toString(json['remark']),
      approvalRemark: _toString(json['approvalRemark']),

      assignedDate: _toDate(json['assignedDate']),
      actionDate: _toDate(json['actionDate']),

      isCurrentLevel: _toBool(json['isCurrentLevel']),
      isFinalLevel: _toBool(json['isFinalLevel']),
      isApproved: _toBool(json['isApproved']),

      isDelegated: _toBool(json['isDelegated']),
      isEscalated: _toBool(json['isEscalated']),
      isForceAction: _toBool(json['isForceAction']),

      approvalMode: _toString(json['approvalMode']),
    );
  }
}

// ============================================================
// JSON HELPERS
// ============================================================

int _toInt(dynamic value) {
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

int? _toNullableInt(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString());
}

double _toDouble(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString()) ?? 0;
}

bool _toBool(dynamic value) {
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

String _toString(dynamic value) {
  return value?.toString().trim() ?? '';
}

DateTime? _toDate(dynamic value) {
  if (value == null) {
    return null;
  }

  final text = value.toString().trim();

  if (text.isEmpty) {
    return null;
  }

  return DateTime.tryParse(text);
}
