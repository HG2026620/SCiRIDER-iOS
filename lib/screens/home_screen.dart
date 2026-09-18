import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/dashboard_model.dart';
import '../models/user_profile.dart';

import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import '../services/approval_service.dart';
import '../services/update_popup_service.dart';

import 'login_screen.dart';
import 'my_approvals_screen.dart';
import 'documents_screen.dart';
import 'alerts_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserProfile user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color primaryBlue = Color(0xFF079BD3);

  static const Color primaryBlueDark = Color(0xFF067FAE);

  static const Color navyBlue = Color(0xFF173F6B);

  static const Color navyBlueLight = Color(0xFF245B8A);

  static const Color textDark = Color(0xFF182632);

  static const Color textMedium = Color(0xFF62717E);

  static const Color textLight = Color(0xFF8996A1);

  static const Color pageBackground = Color(0xFFF3F6F9);

  static const Color cardBorder = Color(0xFFE1E7EC);

  static const Color softBlue = Color(0xFFEAF7FC);

  static const Color softNavy = Color(0xFFEEF3F8);

  static const Color successGreen = Color(0xFF28A66A);

  static const Color pendingAmber = Color(0xFFF2A51A);

  static const Color rejectRed = Color(0xFFE04B4B);

  // ============================================================
  // SERVICES
  // ============================================================

  final DashboardService _dashboardService = DashboardService();

  final ApprovalService _approvalService = ApprovalService();

  // ============================================================
  // DASHBOARD
  // ============================================================

  DashboardModel? _dashboard;

  bool _loading = true;

  String _error = '';

  // ============================================================
  // APPROVAL WATCHER
  // ============================================================

  Timer? _approvalAlertTimer;

  Set<int> _knownApprovalTxnIds = <int>{};

  bool _approvalAlertBaselineReady = false;

  bool _checkingApprovals = false;

  bool _appInForeground = true;

  static const Duration _approvalCheckInterval = Duration(seconds: 30);

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _loadDashboard();

    _startNewApprovalWatcher();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      await UpdatePopupService.showIfRequired(
        context,
        releaseKey: 'scirider_v2_20260917',
        title: 'SCiRIDER V2',
        updates: const <String>[
          'PR, NFA and PO approval details are available.',
          'Document PDF viewing is available.',
          'Approval history is available.',
          'New approval alerts are enabled while the app is open.',
          'Dashboard approval counts refresh automatically.',
        ],
      );
    });
  }

  // ============================================================
  // APP LIFECYCLE
  // ============================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _appInForeground = true;

        _checkForNewApprovals();

        _startApprovalTimer();

        break;

      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _appInForeground = false;

        _approvalAlertTimer?.cancel();

        _approvalAlertTimer = null;

        break;
    }
  }

  // ============================================================
  // APPROVAL WATCHER
  // ============================================================

  void _startNewApprovalWatcher() {
    _checkForNewApprovals(allowAlert: false);

    _startApprovalTimer();
  }

  void _startApprovalTimer() {
    _approvalAlertTimer?.cancel();

    if (!_appInForeground) {
      return;
    }

    _approvalAlertTimer = Timer.periodic(_approvalCheckInterval, (_) {
      if (_appInForeground) {
        _checkForNewApprovals();
      }
    });
  }

  Future<void> _checkForNewApprovals({bool allowAlert = true}) async {
    if (_checkingApprovals) {
      return;
    }

    _checkingApprovals = true;

    try {
      final approvals = await _approvalService.getMyApprovals();

      final Set<int> currentIds = approvals
          .where((x) => x.approvalTxnId > 0)
          .map((x) => x.approvalTxnId)
          .toSet();

      // ========================================================
      // FIRST LOAD = BASELINE ONLY
      // ========================================================

      if (!_approvalAlertBaselineReady) {
        _knownApprovalTxnIds = Set<int>.from(currentIds);

        _approvalAlertBaselineReady = true;

        debugPrint(
          'SCiRIDER: Approval baseline = '
          '$_knownApprovalTxnIds',
        );

        return;
      }

      // ========================================================
      // FIND NEW APPROVAL IDS
      // ========================================================

      final Set<int> newIds = currentIds.difference(_knownApprovalTxnIds);

      // Update before alert to avoid duplicates.
      _knownApprovalTxnIds = Set<int>.from(currentIds);

      if (newIds.isEmpty) {
        return;
      }

      final newApprovals = approvals
          .where((x) => newIds.contains(x.approvalTxnId))
          .toList();

      if (newApprovals.isEmpty ||
          !allowAlert ||
          !mounted ||
          !_appInForeground) {
        return;
      }

      // ========================================================
      // SOUND
      // ========================================================

      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (e) {
        debugPrint('SCiRIDER SOUND ERROR: $e');
      }

      if (!mounted) {
        return;
      }

      // ========================================================
      // ALERT
      // ========================================================

      final approval = newApprovals.first;

      final module = approval.module.toString().trim().toUpperCase();

      final sourceNo = approval.sourceNo.toString().trim();

      final extra = newApprovals.length - 1;

      String message = 'New $module approval received';

      if (sourceNo.isNotEmpty) {
        message += ': $sourceNo';
      }

      if (extra > 0) {
        message += ' (+$extra more)';
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,

            duration: const Duration(seconds: 8),

            margin: const EdgeInsets.all(14),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),

            content: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,

                  padding: const EdgeInsets.all(5),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius: BorderRadius.circular(10),
                  ),

                  child: Image.asset(
                    'assets/images/stride_favicon.png',

                    fit: BoxFit.contain,

                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.notifications_active_rounded,

                      color: primaryBlue,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text(
                        'New Approval',

                        style: TextStyle(
                          fontWeight: FontWeight.w800,

                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        message,

                        maxLines: 2,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            action: SnackBarAction(
              label: 'OPEN',

              textColor: const Color(0xFF7DD7FA),

              onPressed: _openApprovals,
            ),
          ),
        );

      await _loadDashboard(showLoading: false);
    } catch (e) {
      debugPrint('SCiRIDER APPROVAL WATCH ERROR: $e');
    } finally {
      _checkingApprovals = false;
    }
  }

  // ============================================================
  // DASHBOARD
  // ============================================================

  Future<void> _loadDashboard({bool showLoading = true}) async {
    if (mounted && showLoading) {
      setState(() {
        _loading = true;
        _error = '';
      });
    }

    try {
      final result = await _dashboardService.getDashboard();

      if (!mounted) {
        return;
      }

      setState(() {
        _dashboard = result;
        _error = '';
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted && showLoading) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ============================================================
  // ORGANIZATION VALUE
  // ============================================================

  String _organizationValue({required String name, required int id}) {
    final cleanName = name.trim();

    if (cleanName.isNotEmpty && cleanName.toLowerCase() != 'null') {
      return cleanName;
    }

    // ----------------------------------------------------------
    // Name was not returned by backend.
    //
    // Keep ID visible temporarily instead of displaying
    // incorrect/hard-coded organization information.
    // ----------------------------------------------------------

    if (id > 0) {
      return 'ID: $id';
    }

    return '-';
  }

  String _financialYear(DashboardModel data) {
    if (data.financialYear.trim().isNotEmpty) {
      return data.financialYear.trim();
    }

    if (widget.user.defaultFinancialYear.trim().isNotEmpty) {
      return widget.user.defaultFinancialYear.trim();
    }

    return '-';
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  Future<void> _openApprovals() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const MyApprovalsScreen()));

    if (!mounted) {
      return;
    }

    await _loadDashboard();

    await _checkForNewApprovals();
  }

  Future<void> _openDocuments() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const DocumentsScreen()));

    if (mounted) {
      await _loadDashboard();
    }
  }

  Future<void> _openAlerts() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AlertsScreen()));

    if (mounted) {
      await _loadDashboard();
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    _approvalAlertTimer?.cancel();

    await AuthService().logout();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _approvalAlertTimer?.cancel();

    super.dispose();
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

        toolbarHeight: 70,

        titleSpacing: 14,

        title: Row(
          children: [
            _buildAppLogo(),

            const SizedBox(width: 10),

            const Expanded(
              child: Text(
                'SCiRIDER',

                style: TextStyle(
                  color: textDark,

                  fontSize: 21,

                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',

            onPressed: () async {
              await _loadDashboard();

              await _checkForNewApprovals();
            },

            icon: const Icon(Icons.refresh_rounded, color: textMedium),
          ),

          IconButton(
            tooltip: 'Logout',

            onPressed: _logout,

            icon: const Icon(Icons.logout_rounded, color: textMedium),
          ),

          const SizedBox(width: 5),
        ],
      ),

      body: RefreshIndicator(
        color: primaryBlue,

        onRefresh: () async {
          await _loadDashboard();

          await _checkForNewApprovals();
        },

        child: _buildBody(),
      ),

      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // ============================================================
  // LOGO
  // ============================================================

  Widget _buildAppLogo() {
    return Container(
      width: 47,
      height: 47,

      padding: const EdgeInsets.all(6),

      decoration: BoxDecoration(
        color: const Color(0xFFF5FBFE),

        borderRadius: BorderRadius.circular(13),

        border: Border.all(color: const Color(0xFFD8EDF6)),
      ),

      child: Image.asset(
        'assets/images/stride_favicon.png',

        fit: BoxFit.contain,

        errorBuilder: (_, __, ___) =>
            const Icon(Icons.change_history_rounded, color: primaryBlue),
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_loading && _dashboard == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),

        children: const [
          SizedBox(height: 180),

          Center(child: CircularProgressIndicator(color: primaryBlue)),

          SizedBox(height: 18),

          Center(
            child: Text(
              'Loading dashboard...',

              style: TextStyle(color: textMedium),
            ),
          ),
        ],
      );
    }

    if (_error.isNotEmpty && _dashboard == null) {
      return _buildDashboardError();
    }

    final data = _dashboard;

    if (data == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),

        children: const [
          SizedBox(height: 150),

          Center(child: Text('Dashboard data not available.')),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.fromLTRB(15, 15, 15, 32),

      children: [
        if (_error.isNotEmpty) _buildWarningMessage(),

        _buildUserHeader(data),

        const SizedBox(height: 22),

        _buildSectionHeader(
          title: 'Approval Overview',

          actionText: 'View All',

          onPressed: _openApprovals,
        ),

        const SizedBox(height: 10),

        _buildMainApprovalCard(data),

        const SizedBox(height: 14),

        GridView.count(
          crossAxisCount: 2,

          shrinkWrap: true,

          physics: const NeverScrollableScrollPhysics(),

          crossAxisSpacing: 12,

          mainAxisSpacing: 12,

          childAspectRatio: 1.45,

          children: [
            _buildDashboardCard(
              title: 'PR / SR',

              count: data.pendingPRSR,

              icon: Icons.description_outlined,

              accentColor: primaryBlue,

              softColor: softBlue,

              onTap: _openApprovals,
            ),

            _buildDashboardCard(
              title: 'NFA',

              count: data.pendingNFA,

              icon: Icons.fact_check_outlined,

              accentColor: pendingAmber,

              softColor: const Color(0xFFFFF5DF),

              onTap: _openApprovals,
            ),

            _buildDashboardCard(
              title: 'Comparison',

              count: data.pendingVendorComparison,

              icon: Icons.compare_arrows_rounded,

              accentColor: const Color(0xFF7965C1),

              softColor: const Color(0xFFF1EEFB),

              onTap: _openApprovals,
            ),

            _buildDashboardCard(
              title: 'Purchase Order',

              count: data.pendingPO,

              icon: Icons.shopping_cart_outlined,

              accentColor: successGreen,

              softColor: const Color(0xFFE8F7EF),

              onTap: _openApprovals,
            ),

            _buildDashboardCard(
              title: 'Vendor Payment',

              count: data.pendingVendorPayment,

              icon: Icons.payments_outlined,

              accentColor: const Color(0xFFDD7A28),

              softColor: const Color(0xFFFFF1E6),

              onTap: _openApprovals,
            ),

            _buildDashboardCard(
              title: 'All Approvals',

              count: data.pendingApprovals,

              icon: Icons.approval_outlined,

              accentColor: navyBlue,

              softColor: softNavy,

              onTap: _openApprovals,
            ),
          ],
        ),

        const SizedBox(height: 25),

        _buildSectionTitle('Current Organization'),

        const SizedBox(height: 12),

        _buildOrganizationCard(data),

        const SizedBox(height: 25),

        _buildQuickActions(),
      ],
    );
  }

  // ============================================================
  // USER HEADER
  // ============================================================

  Widget _buildUserHeader(DashboardModel data) {
    final name = data.fullName.trim().isNotEmpty
        ? data.fullName
        : widget.user.fullName;

    final designation = data.designation.trim().isNotEmpty
        ? data.designation
        : widget.user.designation;

    return Container(
      padding: const EdgeInsets.all(19),

      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [navyBlue, navyBlueLight]),

        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(18),
            ),

            child: const Icon(
              Icons.person_rounded,

              size: 38,

              color: primaryBlue,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'Welcome',

                  style: TextStyle(color: Color(0xFFD4E5F2)),
                ),

                const SizedBox(height: 3),

                Text(
                  name,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: Colors.white,

                    fontSize: 19,

                    fontWeight: FontWeight.w800,
                  ),
                ),

                if (designation.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),

                  Text(
                    designation,

                    style: const TextStyle(color: Color(0xFFE1EDF5)),
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
  // MAIN APPROVAL
  // ============================================================

  Widget _buildMainApprovalCard(DashboardModel data) {
    return Material(
      color: Colors.white,

      borderRadius: BorderRadius.circular(18),

      child: InkWell(
        borderRadius: BorderRadius.circular(18),

        onTap: _openApprovals,

        child: Container(
          padding: const EdgeInsets.all(18),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),

            border: Border.all(color: cardBorder),
          ),

          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,

                decoration: BoxDecoration(
                  color: softBlue,

                  borderRadius: BorderRadius.circular(16),
                ),

                child: const Icon(
                  Icons.pending_actions_rounded,

                  size: 32,

                  color: primaryBlue,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const Text(
                      'Pending Approvals',

                      style: TextStyle(color: textMedium),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '${data.pendingApprovals}',

                      style: const TextStyle(
                        fontSize: 31,

                        fontWeight: FontWeight.w900,

                        color: textDark,
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      'Tap to review pending documents',

                      style: TextStyle(color: textLight, fontSize: 11),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right_rounded, color: textMedium),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DASHBOARD CARD
  // ============================================================

  Widget _buildDashboardCard({
    required String title,
    required int count,
    required IconData icon,
    required Color accentColor,
    required Color softColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,

      borderRadius: BorderRadius.circular(17),

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(17),

        child: Container(
          padding: const EdgeInsets.all(14),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),

            border: Border.all(color: cardBorder),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,

                    decoration: BoxDecoration(
                      color: softColor,

                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Icon(icon, color: accentColor, size: 22),
                  ),

                  const Spacer(),

                  Text(
                    '$count',

                    style: TextStyle(
                      fontSize: 26,

                      fontWeight: FontWeight.w900,

                      color: accentColor,
                    ),
                  ),
                ],
              ),

              Text(
                title,

                maxLines: 2,

                overflow: TextOverflow.ellipsis,

                style: const TextStyle(
                  color: textMedium,

                  fontWeight: FontWeight.w700,

                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ORGANIZATION CARD - CORRECTED
  // ============================================================

  Widget _buildOrganizationCard(DashboardModel data) {
    final company = _organizationValue(
      name: data.companyName,
      id: data.companyId,
    );

    final project = _organizationValue(
      name: data.projectName,
      id: data.projectId,
    );

    final department = _organizationValue(
      name: data.departmentName,
      id: data.departmentId,
    );

    final financialYear = _financialYear(data);

    return Container(
      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(17),

        border: Border.all(color: cardBorder),
      ),

      child: Column(
        children: [
          _organizationRow(
            icon: Icons.business_outlined,

            label: 'Company',

            value: company,
          ),

          const Divider(height: 22),

          _organizationRow(
            icon: Icons.location_city_outlined,

            label: 'Project',

            value: project,
          ),

          const Divider(height: 22),

          _organizationRow(
            icon: Icons.account_tree_outlined,

            label: 'Department',

            value: department,
          ),

          const Divider(height: 22),

          _organizationRow(
            icon: Icons.calendar_month_outlined,

            label: 'Financial Year',

            value: financialYear,
          ),
        ],
      ),
    );
  }

  Widget _organizationRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 39,
          height: 39,

          decoration: BoxDecoration(
            color: softNavy,

            borderRadius: BorderRadius.circular(11),
          ),

          child: Icon(icon, color: navyBlue, size: 20),
        ),

        const SizedBox(width: 12),

        SizedBox(
          width: 100,

          child: Text(
            label,

            style: const TextStyle(color: textMedium, fontSize: 13),
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            value,

            maxLines: 2,

            overflow: TextOverflow.ellipsis,

            textAlign: TextAlign.right,

            style: const TextStyle(
              color: textDark,

              fontWeight: FontWeight.w700,

              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(17),

        border: Border.all(color: cardBorder),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'Quick Actions',

            style: TextStyle(
              fontSize: 17,

              fontWeight: FontWeight.w800,

              color: textDark,
            ),
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openApprovals,

                  icon: const Icon(Icons.approval_outlined),

                  label: const Text('Approvals'),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await _loadDashboard();

                    await _checkForNewApprovals();
                  },

                  icon: const Icon(Icons.refresh_rounded),

                  label: const Text('Refresh'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION
  // ============================================================

  Widget _buildSectionHeader({
    required String title,
    required String actionText,
    required VoidCallback onPressed,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,

            style: const TextStyle(
              fontSize: 19,

              fontWeight: FontWeight.w800,

              color: textDark,
            ),
          ),
        ),

        TextButton(
          onPressed: onPressed,

          child: Text(
            actionText,

            style: const TextStyle(
              color: primaryBlueDark,

              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,

      style: const TextStyle(
        fontSize: 18,

        fontWeight: FontWeight.w800,

        color: textDark,
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildDashboardError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.all(24),

      children: [
        const SizedBox(height: 100),

        const Icon(Icons.cloud_off_rounded, size: 60, color: textLight),

        const SizedBox(height: 20),

        const Text(
          'Unable to load dashboard',

          textAlign: TextAlign.center,

          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),

        const SizedBox(height: 10),

        Text(
          _error,

          textAlign: TextAlign.center,

          style: const TextStyle(color: rejectRed),
        ),

        const SizedBox(height: 20),

        OutlinedButton.icon(
          onPressed: _loadDashboard,

          icon: const Icon(Icons.refresh_rounded),

          label: const Text('Try Again'),
        ),
      ],
    );
  }

  Widget _buildWarningMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F4),

        borderRadius: BorderRadius.circular(12),
      ),

      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: rejectRed),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              _error,

              style: const TextStyle(color: rejectRed, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNavigation() {
    return NavigationBar(
      selectedIndex: 0,

      backgroundColor: Colors.white,

      indicatorColor: const Color(0xFFE0F3FA),

      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            _loadDashboard();
            break;

          case 1:
            _openApprovals();
            break;

          case 2:
            _openDocuments();
            break;

          case 3:
            _openAlerts();
            break;

          case 4:
            _showProfile();
            break;
        }
      },

      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),

          selectedIcon: Icon(Icons.dashboard_rounded),

          label: 'Dashboard',
        ),

        NavigationDestination(
          icon: Icon(Icons.approval_outlined),

          selectedIcon: Icon(Icons.approval_rounded),

          label: 'Approvals',
        ),

        NavigationDestination(
          icon: Icon(Icons.folder_outlined),

          selectedIcon: Icon(Icons.folder_rounded),

          label: 'Documents',
        ),

        NavigationDestination(
          icon: Icon(Icons.notifications_none_rounded),

          selectedIcon: Icon(Icons.notifications_rounded),

          label: 'Alerts',
        ),

        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),

          selectedIcon: Icon(Icons.person_rounded),

          label: 'Profile',
        ),
      ],
    );
  }

  // ============================================================
  // PROFILE
  // ============================================================

  void _showProfile() {
    showModalBottomSheet(
      context: context,

      showDragHandle: true,

      backgroundColor: Colors.white,

      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                const Icon(Icons.person_rounded, size: 60, color: navyBlue),

                const SizedBox(height: 12),

                Text(
                  widget.user.fullName,

                  style: const TextStyle(
                    fontSize: 20,

                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 20),

                _profileRow('User Code', widget.user.userCode),

                _profileRow('Login ID', widget.user.loginId),

                _profileRow('Email', widget.user.email),

                _profileRow('Mobile', widget.user.mobileNo),

                _profileRow('Financial Year', widget.user.defaultFinancialYear),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);

                      _logout();
                    },

                    icon: const Icon(Icons.logout_rounded),

                    label: const Text('Logout'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),

      child: Row(
        children: [
          SizedBox(
            width: 110,

            child: Text(label, style: const TextStyle(color: textLight)),
          ),

          Expanded(
            child: Text(
              value.trim().isEmpty ? '-' : value,

              textAlign: TextAlign.right,

              style: const TextStyle(
                fontWeight: FontWeight.w600,

                color: textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
