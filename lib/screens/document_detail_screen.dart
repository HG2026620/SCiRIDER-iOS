import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../models/document_model.dart';
import '../models/document_approval_history_model.dart';
import '../models/prsr_change_history_model.dart';
import '../services/approval_service.dart';
import '../widgets/approval_history_widget.dart';
import '../widgets/change_history_widget.dart';

class DocumentDetailScreen extends StatefulWidget {
  final DocumentModel document;

  const DocumentDetailScreen({super.key, required this.document});

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color _primary = Color(0xFF079BD3);
  static const Color _navy = Color(0xFF173F6B);
  static const Color _background = Color(0xFFF4F8FB);

  // ============================================================
  // SERVICES
  // ============================================================

  final ApprovalService _approvalService = ApprovalService();

  // ============================================================
  // STATE
  // ============================================================

  bool _loading = true;
  bool _downloadingPdf = false;

  String _error = '';

  List<DocumentApprovalHistoryModel> _history =
      <DocumentApprovalHistoryModel>[];

  List<PRSRChangeHistoryModel> _changeHistory = <PRSRChangeHistoryModel>[];

  // ============================================================
  // MODULE
  // ============================================================

  String get _module => widget.document.module.trim().toUpperCase();

  // ============================================================
  // SOURCE ID
  // ============================================================

  int get _sourceId => widget.document.sourceId;

  // ============================================================
  // CHANGE HISTORY SUPPORT
  // ============================================================

  bool get _supportsChangeHistory {
    return _module == 'PR' || _module == 'SR';
  }

  // ============================================================
  // PDF SUPPORT
  // ============================================================

  bool get _supportsPdf {
    return _module == 'PR' ||
        _module == 'SR' ||
        _module == 'NFA' ||
        _module == 'PO';
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadHistory();
  }

  // ============================================================
  // LOAD DOCUMENT HISTORY
  //
  // IMPORTANT:
  //
  // PO:
  //   History -> sourceId/orderId
  //
  // NFA:
  //   History -> sourceId/nfaId
  //
  // PR/SR:
  //   Approval history -> sourceId
  //   Change history   -> sourceId
  //
  // Change-history failure must never hide approval history.
  // ============================================================

  Future<void> _loadHistory() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = true;
      _error = '';

      _history = <DocumentApprovalHistoryModel>[];
      _changeHistory = <PRSRChangeHistoryModel>[];
    });

    final String module = _module;
    final int sourceId = _sourceId;

    debugPrint('');
    debugPrint('============================================================');
    debugPrint('SCIRIDER DOCUMENT DETAIL - LOAD HISTORY');
    debugPrint('============================================================');
    debugPrint('MODULE     : $module');
    debugPrint('SOURCE ID  : $sourceId');
    debugPrint('SOURCE NO  : ${widget.document.displaySourceNo}');
    debugPrint('STATUS     : ${widget.document.displayStatus}');
    debugPrint('============================================================');

    // ----------------------------------------------------------
    // Validate module
    // ----------------------------------------------------------

    if (module.isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = 'Document module is not available.';
      });

      return;
    }

    // ----------------------------------------------------------
    // Validate source ID
    // ----------------------------------------------------------

    if (sourceId <= 0) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = 'Invalid document source ID. Source ID: $sourceId';
      });

      return;
    }

    try {
      // ========================================================
      // 1. APPROVAL HISTORY
      // ========================================================

      debugPrint('');
      debugPrint('SCIRIDER: Loading approval history...');
      debugPrint('Module   : $module');
      debugPrint('SourceId : $sourceId');

      final List<DocumentApprovalHistoryModel> approvalHistory =
          await _approvalService.getDocumentApprovalHistory(
            module: module,
            sourceId: sourceId,
          );

      debugPrint('SCIRIDER: Approval history loaded.');

      debugPrint(
        'SCIRIDER: Approval history count = '
        '${approvalHistory.length}',
      );

      for (final DocumentApprovalHistoryModel item in approvalHistory) {
        debugPrint(
          'SCIRIDER HISTORY => '
          'Txn=${item.approvalTxnId}, '
          'Module=${item.module}, '
          'SourceId=${item.sourceId}, '
          'Level=${item.approvalLevel}, '
          'Approver=${item.approverName}, '
          'Status=${item.approvalStatus}',
        );
      }

      // ========================================================
      // 2. PR / SR CHANGE HISTORY
      //
      // Separate try/catch intentionally.
      //
      // A failure here must NOT make approval history fail.
      // ========================================================

      List<PRSRChangeHistoryModel> changeHistory = <PRSRChangeHistoryModel>[];

      if (_supportsChangeHistory) {
        try {
          debugPrint('');
          debugPrint('SCIRIDER: Loading PR/SR change history...');

          changeHistory = await _approvalService.getPRSRChangeHistory(
            module: module,
            sourceId: sourceId,
          );

          debugPrint(
            'SCIRIDER: Change history count = '
            '${changeHistory.length}',
          );
        } catch (e, stackTrace) {
          debugPrint('');
          debugPrint(
            '============================================================',
          );
          debugPrint('SCIRIDER CHANGE HISTORY ERROR');
          debugPrint(
            '============================================================',
          );
          debugPrint('MODULE    : $module');
          debugPrint('SOURCE ID : $sourceId');
          debugPrint('ERROR     : $e');
          debugPrint('STACK     : $stackTrace');
          debugPrint(
            '============================================================',
          );

          // Approval history must still be displayed.
          changeHistory = <PRSRChangeHistoryModel>[];
        }
      }

      // ========================================================
      // 3. UPDATE SCREEN
      // ========================================================

      if (!mounted) {
        return;
      }

      setState(() {
        _history = approvalHistory;
        _changeHistory = changeHistory;

        _loading = false;
        _error = '';
      });

      debugPrint('');
      debugPrint(
        '============================================================',
      );
      debugPrint('SCIRIDER DOCUMENT HISTORY COMPLETE');
      debugPrint('Approval History : ${_history.length}');
      debugPrint('Change History   : ${_changeHistory.length}');
      debugPrint(
        '============================================================',
      );
    } catch (e, stackTrace) {
      debugPrint('');
      debugPrint(
        '============================================================',
      );
      debugPrint('SCIRIDER APPROVAL HISTORY ERROR');
      debugPrint(
        '============================================================',
      );
      debugPrint('MODULE    : $module');
      debugPrint('SOURCE ID : $sourceId');
      debugPrint('ERROR     : $e');
      debugPrint('STACK     : $stackTrace');
      debugPrint(
        '============================================================',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;

        _error = _cleanError(e.toString());
      });
    }
  }

  // ============================================================
  // DOWNLOAD PDF
  // ============================================================

  Future<void> _downloadPdf() async {
    if (_downloadingPdf) {
      return;
    }

    if (!_supportsPdf) {
      _showMessage('PDF download is not available for this document.');

      return;
    }

    if (_sourceId <= 0) {
      _showMessage('Invalid document source ID.');

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
      debugPrint('SCIRIDER DOCUMENT PDF');
      debugPrint(
        '============================================================',
      );
      debugPrint('MODULE    : $_module');
      debugPrint('SOURCE ID : $_sourceId');
      debugPrint(
        '============================================================',
      );

      // --------------------------------------------------------
      // Download PDF bytes
      // --------------------------------------------------------

      final bytes = await _approvalService.downloadDocumentPdf(
        module: _module,
        sourceId: _sourceId,
      );

      if (bytes.isEmpty) {
        throw Exception('Downloaded PDF is empty.');
      }

      // --------------------------------------------------------
      // Application document directory
      // --------------------------------------------------------

      final Directory directory = await getApplicationDocumentsDirectory();

      final String safeDocumentNo = _safeFileName(
        widget.document.displaySourceNo,
      );

      final String safeModule = _safeFileName(_module);

      final String fileName = '${safeModule}_$safeDocumentNo.pdf';

      final String filePath = '${directory.path}/$fileName';

      final File file = File(filePath);

      // --------------------------------------------------------
      // Save PDF
      // --------------------------------------------------------

      await file.writeAsBytes(bytes, flush: true);

      if (!await file.exists()) {
        throw Exception('Unable to save PDF on device.');
      }

      debugPrint('SCIRIDER PDF SAVED: ${file.path}');

      // --------------------------------------------------------
      // Open PDF
      // --------------------------------------------------------

      final OpenResult result = await OpenFilex.open(file.path)
          .timeout(const Duration(seconds: 15));

      if (!mounted) {
        return;
      }

      if (result.type == ResultType.done) {
        _showMessage('PDF downloaded successfully.');
      } else {
        final String message = result.message.trim();

        _showMessage(
          message.isNotEmpty
              ? message
              : 'PDF saved successfully but could not be opened.',
        );
      }
    } on FileSystemException catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage('Unable to save PDF. ${e.message}');
    } catch (e, stackTrace) {
      debugPrint('SCIRIDER PDF ERROR: $e');

      debugPrint('$stackTrace');

      if (!mounted) {
        return;
      }

      _showMessage(_cleanError(e.toString()));
    } finally {
      if (mounted) {
        setState(() {
          _downloadingPdf = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,

      appBar: _buildAppBar(),

      body: RefreshIndicator(
        color: _primary,

        onRefresh: _loadHistory,

        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),

          children: [
            // ==================================================
            // DOCUMENT HEADER
            // ==================================================

            _buildHeaderCard(),

            // ==================================================
            // DOCUMENT PDF
            // ==================================================
            if (_supportsPdf) ...[const SizedBox(height: 14), _buildPdfCard()],

            const SizedBox(height: 22),

            // ==================================================
            // APPROVAL WORKFLOW
            // ==================================================
            _buildSectionTitle(
              title: 'Approval Workflow',
              subtitle: 'Document approval hierarchy and action history',
              icon: Icons.account_tree_outlined,
            ),

            const SizedBox(height: 12),

            if (_loading)
              _buildLoading()
            else if (_error.isNotEmpty)
              _buildError()
            else ...[
              ApprovalHistoryWidget(history: _history),

              // ================================================
              // PR / SR CHANGE HISTORY
              // ================================================
              if (_supportsChangeHistory) ...[
                const SizedBox(height: 24),

                _buildSectionTitle(
                  title: 'Change History',
                  subtitle: 'Approver edits recorded during the workflow',
                  icon: Icons.history_rounded,
                ),

                const SizedBox(height: 12),

                ChangeHistoryWidget(history: _changeHistory),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,

      backgroundColor: Colors.white,

      foregroundColor: _navy,

      surfaceTintColor: Colors.white,

      titleSpacing: 4,

      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'Document Detail',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: _navy,
            ),
          ),

          const SizedBox(height: 1),

          Text(
            widget.document.displayModule,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: Colors.black54,
            ),
          ),
        ],
      ),

      actions: [
        if (_supportsPdf)
          IconButton(
            tooltip: 'Download PDF',

            onPressed: _downloadingPdf ? null : _downloadPdf,

            icon: _downloadingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _primary,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
          ),

        IconButton(
          tooltip: 'Refresh',

          onPressed: _loading ? null : _loadHistory,

          icon: const Icon(Icons.refresh_rounded),
        ),

        const SizedBox(width: 4),
      ],
    );
  }

  // ============================================================
  // HEADER CARD
  // ============================================================

  Widget _buildHeaderCard() {
    final DocumentModel document = widget.document;

    final Color moduleColor = _moduleColor(document.module);

    final IconData moduleIcon = _moduleIcon(document.module);

    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),

            blurRadius: 10,

            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Container(
                width: 50,
                height: 50,

                decoration: BoxDecoration(
                  color: moduleColor.withValues(alpha: 0.10),

                  borderRadius: BorderRadius.circular(13),
                ),

                child: Icon(moduleIcon, color: moduleColor, size: 26),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      document.displaySourceNo,

                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _navy,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Wrap(
                      spacing: 7,
                      runSpacing: 5,

                      children: [
                        _buildTag(document.displayModule, moduleColor),

                        if (document.displayRequestType.trim().isNotEmpty)
                          _buildTag(document.displayRequestType, _navy),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              _buildStatusBadge(document.displayStatus),
            ],
          ),

          const SizedBox(height: 18),

          const Divider(height: 1),

          const SizedBox(height: 12),

          _detailRow(
            'Status',
            document.displayStatus,
            icon: Icons.info_outline_rounded,
          ),

          _detailRow(
            'Approval Level',
            document.approvalLevel.toString(),
            icon: Icons.layers_outlined,
          ),

          _detailRow(
            'Document Date',
            document.displayDate,
            icon: Icons.calendar_today_outlined,
          ),

          _detailRow(
            'Actionable',
            document.isActionable ? 'Yes' : 'No',
            icon: Icons.task_alt_outlined,
          ),

          _detailRow(
            'Mode',
            document.isReadOnly ? 'Read Only' : 'Approval',
            icon: document.isReadOnly
                ? Icons.visibility_outlined
                : Icons.edit_note_outlined,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PDF CARD
  // ============================================================

  Widget _buildPdfCard() {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: _primary.withValues(alpha: 0.12)),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),

            blurRadius: 8,

            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,

            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),

              borderRadius: BorderRadius.circular(12),
            ),

            child: const Icon(
              Icons.picture_as_pdf_outlined,
              color: Colors.redAccent,
              size: 26,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  'Document PDF',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _navy,
                  ),
                ),

                SizedBox(height: 3),

                Text(
                  'Download and open the official ERP document copy.',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          FilledButton.icon(
            onPressed: _downloadingPdf ? null : _downloadPdf,

            style: FilledButton.styleFrom(
              backgroundColor: _primary,

              foregroundColor: Colors.white,

              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),

            icon: _downloadingPdf
                ? const SizedBox(
                    width: 16,
                    height: 16,

                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download_rounded, size: 18),

            label: Text(
              _downloadingPdf ? 'Downloading' : 'PDF',

              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Container(
          width: 38,
          height: 38,

          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.10),

            borderRadius: BorderRadius.circular(10),
          ),

          child: Icon(icon, size: 21, color: _primary),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                title,

                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _navy,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                subtitle,

                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          if (icon != null) ...[
            Icon(icon, size: 17, color: Colors.black45),

            const SizedBox(width: 8),
          ],

          SizedBox(
            width: icon == null ? 120 : 112,

            child: Text(
              label,

              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),

          Expanded(
            child: Text(
              value,

              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge(String status) {
    final String upper = status.trim().toUpperCase();

    Color color = Colors.orange;

    IconData icon = Icons.schedule_outlined;

    if (upper == 'APPROVED') {
      color = Colors.green;
      icon = Icons.check_circle_outline;
    } else if (upper == 'REJECTED') {
      color = Colors.redAccent;
      icon = Icons.cancel_outlined;
    } else if (upper == 'PENDING') {
      color = Colors.orange;
      icon = Icons.schedule_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),

      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),

        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(icon, size: 14, color: color),

          const SizedBox(width: 4),

          Text(
            status,

            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TAG
  // ============================================================

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),

        borderRadius: BorderRadius.circular(8),
      ),

      child: Text(
        text,

        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // ============================================================
  // MODULE COLOR
  // ============================================================

  Color _moduleColor(String module) {
    switch (module.trim().toUpperCase()) {
      case 'PR':
        return _primary;

      case 'SR':
        return Colors.teal;

      case 'NFA':
        return Colors.deepPurple;

      case 'PO':
        return Colors.orange;

      case 'MIN':
        return const Color(0xFF3D7EDB);

      default:
        return _navy;
    }
  }

  // ============================================================
  // MODULE ICON
  // ============================================================

  IconData _moduleIcon(String module) {
    switch (module.trim().toUpperCase()) {
      case 'PR':
        return Icons.shopping_cart_outlined;

      case 'SR':
        return Icons.miscellaneous_services_outlined;

      case 'NFA':
        return Icons.approval_outlined;

      case 'PO':
        return Icons.receipt_long_outlined;

      case 'MIN':
        return Icons.inventory_2_outlined;

      default:
        return Icons.description_outlined;
    }
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 45),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(16),
      ),

      child: const Center(child: CircularProgressIndicator(color: _primary)),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.15)),
      ),

      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,

            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.08),

              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.error_outline,
              color: Colors.redAccent,
              size: 30,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'Unable to load document history',

            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _navy,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            _error,

            textAlign: TextAlign.center,

            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),

          const SizedBox(height: 14),

          ElevatedButton.icon(
            onPressed: _loadHistory,

            icon: const Icon(Icons.refresh),

            label: const Text('Retry'),

            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,

              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SAFE FILE NAME
  // ============================================================

  String _safeFileName(String value) {
    String result = value.trim();

    if (result.isEmpty) {
      result = 'Document_${widget.document.sourceId}';
    }

    result = result.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

    result = result.replaceAll(RegExp(r'\s+'), '_');

    return result;
  }

  // ============================================================
  // CLEAN ERROR
  // ============================================================

  String _cleanError(String message) {
    String result = message.trim();

    if (result.startsWith('Exception: ')) {
      result = result.substring('Exception: '.length);
    }

    if (result.isEmpty) {
      result = 'Something went wrong.';
    }

    return result;
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),

        behavior: SnackBarBehavior.floating,

        duration: const Duration(seconds: 3),
      ),
    );
  }
}
