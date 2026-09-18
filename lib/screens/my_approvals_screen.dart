import 'package:flutter/material.dart';

import '../models/approval_model.dart';
import '../services/approval_service.dart';

import '../routes/approval_detail_router.dart';

class MyApprovalsScreen extends StatefulWidget {
  const MyApprovalsScreen({super.key});

  @override
  State<MyApprovalsScreen> createState() => _MyApprovalsScreenState();
}

class _MyApprovalsScreenState extends State<MyApprovalsScreen> {
  // ============================================================
  // SCI THEME
  // ============================================================

  static const Color primaryBlue = Color(0xFF079BD3);

  static const Color navyBlue = Color(0xFF173F6B);

  static const Color pageBackground = Color(0xFFF3F6F9);

  static const Color textDark = Color(0xFF182632);

  static const Color textMedium = Color(0xFF687682);

  static const Color textLight = Color(0xFF8A96A1);

  static const Color borderColor = Color(0xFFE3E9EE);

  static const Color softBlue = Color(0xFFEAF7FC);

  static const Color pendingBackground = Color(0xFFFFF4DB);

  static const Color pendingText = Color(0xFFB27600);

  static const Color errorRed = Color(0xFFD74848);

  // ============================================================
  // SERVICES
  // ============================================================

  final ApprovalService _approvalService = ApprovalService();

  final TextEditingController _searchController = TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  List<ApprovalModel> _approvals = [];

  bool _loading = true;

  String _error = '';

  String _selectedModule = 'ALL';

  // ============================================================
  // CLIENT-SIDE MODULE FILTER
  // ============================================================
  //
  // The API already accepts a module filter. This local filter is
  // intentionally kept as a defensive layer so that the UI never
  // renders a record under the wrong chip if the backend returns
  // mixed data.
  //
  // IMPORTANT:
  // PO is identified by approval.module == 'PO'.
  // requestType can be MATERIAL / SERVICE etc. and must NOT be used
  // to identify a Purchase Order.
  // ============================================================

  List<ApprovalModel> get _visibleApprovals {
    final selected = _selectedModule.trim().toUpperCase();

    if (selected.isEmpty || selected == 'ALL') {
      return _approvals;
    }

    if (selected == 'PR/SR' || selected == 'PRSR') {
      return _approvals
          .where((approval) {
            final module = approval.module.trim().toUpperCase();
            return module == 'PR' || module == 'SR' || module == 'PRSR';
          })
          .toList(growable: false);
    }

    return _approvals
        .where((approval) {
          return approval.module.trim().toUpperCase() == selected;
        })
        .toList(growable: false);
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadApprovals();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD APPROVALS
  // ============================================================

  Future<void> _loadApprovals() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = '';
      });
    }

    try {
      final data = await _approvalService.getMyApprovals(
        module: _selectedModule,
        searchText: _searchController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _approvals = data;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Future<void> _search() async {
    FocusScope.of(context).unfocus();

    await _loadApprovals();
  }

  // ============================================================
  // CLEAR SEARCH
  // ============================================================

  Future<void> _clearSearch() async {
    _searchController.clear();

    FocusScope.of(context).unfocus();

    await _loadApprovals();
  }

  // ============================================================
  // OPEN APPROVAL DETAIL
  // ============================================================
  Future<void> _openApproval(ApprovalModel approval) async {
    try {
      final String module = approval.module.trim().toUpperCase();

      final int approvalTxnId = approval.approvalTxnId;

      debugPrint(
        '============================================================',
      );
      debugPrint('SCiRIDER: OPEN APPROVAL');
      debugPrint('Module        : $module');
      debugPrint('ApprovalTxnId : $approvalTxnId');
      debugPrint('SourceId      : ${approval.sourceId}');
      debugPrint('SourceNo      : ${approval.sourceNo}');
      debugPrint('RequestType   : ${approval.requestType}');
      debugPrint(
        '============================================================',
      );

      // ------------------------------------------------------------
      // VALIDATE MODULE
      // ------------------------------------------------------------

      if (module.isEmpty) {
        throw Exception('Approval module is not available.');
      }

      // ------------------------------------------------------------
      // VALIDATE APPROVAL TRANSACTION
      // ------------------------------------------------------------

      if (approvalTxnId <= 0) {
        throw Exception('Invalid approval transaction ID.');
      }

      // ------------------------------------------------------------
      // CHECK SUPPORTED MODULE
      // ------------------------------------------------------------

      if (!ApprovalDetailRouter.isSupportedModule(module)) {
        throw Exception('$module approval is not currently supported.');
      }

      // ------------------------------------------------------------
      // OPEN DETAIL SCREEN
      // ------------------------------------------------------------

      debugPrint('SCiRIDER: Opening $module approval detail...');

      final bool? result = await ApprovalDetailRouter.open(context, approval);

      debugPrint('SCiRIDER: $module detail screen returned: $result');

      if (!mounted) {
        return;
      }

      // ------------------------------------------------------------
      // REFRESH AFTER APPROVE / REJECT
      // ------------------------------------------------------------

      if (result == true) {
        debugPrint('SCiRIDER: Approval action completed. Refreshing list...');

        await _loadApprovals();
      }
    } catch (e, stackTrace) {
      debugPrint(
        '============================================================',
      );
      debugPrint('SCiRIDER: OPEN APPROVAL ERROR');
      debugPrint('$e');
      debugPrint('$stackTrace');
      debugPrint(
        '============================================================',
      );

      if (!mounted) {
        return;
      }

      final String message = e
          .toString()
          .replaceFirst('Exception: ', '')
          .trim();

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              message.isEmpty ? 'Unable to open approval detail.' : message,
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: errorRed,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        toolbarHeight: 68,

        titleSpacing: 4,

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Approvals',
              style: TextStyle(
                color: textDark,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),

            SizedBox(height: 2),

            Text(
              'Review pending documents',
              style: TextStyle(
                color: textMedium,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadApprovals,
            icon: const Icon(Icons.refresh_rounded, color: navyBlue),
          ),

          const SizedBox(width: 4),
        ],

        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFECEFF2)),
        ),
      ),

      body: RefreshIndicator(
        color: primaryBlue,
        onRefresh: _loadApprovals,

        child: Column(
          children: [
            _buildFilters(),

            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FILTERS
  // ============================================================

  Widget _buildFilters() {
    return Container(
      width: double.infinity,

      color: Colors.white,

      padding: const EdgeInsets.fromLTRB(15, 12, 15, 14),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // SEARCH
          // ======================================================

          TextField(
            controller: _searchController,

            textInputAction: TextInputAction.search,

            onSubmitted: (_) {
              _search();
            },

            onChanged: (_) {
              setState(() {});
            },

            decoration: InputDecoration(
              hintText: 'Search document no...',

              hintStyle: const TextStyle(
                color: Color(0xFF9AA6B0),
                fontSize: 13,
              ),

              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF788692),
              ),

              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear',

                      onPressed: _clearSearch,

                      icon: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Color(0xFF788692),
                      ),
                    ),

              filled: true,

              fillColor: const Color(0xFFF5F7F9),

              contentPadding: const EdgeInsets.symmetric(vertical: 13),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),

                borderSide: BorderSide.none,
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),

                borderSide: const BorderSide(color: Color(0xFFE6EBEF)),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),

                borderSide: const BorderSide(color: primaryBlue, width: 1.4),
              ),
            ),
          ),

          const SizedBox(height: 13),

          // ======================================================
          // MODULE FILTER
          // ======================================================
          SizedBox(
            height: 39,

            child: ListView(
              scrollDirection: Axis.horizontal,

              children: [
                _moduleChip('ALL', 'All'),

                _moduleChip('PR/SR', 'PR / SR'),

                _moduleChip('NFA', 'NFA'),

                _moduleChip('PO', 'PO'),

                _moduleChip('VENDOR PAYMENT', 'Vendor Payment'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MODULE CHIP
  // ============================================================

  Widget _moduleChip(String module, String displayText) {
    final bool selected = _selectedModule == module;

    return Padding(
      padding: const EdgeInsets.only(right: 8),

      child: ChoiceChip(
        selected: selected,

        showCheckmark: false,

        label: Text(displayText),

        labelStyle: TextStyle(
          color: selected ? Colors.white : textMedium,

          fontSize: 12,

          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        ),

        selectedColor: navyBlue,

        backgroundColor: const Color(0xFFF1F4F6),

        side: BorderSide(color: selected ? navyBlue : const Color(0xFFE0E6EA)),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

        onSelected: (_) {
          if (_selectedModule == module) {
            return;
          }

          setState(() {
            _selectedModule = module;
          });

          _loadApprovals();
        },
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    // ==========================================================
    // FIRST LOAD
    // ==========================================================

    if (_loading && _approvals.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),

        children: const [
          SizedBox(height: 140),

          Center(child: CircularProgressIndicator(color: primaryBlue)),

          SizedBox(height: 16),

          Center(
            child: Text(
              'Loading approvals...',
              style: TextStyle(color: textMedium, fontSize: 13),
            ),
          ),
        ],
      );
    }

    // ==========================================================
    // ERROR
    // ==========================================================

    if (_error.isNotEmpty && _approvals.isEmpty) {
      return _buildError();
    }

    // ==========================================================
    // EMPTY
    // ==========================================================

    if (_visibleApprovals.isEmpty) {
      return _buildEmpty();
    }

    // ==========================================================
    // LIST
    // ==========================================================

    return Stack(
      children: [
        ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.fromLTRB(15, 15, 15, 28),

          itemCount: _visibleApprovals.length,

          separatorBuilder: (_, _) => const SizedBox(height: 11),

          itemBuilder: (context, index) {
            return _approvalCard(_visibleApprovals[index]);
          },
        ),

        if (_loading)
          const Positioned(
            left: 0,
            top: 0,
            right: 0,

            child: LinearProgressIndicator(minHeight: 2, color: primaryBlue),
          ),
      ],
    );
  }

  // ============================================================
  // APPROVAL CARD
  // ============================================================

  Widget _approvalCard(ApprovalModel approval) {
    return Material(
      color: Colors.white,

      borderRadius: BorderRadius.circular(16),

      child: InkWell(
        borderRadius: BorderRadius.circular(16),

        onTap: () {
          _openApproval(approval);
        },

        child: Container(
          padding: const EdgeInsets.all(16),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),

            border: Border.all(color: borderColor),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),

                blurRadius: 8,

                offset: const Offset(0, 3),
              ),
            ],
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // ==================================================
              // TOP
              // ==================================================

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,

                children: [
                  _moduleIcon(approval.module),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          approval.sourceNo.trim().isNotEmpty
                              ? approval.sourceNo
                              : '#${approval.sourceId}',

                          maxLines: 1,

                          overflow: TextOverflow.ellipsis,

                          style: const TextStyle(
                            fontSize: 16,

                            fontWeight: FontWeight.w800,

                            color: textDark,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          _documentName(approval),

                          maxLines: 2,

                          overflow: TextOverflow.ellipsis,

                          style: const TextStyle(
                            color: textMedium,

                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: 34,
                    height: 34,

                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F6F8),

                      borderRadius: BorderRadius.circular(10),
                    ),

                    child: const Icon(
                      Icons.chevron_right_rounded,

                      size: 25,

                      color: Color(0xFF8E9AA4),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ==================================================
              // STATUS
              // ==================================================
              Wrap(
                spacing: 8,
                runSpacing: 8,

                children: [
                  _statusBadge(approval.approvalStatus),

                  _smallBadge('Level ${approval.approvalLevel}'),

                  if (approval.isFinalLevel) _smallBadge('Final Level'),

                  if (approval.isDelegated) _smallBadge('Delegated'),

                  if (approval.isEscalated) _smallBadge('Escalated'),
                ],
              ),

              const SizedBox(height: 14),

              const Divider(height: 1, color: Color(0xFFEDF0F2)),

              const SizedBox(height: 12),

              // ==================================================
              // APPROVER / ROLE
              // ==================================================
              Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,

                    size: 17,

                    color: Color(0xFF7A8793),
                  ),

                  const SizedBox(width: 6),

                  Expanded(
                    child: Text(
                      _approverText(approval),

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(fontSize: 12, color: textMedium),
                    ),
                  ),

                  if (approval.assignedDate != null) ...[
                    const SizedBox(width: 8),

                    const Icon(
                      Icons.calendar_today_outlined,

                      size: 13,

                      color: textLight,
                    ),

                    const SizedBox(width: 4),

                    Text(
                      _formatDate(approval.assignedDate!),

                      style: const TextStyle(fontSize: 11, color: textLight),
                    ),
                  ],
                ],
              ),

              // ==================================================
              // EXISTING REMARK
              // ==================================================
              if (approval.remark.trim().isNotEmpty) ...[
                const SizedBox(height: 12),

                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.all(10),

                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9FA),

                    borderRadius: BorderRadius.circular(10),
                  ),

                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Icon(
                        Icons.comment_outlined,

                        size: 16,

                        color: Color(0xFF84919C),
                      ),

                      const SizedBox(width: 7),

                      Expanded(
                        child: Text(
                          approval.remark,

                          maxLines: 2,

                          overflow: TextOverflow.ellipsis,

                          style: const TextStyle(
                            color: textMedium,

                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MODULE ICON
  // ============================================================

  Widget _moduleIcon(String module) {
    IconData icon;

    Color iconColor;

    Color backgroundColor;

    switch (module.trim().toUpperCase()) {
      case 'PR':
      case 'SR':
        icon = Icons.description_outlined;

        iconColor = primaryBlue;

        backgroundColor = softBlue;

        break;

      case 'NFA':
        icon = Icons.fact_check_outlined;

        iconColor = const Color(0xFFE79A16);

        backgroundColor = const Color(0xFFFFF4DD);

        break;

      case 'PO':
        icon = Icons.shopping_cart_outlined;

        iconColor = const Color(0xFF2D9B67);

        backgroundColor = const Color(0xFFE9F7F0);

        break;

      case 'VENDOR PAYMENT':
        icon = Icons.payments_outlined;

        iconColor = const Color(0xFFDD7A28);

        backgroundColor = const Color(0xFFFFF1E6);

        break;

      default:
        icon = Icons.approval_outlined;

        iconColor = navyBlue;

        backgroundColor = const Color(0xFFEEF3F8);
    }

    return Container(
      width: 47,
      height: 47,

      decoration: BoxDecoration(
        color: backgroundColor,

        borderRadius: BorderRadius.circular(13),
      ),

      child: Icon(icon, color: iconColor, size: 24),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(String status) {
    final normalized = status.trim().toUpperCase();

    Color backgroundColor;

    Color textColor;

    if (normalized == 'APPROVED' || normalized == 'APPROVE') {
      backgroundColor = const Color(0xFFE7F7EF);

      textColor = const Color(0xFF218C5B);
    } else if (normalized == 'REJECTED' || normalized == 'REJECT') {
      backgroundColor = const Color(0xFFFFEAEA);

      textColor = errorRed;
    } else {
      backgroundColor = pendingBackground;

      textColor = pendingText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),

      decoration: BoxDecoration(
        color: backgroundColor,

        borderRadius: BorderRadius.circular(20),
      ),

      child: Text(
        status.trim().isEmpty ? 'Pending' : status,

        style: TextStyle(
          fontSize: 11,

          fontWeight: FontWeight.w700,

          color: textColor,
        ),
      ),
    );
  }

  // ============================================================
  // SMALL BADGE
  // ============================================================

  Widget _smallBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),

      decoration: BoxDecoration(
        color: const Color(0xFFF0F3F6),

        borderRadius: BorderRadius.circular(20),
      ),

      child: Text(
        text,

        style: const TextStyle(
          fontSize: 10,

          fontWeight: FontWeight.w600,

          color: Color(0xFF65727E),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.all(25),

      children: [
        const SizedBox(height: 80),

        Center(
          child: Container(
            width: 88,
            height: 88,

            decoration: BoxDecoration(
              color: const Color(0xFFFFEEEE),

              borderRadius: BorderRadius.circular(25),
            ),

            child: const Icon(
              Icons.error_outline_rounded,

              size: 50,

              color: errorRed,
            ),
          ),
        ),

        const SizedBox(height: 22),

        const Text(
          'Unable to load approvals',

          textAlign: TextAlign.center,

          style: TextStyle(
            color: textDark,

            fontSize: 18,

            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 9),

        Text(
          _error,

          textAlign: TextAlign.center,

          style: const TextStyle(color: errorRed, fontSize: 12),
        ),

        const SizedBox(height: 22),

        SizedBox(
          width: double.infinity,

          child: OutlinedButton.icon(
            onPressed: _loadApprovals,

            icon: const Icon(Icons.refresh_rounded),

            label: const Text('Try Again'),

            style: OutlinedButton.styleFrom(
              foregroundColor: navyBlue,

              padding: const EdgeInsets.symmetric(vertical: 14),

              side: const BorderSide(color: Color(0xFFD1DCE5)),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),

      children: [
        const SizedBox(height: 100),

        Center(
          child: Container(
            width: 92,
            height: 92,

            decoration: BoxDecoration(
              color: const Color(0xFFEEF4F7),

              borderRadius: BorderRadius.circular(28),
            ),

            child: const Icon(
              Icons.task_alt_rounded,

              size: 55,

              color: Color(0xFF91A2AF),
            ),
          ),
        ),

        const SizedBox(height: 22),

        const Center(
          child: Text(
            'No pending approvals',

            style: TextStyle(
              color: textDark,

              fontWeight: FontWeight.w800,

              fontSize: 17,
            ),
          ),
        ),

        const SizedBox(height: 7),

        const Center(
          child: Text(
            'You are all caught up.',

            style: TextStyle(color: textMedium, fontSize: 12),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _documentName(ApprovalModel approval) {
    if (approval.requestType.trim().isNotEmpty) {
      return approval.requestType;
    }

    if (approval.module.trim().isNotEmpty) {
      return approval.module;
    }

    return 'Approval';
  }

  String _approverText(ApprovalModel approval) {
    if (approval.roleName.trim().isNotEmpty) {
      if (approval.approverName.trim().isNotEmpty) {
        return '${approval.roleName} • ${approval.approverName}';
      }

      return approval.roleName;
    }

    if (approval.approverName.trim().isNotEmpty) {
      return approval.approverName;
    }

    return 'Approver';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}
