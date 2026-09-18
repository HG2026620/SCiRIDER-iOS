import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../models/approval_model.dart';
import '../services/approval_service.dart';
import '../services/master_service.dart';

class ApprovalDetailScreen extends StatefulWidget {
  final ApprovalModel approval;

  const ApprovalDetailScreen({
    super.key,
    required this.approval,
  });

  @override
  State<ApprovalDetailScreen> createState() =>
      _ApprovalDetailScreenState();
}

class _ApprovalDetailScreenState extends State<ApprovalDetailScreen> {
  // ============================================================
  // THEME
  // ============================================================

  static const Color primaryBlue = Color(0xFF079BD3);
  static const Color primaryBlueDark = Color(0xFF067FAE);
  static const Color navyBlue = Color(0xFF173F6B);
  static const Color pageBackground = Color(0xFFF4F8FB);

  final ApprovalService _approvalService = ApprovalService();
  final MasterService _masterService = MasterService();

  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _documentTotalNotifier =
      ValueNotifier<double>(0);

  final Map<int, ValueNotifier<double>> _amountNotifiers = {};

  bool _loading = true;
  bool _saving = false;
  bool _processingAction = false;
  bool _downloadingAttachment = false;

  String? _errorMessage;

  Map<String, dynamic> _header = {};

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _approvalHistory = [];

  // ============================================================
  // DROPDOWN LISTS
  // ============================================================

  List<MasterOption> _requirementTypes = [];
  List<MasterOption> _actionTypes = [];
  List<MasterOption> _frequencies = [];
  List<MasterOption> _priorities = [];
  List<MasterOption> _criticalities = [];
  List<MasterOption> _budgetTypes = [];
  List<MasterOption> _expenseTypes = [];
  List<MasterOption> _parentItemCategories = [];
  List<MasterOption> _aopCategories = [];
  List<MasterOption> _aopSubCategories = [];
  List<MasterOption> _aopDescriptions = [];

  int? _selectedRequirementTypeId;
  int? _selectedActionTypeId;
  int? _selectedFrequencyId;
  int? _selectedPriorityId;
  int? _selectedCriticalityId;
  int? _selectedBudgetTypeId;
  int? _selectedExpenseTypeId;
  int? _selectedParentItemCategoryId;
  int? _selectedAopCategoryId;
  int? _selectedAopSubCategoryId;
  int? _selectedAopDescriptionId;

  // ============================================================
  // HEADER
  // ============================================================

  final TextEditingController _requiredDateController =
      TextEditingController();

  final TextEditingController _budgetTypeController =
      TextEditingController();

  final TextEditingController _priorityController =
      TextEditingController();

  final TextEditingController _criticalityController =
      TextEditingController();

  final TextEditingController _requirementTypeController =
      TextEditingController();

  final TextEditingController _materialPartSerialController =
      TextEditingController();

  final TextEditingController _actionTypeController =
      TextEditingController();

  final TextEditingController _frequencyController =
      TextEditingController();

  final TextEditingController _prAmountBudgetController =
      TextEditingController();

  // ============================================================
  // BUSINESS JUSTIFICATION
  // ============================================================

  final TextEditingController _subjectController =
      TextEditingController();

  final TextEditingController _purposeController =
      TextEditingController();

  final TextEditingController _backgroundController =
      TextEditingController();

  final TextEditingController _justificationController =
      TextEditingController();

  final TextEditingController _scopeOfWorkController =
      TextEditingController();

  // ============================================================
  // AOP
  // ============================================================

  final TextEditingController _typeOfExpenseController =
      TextEditingController();

  final TextEditingController _aopCategoryController =
      TextEditingController();

  final TextEditingController _aopSubCategoryController =
      TextEditingController();

  final TextEditingController _aopProjectDescriptionController =
      TextEditingController();

  // ============================================================
  // APPROVAL REMARK
  // ============================================================

  final TextEditingController _approvalRemarkController =
      TextEditingController();

  // ============================================================
  // ITEM CONTROLLERS
  // ============================================================

  final Map<int, TextEditingController> _qtyControllers = {};
  final Map<int, TextEditingController> _rateControllers = {};
  final Map<int, TextEditingController> _lineRemarkControllers = {};

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  @override
  void dispose() {
    _requiredDateController.dispose();
    _budgetTypeController.dispose();
    _priorityController.dispose();
    _criticalityController.dispose();
    _requirementTypeController.dispose();
    _materialPartSerialController.dispose();
    _actionTypeController.dispose();
    _frequencyController.dispose();
    _prAmountBudgetController.dispose();

    _subjectController.dispose();
    _purposeController.dispose();
    _backgroundController.dispose();
    _justificationController.dispose();
    _scopeOfWorkController.dispose();

    _typeOfExpenseController.dispose();
    _aopCategoryController.dispose();
    _aopSubCategoryController.dispose();
    _aopProjectDescriptionController.dispose();

    _approvalRemarkController.dispose();

    for (final controller in _qtyControllers.values) {
      controller.dispose();
    }

    for (final controller in _rateControllers.values) {
      controller.dispose();
    }

    for (final controller in _lineRemarkControllers.values) {
      controller.dispose();
    }

    for (final notifier in _amountNotifiers.values) {
      notifier.dispose();
    }

    _amountNotifiers.clear();
    _documentTotalNotifier.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD PAGE
  // ============================================================

  Future<void> _loadPage({
    bool showLoader = true,
    bool preserveScroll = false,
  }) async {
    if (!mounted) return;

    final previousOffset =
        _scrollController.hasClients ? _scrollController.offset : 0.0;

    if (showLoader) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    } else {
      _errorMessage = null;
    }

    try {
      if (widget.approval.module.toUpperCase() != 'PR') {
        throw Exception(
          'Detailed mobile editing is currently available for Purchase Requests only.',
        );
      }

      final results = await Future.wait([
        _approvalService.getPRDetail(
          widget.approval.approvalTxnId,
        ),
        _masterService.getPRDropdowns(),
      ]);

      final prDetail = results[0];
      final dropdownData = results[1];

      _bindPRData(prDetail);
      _bindDropdowns(dropdownData);

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      if (preserveScroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_scrollController.hasClients) {
            return;
          }

          final maxScroll =
              _scrollController.position.maxScrollExtent;

          final target =
              previousOffset.clamp(0.0, maxScroll).toDouble();

          _scrollController.jumpTo(target);
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage = e.toString().replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  // ============================================================
  // BIND PR DATA
  // ============================================================

  void _bindPRData(
    Map<String, dynamic> prDetail,
  ) {
    _header = {};

    if (prDetail['header'] is Map) {
      _header = Map<String, dynamic>.from(
        prDetail['header'],
      );
    }

    _items = [];

    if (prDetail['items'] is List) {
      for (final row in prDetail['items']) {
        if (row is Map) {
          _items.add(
            Map<String, dynamic>.from(row),
          );
        }
      }
    }

    _approvalHistory = [];

    if (prDetail['approvalHistory'] is List) {
      for (final row in prDetail['approvalHistory']) {
        if (row is Map) {
          _approvalHistory.add(
            Map<String, dynamic>.from(row),
          );
        }
      }
    }

    _bindHeader();
    _bindItems();
  }

  // ============================================================
  // BIND DROPDOWNS
  // ============================================================

  void _bindDropdowns(
    Map<String, dynamic> data,
  ) {
    _requirementTypes = _masterService.toOptionList(
      _value(data, ['requirementTypes', 'RequirementTypes']),
    );

    _actionTypes = _masterService.toOptionList(
      _value(data, ['actionTypes', 'ActionTypes']),
    );

    _frequencies = _masterService.toOptionList(
      _value(data, ['frequencies', 'Frequencies']),
    );

    _priorities = _masterService.toOptionList(
      _value(data, ['priorities', 'Priorities']),
    );

    _criticalities = _masterService.toOptionList(
      _value(data, ['criticalities', 'Criticalities']),
    );

    _budgetTypes = _masterService.toOptionList(
      _value(data, ['budgetTypes', 'BudgetTypes']),
    );

    _expenseTypes = _masterService.toOptionList(
      _value(data, ['expenseTypes', 'ExpenseTypes']),
    );

    _parentItemCategories = _masterService.toOptionList(
      _value(data, ['parentItemCategories', 'ParentItemCategories']),
    );

    _aopCategories = _masterService.toOptionList(
      _value(data, ['aopCategories', 'AopCategories']),
    );

    _aopSubCategories = _masterService.toOptionList(
      _value(data, ['aopSubCategories', 'AopSubCategories']),
    );

    _aopDescriptions = _masterService.toOptionList(
      _value(data, ['aopDescriptions', 'AopDescriptions']),
    );

    // Current selections always come from the latest DB header values.
    _selectedRequirementTypeId = _dbSelectedId(
      _requirementTypes,
      commonId: _int(
        _value(
          _header,
          ['iRequirementTypeCommonId', 'requirementTypeCommonId'],
        ),
      ),
      rawValue: _text(
        _value(_header, ['sRequirementType', 'requirementType']),
      ),
    );

    _selectedActionTypeId = _dbSelectedId(
      _actionTypes,
      commonId: _int(
        _value(_header, ['iActionTypeCommonId', 'actionTypeCommonId']),
      ),
      rawValue: _text(
        _value(_header, ['sActionType', 'actionType']),
      ),
    );

    _selectedFrequencyId = _dbSelectedId(
      _frequencies,
      commonId: _int(
        _value(_header, ['iFrequencyCommonId', 'frequencyCommonId']),
      ),
      rawValue: _text(
        _value(_header, ['sFrequency', 'frequency']),
      ),
    );

    _selectedPriorityId = _dbSelectedId(
      _priorities,
      commonId: _int(
        _value(_header, ['iPriorityCommonId', 'priorityCommonId']),
      ),
      rawValue: _text(
        _value(_header, ['sPriority', 'priority']),
      ),
    );

    _selectedCriticalityId = _dbSelectedId(
      _criticalities,
      commonId: _int(
        _value(_header, ['iCriticalityCommonId', 'criticalityCommonId']),
      ),
      rawValue: _text(
        _value(_header, ['sCriticality', 'criticality']),
      ),
    );

    _selectedBudgetTypeId = _dbSelectedId(
      _budgetTypes,
      commonId: _int(
        _value(_header, ['iBudgetTypeCommonId', 'budgetTypeCommonId']),
      ),
      rawValue: _text(
        _value(_header, ['sBudgetType', 'budgetType']),
      ),
    );

    _selectedExpenseTypeId = _dbSelectedId(
      _expenseTypes,
      commonId: _int(
        _value(
          _header,
          [
            'iExpenseTypeCommonId',
            'expenseTypeCommonId',
            'iExpenseTypeId',
            'expenseTypeId',
          ],
        ),
      ),
      rawValue: _text(
        _value(_header, ['sTypeOfExpense', 'typeOfExpense']),
      ),
    );

    _selectedParentItemCategoryId = _nullablePositiveInt(
      _value(
        _header,
        ['iParentItemCategoryId', 'parentItemCategoryId'],
      ),
    );

    _selectedAopCategoryId = _nullablePositiveInt(
      _value(_header, ['iAOPCategoryId', 'aopCategoryId']),
    );

    _selectedAopSubCategoryId = _nullablePositiveInt(
      _value(_header, ['iAOPSubCategoryId', 'aopSubCategoryId']),
    );

    _selectedAopDescriptionId = _nullablePositiveInt(
      _value(
        _header,
        ['iAOPProjectDescriptionId', 'aopProjectDescriptionId'],
      ),
    );

    // Show description/name only. Never show raw numeric IDs to the user.
    _requirementTypeController.text = _nameById(
      _requirementTypes,
      _selectedRequirementTypeId,
      fallback: _text(
        _value(
          _header,
          ['sRequirementTypeDisplay', 'sRequirementType', 'requirementType'],
        ),
      ),
    );

    _actionTypeController.text = _nameById(
      _actionTypes,
      _selectedActionTypeId,
      fallback: _text(
        _value(
          _header,
          ['sActionTypeDisplay', 'sActionType', 'actionType'],
        ),
      ),
    );

    _frequencyController.text = _nameById(
      _frequencies,
      _selectedFrequencyId,
      fallback: _text(
        _value(
          _header,
          ['sFrequencyDisplay', 'sFrequency', 'frequency'],
        ),
      ),
    );

    _priorityController.text = _nameById(
      _priorities,
      _selectedPriorityId,
      fallback: _text(
        _value(
          _header,
          ['sPriorityDisplay', 'sPriority', 'priority'],
        ),
      ),
    );

    _criticalityController.text = _nameById(
      _criticalities,
      _selectedCriticalityId,
      fallback: _text(
        _value(
          _header,
          ['sCriticalityDisplay', 'sCriticality', 'criticality'],
        ),
      ),
    );

    _budgetTypeController.text = _nameById(
      _budgetTypes,
      _selectedBudgetTypeId,
      fallback: _text(
        _value(
          _header,
          ['sBudgetTypeDisplay', 'sBudgetType', 'budgetType'],
        ),
      ),
    );

    _typeOfExpenseController.text = _nameById(
      _expenseTypes,
      _selectedExpenseTypeId,
      fallback: _text(
        _value(
          _header,
          ['sTypeOfExpenseDisplay', 'sTypeOfExpense', 'typeOfExpense'],
        ),
      ),
    );

    _aopCategoryController.text = _nameById(
      _aopCategories,
      _selectedAopCategoryId,
      fallback: _text(
        _value(
          _header,
          ['sAOPCategoryName', 'sAOPCategory', 'aopCategoryName'],
        ),
      ),
    );

    _aopSubCategoryController.text = _nameById(
      _aopSubCategories,
      _selectedAopSubCategoryId,
      fallback: _text(
        _value(
          _header,
          ['sAOPSubCategoryName', 'sAOPSubCategory', 'aopSubCategoryName'],
        ),
      ),
    );

    _aopProjectDescriptionController.text = _nameById(
      _aopDescriptions,
      _selectedAopDescriptionId,
      fallback: _text(
        _value(
          _header,
          [
            'sAOPProjectDescriptionDisplay',
            'sAOPProjectDescription',
            'aopProjectDescription',
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BIND HEADER
  // ============================================================

  void _bindHeader() {
    _requiredDateController.text = _displayDate(
      _value(
        _header,
        [
          'dRequiredDate',
          'requiredDate',
        ],
      ),
    );

    _budgetTypeController.text = _text(
      _value(
        _header,
        [
          'sBudgetType',
          'budgetType',
        ],
      ),
    );

    _priorityController.text = _text(
      _value(
        _header,
        [
          'sPriority',
          'priority',
        ],
      ),
    );

    _criticalityController.text = _text(
      _value(
        _header,
        [
          'sCriticality',
          'criticality',
        ],
      ),
    );

    _requirementTypeController.text = _text(
      _value(
        _header,
        [
          'sRequirementType',
          'requirementType',
        ],
      ),
    );

    _materialPartSerialController.text = _text(
      _value(
        _header,
        [
          'sMaterialPartSerialNo',
          'materialPartSerialNo',
        ],
      ),
    );

    _actionTypeController.text = _text(
      _value(
        _header,
        [
          'sActionType',
          'actionType',
        ],
      ),
    );

    _frequencyController.text = _text(
      _value(
        _header,
        [
          'sFrequency',
          'frequency',
        ],
      ),
    );

    _prAmountBudgetController.text = _decimalText(
      _value(
        _header,
        [
          'nPRAmountBudget',
          'prAmountBudget',
        ],
      ),
    );

    _subjectController.text = _text(
      _value(
        _header,
        [
          'sSubject',
          'subject',
        ],
      ),
    );

    _purposeController.text = _text(
      _value(
        _header,
        [
          'sPurpose',
          'purpose',
        ],
      ),
    );

    _backgroundController.text = _text(
      _value(
        _header,
        [
          'sBackground',
          'background',
        ],
      ),
    );

    _justificationController.text = _text(
      _value(
        _header,
        [
          'sJustification',
          'justification',
        ],
      ),
    );

    _scopeOfWorkController.text = _text(
      _value(
        _header,
        [
          'sScopeOfWork',
          'scopeOfWork',
        ],
      ),
    );

    _typeOfExpenseController.text = _text(
      _value(
        _header,
        [
          'sTypeOfExpense',
          'typeOfExpense',
        ],
      ),
    );

    _aopCategoryController.text = _text(
      _value(
        _header,
        [
          'sAOPCategory',
          'sAOPCategoryName',
          'aopCategory',
          'aopCategoryName',
        ],
      ),
    );

    _aopSubCategoryController.text = _text(
      _value(
        _header,
        [
          'sAOPSubCategory',
          'sAOPSubCategoryName',
          'aopSubCategory',
          'aopSubCategoryName',
        ],
      ),
    );

    _aopProjectDescriptionController.text = _text(
      _value(
        _header,
        [
          'sAOPProjectDescription',
          'aopProjectDescription',
        ],
      ),
    );
  }

  // ============================================================
  // BIND ITEMS
  // ============================================================

  void _bindItems() {
    for (final controller in _qtyControllers.values) {
      controller.dispose();
    }

    for (final controller in _rateControllers.values) {
      controller.dispose();
    }

    for (final controller in _lineRemarkControllers.values) {
      controller.dispose();
    }

    for (final notifier in _amountNotifiers.values) {
      notifier.dispose();
    }

    _qtyControllers.clear();
    _rateControllers.clear();
    _lineRemarkControllers.clear();
    _amountNotifiers.clear();

    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];

      final qtyController = TextEditingController(
        text: _decimalText(
          _value(
            item,
            [
              'nQty',
              'qty',
            ],
          ),
        ),
      );

      final rateController = TextEditingController(
        text: _decimalText(
          _value(
            item,
            [
              'nRate',
              'rate',
            ],
          ),
        ),
      );

      final lineRemarkController = TextEditingController(
        text: _text(
          _value(
            item,
            [
              'sLineRemark',
              'lineRemarks',
              'lineRemark',
            ],
          ),
        ),
      );

      final notifier = ValueNotifier<double>(
        (double.tryParse(qtyController.text.trim()) ?? 0) *
            (double.tryParse(rateController.text.trim()) ?? 0),
      );

      void refreshAmount() {
        final qty =
            double.tryParse(qtyController.text.trim()) ?? 0;
        final rate =
            double.tryParse(rateController.text.trim()) ?? 0;

        notifier.value = qty * rate;
        _documentTotalNotifier.value = _calculateCurrentTotal();
      }

      qtyController.addListener(refreshAmount);
      rateController.addListener(refreshAmount);

      _qtyControllers[i] = qtyController;
      _rateControllers[i] = rateController;
      _lineRemarkControllers[i] = lineRemarkController;
      _amountNotifiers[i] = notifier;
    }

    _documentTotalNotifier.value = _calculateCurrentTotal();
  }

  // ============================================================
  // DOWNLOAD ATTACHMENT
  // ============================================================

  Future<void> _downloadAttachment() async {
    if (_downloadingAttachment) return;

    setState(() {
      _downloadingAttachment = true;
    });

    try {
      final attachment = await _approvalService.getAttachment(
        widget.approval.approvalTxnId,
      );

      String fileName = _text(
        _value(
          attachment,
          [
            'fileName',
            'FileName',
          ],
        ),
      );

      final contentType = _text(
        _value(
          attachment,
          [
            'contentType',
            'ContentType',
          ],
        ),
      );

      final base64Content = _text(
        _value(
          attachment,
          [
            'base64Content',
            'Base64Content',
          ],
        ),
      );

      if (base64Content.isEmpty) {
        throw Exception(
          'Attachment content is empty.',
        );
      }

      if (fileName.isEmpty) {
        fileName = 'PR_Attachment';
      }

      fileName = _safeFileName(fileName);
      fileName = _ensureAttachmentExtension(
        fileName,
        contentType,
      );

      // Decode outside the UI isolate so large files do not freeze scrolling.
      final bytes = await compute(
        base64Decode,
        base64Content,
      );

      final directory = await _getAttachmentDownloadDirectory();

      if (!await directory.exists()) {
        await directory.create(
          recursive: true,
        );
      }

      final file = File(
        '${directory.path}${Platform.pathSeparator}$fileName',
      );

      await file.writeAsBytes(
        bytes,
        flush: true,
      );

      if (!mounted) return;

      _showMessage(
        'Downloaded: ${file.path}',
        success: true,
      );

      try {
        final openResult = await OpenFilex.open(
          file.path,
        ).timeout(
          const Duration(seconds: 8),
        );

        if (openResult.type != ResultType.done) {
          if (!mounted) return;

          _showMessage(
            'File saved successfully, but no supported app is available to open it.',
          );
        }
      } catch (_) {
        if (!mounted) return;

        _showMessage(
          'File saved successfully. Open it from: ${file.path}',
          success: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloadingAttachment = false;
        });
      }
    }
  }

  Future<Directory> _getAttachmentDownloadDirectory() async {
    try {
      final downloads = await getDownloadsDirectory();

      if (downloads != null) {
        return downloads;
      }
    } catch (_) {
      // Fall back below.
    }

    if (Platform.isAndroid) {
      try {
        final external = await getExternalStorageDirectory();

        if (external != null) {
          return external;
        }
      } catch (_) {
        // Fall back below.
      }
    }

    return getApplicationDocumentsDirectory();
  }

  String _ensureAttachmentExtension(
    String fileName,
    String contentType,
  ) {
    final lastSegment =
        fileName.split(Platform.pathSeparator).last;

    if (lastSegment.contains('.') &&
        !lastSegment.endsWith('.')) {
      return fileName;
    }

    final type = contentType.toLowerCase();

    if (type.contains('pdf')) {
      return '$fileName.pdf';
    }

    if (type.contains('jpeg') ||
        type.contains('jpg')) {
      return '$fileName.jpg';
    }

    if (type.contains('png')) {
      return '$fileName.png';
    }

    if (type.contains('spreadsheetml')) {
      return '$fileName.xlsx';
    }

    if (type.contains('ms-excel')) {
      return '$fileName.xls';
    }

    if (type.contains('wordprocessingml')) {
      return '$fileName.docx';
    }

    if (type.contains('msword')) {
      return '$fileName.doc';
    }

    return fileName;
  }

  String _safeFileName(
    String value,
  ) {
    return value
        .replaceAll(
          RegExp(
            r'[<>:"/\\|?*]',
          ),
          '_',
        )
        .trim();
  }

  // ============================================================
  // SAVE CHANGES
  // ============================================================

  Future<void> _saveChanges() async {
    if (_saving || _processingAction) return;

    if (_selectedRequirementTypeId == null) {
      _showMessage(
        'Type of Requirement is required.',
      );
      return;
    }

    if (_selectedActionTypeId == null) {
      _showMessage(
        'Type of Action is required.',
      );
      return;
    }

    if (_selectedFrequencyId == null) {
      _showMessage(
        'Frequency is required.',
      );
      return;
    }

    if (_selectedPriorityId == null) {
      _showMessage(
        'Priority is required.',
      );
      return;
    }

    if (_selectedCriticalityId == null) {
      _showMessage(
        'Criticality is required.',
      );
      return;
    }

    if (_subjectController.text.trim().isEmpty) {
      _showMessage(
        'Subject is required.',
      );
      return;
    }

    final aopRequired =
        widget.approval.approvalLevel == 1 ||
            widget.approval.approvalLevel == 2;

    if (aopRequired) {
      if (_selectedExpenseTypeId == null) {
        _showMessage(
          'Type of Expense is required.',
        );
        return;
      }

      if (_selectedAopCategoryId == null) {
        _showMessage(
          'AOP Category is required.',
        );
        return;
      }

      if (_selectedAopSubCategoryId == null) {
        _showMessage(
          'AOP Subcategory is required.',
        );
        return;
      }

      if (_selectedAopDescriptionId == null) {
        _showMessage(
          'AOP Project Description is required.',
        );
        return;
      }
    }

    if (!_validateItems()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final itemPayload = <Map<String, dynamic>>[];

      for (int i = 0; i < _items.length; i++) {
        final item = _items[i];

        final qty = double.tryParse(
              _qtyControllers[i]?.text.trim() ?? '',
            ) ??
            0;

        final rate = double.tryParse(
              _rateControllers[i]?.text.trim() ?? '',
            ) ??
            0;

        final amount = qty * rate;

        itemPayload.add({
          'prsrDetailId': _int(
            _value(
              item,
              [
                'iPRSRDetailId',
                'prsrDetailId',
              ],
            ),
          ),

          'itemId': _int(
            _value(
              item,
              [
                'iItemId',
                'itemId',
              ],
            ),
          ),

          'itemCode': _text(
            _value(
              item,
              [
                'sItemCode',
                'itemCode',
              ],
            ),
          ),

          'itemName': _text(
            _value(
              item,
              [
                'sItemName',
                'itemName',
              ],
            ),
          ),

          'description': _text(
            _value(
              item,
              [
                'sDescription',
                'description',
              ],
            ),
          ),

          'uom': _text(
            _value(
              item,
              [
                'sUOM',
                'uom',
              ],
            ),
          ),

          'qty': qty,
          'rate': rate,
          'amount': amount,

          'budgetAmount': _decimal(
            _value(
              item,
              [
                'nBudgetAmount',
                'budgetAmount',
              ],
            ),
          ),

          'consumedBudget': _decimal(
            _value(
              item,
              [
                'nConsumedBudget',
                'consumedBudget',
              ],
            ),
          ),

          'pendingBudget': _decimal(
            _value(
              item,
              [
                'nPendingBudget',
                'pendingBudget',
              ],
            ),
          ),

          'actualUser': _text(
            _value(
              item,
              [
                'sActualUser',
                'actualUser',
              ],
            ),
          ),

          'requiredDate': _apiDate(
            _value(
              item,
              [
                'dLineRequiredDate',
                'requiredDate',
              ],
            ),
          ),

          'preferredSupplier': _text(
            _value(
              item,
              [
                'sPreferredSupplier',
                'preferredSupplier',
              ],
            ),
          ),

          'lastIndentRate': _decimal(
            _value(
              item,
              [
                'nLastIndentRate',
                'lastIndentRate',
              ],
            ),
          ),

          'lastSupplier': _text(
            _value(
              item,
              [
                'sLastSupplier',
                'lastSupplier',
              ],
            ),
          ),

          'lastPRNo': _text(
            _value(
              item,
              [
                'sLastPRNo',
                'lastPRNo',
              ],
            ),
          ),

          'lastPurchaseDate': _apiDate(
            _value(
              item,
              [
                'dLastPurchaseDate',
                'lastPurchaseDate',
              ],
            ),
          ),

          'lastQty': _decimal(
            _value(
              item,
              [
                'nLastQty',
                'lastQty',
              ],
            ),
          ),

          'brandName': _text(
            _value(
              item,
              [
                'sBrandName',
                'brandName',
              ],
            ),
          ),

          'modelNo': _text(
            _value(
              item,
              [
                'sModelNo',
                'modelNo',
              ],
            ),
          ),

          'specification': _text(
            _value(
              item,
              [
                'sSpecification',
                'specification',
              ],
            ),
          ),

          'lineRemarks':
              _lineRemarkControllers[i]?.text.trim() ?? '',
        });
      }

      final request = <String, dynamic>{
        'approvalTxnId':
            widget.approval.approvalTxnId,

        'requiredDate': _controllerApiDate(
          _requiredDateController.text,
        ),

        'budgetType': _dbMasterSaveValue(
          _budgetTypes,
          _selectedBudgetTypeId,
          _value(_header, ['sBudgetType', 'budgetType']),
        ),

        'priority': _dbMasterSaveValue(
          _priorities,
          _selectedPriorityId,
          _value(_header, ['sPriority', 'priority']),
        ),

        'criticality': _dbMasterSaveValue(
          _criticalities,
          _selectedCriticalityId,
          _value(_header, ['sCriticality', 'criticality']),
        ),

        'parentItemCategoryId':
            _selectedParentItemCategoryId,

        'requirementType': _dbMasterSaveValue(
          _requirementTypes,
          _selectedRequirementTypeId,
          _value(_header, ['sRequirementType', 'requirementType']),
        ),

        'materialPartSerialNo':
            _materialPartSerialController.text.trim(),

        'budgetId': _nullablePositiveInt(
          _value(
            _header,
            [
              'iBudgetId',
              'budgetId',
            ],
          ),
        ),

        'actionType': _dbMasterSaveValue(
          _actionTypes,
          _selectedActionTypeId,
          _value(_header, ['sActionType', 'actionType']),
        ),

        'typeOfExpense': _dbMasterSaveValue(
          _expenseTypes,
          _selectedExpenseTypeId,
          _value(_header, ['sTypeOfExpense', 'typeOfExpense']),
        ),

        'expenseTypeId':
            _selectedExpenseTypeId,

        'frequency': _dbMasterSaveValue(
          _frequencies,
          _selectedFrequencyId,
          _value(_header, ['sFrequency', 'frequency']),
        ),

        'prAmountBudget': double.tryParse(
              _prAmountBudgetController.text.trim(),
            ) ??
            0,

        'aopCategoryId':
            _selectedAopCategoryId,

        'aopSubCategoryId':
            _selectedAopSubCategoryId,

        'aopProjectDescriptionId':
            _selectedAopDescriptionId,

        'aopProjectDescription': _nameById(
          _aopDescriptions,
          _selectedAopDescriptionId,
          fallback:
              _aopProjectDescriptionController.text.trim(),
        ),

        'subject':
            _subjectController.text.trim(),

        'purpose':
            _purposeController.text.trim(),

        'background':
            _backgroundController.text.trim(),

        'justification':
            _justificationController.text.trim(),

        'scopeOfWork':
            _scopeOfWorkController.text.trim(),

        'attachmentFileName': _text(
          _value(
            _header,
            [
              'sAttachmentFileName',
              'attachmentFileName',
            ],
          ),
        ),

        'attachmentFilePath': _text(
          _value(
            _header,
            [
              'sAttachmentFilePath',
              'attachmentFilePath',
            ],
          ),
        ),

        'remarks':
            _approvalRemarkController.text.trim(),

        'items': itemPayload,
      };

      final response =
          await _approvalService.savePRChanges(
        request,
      );

      final success = _bool(
        _value(
          response,
          [
            'success',
            'bSuccess',
          ],
        ),
      );

      final message = _text(
        _value(
          response,
          [
            'message',
            'sMessage',
          ],
        ),
      );

      if (!mounted) return;

      if (success) {
        _showMessage(
          message.isEmpty
              ? 'Changes saved successfully.'
              : message,
          success: true,
        );

        await _loadPage(
          showLoader: false,
          preserveScroll: true,
        );
      } else {
        _showMessage(
          message.isEmpty
              ? 'Unable to save changes.'
              : message,
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ============================================================
  // VALIDATION
  // ============================================================


  // ============================================================
  // AOP VALIDATION BEFORE APPROVAL
  // Mandatory for PR Approval Level 1 and Level 2.
  //
  // NOTE:
  // This Flutter validation improves the user experience.
  // The API must ALSO validate the same rule before executing
  // the workflow approval, so approval cannot be bypassed by
  // calling the API directly.
  // ============================================================

  bool _validateAopBeforeApproval() {
    final level = widget.approval.approvalLevel;

    // AOP is mandatory only at Approval Level 1 and Level 2.
    if (level != 1 && level != 2) {
      return true;
    }

    final missing = <String>[];

    // Type of Expense
    if (_selectedExpenseTypeId == null ||
        _selectedExpenseTypeId! <= 0 ||
        _typeOfExpenseController.text.trim().isEmpty) {
      missing.add('Type of Expense');
    }

    // AOP Category
    if (_selectedAopCategoryId == null ||
        _selectedAopCategoryId! <= 0) {
      missing.add('AOP Category');
    }

    // AOP Subcategory
    if (_selectedAopSubCategoryId == null ||
        _selectedAopSubCategoryId! <= 0) {
      missing.add('AOP Subcategory');
    }

    // AOP Project Description
    if ((_selectedAopDescriptionId == null ||
            _selectedAopDescriptionId! <= 0) &&
        _aopProjectDescriptionController.text.trim().isEmpty) {
      missing.add('AOP Project Description');
    }

    if (missing.isEmpty) {
      return true;
    }

    _showMessage(
      'Please complete all mandatory AOP fields before approval.\n\n'
      'Missing: ${missing.join(', ')}',
    );

    return false;
  }

  bool _validateItems() {
    if (_items.isEmpty) {
      _showMessage(
        'At least one Item / Service is required.',
      );

      return false;
    }

    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];

      final itemName = _text(
        _value(
          item,
          [
            'sItemName',
            'itemName',
          ],
        ),
      );

      final qty = double.tryParse(
            _qtyControllers[i]?.text.trim() ?? '',
          ) ??
          0;

      final rate = double.tryParse(
            _rateControllers[i]?.text.trim() ?? '',
          ) ??
          0;

      if (qty <= 0) {
        _showMessage(
          'Qty must be greater than zero for ${itemName.isEmpty ? 'Item ${i + 1}' : itemName}.',
        );

        return false;
      }

      if (rate <= 0) {
        _showMessage(
          'Rate must be greater than zero for ${itemName.isEmpty ? 'Item ${i + 1}' : itemName}.',
        );

        return false;
      }

      final detailId = _int(
        _value(
          item,
          [
            'iPRSRDetailId',
            'prsrDetailId',
          ],
        ),
      );

      if (detailId <= 0) {
        _showMessage(
          'Invalid PR detail reference for ${itemName.isEmpty ? 'Item ${i + 1}' : itemName}.',
        );

        return false;
      }

      final itemId = _int(
        _value(
          item,
          [
            'iItemId',
            'itemId',
          ],
        ),
      );

      if (itemId <= 0) {
        _showMessage(
          'Invalid Item / Service reference for ${itemName.isEmpty ? 'Item ${i + 1}' : itemName}.',
        );

        return false;
      }
    }

    return true;
  }

  // ============================================================
  // APPROVE
  // ============================================================

  Future<void> _approve() async {
    if (_saving || _processingAction) return;

    // Block Level 1 / Level 2 PR approval until mandatory
    // Expense / AOP fields have been completed.
    if (!_validateAopBeforeApproval()) {
      return;
    }

    final confirmed = await _confirmDialog(
      title: 'Approve Purchase Request',
      message:
          'Are you sure you want to approve this Purchase Request?',
      confirmText: 'Approve',
      confirmColor: const Color(0xFF1B8F4B),
    );

    if (!confirmed) return;

    setState(() {
      _processingAction = true;
    });

    try {
      final response =
          await _approvalService.approve(
        approvalTxnId: widget.approval.approvalTxnId,
        remark: _approvalRemarkController.text.trim(),
      );

      final success = _bool(
        _value(
          response,
          [
            'success',
            'bSuccess',
          ],
        ),
      );

      final message = _text(
        _value(
          response,
          [
            'message',
            'sMessage',
          ],
        ),
      );

      if (!mounted) return;

      if (success) {
        _showMessage(
          message.isEmpty
              ? 'Purchase Request approved successfully.'
              : message,
          success: true,
        );

        Navigator.of(context).pop(true);
      } else {
        _showMessage(
          message.isEmpty
              ? 'Unable to approve Purchase Request.'
              : message,
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
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
    if (_saving || _processingAction) return;

    final remark =
        _approvalRemarkController.text.trim();

    if (remark.isEmpty) {
      _showMessage(
        'Approval remark is required for rejection.',
      );

      return;
    }

    final confirmed = await _confirmDialog(
      title: 'Reject Purchase Request',
      message:
          'Are you sure you want to reject this Purchase Request?',
      confirmText: 'Reject',
      confirmColor: Colors.red,
    );

    if (!confirmed) return;

    setState(() {
      _processingAction = true;
    });

    try {
      final response =
          await _approvalService.reject(
        approvalTxnId: widget.approval.approvalTxnId,
        remark: remark,
      );

      final success = _bool(
        _value(
          response,
          [
            'success',
            'bSuccess',
          ],
        ),
      );

      final message = _text(
        _value(
          response,
          [
            'message',
            'sMessage',
          ],
        ),
      );

      if (!mounted) return;

      if (success) {
        _showMessage(
          message.isEmpty
              ? 'Purchase Request rejected successfully.'
              : message,
          success: true,
        );

        Navigator.of(context).pop(true);
      } else {
        _showMessage(
          message.isEmpty
              ? 'Unable to reject Purchase Request.'
              : message,
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingAction = false;
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
      backgroundColor: pageBackground,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: navyBlue,
        titleSpacing: 4,

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Purchase Request Approval',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),

            Text(
              widget.approval.sourceNo,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadPage,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),

      body: _buildBody(),

      bottomNavigationBar: !_loading &&
              _errorMessage == null &&
              widget.approval.isCurrentLevel
          ? _buildBottomActionBar()
          : null,
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: primaryBlue,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 52,
                color: Colors.redAccent,
              ),

              const SizedBox(height: 14),

              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: navyBlue,
                ),
              ),

              const SizedBox(height: 18),

              ElevatedButton.icon(
                onPressed: _loadPage,
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text(
                  'Retry',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPage,
      color: primaryBlue,

      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          12,
          12,
          12,
          140,
        ),

        children: [
          _buildApprovalHeaderCard(),

          const SizedBox(height: 12),

          _section(
            title: 'Request Details',
            icon: Icons.description_outlined,
            child: _buildRequestSummary(),
          ),

          const SizedBox(height: 12),

          _section(
            title: 'Business Justification',
            icon: Icons.business_center_outlined,
            child: _buildBusinessJustification(),
          ),

          const SizedBox(height: 12),

          _section(
            title: 'Item / Service Details',
            icon: Icons.inventory_2_outlined,
            child: _buildItems(),
          ),

          const SizedBox(height: 12),

          _section(
            title: 'Expense / AOP',
            icon: Icons.account_tree_outlined,
            child: _buildAopSection(),
          ),

          const SizedBox(height: 12),

          _section(
            title: 'Approval Workflow & History',
            icon: Icons.timeline_rounded,
            child: _buildApprovalHistory(),
          ),

          const SizedBox(height: 12),

          _section(
            title: 'Approval Remarks',
            icon: Icons.comment_outlined,
            child: TextField(
              controller: _approvalRemarkController,
              minLines: 2,
              maxLines: 5,
              decoration: _inputDecoration(
                'Enter approval remarks',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER CARD
  // ============================================================

  Widget _buildApprovalHeaderCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            navyBlue,
            Color(0xFF245B8A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),

      padding: const EdgeInsets.all(16),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.approval.sourceNo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      widget.approval.requestType,
                      style: TextStyle(
                        color: Colors.white.withValues(
                          alpha: 0.82,
                        ),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              _statusChip(
                widget.approval.approvalStatus,
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _headerInfo(
                  'Approval Level',
                  'Level ${widget.approval.approvalLevel}',
                ),
              ),

              Expanded(
                child: _headerInfo(
                  'Role',
                  widget.approval.roleName,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REQUEST SUMMARY
  // ============================================================

  Widget _buildRequestSummary() {
    return Column(
      children: [
        _editableField(
          label: 'Required Date *',
          controller: _requiredDateController,
          readOnly: true,
          suffixIcon: Icons.calendar_month_outlined,
          onTap: _selectRequiredDate,
        ),

        _masterDropdownField(
          label: 'Type of Requirement',
          options: _requirementTypes,
          selectedId: _selectedRequirementTypeId,
          required: true,
          onChanged: (value) {
            setState(() {
              _selectedRequirementTypeId = value;
              _requirementTypeController.text = _nameById(
                _requirementTypes,
                value,
              );
            });
          },
        ),

        _masterDropdownField(
          label: 'Type of Action',
          options: _actionTypes,
          selectedId: _selectedActionTypeId,
          required: true,
          onChanged: (value) {
            setState(() {
              _selectedActionTypeId = value;
              _actionTypeController.text = _nameById(
                _actionTypes,
                value,
              );
            });
          },
        ),

        _masterDropdownField(
          label: 'Frequency',
          options: _frequencies,
          selectedId: _selectedFrequencyId,
          required: true,
          onChanged: (value) {
            setState(() {
              _selectedFrequencyId = value;
              _frequencyController.text = _nameById(
                _frequencies,
                value,
              );
            });
          },
        ),

        _masterDropdownField(
          label: 'Priority',
          options: _priorities,
          selectedId: _selectedPriorityId,
          required: true,
          onChanged: (value) {
            setState(() {
              _selectedPriorityId = value;
              _priorityController.text = _nameById(
                _priorities,
                value,
              );
            });
          },
        ),

        _masterDropdownField(
          label: 'Criticality',
          options: _criticalities,
          selectedId: _selectedCriticalityId,
          required: true,
          onChanged: (value) {
            setState(() {
              _selectedCriticalityId = value;
              _criticalityController.text = _nameById(
                _criticalities,
                value,
              );
            });
          },
        ),

        _masterDropdownField(
          label: 'Budget Type',
          options: _budgetTypes,
          selectedId: _selectedBudgetTypeId,
          onChanged: (value) {
            setState(() {
              _selectedBudgetTypeId = value;
              _budgetTypeController.text = _nameById(
                _budgetTypes,
                value,
              );
            });
          },
        ),

        _masterDropdownField(
          label: 'Parent Item Category',
          options: _parentItemCategories,
          selectedId: _selectedParentItemCategoryId,
          onChanged: (value) {
            setState(() {
              _selectedParentItemCategoryId = value;
            });
          },
        ),

        _editableField(
          label: 'Material Part Code / Serial No.',
          controller: _materialPartSerialController,
        ),

        _editableField(
          label: 'PR Budget Amount',
          controller: _prAmountBudgetController,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
        ),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F9FC),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: const Color(0xFFDCE7EE),
            ),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'PR Amount',
                  style: TextStyle(
                    fontSize: 13,
                    color: navyBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ValueListenableBuilder<double>(
                valueListenable: _documentTotalNotifier,
                builder: (
                  context,
                  total,
                  _,
                ) {
                  return Text(
                    _money(total),
                    style: const TextStyle(
                      fontSize: 16,
                      color: navyBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BUSINESS JUSTIFICATION
  // ============================================================

  Widget _buildBusinessJustification() {
    final attachmentName = _text(
      _value(
        _header,
        [
          'sAttachmentFileName',
          'attachmentFileName',
        ],
      ),
    );

    final attachmentPath = _text(
      _value(
        _header,
        [
          'sAttachmentFilePath',
          'attachmentFilePath',
        ],
      ),
    );

    final hasAttachment =
        attachmentName.isNotEmpty ||
            attachmentPath.isNotEmpty;

    return Column(
      children: [
        _editableField(
          label: 'Subject *',
          controller: _subjectController,
          maxLines: 3,
        ),

        _editableField(
          label: 'Purpose',
          controller: _purposeController,
          maxLines: 4,
        ),

        _editableField(
          label: 'Background *',
          controller: _backgroundController,
          maxLines: 5,
        ),

        _editableField(
          label: 'Justification *',
          controller: _justificationController,
          maxLines: 5,
        ),

        _editableField(
          label: 'Scope of Work',
          controller: _scopeOfWorkController,
          maxLines: 5,
        ),

        if (hasAttachment)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color: const Color(0xFFF6FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFDCE7EE),
              ),
            ),

            child: Row(
              children: [
                const Icon(
                  Icons.attach_file_rounded,
                  color: primaryBlueDark,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    attachmentName.isEmpty
                        ? 'PR Attachment'
                        : attachmentName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: navyBlue,
                    ),
                  ),
                ),

                TextButton.icon(
                  onPressed:
                      _downloadingAttachment
                          ? null
                          : _downloadAttachment,

                  icon: _downloadingAttachment
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.download_rounded,
                        ),

                  label: Text(
                    _downloadingAttachment
                        ? 'Downloading'
                        : 'Download',
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ============================================================
  // ITEMS
  // ============================================================

  Widget _buildItems() {
    if (_items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(10),
        child: Text(
          'No Item / Service details found.',
        ),
      );
    }

    return Column(
      children: List.generate(
        _items.length,
        (index) => _buildItemCard(
          index,
          _items[index],
        ),
      ),
    );
  }

  Widget _buildItemCard(
    int index,
    Map<String, dynamic> item,
  ) {
    final itemName = _text(
      _value(
        item,
        [
          'sItemName',
          'itemName',
        ],
      ),
    );

    final itemCode = _text(
      _value(
        item,
        [
          'sItemCode',
          'itemCode',
        ],
      ),
    );

    final description = _text(
      _value(
        item,
        [
          'sDescription',
          'description',
        ],
      ),
    );

    final uom = _text(
      _value(
        item,
        [
          'sUOM',
          'uom',
        ],
      ),
    );

    final preferredSupplier = _text(
      _value(
        item,
        [
          'sPreferredSupplier',
          'preferredSupplier',
        ],
      ),
    );

    final requiredDate = _displayDate(
      _value(
        item,
        [
          'dLineRequiredDate',
          'requiredDate',
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),

        border: Border.all(
          color: const Color(0xFFDCE7EE),
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),

            decoration: const BoxDecoration(
              color: Color(0xFFF3F8FB),

              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemName.isEmpty
                      ? 'Item / Service ${index + 1}'
                      : itemName,

                  style: const TextStyle(
                    color: navyBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                if (itemCode.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      itemCode,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ),

                if (description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
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
                Row(
                  children: [
                    Expanded(
                      child: _compactEditable(
                        label: 'Qty *',
                        controller: _qtyControllers[index]!,
                        onChanged: (_) {},
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: _compactEditable(
                        label: 'Unit Rate *',
                        controller: _rateControllers[index]!,
                        onChanged: (_) {},
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _smallInfo(
                        'UOM',
                        uom,
                      ),
                    ),

                    Expanded(
                      child: ValueListenableBuilder<double>(
                        valueListenable:
                            _amountNotifiers[index]!,
                        builder: (
                          context,
                          currentAmount,
                          _,
                        ) {
                          return _smallInfo(
                            'Amount',
                            _money(currentAmount),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const Divider(height: 26),

                _readOnlyRow(
                  'Preferred Supplier',
                  preferredSupplier,
                ),

                _readOnlyRow(
                  'Required Date',
                  requiredDate,
                ),

                const SizedBox(height: 8),

                _editableField(
                  label: 'Line Remarks',
                  controller:
                      _lineRemarkControllers[index]!,
                  maxLines: 3,
                ),

                _buildLastPurchaseInfo(
                  item,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LAST PURCHASE
  // ============================================================

  Widget _buildLastPurchaseInfo(
    Map<String, dynamic> item,
  ) {
    final supplier = _text(
      _value(
        item,
        [
          'sLastSupplier',
          'lastSupplier',
        ],
      ),
    );

    final rate = _decimal(
      _value(
        item,
        [
          'nLastIndentRate',
          'lastIndentRate',
        ],
      ),
    );

    final lastNo = _text(
      _value(
        item,
        [
          'sLastPRNo',
          'lastPRNo',
        ],
      ),
    );

    final lastQty = _decimal(
      _value(
        item,
        [
          'nLastQty',
          'lastQty',
        ],
      ),
    );

    final lastPurchaseDate = _displayDate(
      _value(
        item,
        [
          'dLastPurchaseDate',
          'lastPurchaseDate',
        ],
      ),
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(10),

      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(8),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Last Purchase Details',
            style: TextStyle(
              fontSize: 12,
              color: navyBlue,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          _readOnlyRow(
            'Supplier',
            supplier,
          ),

          _readOnlyRow(
            'Rate',
            _money(rate),
          ),

          _readOnlyRow(
            'PR / PO No.',
            lastNo,
          ),

          _readOnlyRow(
            'Purchase Date',
            lastPurchaseDate,
          ),

          _readOnlyRow(
            'Qty',
            _decimalText(lastQty),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AOP
  // ============================================================

  Widget _buildAopSection() {
    final required =
        widget.approval.approvalLevel == 1 ||
            widget.approval.approvalLevel == 2;

    final filteredSubCategories =
        _selectedAopCategoryId == null
            ? _aopSubCategories
            : _aopSubCategories
                .where(
                  (x) =>
                      x.parentId == 0 ||
                      x.parentId == _selectedAopCategoryId,
                )
                .toList();

    final filteredDescriptions =
        _selectedAopSubCategoryId == null
            ? _aopDescriptions
            : _aopDescriptions
                .where(
                  (x) =>
                      x.parentId == 0 ||
                      x.parentId == _selectedAopSubCategoryId,
                )
                .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _masterDropdownField(
          label: 'Type of Expense',
          options: _expenseTypes,
          selectedId: _selectedExpenseTypeId,
          required: required,
          onChanged: (value) {
            setState(() {
              _selectedExpenseTypeId = value;
              _typeOfExpenseController.text = _nameById(
                _expenseTypes,
                value,
              );
            });
          },
        ),

        _masterDropdownField(
          label: 'AOP Category',
          options: _aopCategories,
          selectedId: _selectedAopCategoryId,
          required: required,
          onChanged: (value) {
            setState(() {
              _selectedAopCategoryId = value;
              _selectedAopSubCategoryId = null;
              _selectedAopDescriptionId = null;

              _aopCategoryController.text = _nameById(
                _aopCategories,
                value,
              );
              _aopSubCategoryController.clear();
              _aopProjectDescriptionController.clear();
            });
          },
        ),

        _masterDropdownField(
          label: 'AOP Subcategory',
          options: filteredSubCategories,
          selectedId: _selectedAopSubCategoryId,
          required: required,
          onChanged: (value) {
            setState(() {
              _selectedAopSubCategoryId = value;
              _selectedAopDescriptionId = null;

              _aopSubCategoryController.text = _nameById(
                filteredSubCategories,
                value,
              );
              _aopProjectDescriptionController.clear();
            });
          },
        ),

        _masterDropdownField(
          label: 'AOP Project Description',
          options: filteredDescriptions,
          selectedId: _selectedAopDescriptionId,
          required: required,
          onChanged: (value) {
            setState(() {
              _selectedAopDescriptionId = value;
              _aopProjectDescriptionController.text = _nameById(
                filteredDescriptions,
                value,
              );
            });
          },
        ),

        if (required)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Color(0xFFA56A00),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Type of Expense, AOP Category, AOP Subcategory and AOP Project Description are mandatory at Approval Level 1 and Level 2.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Color(0xFF775300),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ============================================================
  // APPROVAL HISTORY
  // ============================================================

  Widget _buildApprovalHistory() {
    if (_approvalHistory.isEmpty) {
      return const Text(
        'No approval history found.',
      );
    }

    return Column(
      children: _approvalHistory.map(
        (history) {
          final level = _text(
            _value(
              history,
              [
                'iApprovalLevel',
                'approvalLevel',
              ],
            ),
          );

          final role = _text(
            _value(
              history,
              [
                'sRoleName',
                'roleName',
              ],
            ),
          );

          final approver = _text(
            _value(
              history,
              [
                'sApproverName',
                'approverName',
              ],
            ),
          );

          final status = _text(
            _value(
              history,
              [
                'sApprovalStatus',
                'approvalStatus',
              ],
            ),
          );

          final remark = _text(
            _value(
              history,
              [
                'sRemark',
                'sApprovalRemark',
                'remark',
                'approvalRemark',
              ],
            ),
          );

          final date = _displayDateTime(
            _value(
              history,
              [
                'dActionDate',
                'actionDate',
                'dAssignedDate',
                'assignedDate',
              ],
            ),
          );

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFB),
              borderRadius: BorderRadius.circular(10),

              border: Border.all(
                color: const Color(0xFFE3EBF0),
              ),
            ),

            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,

                  decoration: BoxDecoration(
                    color: primaryBlue.withValues(
                      alpha: 0.10,
                    ),
                    shape: BoxShape.circle,
                  ),

                  child: Text(
                    level.isEmpty ? '-' : level,

                    style: const TextStyle(
                      color: primaryBlueDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.isEmpty ? 'Approval' : role,

                        style: const TextStyle(
                          color: navyBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),

                      if (approver.isNotEmpty) ...[
                        const SizedBox(height: 3),

                        Text(
                          approver,
                          style: const TextStyle(
                            fontSize: 13,
                          ),
                        ),
                      ],

                      const SizedBox(height: 6),

                      Wrap(
                        crossAxisAlignment:
                            WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _miniStatusChip(
                            status,
                          ),

                          if (date.isNotEmpty)
                            Text(
                              date,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),

                      if (remark.isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 7),

                          child: Text(
                            remark,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ).toList(),
    );
  }

  // ============================================================
  // BOTTOM ACTION BAR
  // ============================================================

  Widget _buildBottomActionBar() {
    final busy =
        _saving || _processingAction;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          12,
          10,
          12,
          10,
        ),

        decoration: BoxDecoration(
          color: Colors.white,

          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.08,
              ),
              blurRadius: 14,
              offset: const Offset(
                0,
                -4,
              ),
            ),
          ],
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed: busy ? null : _saveChanges,

                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(
                    0,
                    46,
                  ),

                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),

                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,

                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.save_outlined,
                      ),

                label: Text(
                  _saving
                      ? 'Saving Changes...'
                      : 'Save Changes',
                ),
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : _reject,

                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          Colors.red.shade700,

                      side: BorderSide(
                        color:
                            Colors.red.shade300,
                      ),

                      minimumSize:
                          const Size(
                        0,
                        46,
                      ),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                      ),
                    ),

                    icon: const Icon(
                      Icons.close_rounded,
                    ),

                    label: const Text(
                      'Reject',
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: busy ? null : _approve,

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                        0xFF1B8F4B,
                      ),

                      foregroundColor:
                          Colors.white,

                      minimumSize:
                          const Size(
                        0,
                        46,
                      ),

                      elevation: 0,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                      ),
                    ),

                    icon: const Icon(
                      Icons.check_rounded,
                    ),

                    label: const Text(
                      'Approve',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION
  // ============================================================

  Widget _section({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(14),

        border: Border.all(
          color: const Color(0xFFE1E9EE),
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(13),

            decoration: const BoxDecoration(
              color: Color(0xFFF7FAFC),

              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),

            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: primaryBlueDark,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    title,

                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: navyBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(13),
            child: child,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MASTER DROPDOWN FIELD
  // ============================================================

  Widget _masterDropdownField({
    required String label,
    required List<MasterOption> options,
    required int? selectedId,
    required ValueChanged<int?> onChanged,
    bool required = false,
  }) {
    int? validValue;

    if (selectedId != null &&
        options.any((x) => x.id == selectedId)) {
      validValue = selectedId;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: DropdownButtonFormField<int>(
        key: ValueKey(
          '$label|$validValue|${options.length}',
        ),
        initialValue: validValue,
        isExpanded: true,
        decoration: _inputDecoration(
          required ? '$label *' : label,
        ),
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: primaryBlueDark,
        ),
        items: options.map(
          (option) {
            return DropdownMenuItem<int>(
              value: option.id,
              child: Text(
                option.name,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        ).toList(),
        onChanged: options.isEmpty ? null : onChanged,
      ),
    );
  }

  // ============================================================
  // INPUTS
  // ============================================================

  Widget _editableField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    bool readOnly = false,
    IconData? suffixIcon,
    VoidCallback? onTap,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),

      child: TextField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        onTap: onTap,
        keyboardType: keyboardType,

        decoration: _inputDecoration(
          label,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _compactEditable({
    required String label,
    required TextEditingController controller,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,

      keyboardType:
          const TextInputType.numberWithOptions(
        decimal: true,
      ),

      onChanged: onChanged,

      decoration: _inputDecoration(
        label,
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label, {
    IconData? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,

      labelStyle: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade700,
      ),

      suffixIcon: suffixIcon == null
          ? null
          : Icon(
              suffixIcon,
              size: 19,
            ),

      filled: true,
      fillColor: Colors.white,

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(9),

        borderSide: const BorderSide(
          color: Color(0xFFD8E2E8),
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(9),

        borderSide: const BorderSide(
          color: primaryBlue,
          width: 1.4,
        ),
      ),

      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(9),
      ),
    );
  }

  // ============================================================
  // SMALL UI HELPERS
  // ============================================================

  Widget _readOnlyRow(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 4,
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,

              style: TextStyle(
                fontSize: 12,
                color:
                    Colors.grey.shade600,
              ),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              value.isEmpty
                  ? '-'
                  : value,

              textAlign:
                  TextAlign.right,

              style: const TextStyle(
                fontSize: 12,
                color: navyBlue,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallInfo(
    String label,
    String value,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color:
                Colors.grey.shade600,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          value.isEmpty ? '-' : value,

          style: const TextStyle(
            fontSize: 13,
            color: navyBlue,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _headerInfo(
    String label,
    String value,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,

          style: TextStyle(
            color:
                Colors.white.withValues(
              alpha: 0.65,
            ),
            fontSize: 11,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          value.isEmpty ? '-' : value,

          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _statusChip(
    String status,
  ) {
    final normalized =
        status.trim().toUpperCase();

    Color color;

    if (normalized == 'APPROVED' ||
        normalized == 'APPROVE') {
      color = Colors.green;
    } else if (normalized == 'PENDING' ||
        normalized == 'WAITING') {
      color = Colors.orange;
    } else if (normalized == 'REJECTED' ||
        normalized == 'REJECT') {
      color = Colors.red;
    } else {
      color = Colors.blueGrey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.20,
        ),

        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color: color.withValues(
            alpha: 0.50,
          ),
        ),
      ),

      child: Text(
        status.isEmpty ? '-' : status,

        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }

  Widget _miniStatusChip(
    String status,
  ) {
    final normalized =
        status.trim().toUpperCase();

    Color color;

    if (normalized == 'APPROVED' ||
        normalized == 'APPROVE') {
      color = Colors.green;
    } else if (normalized == 'REJECTED' ||
        normalized == 'REJECT') {
      color = Colors.red;
    } else if (normalized == 'PENDING' ||
        normalized == 'WAITING') {
      color = Colors.orange;
    } else {
      color = Colors.blueGrey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 3,
      ),

      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.10,
        ),

        borderRadius:
            BorderRadius.circular(12),
      ),

      child: Text(
        status.isEmpty ? '-' : status,

        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _selectRequiredDate() async {
    DateTime initialDate =
        DateTime.now();

    final existing =
        _parseDisplayDate(
      _requiredDateController.text,
    );

    if (existing != null) {
      initialDate = existing;
    }

    final picked =
        await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      _requiredDateController.text =
          _formatDate(
        picked,
      );
    });
  }

  // ============================================================
  // CONFIRM DIALOG
  // ============================================================

  Future<bool> _confirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) async {
    final result =
        await showDialog<bool>(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            title,
          ),

          content: Text(
            message,
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },

              child: const Text(
                'Cancel',
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    confirmColor,
                foregroundColor:
                    Colors.white,
              ),

              child: Text(
                confirmText,
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool success = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),

        backgroundColor: success
            ? const Color(0xFF1B8F4B)
            : Colors.red.shade700,
      ),
    );
  }

  // ============================================================
  // TOTAL
  // ============================================================

  double _calculateCurrentTotal() {
    double total = 0;

    for (int i = 0;
        i < _items.length;
        i++) {
      final qty = double.tryParse(
            _qtyControllers[i]
                    ?.text
                    .trim() ??
                '',
          ) ??
          0;

      final rate = double.tryParse(
            _rateControllers[i]
                    ?.text
                    .trim() ??
                '',
          ) ??
          0;

      total += qty * rate;
    }

    return total;
  }

  // ============================================================
  // MASTER OPTION HELPERS
  // ============================================================

  int? _dbSelectedId(
    List<MasterOption> options, {
    required int commonId,
    required String rawValue,
  }) {
    if (commonId > 0 &&
        options.any((x) => x.id == commonId)) {
      return commonId;
    }

    final raw = rawValue.trim();

    if (raw.isEmpty) {
      return null;
    }

    final numericId = int.tryParse(raw);

    if (numericId != null &&
        options.any((x) => x.id == numericId)) {
      return numericId;
    }

    for (final option in options) {
      if (option.code.trim().toLowerCase() ==
          raw.toLowerCase()) {
        return option.id;
      }

      if (option.name.trim().toLowerCase() ==
          raw.toLowerCase()) {
        return option.id;
      }
    }

    return null;
  }

  String _nameById(
    List<MasterOption> options,
    int? id, {
    String fallback = '',
  }) {
    if (id != null) {
      for (final option in options) {
        if (option.id == id) {
          return option.name;
        }
      }
    }

    return fallback;
  }

  MasterOption? _optionById(
    List<MasterOption> options,
    int? id,
  ) {
    if (id == null) {
      return null;
    }

    for (final option in options) {
      if (option.id == id) {
        return option;
      }
    }

    return null;
  }

  String _dbMasterSaveValue(
    List<MasterOption> options,
    int? selectedId,
    dynamic originalValue,
  ) {
    final option = _optionById(
      options,
      selectedId,
    );

    if (option == null) {
      return _text(originalValue);
    }

    final original = _text(originalValue);

    // If existing DB value is a CommonMaster ID, keep saving ID.
    if (int.tryParse(original) != null) {
      return option.id.toString();
    }

    // If existing DB value uses CommonMaster code, keep saving code.
    if (original.isNotEmpty) {
      for (final current in options) {
        if (current.code.trim().toLowerCase() ==
            original.toLowerCase()) {
          return option.code.isNotEmpty
              ? option.code
              : option.name;
        }
      }
    }

    // Otherwise keep the name convention.
    return option.name;
  }

  // ============================================================
  // MAP HELPERS
  // ============================================================

  dynamic _value(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      if (map.containsKey(key)) {
        final value = map[key];

        if (value != null) {
          return value;
        }
      }

      for (final entry
          in map.entries) {
        if (entry.key.toLowerCase() ==
            key.toLowerCase()) {
          if (entry.value != null) {
            return entry.value;
          }
        }
      }
    }

    return null;
  }

  String _text(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  int _int(
    dynamic value,
  ) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value.toString(),
        ) ??
        0;
  }

  int? _nullablePositiveInt(
    dynamic value,
  ) {
    final result =
        _int(value);

    return result > 0
        ? result
        : null;
  }

  double _decimal(
    dynamic value,
  ) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString(),
        ) ??
        0;
  }

  bool _bool(
    dynamic value,
  ) {
    if (value == null) {
      return false;
    }

    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final text = value
        .toString()
        .trim()
        .toLowerCase();

    return text == 'true' ||
        text == '1' ||
        text == 'yes';
  }

  // ============================================================
  // NUMBER FORMAT
  // ============================================================

  String _decimalText(
    dynamic value,
  ) {
    final number =
        _decimal(value);

    if (number ==
        number.roundToDouble()) {
      return number.toStringAsFixed(0);
    }

    return number.toStringAsFixed(2);
  }

  String _money(
    dynamic value,
  ) {
    final number =
        _decimal(value);

    return '₹${number.toStringAsFixed(2)}';
  }

  // ============================================================
  // DATE HELPERS
  // ============================================================

  String _displayDate(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    final text =
        value.toString().trim();

    if (text.isEmpty) {
      return '';
    }

    final date =
        DateTime.tryParse(text);

    if (date == null) {
      return text;
    }

    return _formatDate(date);
  }

  String _displayDateTime(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    final text =
        value.toString().trim();

    if (text.isEmpty) {
      return '';
    }

    final date =
        DateTime.tryParse(text);

    if (date == null) {
      return text;
    }

    final hour12 = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;

    final amPm =
        date.hour >= 12
            ? 'PM'
            : 'AM';

    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year} '
        '${hour12.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')} '
        '$amPm';
  }

  String _formatDate(
    DateTime date,
  ) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }

  DateTime? _parseDisplayDate(
    String value,
  ) {
    final text =
        value.trim();

    if (text.isEmpty) {
      return null;
    }

    final parts =
        text.split('-');

    if (parts.length != 3) {
      return null;
    }

    final day =
        int.tryParse(parts[0]);

    final month =
        int.tryParse(parts[1]);

    final year =
        int.tryParse(parts[2]);

    if (day == null ||
        month == null ||
        year == null) {
      return null;
    }

    return DateTime(
      year,
      month,
      day,
    );
  }

  String? _controllerApiDate(
    String value,
  ) {
    final date =
        _parseDisplayDate(value);

    if (date == null) {
      return null;
    }

    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String? _apiDate(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final text =
        value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    final parsed =
        DateTime.tryParse(text);

    if (parsed == null) {
      return null;
    }

    return '${parsed.year.toString().padLeft(4, '0')}-'
        '${parsed.month.toString().padLeft(2, '0')}-'
        '${parsed.day.toString().padLeft(2, '0')}';
  }
}