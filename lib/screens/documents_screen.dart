import 'package:flutter/material.dart';

import '../models/document_model.dart';
import '../services/approval_service.dart';
import 'document_detail_screen.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  // ============================================================
  // THEME
  // ============================================================

  static const Color _primary = Color(0xFF079BD3);

  static const Color _darkBlue = Color(0xFF067FAE);

  static const Color _navy = Color(0xFF173F6B);

  static const Color _background = Color(0xFFF4F8FB);

  // ============================================================
  // SERVICES
  // ============================================================

  final ApprovalService _approvalService = ApprovalService();

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _searchController = TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  bool _loading = true;

  String _error = '';

  String _selectedModule = 'ALL';

  String _selectedStatus = 'ALL';

  List<DocumentModel> _documents = <DocumentModel>[];

  // ============================================================
  // FILTER VALUES
  // ============================================================

  final List<String> _modules = <String>['ALL', 'PR', 'SR', 'NFA', 'PO', 'MIN'];

  final List<String> _statuses = <String>[
    'ALL',
    'PENDING',
    'APPROVED',
    'REJECTED',
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadDocuments();
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
  // LOAD DOCUMENTS
  // ============================================================

  Future<void> _loadDocuments({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _loading = true;
        _error = '';
      });
    }

    try {
      final List<DocumentModel> data = await _approvalService.getDocuments(
        module: _selectedModule,
        status: _selectedStatus,
        search: _searchController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _documents = data;
        _loading = false;
        _error = '';
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _documents = <DocumentModel>[];

        _loading = false;

        _error = _cleanError(e.toString());
      });
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Future<void> _search() async {
    FocusScope.of(context).unfocus();

    await _loadDocuments();
  }

  // ============================================================
  // CLEAR SEARCH
  // ============================================================

  Future<void> _clearSearch() async {
    _searchController.clear();

    FocusScope.of(context).unfocus();

    await _loadDocuments();
  }

  // ============================================================
  // MODULE FILTER
  // ============================================================

  Future<void> _changeModule(String module) async {
    if (_selectedModule == module) {
      return;
    }

    setState(() {
      _selectedModule = module;
    });

    await _loadDocuments();
  }

  // ============================================================
  // STATUS FILTER
  // ============================================================

  Future<void> _changeStatus(String status) async {
    if (_selectedStatus == status) {
      return;
    }

    setState(() {
      _selectedStatus = status;
    });

    await _loadDocuments();
  }

  // ============================================================
  // OPEN DOCUMENT
  // ============================================================

  Future<void> _openDocument(DocumentModel document) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentDetailScreen(document: document),
      ),
    );
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
        onRefresh: () => _loadDocuments(showLoader: false),
        child: _buildBody(),
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

      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Documents',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _navy,
            ),
          ),

          SizedBox(height: 2),

          Text(
            'PR • SR • NFA • PO • MIN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: Colors.black54,
            ),
          ),
        ],
      ),

      actions: [
        IconButton(
          tooltip: 'Refresh',

          onPressed: _loading ? null : () => _loadDocuments(),

          icon: const Icon(Icons.refresh_rounded),
        ),

        const SizedBox(width: 4),
      ],
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),

      children: [
        _buildSummaryCard(),

        const SizedBox(height: 16),

        _buildSearchBox(),

        const SizedBox(height: 18),

        _buildFilterHeading('Module'),

        const SizedBox(height: 8),

        _buildModuleFilters(),

        const SizedBox(height: 18),

        _buildFilterHeading('Status'),

        const SizedBox(height: 8),

        _buildStatusFilters(),

        const SizedBox(height: 20),

        _buildResultHeader(),

        const SizedBox(height: 12),

        if (_loading)
          _buildLoading()
        else if (_error.isNotEmpty)
          _buildError()
        else if (_documents.isEmpty)
          _buildEmpty()
        else
          ..._documents.map(_buildDocumentCard),
      ],
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _buildSummaryCard() {
    final int total = _documents.length;

    final int pending = _documents.where((e) => e.isPending).length;

    final int approved = _documents.where((e) => e.isApproved).length;

    final int rejected = _documents.where((e) => e.isRejected).length;

    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _darkBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,

                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),

                  borderRadius: BorderRadius.circular(14),
                ),

                child: const Icon(
                  Icons.folder_copy_outlined,
                  color: Colors.white,
                  size: 27,
                ),
              ),

              const SizedBox(width: 13),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All Documents',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      'View workflow documents and history',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(child: _buildSummaryValue(total.toString(), 'Total')),

              _buildVerticalDivider(),

              Expanded(
                child: _buildSummaryValue(pending.toString(), 'Pending'),
              ),

              _buildVerticalDivider(),

              Expanded(
                child: _buildSummaryValue(approved.toString(), 'Approved'),
              ),

              _buildVerticalDivider(),

              Expanded(
                child: _buildSummaryValue(rejected.toString(), 'Rejected'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryValue(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white.withValues(alpha: 0.25),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearchBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(15),

        border: Border.all(color: Colors.grey.shade200),
      ),

      child: TextField(
        controller: _searchController,

        textInputAction: TextInputAction.search,

        onSubmitted: (_) => _search(),

        decoration: InputDecoration(
          hintText: 'Search document number...',

          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),

          prefixIcon: const Icon(Icons.search_rounded, color: _primary),

          suffixIcon: _searchController.text.trim().isNotEmpty
              ? IconButton(
                  onPressed: _clearSearch,

                  icon: const Icon(Icons.close_rounded),
                )
              : IconButton(
                  tooltip: 'Search',

                  onPressed: _search,

                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                    color: _primary,
                  ),
                ),

          border: InputBorder.none,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
        ),

        onChanged: (_) {
          setState(() {});
        },
      ),
    );
  }

  // ============================================================
  // FILTER HEADING
  // ============================================================

  Widget _buildFilterHeading(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: _navy,
      ),
    );
  }

  // ============================================================
  // MODULE FILTERS
  // ============================================================

  Widget _buildModuleFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,

      child: Row(
        children: _modules.map((module) {
          final bool selected = _selectedModule == module;

          return Padding(
            padding: const EdgeInsets.only(right: 8),

            child: ChoiceChip(
              selected: selected,

              label: Text(module),

              onSelected: (_) => _changeModule(module),

              selectedColor: _primary,

              backgroundColor: Colors.white,

              side: BorderSide(
                color: selected ? _primary : Colors.grey.shade300,
              ),

              labelStyle: TextStyle(
                color: selected ? Colors.white : _navy,

                fontSize: 12,

                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),

              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // STATUS FILTERS
  // ============================================================

  Widget _buildStatusFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,

      child: Row(
        children: _statuses.map((status) {
          final bool selected = _selectedStatus == status;

          return Padding(
            padding: const EdgeInsets.only(right: 8),

            child: ChoiceChip(
              selected: selected,

              label: Text(_formatFilterText(status)),

              onSelected: (_) => _changeStatus(status),

              selectedColor: _primary,

              backgroundColor: Colors.white,

              side: BorderSide(
                color: selected ? _primary : Colors.grey.shade300,
              ),

              labelStyle: TextStyle(
                color: selected ? Colors.white : _navy,

                fontSize: 12,

                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),

              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // RESULT HEADER
  // ============================================================

  Widget _buildResultHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Document List',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _navy,
            ),
          ),
        ),

        if (!_loading && _error.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),

            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.08),

              borderRadius: BorderRadius.circular(20),
            ),

            child: Text(
              '${_documents.length} Documents',

              style: const TextStyle(
                color: _primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // DOCUMENT CARD
  // ============================================================

  Widget _buildDocumentCard(DocumentModel document) {
    final Color statusColor = _statusColor(document.documentStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      child: Material(
        color: Colors.white,

        borderRadius: BorderRadius.circular(17),

        child: InkWell(
          borderRadius: BorderRadius.circular(17),

          onTap: () => _openDocument(document),

          child: Container(
            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),

              border: Border.all(color: Colors.grey.shade200),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,

                      decoration: BoxDecoration(
                        color: _moduleColor(document.module).withValues(alpha: 0.10),

                        borderRadius: BorderRadius.circular(12),
                      ),

                      child: Icon(
                        _moduleIcon(document.module),

                        color: _moduleColor(document.module),

                        size: 23,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  document.displaySourceNo,

                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _navy,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              _buildStatusBadge(
                                document.displayStatus,
                                statusColor,
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildMiniTag(document.displayModule),

                              if (document.displayRequestType != '-')
                                _buildMiniTag(document.displayRequestType),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                const Divider(height: 1),

                const SizedBox(height: 13),

                Row(
                  children: [
                    Expanded(
                      child: _buildCardInfo(
                        icon: Icons.account_tree_outlined,

                        label: 'Approval Level',

                        value: document.approvalLevel > 0
                            ? 'Level ${document.approvalLevel}'
                            : '-',
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _buildCardInfo(
                        icon: Icons.calendar_today_outlined,

                        label: 'Document Date',

                        value: document.displayDate,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 13),

                Row(
                  children: [
                    Icon(
                      document.isReadOnly
                          ? Icons.lock_outline_rounded
                          : Icons.touch_app_outlined,

                      size: 15,

                      color: document.isReadOnly
                          ? Colors.grey.shade600
                          : _primary,
                    ),

                    const SizedBox(width: 6),

                    Text(
                      document.isReadOnly
                          ? 'Read-only document'
                          : 'Approval action available',

                      style: TextStyle(
                        fontSize: 11,

                        fontWeight: FontWeight.w600,

                        color: document.isReadOnly
                            ? Colors.grey.shade600
                            : _primary,
                      ),
                    ),

                    const Spacer(),

                    const Text(
                      'View History',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),

                    const SizedBox(width: 3),

                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: _primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),

      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),

        borderRadius: BorderRadius.circular(20),
      ),

      child: Text(
        status,

        style: TextStyle(
          color: color,

          fontSize: 10,

          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // MINI TAG
  // ============================================================

  Widget _buildMiniTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FB),

        borderRadius: BorderRadius.circular(8),
      ),

      child: Text(
        text,

        style: const TextStyle(
          fontSize: 10,

          fontWeight: FontWeight.w600,

          color: _navy,
        ),
      ),
    );
  }

  // ============================================================
  // CARD INFO
  // ============================================================

  Widget _buildCardInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Icon(icon, size: 17, color: _primary),

        const SizedBox(width: 7),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,

                style: const TextStyle(fontSize: 10, color: Colors.black45),
              ),

              const SizedBox(height: 3),

              Text(
                value,

                maxLines: 2,

                overflow: TextOverflow.ellipsis,

                style: const TextStyle(
                  fontSize: 11,

                  fontWeight: FontWeight.w600,

                  color: _navy,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),

      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: _primary),

            SizedBox(height: 15),

            Text(
              'Loading documents...',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(17),

        border: Border.all(color: Colors.red.shade100),
      ),

      child: Column(
        children: [
          Container(
            width: 55,
            height: 55,

            decoration: BoxDecoration(
              color: Colors.red.shade50,

              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 30,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'Unable to load documents',
            style: TextStyle(
              fontSize: 15,

              fontWeight: FontWeight.w700,

              color: _navy,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            _error,

            textAlign: TextAlign.center,

            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,

              foregroundColor: Colors.white,

              elevation: 0,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),

            onPressed: _loadDocuments,

            icon: const Icon(Icons.refresh_rounded),

            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 45),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(17),

        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,

            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.08),

              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.folder_open_outlined,
              color: _primary,
              size: 31,
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'No documents found',
            style: TextStyle(
              fontSize: 16,

              fontWeight: FontWeight.w700,

              color: _navy,
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'Try changing the module, status or search filter.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COLORS
  // ============================================================

  Color _statusColor(String status) {
    switch (status.trim().toUpperCase()) {
      case 'APPROVED':
        return const Color(0xFF2E9D60);

      case 'REJECTED':
        return const Color(0xFFD94A4A);

      case 'PENDING':
        return const Color(0xFFF59E0B);

      case 'WAITING':
        return const Color(0xFF7C8798);

      case 'IN PROCESS':
      case 'INPROCESS':
      case 'IN_PROCESS':
        return const Color(0xFF3D7EDB);

      default:
        return _primary;
    }
  }

  Color _moduleColor(String module) {
    switch (module.trim().toUpperCase()) {
      case 'PR':
        return _primary;

      case 'SR':
        return const Color(0xFF8258C9);

      case 'NFA':
        return const Color(0xFFE58B29);

      case 'PO':
        return const Color(0xFF2E9D60);

      case 'MIN':
        return const Color(0xFF3D7EDB);

      default:
        return _navy;
    }
  }

  // ============================================================
  // ICONS
  // ============================================================

  IconData _moduleIcon(String module) {
    switch (module.trim().toUpperCase()) {
      case 'PR':
        return Icons.shopping_cart_outlined;

      case 'SR':
        return Icons.build_outlined;

      case 'NFA':
        return Icons.fact_check_outlined;

      case 'PO':
        return Icons.receipt_long_outlined;

      case 'MIN':
        return Icons.inventory_2_outlined;

      default:
        return Icons.description_outlined;
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _formatFilterText(String value) {
    switch (value.trim().toUpperCase()) {
      case 'ALL':
        return 'All';

      case 'PENDING':
        return 'Pending';

      case 'APPROVED':
        return 'Approved';

      case 'REJECTED':
        return 'Rejected';

      default:
        return value;
    }
  }

  String _cleanError(String value) {
    String result = value.trim();

    if (result.startsWith('Exception:')) {
      result = result.substring('Exception:'.length).trim();
    }

    return result;
  }
}
