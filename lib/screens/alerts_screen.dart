import 'package:flutter/material.dart';

import '../models/approval_model.dart';
import '../routes/approval_detail_router.dart';
import '../services/approval_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  static const Color primary = Color(0xFF079BD3);
  static const Color navy = Color(0xFF173F6B);
  static const Color background = Color(0xFFF4F8FB);

  final ApprovalService _service = ApprovalService();
  bool _loading = true;
  String _error = '';
  List<ApprovalModel> _alerts = <ApprovalModel>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = ''; });
    try {
      final data = await _service.getMyApprovals();
      if (!mounted) return;
      setState(() { _alerts = data; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _open(ApprovalModel approval) async {
    await ApprovalDetailRouter.open(context, approval);
    if (mounted) await _load();
  }

  String _date(DateTime? d) {
    if (d == null) return '-';
    return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: navy,
        title: const Text('Approval Alerts', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh))],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(children: const [SizedBox(height: 220), Center(child: CircularProgressIndicator(color: primary))])
            : _error.isNotEmpty
                ? ListView(children: [
                    const SizedBox(height: 180),
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Text(_error, textAlign: TextAlign.center)),
                  ])
                : _alerts.isEmpty
                    ? ListView(children: const [
                        SizedBox(height: 180),
                        Icon(Icons.notifications_none_rounded, size: 58, color: Colors.grey),
                        SizedBox(height: 12),
                        Center(child: Text('No pending approval alerts.')),
                      ])
                    : ListView.separated(
                        padding: const EdgeInsets.all(14),
                        itemCount: _alerts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final a = _alerts[i];
                          return Card(
                            elevation: 0,
                            child: ListTile(
                              onTap: () => _open(a),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFEAF7FC),
                                child: Text(a.module.toUpperCase(), style: const TextStyle(color: navy, fontSize: 11, fontWeight: FontWeight.w800)),
                              ),
                              title: Text(a.sourceNo.isEmpty ? '${a.module} Approval' : a.sourceNo, style: const TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: Text('${a.roleName.isEmpty ? 'Approval pending' : a.roleName} • ${_date(a.assignedDate)}'),
                              trailing: const Icon(Icons.chevron_right_rounded),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
