import 'package:flutter/material.dart';

import '../models/approval_model.dart';
import '../services/approval_service.dart';

class MyApprovalsScreen extends StatefulWidget {
  const MyApprovalsScreen({
    super.key,
  });

  @override
  State<MyApprovalsScreen> createState() =>
      _MyApprovalsScreenState();
}

class _MyApprovalsScreenState
    extends State<MyApprovalsScreen> {
  final ApprovalService _approvalService =
      ApprovalService();

  final TextEditingController _searchController =
      TextEditingController();

  List<ApprovalModel> _approvals = [];

  bool _loading = true;

  String _error = '';

  String _selectedModule = 'ALL';

  @override
  void initState() {
    super.initState();

    _loadApprovals();
  }

  Future<void> _loadApprovals() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final data =
          await _approvalService.getMyApprovals(
        module: _selectedModule,
        searchText: _searchController.text,
      );

      if (!mounted) return;

      setState(() {
        _approvals = data;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F7FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'My Approvals',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                _loading ? null : _loadApprovals,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _loadApprovals,
        child: Column(
          children: [
            _buildFilters(),

            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding:
          const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        15,
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            textInputAction:
                TextInputAction.search,
            onSubmitted: (_) {
              _loadApprovals();
            },
            decoration: InputDecoration(
              hintText:
                  'Search document no...',
              prefixIcon: const Icon(
                Icons.search,
              ),
              suffixIcon:
                  _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController
                                .clear();

                            _loadApprovals();
                          },
                          icon: const Icon(
                            Icons.close,
                          ),
                        ),
              filled: true,
              fillColor:
                  const Color(0xFFF5F7F9),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
                borderSide:
                    BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection:
                  Axis.horizontal,
              children: [
                _moduleChip('ALL'),
                _moduleChip('PR'),
                _moduleChip('NFA'),
                _moduleChip('PO'),
                _moduleChip(
                  'VENDOR PAYMENT',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _moduleChip(
    String module,
  ) {
    final selected =
        _selectedModule == module;

    return Padding(
      padding:
          const EdgeInsets.only(
        right: 8,
      ),
      child: ChoiceChip(
        label: Text(
          module == 'ALL'
              ? 'All'
              : module,
        ),
        selected: selected,
        onSelected: (_) {
          setState(() {
            _selectedModule = module;
          });

          _loadApprovals();
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_loading &&
        _approvals.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error.isNotEmpty &&
        _approvals.isEmpty) {
      return ListView(
        padding:
            const EdgeInsets.all(25),
        children: [
          const SizedBox(height: 80),

          const Icon(
            Icons.error_outline,
            size: 55,
            color: Colors.grey,
          ),

          const SizedBox(height: 15),

          Text(
            _error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.red,
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: _loadApprovals,
            icon: const Icon(
              Icons.refresh,
            ),
            label: const Text(
              'Try Again',
            ),
          ),
        ],
      );
    }

    if (_approvals.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),

          Icon(
            Icons.task_alt_rounded,
            size: 65,
            color: Color(0xFF9AA7B2),
          ),

          SizedBox(height: 15),

          Center(
            child: Text(
              'No pending approvals.',
              style: TextStyle(
                color:
                    Color(0xFF687682),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding:
          const EdgeInsets.all(16),

      itemCount:
          _approvals.length,

      separatorBuilder:
          (_, _) =>
              const SizedBox(
        height: 11,
      ),

      itemBuilder:
          (context, index) {
        return _approvalCard(
          _approvals[index],
        );
      },
    );
  }

  Widget _approvalCard(
    ApprovalModel approval,
  ) {
    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(15),

      child: InkWell(
        borderRadius:
            BorderRadius.circular(15),

        onTap: () {
          _openApproval(
            approval,
          );
        },

        child: Container(
          padding:
              const EdgeInsets.all(16),

          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              15,
            ),
            border: Border.all(
              color:
                  const Color(
                0xFFE3E9EE,
              ),
            ),
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Row(
                children: [
                  _moduleIcon(
                    approval.module,
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          approval
                                  .sourceNo
                                  .isNotEmpty
                              ? approval
                                  .sourceNo
                              : '#${approval.sourceId}',

                          style:
                              const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight
                                    .w700,
                            color:
                                Color(
                              0xFF17212B,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 3,
                        ),

                        Text(
                          _documentName(
                            approval,
                          ),
                          style:
                              const TextStyle(
                            color:
                                Color(
                              0xFF687682,
                            ),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons
                        .chevron_right_rounded,
                    color:
                        Color(
                      0xFF9CA7B1,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 14,
              ),

              Row(
                children: [
                  _statusBadge(
                    approval
                        .approvalStatus,
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  _smallBadge(
                    'Level ${approval.approvalLevel}',
                  ),

                  if (approval
                      .isFinalLevel) ...[
                    const SizedBox(
                      width: 8,
                    ),

                    _smallBadge(
                      'Final',
                    ),
                  ],
                ],
              ),

              const SizedBox(
                height: 14,
              ),

              const Divider(
                height: 1,
              ),

              const SizedBox(
                height: 12,
              ),

              Row(
                children: [
                  const Icon(
                    Icons
                        .person_outline,
                    size: 16,
                    color:
                        Color(
                      0xFF7A8793,
                    ),
                  ),

                  const SizedBox(
                    width: 5,
                  ),

                  Expanded(
                    child: Text(
                      approval
                              .roleName
                              .isNotEmpty
                          ? approval
                              .roleName
                          : approval
                              .approverName,

                      style:
                          const TextStyle(
                        fontSize: 12,
                        color:
                            Color(
                          0xFF687682,
                        ),
                      ),
                    ),
                  ),

                  if (approval
                          .assignedDate !=
                      null)
                    Text(
                      _formatDate(
                        approval
                            .assignedDate!,
                      ),
                      style:
                          const TextStyle(
                        fontSize: 11,
                        color:
                            Color(
                          0xFF8A96A1,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _moduleIcon(
    String module,
  ) {
    IconData icon;

    switch (
        module.toUpperCase()) {
      case 'PR':
        icon =
            Icons.description_outlined;
        break;

      case 'NFA':
        icon =
            Icons.fact_check_outlined;
        break;

      case 'PO':
        icon =
            Icons.shopping_cart_outlined;
        break;

      default:
        icon =
            Icons.approval_outlined;
    }

    return Container(
      width: 45,
      height: 45,

      decoration: BoxDecoration(
        color:
            const Color(0xFFEAF7FC),
        borderRadius:
            BorderRadius.circular(12),
      ),

      child: Icon(
        icon,
        color:
            const Color(0xFF079BD3),
      ),
    );
  }

  Widget _statusBadge(
    String status,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),

      decoration: BoxDecoration(
        color:
            const Color(0xFFFFF4DB),
        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Text(
        status.isEmpty
            ? 'Pending'
            : status,

        style:
            const TextStyle(
          fontSize: 11,
          fontWeight:
              FontWeight.w600,
          color:
              Color(0xFFB27600),
        ),
      ),
    );
  }

  Widget _smallBadge(
    String text,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),

      decoration: BoxDecoration(
        color:
            const Color(0xFFF0F3F6),
        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Text(
        text,
        style:
            const TextStyle(
          fontSize: 10,
          color:
              Color(0xFF65727E),
        ),
      ),
    );
  }

  String _documentName(
    ApprovalModel approval,
  ) {
    if (approval.requestType
        .isNotEmpty) {
      return approval.requestType;
    }

    return approval.module;
  }

  String _formatDate(
    DateTime date,
  ) {
    final day =
        date.day
            .toString()
            .padLeft(2, '0');

    final month =
        date.month
            .toString()
            .padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  void _openApproval(
    ApprovalModel approval,
  ) {
    /*
      We will replace this in the
      next step with ApprovalDetailScreen.
    */

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding:
              const EdgeInsets.all(22),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                approval.sourceNo,
                style:
                    const TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              Text(
                'Module: ${approval.module}',
              ),

              Text(
                'Request: ${approval.requestType}',
              ),

              Text(
                'Approval Level: ${approval.approvalLevel}',
              ),

              Text(
                'Transaction ID: ${approval.approvalTxnId}',
              ),

              const SizedBox(
                height: 20,
              ),
            ],
          ),
        );
      },
    );
  }
}