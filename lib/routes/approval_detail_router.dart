import 'package:flutter/material.dart';

import '../models/approval_model.dart';
import '../screens/approval_detail_screen.dart';
import '../screens/nfa_approval_detail_screen.dart';
import '../screens/po_approval_detail_screen.dart';

class ApprovalDetailRouter {
  const ApprovalDetailRouter._();

  static Future<bool?> open(BuildContext context, ApprovalModel approval) {
    return Navigator.of(context).push<bool?>(route(approval));
  }

  static Route<bool?> route(ApprovalModel approval) {
    final String module = approval.module.trim().toUpperCase();

    return MaterialPageRoute<bool?>(
      settings: RouteSettings(name: _routeName(module), arguments: approval),
      builder: (BuildContext context) {
        switch (module) {
          case 'PO':
            return POApprovalDetailScreen(approval: approval);
          case 'NFA':
            return NFAApprovalDetailScreen(approval: approval);
          case 'PR':
          case 'SR':
          default:
            return ApprovalDetailScreen(approval: approval);
        }
      },
    );
  }

  static String _routeName(String module) {
    switch (module) {
      case 'PO':
        return '/approval/po-detail';
      case 'NFA':
        return '/approval/nfa-detail';
      case 'PR':
        return '/approval/pr-detail';
      case 'SR':
        return '/approval/sr-detail';
      default:
        return '/approval/detail';
    }
  }

  static bool hasDedicatedScreen(String module) {
    final cleanModule = module.trim().toUpperCase();
    return cleanModule == 'PO' || cleanModule == 'NFA';
  }

  static const List<String> supportedModules = <String>['PR', 'SR', 'NFA', 'PO'];

  static bool isSupportedModule(String module) =>
      supportedModules.contains(module.trim().toUpperCase());
}
