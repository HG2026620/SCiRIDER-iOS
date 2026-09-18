import 'package:flutter/material.dart';

import '../models/document_approval_history_model.dart';

class ApprovalHistoryWidget extends StatelessWidget {
  final List<DocumentApprovalHistoryModel> history;

  const ApprovalHistoryWidget({super.key, required this.history});

  static const Color _primary = Color(0xFF079BD3);

  static const Color _navy = Color(0xFF173F6B);

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Text('No approval history available.'),
      );
    }

    return Column(
      children: List.generate(history.length, (index) {
        final item = history[index];

        return _buildHistoryItem(context, item, index, history.length);
      }),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    DocumentApprovalHistoryModel item,
    int index,
    int total,
  ) {
    final isLast = index == total - 1;

    final statusColor = _statusColor(item.approvalStatus);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                  ),
                  child: Icon(
                    _statusIcon(item.approvalStatus),
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: Colors.grey.shade300),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Level ${item.approvalLevel}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _navy,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.displayStatus,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _infoRow(
                    Icons.person_outline,
                    'Approver',
                    item.approverName.isEmpty ? '-' : item.approverName,
                  ),

                  _infoRow(
                    Icons.badge_outlined,
                    'Role',
                    item.roleName.isEmpty ? '-' : item.roleName,
                  ),

                  _infoRow(
                    Icons.schedule_outlined,
                    'Assigned',
                    item.displayAssignedDate,
                  ),

                  _infoRow(
                    Icons.task_alt_outlined,
                    'Action',
                    item.displayActionDate,
                  ),

                  if (item.isFinalLevel)
                    _infoRow(Icons.verified_outlined, 'Final Level', 'Yes'),

                  if (item.remark.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F8FB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Remark',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.remark,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: _primary),
          const SizedBox(width: 8),
          SizedBox(
            width: 74,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.trim().toUpperCase()) {
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'PENDING':
        return Colors.orange;
      case 'WAITING':
        return Colors.blueGrey;
      default:
        return _primary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.trim().toUpperCase()) {
      case 'APPROVED':
        return Icons.check;
      case 'REJECTED':
        return Icons.close;
      case 'PENDING':
        return Icons.schedule;
      case 'WAITING':
        return Icons.hourglass_empty;
      default:
        return Icons.circle;
    }
  }
}
