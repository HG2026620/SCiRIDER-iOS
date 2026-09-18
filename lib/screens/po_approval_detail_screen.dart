import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../models/approval_model.dart';
import '../services/approval_service.dart';

class POApprovalDetailScreen extends StatefulWidget {
  final ApprovalModel approval;

  const POApprovalDetailScreen({super.key, required this.approval});

  @override
  State<POApprovalDetailScreen> createState() => _POApprovalDetailScreenState();
}

class _POApprovalDetailScreenState extends State<POApprovalDetailScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color primaryBlue = Color(0xFF079BD3);
  static const Color primaryBlueDark = Color(0xFF067FAE);
  static const Color navyBlue = Color(0xFF173F6B);
  static const Color pageBackground = Color(0xFFF4F8FB);

  // ============================================================
  // SERVICES / CONTROLLERS
  // ============================================================

  final ApprovalService _approvalService = ApprovalService();

  final TextEditingController _approvalRemarkController =
      TextEditingController();

  final ScrollController _scrollController = ScrollController();

  // ============================================================
  // STATE
  // ============================================================

  bool _loading = true;
  bool _processingAction = false;
  bool _downloadingPdf = false;
  bool _loadingAttachment = false;

  bool _hasAttachment = false;

  String? _errorMessage;

  Map<String, dynamic> _po = <String, dynamic>{};
  Map<String, dynamic> _attachment = <String, dynamic>{};

  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _approvalHistory = <Map<String, dynamic>>[];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _approvalRemarkController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // CURRENT APPROVAL TXN ID
  //
  // Detail / Approve / Reject / Attachment use transaction ID.
  // ============================================================

  int get _currentApprovalTxnId {
    final int detailTxnId = _int(
      _value(_po, const [
        'approvalTxnId',
        'iApprovalTxnId',
        'currentApprovalTxnId',
        'iCurrentApprovalTxnId',
        'ApprovalTxnId',
      ]),
    );

    if (detailTxnId > 0) {
      return detailTxnId;
    }

    return widget.approval.approvalTxnId;
  }

  // ============================================================
  // ORDER / SOURCE ID
  //
  // Document History / PDF use source ID.
  // ============================================================

  int get _orderId {
    int id = _int(
      _value(_po, const ['orderId', 'iOrderId', 'sourceId', 'iSourceId']),
    );

    if (id <= 0) {
      id = widget.approval.sourceId;
    }

    return id;
  }

  // ============================================================
  // LOAD PO DETAIL
  // ============================================================

  Future<void> _loadDetail({bool preserveScroll = false}) async {
    if (!mounted) return;

    final double previousOffset = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final int approvalTxnId = widget.approval.approvalTxnId;

      debugPrint('');
      debugPrint(
        '============================================================',
      );
      debugPrint('SCiRIDER: PO DETAIL');
      debugPrint('Module        : ${widget.approval.module}');
      debugPrint('ApprovalTxnId : $approvalTxnId');
      debugPrint('SourceId      : ${widget.approval.sourceId}');
      debugPrint(
        '============================================================',
      );

      if (approvalTxnId <= 0) {
        throw Exception('Invalid PO approval transaction ID.');
      }

      // =========================================================
      // 1. PO DETAIL
      // =========================================================

      final Map<String, dynamic> detail = await _approvalService.getPODetail(
        approvalTxnId,
      );

      if (detail.isEmpty) {
        throw Exception('Purchase Order detail was not returned by the API.');
      }

      _po = Map<String, dynamic>.from(detail);

      // =========================================================
      // 2. ITEMS
      // =========================================================

      _items = ApprovalService.getMapList(_po['items'] ?? _po['Items']);

      debugPrint('SCiRIDER: PO ITEMS = ${_items.length}');

      debugPrint('SCiRIDER: PO ORDER ID = $_orderId');

      debugPrint(
        'SCiRIDER: PO LIST TXN ID = '
        '${widget.approval.approvalTxnId}',
      );

      debugPrint(
        'SCiRIDER: PO CURRENT TXN ID = '
        '$_currentApprovalTxnId',
      );

      // =========================================================
      // 3. COMPLETE APPROVAL HISTORY
      //
      // IMPORTANT:
      // Uses PO source/order ID, NOT approval transaction ID.
      // =========================================================

      _approvalHistory = <Map<String, dynamic>>[];

      final int sourceId = _orderId;

      if (sourceId > 0) {
        try {
          debugPrint('');
          debugPrint(
            '============================================================',
          );
          debugPrint('SCiRIDER: LOAD COMPLETE PO HISTORY');
          debugPrint('Module        : PO');
          debugPrint('SourceId      : $sourceId');
          debugPrint('ApprovalTxnId : $approvalTxnId');
          debugPrint(
            '============================================================',
          );

          final history = await _approvalService.getDocumentApprovalHistory(
            module: 'PO',
            sourceId: sourceId,
          );

          _approvalHistory = history.map<Map<String, dynamic>>((item) {
            return <String, dynamic>{
              'approvalTxnId': item.approvalTxnId,
              'iApprovalTxnId': item.approvalTxnId,

              'approvalLevel': item.approvalLevel,
              'iApprovalLevel': item.approvalLevel,

              'roleId': item.roleId,
              'iRoleId': item.roleId,

              'roleName': item.roleName,
              'sRoleName': item.roleName,

              'approverUserId': item.approverUserId,
              'iApproverUserId': item.approverUserId,

              'approverName': item.approverName,
              'sApproverName': item.approverName,

              'approvalStatus': item.approvalStatus,
              'sApprovalStatus': item.approvalStatus,

              'assignedDate': item.assignedDate,
              'dAssignedDate': item.assignedDate,

              'actionDate': item.actionDate,
              'dActionDate': item.actionDate,

              'approvalRemark': item.approvalRemark,
              'sApprovalRemark': item.approvalRemark,

              'remark': item.approvalRemark,

              'isCurrentLevel': item.isCurrentLevel,
              'bIsCurrentLevel': item.isCurrentLevel,

              'isFinalLevel': item.isFinalLevel,
              'bIsFinalLevel': item.isFinalLevel,

              'isApproved': item.isApproved,

              'approvalMode': item.approvalMode,
            };
          }).toList();

          debugPrint(
            'SCiRIDER: PO DOCUMENT HISTORY COUNT = '
            '${_approvalHistory.length}',
          );

          for (final Map<String, dynamic> row in _approvalHistory) {
            debugPrint(
              'PO HISTORY => '
              'Txn=${_value(row, const ['approvalTxnId'])}, '
              'Level=${_value(row, const ['approvalLevel'])}, '
              'Approver=${_value(row, const ['approverName'])}, '
              'Status=${_value(row, const ['approvalStatus'])}',
            );
          }
        } catch (e, stackTrace) {
          debugPrint('SCiRIDER: PO DOCUMENT HISTORY ERROR: $e');

          debugPrint('$stackTrace');
        }
      }

      // =========================================================
      // 4. HISTORY FALLBACK
      //
      // If document-history has no rows, use po-detail history.
      // =========================================================

      if (_approvalHistory.isEmpty) {
        debugPrint(
          'SCiRIDER: Dedicated PO history empty. '
          'Using PO detail history fallback.',
        );

        _approvalHistory = ApprovalService.getMapList(
          _po['approvalHistory'] ?? _po['ApprovalHistory'],
        );
      }

      debugPrint(
        'SCiRIDER: FINAL PO APPROVAL HISTORY = '
        '${_approvalHistory.length}',
      );

      // =========================================================
      // 5. ATTACHMENT
      // =========================================================

      await _loadAttachment(updateUi: false);

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      // =========================================================
      // 6. RESTORE SCROLL
      // =========================================================

      if (preserveScroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_scrollController.hasClients) {
            return;
          }

          final double maxScroll = _scrollController.position.maxScrollExtent;

          final double target = previousOffset.clamp(0.0, maxScroll).toDouble();

          _scrollController.jumpTo(target);
        });
      }
    } catch (e, stackTrace) {
      debugPrint('SCiRIDER: PO DETAIL ERROR: $e');

      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _loading = false;

        _errorMessage = e.toString().replaceFirst('Exception: ', '').trim();
      });
    }
  }

  // ============================================================
  // LOAD ATTACHMENT
  // ============================================================

  Future<void> _loadAttachment({bool updateUi = true}) async {
    final int approvalTxnId = _currentApprovalTxnId;

    if (approvalTxnId <= 0) {
      return;
    }

    if (updateUi && mounted) {
      setState(() {
        _loadingAttachment = true;
      });
    }

    try {
      debugPrint(
        'SCiRIDER: Loading PO attachment for '
        'ApprovalTxnId=$approvalTxnId',
      );

      final Map<String, dynamic> result = await _approvalService.getAttachment(
        approvalTxnId,
      );

      debugPrint('SCiRIDER: PO ATTACHMENT RESPONSE = $result');

      _attachment = Map<String, dynamic>.from(result);

      _hasAttachment =
          _attachment.isNotEmpty &&
          _boolValue(_attachment, const ['success', 'Success']);

      if (_attachment.isNotEmpty &&
          !_attachment.containsKey('success') &&
          !_attachment.containsKey('Success')) {
        _hasAttachment = true;
      }
    } catch (e) {
      debugPrint('SCiRIDER: PO attachment not available: $e');

      _attachment = <String, dynamic>{};

      _hasAttachment = false;
    } finally {
      if (updateUi && mounted) {
        setState(() {
          _loadingAttachment = false;
        });
      }
    }
  }

  // ============================================================
  // APPROVE
  // ============================================================

  Future<void> _approve() async {
    if (_processingAction) {
      return;
    }

    final bool? confirmed = await _confirmAction(
      title: 'Approve Purchase Order',
      message: 'Are you sure you want to approve this Purchase Order?',
      confirmText: 'Approve',
      confirmColor: Colors.green,
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final int txnId = _currentApprovalTxnId;

    if (txnId <= 0) {
      _showMessage('Approval transaction ID not found.', isError: true);

      return;
    }

    setState(() {
      _processingAction = true;
    });

    try {
      final String remark = _approvalRemarkController.text.trim();

      debugPrint('');
      debugPrint(
        '############################################################',
      );
      debugPrint('PO APPROVAL BUTTON PRESSED');
      debugPrint(
        '############################################################',
      );
      debugPrint(
        'List Txn ID    : '
        '${widget.approval.approvalTxnId}',
      );
      debugPrint('Current Txn ID : $txnId');
      debugPrint('Order ID       : $_orderId');
      debugPrint('Status         : $_currentStatus');
      debugPrint('Remark         : $remark');
      debugPrint(
        '############################################################',
      );

      final Map<String, dynamic> response = await _approvalService.approve(
        approvalTxnId: txnId,
        remark: remark,
      );

      debugPrint('SCiRIDER PO APPROVE RESPONSE: $response');

      if (!mounted) return;

      final bool success = _boolValue(response, const ['success', 'Success']);

      final String message = _text(
        _value(response, const ['message', 'Message']),
      );

      _showMessage(
        message.isNotEmpty
            ? message
            : success
            ? 'Purchase Order approved successfully.'
            : 'Unable to approve Purchase Order.',
        isError: !success,
      );

      if (success) {
        _approvalRemarkController.clear();

        await Future<void>.delayed(const Duration(milliseconds: 400));

        if (!mounted) return;

        Navigator.of(context).pop(true);
      }
    } catch (e, stackTrace) {
      debugPrint('SCiRIDER PO APPROVE ERROR: $e');

      debugPrint('$stackTrace');

      if (!mounted) return;

      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _processingAction = false;
        });
      }
    }
  }

  // ============================================================
  // REJECT
  // ============================================================

  Future<void> _reject() async {
    if (_processingAction) {
      return;
    }

    final String remark = _approvalRemarkController.text.trim();

    if (remark.isEmpty) {
      _showMessage('Please enter a rejection remark.', isError: true);

      return;
    }

    final bool? confirmed = await _confirmAction(
      title: 'Reject Purchase Order',
      message: 'Are you sure you want to reject this Purchase Order?',
      confirmText: 'Reject',
      confirmColor: Colors.red,
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final int txnId = _currentApprovalTxnId;

    if (txnId <= 0) {
      _showMessage('Approval transaction ID not found.', isError: true);

      return;
    }

    setState(() {
      _processingAction = true;
    });

    try {
      debugPrint('');
      debugPrint(
        '############################################################',
      );
      debugPrint('PO REJECT BUTTON PRESSED');
      debugPrint(
        '############################################################',
      );
      debugPrint(
        'List Txn ID    : '
        '${widget.approval.approvalTxnId}',
      );
      debugPrint('Current Txn ID : $txnId');
      debugPrint('Order ID       : $_orderId');
      debugPrint('Remark         : $remark');
      debugPrint(
        '############################################################',
      );

      final Map<String, dynamic> response = await _approvalService.reject(
        approvalTxnId: txnId,
        remark: remark,
      );

      debugPrint('SCiRIDER PO REJECT RESPONSE: $response');

      if (!mounted) return;

      final bool success = _boolValue(response, const ['success', 'Success']);

      final String message = _text(
        _value(response, const ['message', 'Message']),
      );

      _showMessage(
        message.isNotEmpty
            ? message
            : success
            ? 'Purchase Order rejected successfully.'
            : 'Unable to reject Purchase Order.',
        isError: !success,
      );

      if (success) {
        _approvalRemarkController.clear();

        await Future<void>.delayed(const Duration(milliseconds: 400));

        if (!mounted) return;

        Navigator.of(context).pop(true);
      }
    } catch (e, stackTrace) {
      debugPrint('SCiRIDER PO REJECT ERROR: $e');

      debugPrint('$stackTrace');

      if (!mounted) return;

      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _processingAction = false;
        });
      }
    }
  }

  // ============================================================
  // CURRENT STATUS
  // ============================================================

  String get _currentStatus {
    return _text(
      _value(_po, const [
        'currentApprovalStatus',
        'sCurrentApprovalStatus',
        'approvalStatus',
        'sApprovalStatus',
        'status',
        'sStatus',
      ]),
    );
  }

  // ============================================================
  // CONFIRM ACTION
  // ============================================================

  Future<bool?> _confirmAction({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: confirmColor),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DOWNLOAD / OPEN PDF
  // ============================================================

  Future<void> _downloadPdf() async {
    if (_downloadingPdf) {
      return;
    }

    // IMPORTANT:
    // PDF uses Order/Source ID.
    final int orderId = _orderId;

    if (orderId <= 0) {
      _showMessage(
        'Purchase Order document ID is not available.',
        isError: true,
      );

      return;
    }

    setState(() {
      _downloadingPdf = true;
    });

    try {
      debugPrint('');
      debugPrint(
        '============================================================',
      );
      debugPrint('SCiRIDER: DOWNLOAD PO PDF');
      debugPrint('Module   : PO');
      debugPrint('SourceId : $orderId');
      debugPrint(
        '============================================================',
      );

      final Uint8List bytes = await _approvalService.downloadDocumentPdf(
        module: 'PO',
        sourceId: orderId,
      );

      if (bytes.isEmpty) {
        throw Exception('Purchase Order PDF is empty.');
      }

      final Directory directory = await getTemporaryDirectory();

      final String orderNo = _text(_value(_po, const ['orderNo', 'sOrderNo']));

      final String fileName = _safeFileName(
        orderNo.isEmpty ? 'Purchase_Order_$orderId' : orderNo,
      );

      final File file = File('${directory.path}/$fileName.pdf');

      await file.writeAsBytes(bytes, flush: true);

      final OpenResult result = await OpenFilex.open(file.path);

      if (!mounted) return;

      if (result.type != ResultType.done) {
        _showMessage(
          result.message.isNotEmpty
              ? result.message
              : 'Unable to open Purchase Order PDF.',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _downloadingPdf = false;
        });
      }
    }
  }

  // ============================================================
  // FILE NAME
  // ============================================================

  String _safeFileName(String value) {
    return value
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? Colors.red.shade700
              : Colors.green.shade700,
        ),
      );
  }

  // ============================================================
  // CAN TAKE ACTION
  // ============================================================

  bool get _canTakeAction {
    final String status = _currentStatus.toUpperCase();

    final dynamic currentRaw = _value(_po, const [
      'isCurrentLevel',
      'bIsCurrentLevel',
    ]);

    final bool isCurrentLevel = currentRaw == null ? true : _bool(currentRaw);

    final dynamic canApproveRaw = _value(_po, const [
      'canApprove',
      'CanApprove',
    ]);

    final dynamic canRejectRaw = _value(_po, const ['canReject', 'CanReject']);

    if (canApproveRaw != null || canRejectRaw != null) {
      return _bool(canApproveRaw) || _bool(canRejectRaw);
    }

    return isCurrentLevel &&
        (status == 'PENDING' ||
            status == 'PENDING APPROVAL' ||
            status == 'WAITING' ||
            status == 'ASSIGNED');
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        titleSpacing: 0,

        title: const Text(
          'Purchase Order Approval',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),

        actions: [
          IconButton(
            tooltip: 'Open PO PDF',

            onPressed: _loading || _downloadingPdf ? null : _downloadPdf,

            icon: _downloadingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
          ),

          IconButton(
            tooltip: 'Refresh',

            onPressed: _loading
                ? null
                : () => _loadDetail(preserveScroll: true),

            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: _buildBody(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: primaryBlue));
    }

    if (_errorMessage != null && _errorMessage!.isNotEmpty) {
      return _buildErrorView();
    }

    if (_po.isEmpty) {
      return const Center(
        child: Text(
          'Purchase Order detail not found.',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      );
    }

    return RefreshIndicator(
      color: primaryBlue,

      onRefresh: () => _loadDetail(preserveScroll: true),

      child: SingleChildScrollView(
        controller: _scrollController,

        physics: const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [
            _buildPOHeaderCard(),

            const SizedBox(height: 12),

            _buildVendorCard(),

            const SizedBox(height: 12),

            _buildCommercialTermsCard(),

            const SizedBox(height: 12),

            _buildAddressCard(),

            const SizedBox(height: 12),

            _buildItemSection(),

            const SizedBox(height: 12),

            _buildSummaryCard(),

            const SizedBox(height: 12),

            _buildAttachmentCard(),

            const SizedBox(height: 12),

            _buildPdfCard(),

            const SizedBox(height: 12),

            _buildLastApprovedCard(),

            const SizedBox(height: 12),

            _buildApprovalHistoryCard(),

            const SizedBox(height: 12),

            _buildActionCard(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade600),

            const SizedBox(height: 12),

            Text(
              _errorMessage ?? 'Unable to load Purchase Order.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 16),

            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: primaryBlue),

              onPressed: _loadDetail,

              icon: const Icon(Icons.refresh),

              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
  // ============================================================
  // PO HEADER
  // ============================================================

  Widget _buildPOHeaderCard() {
    final String status = _currentStatus;

    return _sectionCard(
      icon: Icons.shopping_cart_checkout_outlined,
      title: 'Purchase Order',
      trailing: _statusChip(status),
      child: Column(
        children: [
          _infoRow(
            'PO No.',
            _display(_value(_po, const ['orderNo', 'sOrderNo'])),
          ),
          _divider(),

          _infoRow(
            'PO Date',
            _displayDate(_value(_po, const ['orderDate', 'dOrderDate'])),
          ),
          _divider(),

          _infoRow(
            'Order Type',
            _display(_value(_po, const ['orderType', 'sOrderType'])),
          ),
          _divider(),

          _infoRow(
            'Financial Year',
            _display(_value(_po, const ['financialYear', 'sFinancialYear'])),
          ),
          _divider(),

          _infoRow('NFA No.', _display(_value(_po, const ['nfaNo', 'sNFANo']))),
          _divider(),

          _infoRow(
            'Company',
            _display(_value(_po, const ['companyName', 'sCompanyName'])),
          ),
          _divider(),

          _infoRow(
            'Project',
            _display(_value(_po, const ['projectName', 'sProjectName'])),
          ),
          _divider(),

          _infoRow(
            'Department',
            _display(_value(_po, const ['departmentName', 'sDepartmentName'])),
          ),
          _divider(),

          _infoRow(
            'Subject',
            _display(_value(_po, const ['subject', 'sSubject'])),
            multiline: true,
          ),
          _divider(),

          _infoRow(
            'Remark',
            _display(_value(_po, const ['remark', 'sRemark'])),
            multiline: true,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VENDOR
  // ============================================================

  Widget _buildVendorCard() {
    return _sectionCard(
      icon: Icons.business_outlined,
      title: 'Vendor Details',
      child: Column(
        children: [
          _infoRow(
            'Vendor',
            _display(_value(_po, const ['vendorName', 'sVendorName'])),
          ),
          _divider(),

          _infoRow(
            'Vendor Code',
            _display(_value(_po, const ['vendorCode', 'sVendorCode'])),
          ),
          _divider(),

          _infoRow(
            'GST No.',
            _display(_value(_po, const ['vendorGSTNo', 'sVendorGSTNo'])),
          ),
          _divider(),

          _infoRow(
            'PAN No.',
            _display(_value(_po, const ['vendorPANNo', 'sVendorPANNo'])),
          ),
          _divider(),

          _infoRow(
            'Phone',
            _display(_value(_po, const ['vendorPhoneNo', 'sVendorPhoneNo'])),
          ),
          _divider(),

          _infoRow(
            'Email',
            _display(_value(_po, const ['vendorEmail', 'sVendorEmail'])),
            multiline: true,
          ),
          _divider(),

          _infoRow(
            'Address',
            _display(_value(_po, const ['vendorAddress', 'sVendorAddress'])),
            multiline: true,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMMERCIAL TERMS
  // ============================================================

  Widget _buildCommercialTermsCard() {
    return _sectionCard(
      icon: Icons.receipt_long_outlined,
      title: 'Commercial Terms',
      child: Column(
        children: [
          _infoRow(
            'Currency',
            _display(_value(_po, const ['currencyName', 'currency'])),
          ),
          _divider(),

          _infoRow(
            'Delivery Date',
            _displayDate(_value(_po, const ['deliveryDate'])),
          ),
          _divider(),

          _infoRow(
            'Expected Date',
            _displayDate(_value(_po, const ['expectedDate'])),
          ),
          _divider(),

          _infoRow(
            'Payment Terms',
            _display(_value(_po, const ['paymentTerms'])),
            multiline: true,
          ),
          _divider(),

          _infoRow(
            'Delivery Terms',
            _display(_value(_po, const ['deliveryTerms'])),
            multiline: true,
          ),
          _divider(),

          _infoRow(
            'Warranty Terms',
            _display(_value(_po, const ['warrantyTerms'])),
            multiline: true,
          ),
          _divider(),

          _infoRow(
            'Mode of Payment',
            _display(_value(_po, const ['modeOfPaymentName'])),
          ),
          _divider(),

          _infoRow(
            'Price Basis',
            _display(_value(_po, const ['priceBasisName'])),
          ),
          _divider(),

          _infoRow(
            'PO Validity',
            _display(_value(_po, const ['poValidityName'])),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ADDRESS
  // ============================================================

  Widget _buildAddressCard() {
    return _sectionCard(
      icon: Icons.location_on_outlined,
      title: 'Billing & Delivery',
      child: Column(
        children: [
          _subTitle('Bill To'),

          _infoRow(
            'Company',
            _display(_value(_po, const ['billToCompanyName'])),
          ),
          _divider(),

          _infoRow('GST No.', _display(_value(_po, const ['billToGSTNo']))),
          _divider(),

          _infoRow(
            'Address',
            _display(_value(_po, const ['billToCompanyAddress'])),
            multiline: true,
          ),

          const SizedBox(height: 14),

          _subTitle('Ship To'),

          _infoRow(
            'Company',
            _display(_value(_po, const ['shipToCompanyName'])),
          ),
          _divider(),

          _infoRow('GST No.', _display(_value(_po, const ['shipToGSTNo']))),
          _divider(),

          _infoRow(
            'Address',
            _display(_value(_po, const ['shipToCompanyAddress'])),
            multiline: true,
          ),
          _divider(),

          _infoRow(
            'Delivery Address',
            _display(_value(_po, const ['deliveryAddress'])),
            multiline: true,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ITEMS
  // ============================================================

  Widget _buildItemSection() {
    return _sectionCard(
      icon: Icons.inventory_2_outlined,
      title: 'Item Details',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: primaryBlue.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${_items.length} '
          'Item${_items.length == 1 ? '' : 's'}',
          style: const TextStyle(
            color: navyBlue,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
      child: _items.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No item details found.',
                style: TextStyle(color: Colors.black54),
              ),
            )
          : Column(
              children: List.generate(
                _items.length,
                (int index) => _buildItemCard(index, _items[index]),
              ),
            ),
    );
  }

  Widget _buildItemCard(int index, Map<String, dynamic> item) {
    final String itemName = _display(
      _value(item, const ['itemName', 'sItemName']),
    );

    final String itemCode = _display(
      _value(item, const ['itemCode', 'sItemCode']),
    );

    final double qty = _number(_value(item, const ['qty', 'nQty']));

    final double rate = _number(_value(item, const ['rate', 'nRate']));

    final double lineTotal = _number(
      _value(item, const ['lineTotal', 'nLineTotal']),
    );

    return Container(
      margin: EdgeInsets.only(bottom: index == _items.length - 1 ? 0 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3EBF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFEAF7FC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: primaryBlue,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    itemName,
                    style: const TextStyle(
                      color: navyBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _infoRow('Item Code', itemCode),
                _divider(),

                _infoRow('UOM', _display(_value(item, const ['uom', 'sUOM']))),
                _divider(),

                _infoRow(
                  'HSN Code',
                  _display(_value(item, const ['hsnCode', 'sHSNCode'])),
                ),
                _divider(),

                _infoRow('Qty', _formatNumber(qty)),
                _divider(),

                _infoRow('Rate', _money(rate)),
                _divider(),

                _infoRow(
                  'Basic Amount',
                  _money(_number(_value(item, const ['basicAmount']))),
                ),
                _divider(),

                _infoRow(
                  'Discount',
                  '${_formatNumber(_number(_value(item, const ['discountPer'])))}% '
                      '(${_money(_number(_value(item, const ['discountAmount'])))})',
                ),
                _divider(),

                _infoRow(
                  'CGST',
                  '${_formatNumber(_number(_value(item, const ['cgstPer'])))}% '
                      '(${_money(_number(_value(item, const ['cgstAmount'])))})',
                ),
                _divider(),

                _infoRow(
                  'SGST',
                  '${_formatNumber(_number(_value(item, const ['sgstPer'])))}% '
                      '(${_money(_number(_value(item, const ['sgstAmount'])))})',
                ),
                _divider(),

                _infoRow(
                  'IGST',
                  '${_formatNumber(_number(_value(item, const ['igstPer'])))}% '
                      '(${_money(_number(_value(item, const ['igstAmount'])))})',
                ),
                _divider(),

                _infoRow(
                  'Tax Amount',
                  _money(_number(_value(item, const ['taxAmount']))),
                ),
                _divider(),

                _infoRow(
                  'Line Total',
                  _money(lineTotal),
                  valueStyle: const TextStyle(
                    color: navyBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                _buildItemRemark(item),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRemark(Map<String, dynamic> item) {
    final String remark = _text(_value(item, const ['remark', 'lineRemark']));

    if (remark.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [_divider(), _infoRow('Remark', remark, multiline: true)],
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummaryCard() {
    return _sectionCard(
      icon: Icons.calculate_outlined,
      title: 'Amount Summary',
      child: Column(
        children: [
          _amountRow('Basic Total', _number(_value(_po, const ['basicTotal']))),
          _divider(),

          _amountRow(
            'Discount Amount',
            _number(_value(_po, const ['discountAmount'])),
          ),
          _divider(),

          _amountRow('Tax Amount', _number(_value(_po, const ['taxAmount']))),
          _divider(),

          _amountRow(
            'Other Charges',
            _number(_value(_po, const ['otherCharges'])),
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: primaryBlue.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(10),
            ),
            child: _amountRow(
              'Grand Total',
              _number(
                _value(_po, const ['grandTotal', 'poAmount', 'totalAmount']),
              ),
              bold: true,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ATTACHMENT
  // ============================================================

  Widget _buildAttachmentCard() {
    return _sectionCard(
      icon: Icons.attach_file_outlined,
      title: 'PO Attachment',
      trailing: _loadingAttachment
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: primaryBlue,
              ),
            )
          : IconButton(
              tooltip: 'Refresh Attachment',
              visualDensity: VisualDensity.compact,
              onPressed: _loadAttachment,
              icon: const Icon(Icons.refresh, size: 19, color: primaryBlue),
            ),
      child: _loadingAttachment
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: primaryBlue,
                ),
              ),
            )
          : _hasAttachment
          ? _buildAttachmentAvailable()
          : _buildNoAttachment(),
    );
  }

  Widget _buildNoAttachment() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4EBF0)),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            color: Colors.black45,
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No attachment available for this Purchase Order.',
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentAvailable() {
    final String message = _text(
      _value(_attachment, const ['message', 'Message']),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        children: [
          Icon(
            Icons.attachment_outlined,
            color: Colors.green.shade700,
            size: 25,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attachment Available',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                if (message.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    message,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PDF CARD
  // ============================================================

  Widget _buildPdfCard() {
    return _sectionCard(
      icon: Icons.picture_as_pdf_outlined,
      title: 'Purchase Order PDF',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'View the generated Purchase Order document.',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),

          const SizedBox(height: 12),

          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: primaryBlue,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            onPressed: _orderId <= 0 || _downloadingPdf ? null : _downloadPdf,

            icon: _downloadingPdf
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),

            label: Text(
              _downloadingPdf ? 'Opening PDF...' : 'View PO PDF',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LAST APPROVED
  // ============================================================

  Widget _buildLastApprovedCard() {
    Map<String, dynamic>? lastApproved;

    final dynamic apiValue = _value(_po, const [
      'lastApprovedBy',
      'LastApprovedBy',
      'lastApprovedApprover',
    ]);

    if (apiValue is Map) {
      lastApproved = Map<String, dynamic>.from(apiValue);
    }

    // If the detail endpoint does not provide lastApprovedBy,
    // find the latest APPROVED row from complete document history.
    if (lastApproved == null || lastApproved.isEmpty) {
      for (final Map<String, dynamic> row in _approvalHistory.reversed) {
        final String rowStatus = _text(
          _value(row, const ['approvalStatus', 'status', 'sApprovalStatus']),
        ).toUpperCase();

        if (rowStatus == 'APPROVED') {
          lastApproved = row;
          break;
        }
      }
    }

    if (lastApproved == null || lastApproved.isEmpty) {
      return _sectionCard(
        icon: Icons.verified_user_outlined,
        title: 'Last Approved By',
        child: const Text(
          'No previous approval has been completed yet.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    final String name = _display(
      _value(lastApproved, const ['name', 'approverName', 'sApproverName']),
    );

    final String role = _display(
      _value(lastApproved, const ['role', 'roleName', 'sRoleName']),
    );

    final dynamic date = _value(lastApproved, const [
      'approvedDate',
      'actionDate',
      'dActionDate',
    ]);

    final String remark = _display(
      _value(lastApproved, const [
        'remarks',
        'approvalRemark',
        'sApprovalRemark',
        'remark',
      ]),
    );

    return _sectionCard(
      icon: Icons.verified_user_outlined,
      title: 'Last Approved By',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: Colors.green.shade700),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: navyBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      role,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              _statusChip('Approved'),
            ],
          ),

          const SizedBox(height: 12),

          _infoRow('Approved On', _displayDateTime(date)),

          if (remark != '-' && remark.isNotEmpty) ...[
            _divider(),

            _infoRow('Remark', remark, multiline: true),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // APPROVAL HISTORY
  // ============================================================

  Widget _buildApprovalHistoryCard() {
    return _sectionCard(
      icon: Icons.history_outlined,
      title: 'Approval Workflow',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: primaryBlue.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${_approvalHistory.length}',
          style: const TextStyle(
            color: navyBlue,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      child: _approvalHistory.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No approval history found.',
                style: TextStyle(color: Colors.black54),
              ),
            )
          : Column(
              children: List.generate(_approvalHistory.length, (int index) {
                return _buildHistoryRow(index, _approvalHistory[index]);
              }),
            ),
    );
  }

  Widget _buildHistoryRow(int index, Map<String, dynamic> row) {
    final String status = _text(
      _value(row, const ['approvalStatus', 'sApprovalStatus', 'status']),
    );

    final String approver = _display(
      _value(row, const ['approverName', 'sApproverName']),
    );

    final String role = _display(_value(row, const ['roleName', 'sRoleName']));

    final String remark = _display(
      _value(row, const ['approvalRemark', 'sApprovalRemark', 'remark']),
    );

    final int approvalTxnId = _int(
      _value(row, const ['approvalTxnId', 'iApprovalTxnId']),
    );

    return Container(
      margin: EdgeInsets.only(
        bottom: index == _approvalHistory.length - 1 ? 0 : 12,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFCFE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5ECF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primaryBlue.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 20,
                  color: navyBlue,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      approver,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: navyBlue,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      role,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              _statusChip(status),
            ],
          ),

          const SizedBox(height: 12),

          if (approvalTxnId > 0) ...[
            _infoRow('Txn ID', approvalTxnId.toString()),
            _divider(),
          ],

          _infoRow(
            'Level',
            _display(_value(row, const ['approvalLevel', 'iApprovalLevel'])),
          ),
          _divider(),

          _infoRow(
            'Assigned',
            _displayDateTime(
              _value(row, const ['assignedDate', 'dAssignedDate']),
            ),
          ),
          _divider(),

          _infoRow(
            'Action Date',
            _displayDateTime(_value(row, const ['actionDate', 'dActionDate'])),
          ),
          _divider(),

          _infoRow('Remark', remark, multiline: true),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION
  // ============================================================

  Widget _buildActionCard() {
    final String status = _currentStatus;

    if (!_canTakeAction) {
      return _sectionCard(
        icon: Icons.verified_outlined,
        title: 'Approval Status',
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _statusBackground(status),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(_statusIcon(status), color: _statusColor(status)),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  status.isEmpty
                      ? 'No action is currently available.'
                      : 'Current status: $status',
                  style: TextStyle(
                    color: _statusColor(status),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _sectionCard(
      icon: Icons.approval_outlined,
      title: 'Approval Action',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _approvalRemarkController,
            maxLines: 3,
            minLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Approval Remark',
              hintText: 'Enter remark',
              alignLabelWithHint: true,
              filled: true,
              fillColor: const Color(0xFFFAFCFE),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD9E4EC)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: primaryBlue, width: 1.4),
              ),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _processingAction ? null : _reject,
                  icon: const Icon(Icons.close),
                  label: const Text(
                    'Reject',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _processingAction ? null : _approve,
                  icon: _processingAction
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    _processingAction ? 'Processing...' : 'Approve',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  // ============================================================
  // COMMON HELPERS
  // ============================================================

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2EAF0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF7FBFD),
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: primaryBlue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: primaryBlueDark, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: navyBlue,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    bool multiline = false,
    TextStyle? valueStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: valueStyle ??
                  const TextStyle(
                    color: Color(0xFF263746),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountRow(String label, double amount, {bool bold = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: bold ? navyBlue : Colors.black54,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
        Text(
          _money(amount),
          style: TextStyle(
            color: bold ? navyBlue : const Color(0xFF263746),
            fontSize: bold ? 16 : 13,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _divider() => const Divider(
        height: 13,
        thickness: 0.7,
        color: Color(0xFFE8EEF3),
      );

  Widget _subTitle(String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: primaryBlue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: navyBlue,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final String clean = status.trim().isEmpty ? 'Unknown' : status.trim();
    return Container(
      constraints: const BoxConstraints(maxWidth: 145),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _statusBackground(clean),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _statusColor(clean).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(clean), size: 13, color: _statusColor(clean)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              clean,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _statusColor(clean),
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    final String s = status.trim().toUpperCase();
    if (s == 'APPROVED' || s == 'ACCEPTED' || s == 'COMPLETED') {
      return Colors.green.shade700;
    }
    if (s == 'REJECTED' || s == 'CANCELLED' || s == 'CANCELED') {
      return Colors.red.shade700;
    }
    if (s == 'PENDING' ||
        s == 'PENDING APPROVAL' ||
        s == 'WAITING' ||
        s == 'ASSIGNED') {
      return Colors.orange.shade800;
    }
    return Colors.blueGrey.shade700;
  }

  Color _statusBackground(String status) {
    final String s = status.trim().toUpperCase();
    if (s == 'APPROVED' || s == 'ACCEPTED' || s == 'COMPLETED') {
      return Colors.green.shade50;
    }
    if (s == 'REJECTED' || s == 'CANCELLED' || s == 'CANCELED') {
      return Colors.red.shade50;
    }
    if (s == 'PENDING' ||
        s == 'PENDING APPROVAL' ||
        s == 'WAITING' ||
        s == 'ASSIGNED') {
      return Colors.orange.shade50;
    }
    return Colors.blueGrey.shade50;
  }

  IconData _statusIcon(String status) {
    final String s = status.trim().toUpperCase();
    if (s == 'APPROVED' || s == 'ACCEPTED' || s == 'COMPLETED') {
      return Icons.check_circle_outline;
    }
    if (s == 'REJECTED' || s == 'CANCELLED' || s == 'CANCELED') {
      return Icons.cancel_outlined;
    }
    if (s == 'PENDING' ||
        s == 'PENDING APPROVAL' ||
        s == 'WAITING' ||
        s == 'ASSIGNED') {
      return Icons.schedule_outlined;
    }
    return Icons.info_outline;
  }

  dynamic _value(Map<String, dynamic>? source, List<String> keys) {
    if (source == null || source.isEmpty) return null;

    for (final String key in keys) {
      if (source.containsKey(key) && source[key] != null) {
        return source[key];
      }
    }

    final Map<String, dynamic> lower = <String, dynamic>{};
    for (final entry in source.entries) {
      lower[entry.key.toLowerCase()] = entry.value;
    }

    for (final String key in keys) {
      final dynamic value = lower[key.toLowerCase()];
      if (value != null) return value;
    }
    return null;
  }

  String _text(dynamic value) {
    if (value == null) return '';
    final String result = value.toString().trim();
    if (result.isEmpty || result.toLowerCase() == 'null') return '';
    return result;
  }

  String _display(dynamic value) {
    final String result = _text(value);
    return result.isEmpty ? '-' : result;
  }

  int _int(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim()) ?? 0;
  }

  double _number(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    final String raw =
        value.toString().trim().replaceAll(',', '').replaceAll('₹', '');
    return double.tryParse(raw) ?? 0.0;
  }

  bool _bool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final String raw = value.toString().trim().toLowerCase();
    return raw == 'true' ||
        raw == '1' ||
        raw == 'yes' ||
        raw == 'y' ||
        raw == 't';
  }

  bool _boolValue(Map<String, dynamic> source, List<String> keys) =>
      _bool(_value(source, keys));

  DateTime? _dateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final String raw = _text(value);
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  String _displayDate(dynamic value) {
    final DateTime? date = _dateTime(value);
    if (date == null) return _display(value);
    return '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year}';
  }

  String _displayDateTime(dynamic value) {
    final DateTime? date = _dateTime(value);
    if (date == null) return _display(value);

    final int hour12 =
        date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final String period = date.hour >= 12 ? 'PM' : 'AM';

    return '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year} '
        '${_twoDigits(hour12)}:${_twoDigits(date.minute)} $period';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    String result = value.toStringAsFixed(2);
    while (result.contains('.') && result.endsWith('0')) {
      result = result.substring(0, result.length - 1);
    }
    if (result.endsWith('.')) result = result.substring(0, result.length - 1);
    return result;
  }

  String _money(double value) => '₹${value.toStringAsFixed(2)}';
}
