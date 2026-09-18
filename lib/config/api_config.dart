class ApiConfig {
  ApiConfig._();

  // ============================================================
  // BASE URL
  // ============================================================
  //
  // UAT IIS API:
  // http://68.178.175.192/SCiRIDER_API
  //
  // Android Emulator local API:
  // http://10.0.2.2:5196
  //
  // Production:
  // Replace with HTTPS production API URL.
  // ============================================================

  static const String baseUrl = 'http://68.178.175.192/SCiRIDER_API';

  // ============================================================
  // AUTH
  // ============================================================

  static const String login = '$baseUrl/api/Auth/login';

  static const String validateToken = '$baseUrl/api/Auth/validate';

  // ============================================================
  // DASHBOARD
  // ============================================================

  static const String dashboard = '$baseUrl/api/Dashboard/summary';

  // ============================================================
  // APPROVAL LIST / USER
  // ============================================================

  static const String myApprovals = '$baseUrl/api/Approval/my-approvals';

  static const String documents = '$baseUrl/api/Approval/documents';

  static const String approvalCount = '$baseUrl/api/Approval/count';

  static const String approvalMe = '$baseUrl/api/Approval/me';

  // ============================================================
  // GENERIC APPROVAL DETAIL
  // ============================================================

  static String approvalDetail(int approvalTxnId) =>
      '$baseUrl/api/Approval/$approvalTxnId';

  // ============================================================
  // PR DETAIL
  // ============================================================
  //
  // approvalTxnId = ApprovalTransaction.iApprovalTxnId
  // ============================================================

  static String prDetail(int approvalTxnId) =>
      '$baseUrl/api/Approval/$approvalTxnId/pr-detail';

  // ============================================================
  // PO DETAIL
  // ============================================================
  //
  // IMPORTANT:
  // approvalTxnId = ApprovalTransaction.iApprovalTxnId
  //
  // Example:
  // ApprovalTxnId = 75
  // OrderId       = 3858
  //
  // PO detail uses ApprovalTxnId.
  // ============================================================

  static String poDetail(int approvalTxnId) =>
      '$baseUrl/api/Approval/$approvalTxnId/po-detail';

  // ============================================================
  // NFA DETAIL
  // ============================================================
  //
  // NFA detail also uses ApprovalTxnId.
  // ============================================================

  static String nfaDetail(int approvalTxnId) =>
      '$baseUrl/api/Approval/$approvalTxnId/nfa-detail';

  // ============================================================
  // PR APPROVAL EDIT / SAVE
  // ============================================================

  static const String savePRChanges = '$baseUrl/api/Approval/pr/save-changes';

  // ============================================================
  // APPROVE / REJECT
  // ============================================================

  static const String approve = '$baseUrl/api/Approval/approve';

  static const String reject = '$baseUrl/api/Approval/reject';

  // ============================================================
  // MASTER DATA
  // ============================================================

  static const String prDropdowns = '$baseUrl/api/Master/pr-dropdowns';

  // ============================================================
  // ATTACHMENT
  // ============================================================
  //
  // Uses ApprovalTxnId.
  //
  // NOTE:
  // Backend must have matching endpoint:
  // GET /api/Approval/{approvalTxnId}/attachment
  // ============================================================

  static String approvalAttachment(int approvalTxnId) =>
      '$baseUrl/api/Approval/$approvalTxnId/attachment';

  // ============================================================
  // DOCUMENT APPROVAL HISTORY
  // ============================================================
  //
  // IMPORTANT:
  // This uses document SourceId, NOT ApprovalTxnId.
  //
  // PR  -> PRSRId
  // SR  -> PRSRId
  // NFA -> NFAId
  // PO  -> OrderId
  // ============================================================

  static String documentHistory(String module, int sourceId) =>
      '$baseUrl/api/Approval/document-history/'
      '${Uri.encodeComponent(module.toUpperCase())}/$sourceId';

  // ============================================================
  // PR / SR CHANGE HISTORY
  // ============================================================

  static String changeHistory(String module, int sourceId) =>
      '$baseUrl/api/Approval/change-history/'
      '${Uri.encodeComponent(module.toUpperCase())}/$sourceId';

  // Existing ApprovalService compatibility alias.
  static String prsrChangeHistory(String module, int sourceId) =>
      changeHistory(module, sourceId);

  // ============================================================
  // DOCUMENT PDF
  // ============================================================
  //
  // IMPORTANT:
  // PDF endpoint uses SourceId, NOT ApprovalTxnId.
  //
  // PR:
  // /api/Approval/document-pdf/PR/{prsrId}
  //
  // SR:
  // /api/Approval/document-pdf/SR/{prsrId}
  //
  // NFA:
  // /api/Approval/document-pdf/NFA/{nfaId}
  //
  // PO:
  // /api/Approval/document-pdf/PO/{orderId}
  //
  // Example PO:
  // OrderId = 3858
  //
  // Mobile API:
  // /api/Approval/document-pdf/PO/3858
  //
  // Backend DocumentPdfService converts this to:
  // RDLC_Reports/frmPOPrint.aspx?POId=3858
  // ============================================================

  static String documentPdf(String module, int sourceId) =>
      '$baseUrl/api/Approval/document-pdf/'
      '${Uri.encodeComponent(module.toUpperCase())}/$sourceId';

  // ============================================================
  // MODULE-SPECIFIC PDF HELPERS
  // ============================================================

  static String prPdf(int prsrId) => documentPdf('PR', prsrId);

  static String srPdf(int prsrId) => documentPdf('SR', prsrId);

  static String nfaPdf(int nfaId) => documentPdf('NFA', nfaId);

  static String poPdf(int orderId) => documentPdf('PO', orderId);

  // ============================================================
  // HEALTH CHECK
  // ============================================================

  static const String health = '$baseUrl/health';

  // ============================================================
  // API ROOT
  // ============================================================

  static const String apiRoot = '$baseUrl/';
}
