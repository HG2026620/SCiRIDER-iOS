import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../models/approval_model.dart';
import '../models/document_approval_history_model.dart';
import '../services/approval_service.dart';

class NFAApprovalDetailScreen extends StatefulWidget {
  final ApprovalModel approval;

  const NFAApprovalDetailScreen({super.key, required this.approval});

  @override
  State<NFAApprovalDetailScreen> createState() =>
      _NFAApprovalDetailScreenState();
}

class _NFAApprovalDetailScreenState extends State<NFAApprovalDetailScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color primary = Color(0xFF079BD3);
  static const Color navy = Color(0xFF173F6B);
  static const Color background = Color(0xFFF4F8FB);

  // ============================================================
  // SERVICE / CONTROLLER
  // ============================================================

  final ApprovalService _service = ApprovalService();

  final TextEditingController _remarkController = TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  bool _loading = true;
  bool _processing = false;
  bool _downloadingPdf = false;
  bool _loadingAttachment = false;

  String? _error;

  Map<String, dynamic> _nfa = <String, dynamic>{};

  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];

  List<Map<String, dynamic>> _vendorAwards = <Map<String, dynamic>>[];

  List<Map<String, dynamic>> _approvalHistory = <Map<String, dynamic>>[];

  List<DocumentApprovalHistoryModel> _documentHistory =
      <DocumentApprovalHistoryModel>[];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _load();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _remarkController.dispose();

    super.dispose();
  }

  // ============================================================
  // VALUE HELPERS
  // ============================================================

  dynamic _value(Map<String, dynamic> row, List<String> keys) {
    for (final String key in keys) {
      if (row.containsKey(key) && row[key] != null) {
        return row[key];
      }
    }

    return null;
  }

  String _text(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  int _int(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(_text(value)) ?? 0;
  }

  double _double(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(_text(value)) ?? 0;
  }

  bool _bool(dynamic value) {
    if (value == null) {
      return false;
    }

    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final String v = _text(value).toLowerCase();

    return v == 'true' || v == '1' || v == 'yes' || v == 'y';
  }

  // ============================================================
  // APPROVAL TRANSACTION ID
  //
  // Used for:
  // - NFA Detail API
  // - Approve
  // - Reject
  // - Attachment
  // ============================================================

  int get _approvalTxnId {
    final int detailTxnId = _int(
      _value(_nfa, const [
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
  // NFA SOURCE ID
  //
  // Used for:
  // - Document History
  // - PDF
  //
  // IMPORTANT:
  // Never use approvalTxnId here.
  // ============================================================

  int get _nfaId {
    int id = _int(
      _value(_nfa, const ['nfaId', 'iNFAId', 'sourceId', 'iSourceId']),
    );

    if (id <= 0) {
      id = widget.approval.sourceId;
    }

    return id;
  }

  // ============================================================
  // MONEY
  // ============================================================

  String _money(dynamic value) {
    return _double(value).toStringAsFixed(2);
  }

  // ============================================================
  // DATE
  // ============================================================

  String _date(dynamic value) {
    final String raw = _text(value);

    if (raw.isEmpty) {
      return '-';
    }

    final DateTime? dt = DateTime.tryParse(raw);

    if (dt == null) {
      return raw;
    }

    return '${dt.day.toString().padLeft(2, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> _load() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final int listApprovalTxnId = widget.approval.approvalTxnId;

      debugPrint('');
      debugPrint(
        '============================================================',
      );
      debugPrint('SCiRIDER: NFA DETAIL LOAD');
      debugPrint('Module        : ${widget.approval.module}');
      debugPrint('ApprovalTxnId : $listApprovalTxnId');
      debugPrint('List SourceId : ${widget.approval.sourceId}');
      debugPrint('SourceNo      : ${widget.approval.sourceNo}');
      debugPrint(
        '============================================================',
      );

      if (listApprovalTxnId <= 0) {
        throw Exception('Invalid NFA approval transaction ID.');
      }

      // =========================================================
      // 1. NFA DETAIL
      // =========================================================

      final Map<String, dynamic> detail = await _service.getNFADetail(
        listApprovalTxnId,
      );

      if (detail.isEmpty) {
        throw Exception('NFA detail was not returned by the API.');
      }

      _nfa = Map<String, dynamic>.from(detail);

      debugPrint('SCiRIDER: NFA DETAIL LOADED');

      debugPrint('SCiRIDER: NFA SOURCE ID = $_nfaId');

      debugPrint('SCiRIDER: NFA CURRENT TXN ID = $_approvalTxnId');

      // =========================================================
      // 2. ITEMS
      // =========================================================

      _items = ApprovalService.getMapList(_nfa['items'] ?? _nfa['Items']);

      debugPrint('SCiRIDER: NFA ITEMS = ${_items.length}');

      // =========================================================
      // 3. VENDOR AWARDS
      // =========================================================

      _vendorAwards = ApprovalService.getMapList(
        _nfa['vendorAwards'] ?? _nfa['VendorAwards'],
      );

      debugPrint(
        'SCiRIDER: NFA VENDOR AWARDS = '
        '${_vendorAwards.length}',
      );

      // =========================================================
      // 4. COMPLETE DOCUMENT APPROVAL HISTORY
      //
      // IMPORTANT:
      // Uses NFA SOURCE ID, not approvalTxnId.
      // =========================================================

      _documentHistory = <DocumentApprovalHistoryModel>[];

      _approvalHistory = <Map<String, dynamic>>[];

      final int sourceId = _nfaId;

      if (sourceId > 0) {
        try {
          debugPrint('');
          debugPrint(
            '============================================================',
          );
          debugPrint('SCiRIDER: LOAD COMPLETE NFA HISTORY');
          debugPrint('Module   : NFA');
          debugPrint('SourceId : $sourceId');
          debugPrint(
            '============================================================',
          );

          _documentHistory = await _service.getDocumentApprovalHistory(
            module: 'NFA',
            sourceId: sourceId,
          );

          // Convert dedicated history model into the
          // same map structure used by this screen.
          _approvalHistory = _documentHistory.map<Map<String, dynamic>>((
            DocumentApprovalHistoryModel item,
          ) {
            return <String, dynamic>{
              'approvalTxnId': item.approvalTxnId,
              'iApprovalTxnId': item.approvalTxnId,

              'approvalLevel': item.approvalLevel,
              'iApprovalLevel': item.approvalLevel,

              'roleName': item.roleName,
              'sRoleName': item.roleName,

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
            };
          }).toList();

          debugPrint(
            'SCiRIDER: NFA DOCUMENT HISTORY COUNT = '
            '${_approvalHistory.length}',
          );

          for (final Map<String, dynamic> row in _approvalHistory) {
            debugPrint(
              'NFA HISTORY => '
              'Txn=${_value(row, const ['approvalTxnId'])}, '
              'Level=${_value(row, const ['approvalLevel'])}, '
              'Approver=${_value(row, const ['approverName'])}, '
              'Status=${_value(row, const ['approvalStatus'])}',
            );
          }
        } catch (e, stackTrace) {
          debugPrint('SCiRIDER: NFA DOCUMENT HISTORY ERROR: $e');

          debugPrint('$stackTrace');

          _documentHistory = <DocumentApprovalHistoryModel>[];

          _approvalHistory = <Map<String, dynamic>>[];
        }
      }

      // =========================================================
      // 5. FALLBACK HISTORY
      //
      // If dedicated document-history endpoint gives no data,
      // use history returned by nfa-detail.
      // =========================================================

      if (_approvalHistory.isEmpty) {
        debugPrint(
          'SCiRIDER: Dedicated NFA history empty. '
          'Using NFA detail history fallback.',
        );

        _approvalHistory = ApprovalService.getMapList(
          _nfa['approvalHistory'] ?? _nfa['ApprovalHistory'],
        );
      }

      debugPrint(
        'SCiRIDER: FINAL NFA APPROVAL HISTORY = '
        '${_approvalHistory.length}',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('SCiRIDER: NFA DETAIL ERROR: $e');

      debugPrint('$stackTrace');

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;

        _error = e.toString().replaceFirst('Exception: ', '').trim();
      });
    }
  }

  // ============================================================
  // STATUS
  // ============================================================

  String get _status {
    return _text(
      _value(_nfa, const [
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
  // ACTIONABLE
  // ============================================================

  bool get _actionable {
    final String status = _status.toUpperCase();

    final dynamic current = _value(_nfa, const [
      'isCurrentLevel',
      'bIsCurrentLevel',
    ]);

    final bool isCurrent = current == null ? true : _bool(current);

    final dynamic canApproveRaw = _value(_nfa, const [
      'canApprove',
      'CanApprove',
    ]);

    final dynamic canRejectRaw = _value(_nfa, const ['canReject', 'CanReject']);

    if (canApproveRaw != null || canRejectRaw != null) {
      return _bool(canApproveRaw) || _bool(canRejectRaw);
    }

    return isCurrent &&
        (status == 'PENDING' ||
            status == 'PENDING APPROVAL' ||
            status == 'ASSIGNED' ||
            status == 'WAITING');
  }

  // ============================================================
  // DOWNLOAD PDF
  //
  // Uses NFA source/document ID.
  // ============================================================

  Future<void> _downloadPdf() async {
    if (_downloadingPdf) {
      return;
    }

    final int nfaId = _nfaId;

    if (nfaId <= 0) {
      _message('NFA document ID is not available.', error: true);

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
      debugPrint('SCiRIDER: DOWNLOAD NFA PDF');
      debugPrint('Module   : NFA');
      debugPrint('SourceId : $nfaId');
      debugPrint(
        '============================================================',
      );

      final Uint8List bytes = await _service.downloadDocumentPdf(
        module: 'NFA',
        sourceId: nfaId,
      );

      if (bytes.isEmpty) {
        throw Exception('NFA PDF is empty.');
      }

      final Directory directory = await getTemporaryDirectory();

      final String no = _text(_value(_nfa, const ['nfaNo', 'sNFANo']));

      final String safe = (no.isEmpty ? 'NFA_$nfaId' : no).replaceAll(
        RegExp(r'[\\/:*?"<>|]'),
        '_',
      );

      final File file = File('${directory.path}/$safe.pdf');

      await file.writeAsBytes(bytes, flush: true);

      final OpenResult result = await OpenFilex.open(file.path);

      if (!mounted) {
        return;
      }

      if (result.type != ResultType.done) {
        _message(
          result.message.isEmpty ? 'Unable to open NFA PDF.' : result.message,
          error: true,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('SCiRIDER: NFA PDF ERROR: $e');

      debugPrint('$stackTrace');

      if (!mounted) {
        return;
      }

      _message(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) {
        setState(() {
          _downloadingPdf = false;
        });
      }
    }
  }

  // ============================================================
  // ATTACHMENT
  //
  // Attachment endpoint is transaction based.
  // ============================================================

  Future<void> _showAttachment() async {
    if (_loadingAttachment) {
      return;
    }

    final int txnId = _approvalTxnId;

    if (txnId <= 0) {
      _message('Approval transaction ID not found.', error: true);

      return;
    }

    setState(() {
      _loadingAttachment = true;
    });

    try {
      debugPrint(
        'SCiRIDER: NFA ATTACHMENT '
        'ApprovalTxnId=$txnId',
      );

      final Map<String, dynamic> data = await _service.getAttachment(txnId);

      if (!mounted) {
        return;
      }

      if (data.isEmpty) {
        _message('No attachment available for this NFA.');

        return;
      }

      final entries = data.entries
          .where((e) => e.value != null && _text(e.value).isNotEmpty)
          .toList();

      if (entries.isEmpty) {
        _message('No attachment available for this NFA.');

        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (BuildContext ctx) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NFA Attachment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),

                  const SizedBox(height: 12),

                  ...entries
                      .take(8)
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('${e.key}: ${e.value}'),
                        ),
                      ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      final String msg = e.toString();

      if (msg.contains('404') ||
          msg.toLowerCase().contains('attachment not found')) {
        _message('No attachment available for this NFA.');
      } else {
        _message(msg.replaceFirst('Exception: ', ''), error: true);
      }
    } finally {
      if (mounted) {
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
    if (_processing) {
      return;
    }

    final bool? ok = await _confirm(
      'Approve NFA',
      'Are you sure you want to approve this NFA?',
      'Approve',
      Colors.green,
    );

    if (ok != true || !mounted) {
      return;
    }

    final int txnId = _approvalTxnId;

    if (txnId <= 0) {
      _message('Approval transaction ID not found.', error: true);

      return;
    }

    setState(() {
      _processing = true;
    });

    try {
      final String remark = _remarkController.text.trim();

      debugPrint('');
      debugPrint(
        '############################################################',
      );
      debugPrint('NFA APPROVAL BUTTON PRESSED');
      debugPrint(
        '############################################################',
      );
      debugPrint(
        'List Txn ID    : '
        '${widget.approval.approvalTxnId}',
      );
      debugPrint('Current Txn ID : $txnId');
      debugPrint('NFA Source ID  : $_nfaId');
      debugPrint('Status         : $_status');
      debugPrint('Remark         : $remark');
      debugPrint(
        '############################################################',
      );

      final Map<String, dynamic> result = await _service.approve(
        approvalTxnId: txnId,
        remark: remark,
      );

      debugPrint(
        'SCiRIDER NFA APPROVE RESPONSE: '
        '$result',
      );

      final bool success = _bool(_value(result, const ['success', 'Success']));

      final String message = _text(
        _value(result, const ['message', 'Message']),
      );

      if (!mounted) {
        return;
      }

      _message(
        message.isEmpty
            ? (success
                  ? 'NFA approved successfully.'
                  : 'Unable to approve NFA.')
            : message,
        error: !success,
      );

      if (success) {
        _remarkController.clear();

        await Future<void>.delayed(const Duration(milliseconds: 400));

        if (!mounted) {
          return;
        }

        Navigator.of(context).pop(true);
      }
    } catch (e, stackTrace) {
      debugPrint('SCiRIDER NFA APPROVE ERROR: $e');

      debugPrint('$stackTrace');

      if (mounted) {
        _message(e.toString().replaceFirst('Exception: ', ''), error: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  // ============================================================
  // REJECT
  // ============================================================

  Future<void> _reject() async {
    if (_processing) {
      return;
    }

    final String remark = _remarkController.text.trim();

    if (remark.isEmpty) {
      _message('Please enter a rejection remark.', error: true);

      return;
    }

    final bool? ok = await _confirm(
      'Reject NFA',
      'Are you sure you want to reject this NFA?',
      'Reject',
      Colors.red,
    );

    if (ok != true || !mounted) {
      return;
    }

    final int txnId = _approvalTxnId;

    if (txnId <= 0) {
      _message('Approval transaction ID not found.', error: true);

      return;
    }

    setState(() {
      _processing = true;
    });

    try {
      debugPrint('');
      debugPrint(
        '############################################################',
      );
      debugPrint('NFA REJECT BUTTON PRESSED');
      debugPrint(
        '############################################################',
      );
      debugPrint(
        'List Txn ID    : '
        '${widget.approval.approvalTxnId}',
      );
      debugPrint('Current Txn ID : $txnId');
      debugPrint('NFA Source ID  : $_nfaId');
      debugPrint('Remark         : $remark');
      debugPrint(
        '############################################################',
      );

      final Map<String, dynamic> result = await _service.reject(
        approvalTxnId: txnId,
        remark: remark,
      );

      debugPrint(
        'SCiRIDER NFA REJECT RESPONSE: '
        '$result',
      );

      final bool success = _bool(_value(result, const ['success', 'Success']));

      final String message = _text(
        _value(result, const ['message', 'Message']),
      );

      if (!mounted) {
        return;
      }

      _message(
        message.isEmpty
            ? (success ? 'NFA rejected successfully.' : 'Unable to reject NFA.')
            : message,
        error: !success,
      );

      if (success) {
        _remarkController.clear();

        await Future<void>.delayed(const Duration(milliseconds: 400));

        if (!mounted) {
          return;
        }

        Navigator.of(context).pop(true);
      }
    } catch (e, stackTrace) {
      debugPrint('SCiRIDER NFA REJECT ERROR: $e');

      debugPrint('$stackTrace');

      if (mounted) {
        _message(e.toString().replaceFirst('Exception: ', ''), error: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  // ============================================================
  // CONFIRM
  // ============================================================

  Future<bool?> _confirm(
    String title,
    String message,
    String action,
    Color color,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(title),

          content: Text(message),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),

            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: color),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(action),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _message(String message, {bool error = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
        ),
      );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _card(String title, IconData icon, Widget child) {
    return Card(
      elevation: 0,

      margin: const EdgeInsets.only(bottom: 14),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Row(
              children: [
                Icon(icon, color: primary),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: navy,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            child,
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ROW
  // ============================================================

  Widget _row(String label, dynamic value, {bool money = false}) {
    final String v = money ? _money(value) : _text(value);

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          SizedBox(
            width: 125,

            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Expanded(child: Text(v.isEmpty ? '-' : v)),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _header() {
    return _card(
      'NFA Details',
      Icons.description_outlined,

      Column(
        children: [
          _row('NFA No.', _value(_nfa, const ['nfaNo', 'sNFANo'])),

          _row('Date', _date(_value(_nfa, const ['nfaDate', 'dNFADate']))),

          _row('Status', _status),

          _row('Purpose', _value(_nfa, const ['purpose', 'sPurpose'])),

          _row('Subject', _value(_nfa, const ['subject', 'sSubject'])),

          _row(
            'Justification',
            _value(_nfa, const ['justification', 'sJustification']),
          ),

          _row(
            'Recommendation',
            _value(_nfa, const ['recommendation', 'sRecommendation']),
          ),

          _row('Remark', _value(_nfa, const ['remark', 'sRemark'])),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _summary() {
    return _card(
      'Financial Summary',
      Icons.account_balance_wallet_outlined,

      Column(
        children: [
          _row('Currency', _value(_nfa, const ['currency', 'sCurrency'])),

          _row(
            'Basic Amount',
            _value(_nfa, const ['basicAmount', 'nBasicAmount']),
            money: true,
          ),

          _row(
            'Tax Amount',
            _value(_nfa, const ['taxAmount', 'nTaxAmount']),
            money: true,
          ),

          _row(
            'Final Amount',
            _value(_nfa, const ['finalAmount', 'nFinalAmount']),
            money: true,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ITEM CARD
  // ============================================================

  Widget _itemCard(Map<String, dynamic> item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: background,

        borderRadius: BorderRadius.circular(10),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            '${index + 1}. '
            '${_text(_value(item, const ['itemName', 'sItemName']))}',
            style: const TextStyle(fontWeight: FontWeight.w800, color: navy),
          ),

          const SizedBox(height: 8),

          _row('Item Code', _value(item, const ['itemCode', 'sItemCode'])),

          _row('UOM', _value(item, const ['uom', 'sUOM', 'sUOMName'])),

          _row('Qty', _value(item, const ['qty', 'nQty', 'nQuantity'])),

          _row('Rate', _value(item, const ['rate', 'nRate']), money: true),

          _row(
            'GST %',
            _value(item, const ['gstPercent', 'nGSTPercent', 'nGST']),
          ),

          _row(
            'Basic',
            _value(item, const ['basicAmount', 'nBasicAmount']),
            money: true,
          ),

          _row(
            'Tax',
            _value(item, const ['taxAmount', 'nTaxAmount']),
            money: true,
          ),

          _row(
            'Total',
            _value(item, const [
              'lineTotal',
              'totalAmount',
              'nLineTotal',
              'nTotalAmount',
            ]),
            money: true,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ITEMS SECTION
  // ============================================================

  Widget _itemsSection() {
    return _card(
      'Items (${_items.length})',
      Icons.inventory_2_outlined,

      _items.isEmpty
          ? const Text('No items available.')
          : Column(
              children: [
                for (int i = 0; i < _items.length; i++) _itemCard(_items[i], i),
              ],
            ),
    );
  }

  // ============================================================
  // VENDOR COMPARISON
  // ============================================================

  Widget _vendorSection() {
    return _card(
      'Vendor Comparison',
      Icons.compare_arrows,

      _vendorAwards.isEmpty
          ? const Text('No vendor comparison available.')
          : Column(
              children: _vendorAwards.map((Map<String, dynamic> v) {
                final bool selected = _bool(
                  _value(v, const ['isSelected', 'bIsSelected']),
                );

                final String rank = _text(_value(v, const ['rank', 'sRank']));

                final int vendorId = _int(
                  _value(v, const ['vendorId', 'iVendorId', 'awardVendorId']),
                );

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),

                  padding: const EdgeInsets.all(12),

                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selected ? Colors.green : Colors.grey.shade300,
                    ),

                    borderRadius: BorderRadius.circular(10),
                  ),

                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${rank.isEmpty ? 'Vendor' : rank} '
                              '• Vendor ID $vendorId',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: navy,
                              ),
                            ),
                          ),

                          if (selected)
                            const Chip(
                              avatar: Icon(
                                Icons.check_circle,
                                size: 18,
                                color: Colors.green,
                              ),
                              label: Text('Selected'),
                            ),
                        ],
                      ),

                      _row(
                        'Qty',
                        _value(v, const ['qty', 'nQty', 'nQuantity']),
                      ),

                      _row(
                        'Rate',
                        _value(v, const ['rate', 'nRate']),
                        money: true,
                      ),

                      _row(
                        'GST %',
                        _value(v, const ['gstPercent', 'nGSTPercent', 'nGST']),
                      ),

                      _row(
                        'Basic',
                        _value(v, const ['basicAmount', 'nBasicAmount']),
                        money: true,
                      ),

                      _row(
                        'Tax',
                        _value(v, const ['taxAmount', 'nTaxAmount']),
                        money: true,
                      ),

                      _row(
                        'Total',
                        _value(v, const ['totalAmount', 'nTotalAmount']),
                        money: true,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  // ============================================================
  // DOCUMENTS
  // ============================================================

  Widget _documents() {
    return _card(
      'Documents',
      Icons.folder_open_outlined,

      Column(
        children: [
          SizedBox(
            width: double.infinity,

            child: OutlinedButton.icon(
              onPressed: _downloadingPdf ? null : _downloadPdf,

              icon: _downloadingPdf
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),

              label: Text(
                _downloadingPdf
                    ? 'Preparing PDF...'
                    : 'Download / View NFA PDF',
              ),
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,

            child: OutlinedButton.icon(
              onPressed: _loadingAttachment ? null : _showAttachment,

              icon: _loadingAttachment
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.attach_file),

              label: Text(
                _loadingAttachment ? 'Checking...' : 'View Attachment',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // APPROVAL HISTORY
  //
  // This is now the ONE history section.
  // Dedicated document history is preferred.
  // Detail history is only fallback.
  // ============================================================

  Widget _history() {
    return _card(
      'Approval History',
      Icons.history,

      _approvalHistory.isEmpty
          ? const Text('No approval history available.')
          : Column(
              children: _approvalHistory.map((Map<String, dynamic> h) {
                final String role = _text(
                  _value(h, const ['roleName', 'sRoleName']),
                );

                final String approver = _text(
                  _value(h, const ['approverName', 'sApproverName']),
                );

                final String status = _text(
                  _value(h, const ['approvalStatus', 'sApprovalStatus']),
                );

                final int txnId = _int(
                  _value(h, const ['approvalTxnId', 'iApprovalTxnId']),
                );

                return Container(
                  width: double.infinity,

                  margin: const EdgeInsets.only(bottom: 10),

                  padding: const EdgeInsets.all(12),

                  decoration: BoxDecoration(
                    color: background,

                    borderRadius: BorderRadius.circular(10),

                    border: Border.all(color: Colors.grey.shade200),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Expanded(
                            child: Text(
                              role.isEmpty ? 'Approval' : role,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: navy,
                              ),
                            ),
                          ),

                          _statusBadge(status),
                        ],
                      ),

                      const SizedBox(height: 10),

                      _row('Approver', approver),

                      if (txnId > 0) _row('Txn ID', txnId),

                      _row(
                        'Level',
                        _value(h, const ['approvalLevel', 'iApprovalLevel']),
                      ),

                      _row(
                        'Assigned',
                        _date(
                          _value(h, const ['assignedDate', 'dAssignedDate']),
                        ),
                      ),

                      _row(
                        'Action',
                        _date(_value(h, const ['actionDate', 'dActionDate'])),
                      ),

                      _row(
                        'Remark',
                        _value(h, const [
                          'approvalRemark',
                          'sApprovalRemark',
                          'remark',
                        ]),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(String status) {
    final String normalized = status.trim().toUpperCase();

    Color bg;
    Color fg;

    if (normalized == 'APPROVED' || normalized == 'APPROVE') {
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
    } else if (normalized == 'REJECTED' || normalized == 'REJECT') {
      bg = Colors.red.shade50;
      fg = Colors.red.shade800;
    } else {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),

      decoration: BoxDecoration(
        color: bg,

        borderRadius: BorderRadius.circular(20),
      ),

      child: Text(
        status.trim().isEmpty ? 'Pending' : status,

        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Widget _actions() {
    if (!_actionable) {
      return const SizedBox.shrink();
    }

    return _card(
      'Approval Action',
      Icons.fact_check_outlined,

      Column(
        children: [
          TextField(
            controller: _remarkController,

            minLines: 2,
            maxLines: 4,

            textCapitalization: TextCapitalization.sentences,

            decoration: const InputDecoration(
              labelText: 'Remark',
              hintText: 'Enter approval/rejection remark',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _processing ? null : _reject,

                  icon: const Icon(Icons.close, color: Colors.red),

                  label: const Text(
                    'Reject',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),

                  onPressed: _processing ? null : _approve,

                  icon: _processing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check),

                  label: Text(_processing ? 'Processing...' : 'Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: Colors.white,

        foregroundColor: navy,

        elevation: 0,

        title: const Text(
          'NFA Approval',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),

        actions: [
          IconButton(
            tooltip: 'NFA PDF',

            onPressed: _loading || _downloadingPdf ? null : _downloadPdf,

            icon: _downloadingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
          ),

          IconButton(
            tooltip: 'Refresh',

            onPressed: _loading ? null : _load,

            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),

                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),

                    const SizedBox(height: 12),

                    Text(_error!, textAlign: TextAlign.center),

                    const SizedBox(height: 16),

                    FilledButton.icon(
                      onPressed: _load,

                      icon: const Icon(Icons.refresh),

                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              color: primary,

              onRefresh: _load,

              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),

                padding: const EdgeInsets.all(14),

                children: [
                  _header(),

                  _summary(),

                  _itemsSection(),

                  _vendorSection(),

                  _documents(),

                  // Only ONE history section.
                  _history(),

                  _actions(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
