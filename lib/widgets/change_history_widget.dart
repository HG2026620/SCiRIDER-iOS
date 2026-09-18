import 'package:flutter/material.dart';

import '../models/prsr_change_history_model.dart';

class ChangeHistoryWidget extends StatelessWidget {
  final List<PRSRChangeHistoryModel> history;

  const ChangeHistoryWidget({
    super.key,
    required this.history,
  });

  static const Color _primary = Color(0xFF079BD3);
  static const Color _navy = Color(0xFF173F6B);
  static const Color _background = Color(0xFFF4F8FB);

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
        child: const Row(
          children: [
            Icon(Icons.history_toggle_off_outlined, color: Colors.black45),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'No approver changes recorded for this document.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ],
        ),
      );
    }

    final groups = _groupHistory(history);

    return Column(
      children: groups.map((group) => _buildGroup(group)).toList(),
    );
  }

  List<_ChangeGroup> _groupHistory(List<PRSRChangeHistoryModel> items) {
    final Map<String, _ChangeGroup> grouped = <String, _ChangeGroup>{};

    for (final item in items) {
      final changedKey = item.changedOn?.millisecondsSinceEpoch ?? 0;
      final key =
          '${item.approvalTxnId ?? 0}|${item.approvalLevel}|$changedKey|${item.changedBy}|${item.changeArea}';

      final existing = grouped[key];

      if (existing == null) {
        grouped[key] = _ChangeGroup(
          approvalTxnId: item.approvalTxnId,
          approvalLevel: item.approvalLevel,
          changedBy: item.displayChangedBy,
          changedOn: item.changedOn,
          changedOnText: item.displayChangedOn,
          changeArea: item.displayChangeArea,
          action: item.action,
          remarks: item.remarks,
          items: <PRSRChangeHistoryModel>[item],
        );
      } else {
        existing.items.add(item);
      }
    }

    final result = grouped.values.toList();

    result.sort((a, b) {
      final ad = a.changedOn ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.changedOn ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });

    return result;
  }

  Widget _buildGroup(_ChangeGroup group) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
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
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: _primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.approvalLevel > 0
                          ? 'Level ${group.approvalLevel} Changes'
                          : 'Document Changes',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _navy,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${group.changeArea} • ${group.changedOnText}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              _areaBadge(group.changeArea),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 6),
          ...group.items.map(_buildFieldChange),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: _background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  size: 17,
                  color: _primary,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Changed by ${group.changedBy}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _navy,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (group.remarks.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Remark: ${group.remarks.trim()}',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black54,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFieldChange(PRSRChangeHistoryModel item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.displayFieldCaption,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _navy,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _valueBox(
                  caption: 'Old',
                  value: item.displayOldValue,
                  isNew: false,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 17,
                  color: Colors.black38,
                ),
              ),
              Expanded(
                child: _valueBox(
                  caption: 'New',
                  value: item.displayNewValue,
                  isNew: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _valueBox({
    required String caption,
    required String value,
    required bool isNew,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: isNew
            ? _primary.withValues(alpha: 0.07)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: isNew
              ? _primary.withValues(alpha: 0.20)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            caption,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.black45,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isNew ? FontWeight.w700 : FontWeight.w500,
              color: isNew ? _primary : _navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _areaBadge(String area) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        area,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: _primary,
        ),
      ),
    );
  }
}

class _ChangeGroup {
  final int? approvalTxnId;
  final int approvalLevel;
  final String changedBy;
  final DateTime? changedOn;
  final String changedOnText;
  final String changeArea;
  final String action;
  final String remarks;
  final List<PRSRChangeHistoryModel> items;

  _ChangeGroup({
    required this.approvalTxnId,
    required this.approvalLevel,
    required this.changedBy,
    required this.changedOn,
    required this.changedOnText,
    required this.changeArea,
    required this.action,
    required this.remarks,
    required this.items,
  });
}
