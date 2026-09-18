import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdatePopupService {
  UpdatePopupService._();

  static const String _storageKeyPrefix = 'scirider_update_popup_seen_';

  static Future<void> showIfRequired(
    BuildContext context, {
    String? title,
    List<String>? updates,
    String releaseKey = '',
  }) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final version = packageInfo.version.trim();
      final buildNumber = packageInfo.buildNumber.trim();

      final versionKey = buildNumber.isNotEmpty
          ? '${version}_$buildNumber'
          : version;

      final prefs = await SharedPreferences.getInstance();
      final cleanReleaseKey = releaseKey.trim();
      final seenKey = cleanReleaseKey.isEmpty
          ? '$_storageKeyPrefix$versionKey'
          : '$_storageKeyPrefix${versionKey}_$cleanReleaseKey';
      final alreadySeen = prefs.getBool(seenKey) ?? false;

      if (alreadySeen) return;
      if (!context.mounted) return;

      final bool? acknowledged = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return _UpdatePopupDialog(
            version: version,
            buildNumber: buildNumber,
            title: title ?? 'SCiRIDER Updated',
            updates:
                updates ??
                const <String>[
                  'PO Approval is now available in My Approvals.',
                  'PO filtering has been updated.',
                  'PO detail screen has been updated.',
                  'Approve and Reject flow has been improved.',
                  'Approval list refreshes automatically after action.',
                  'General stability improvements have been added.',
                ],
          );
        },
      );

      if (acknowledged == true) {
        await prefs.setBool(seenKey, true);
      }
    } catch (e) {
      debugPrint('UpdatePopupService.showIfRequired error: $e');
    }
  }

  static Future<void> resetCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final version = packageInfo.version.trim();
      final buildNumber = packageInfo.buildNumber.trim();

      final versionKey = buildNumber.isNotEmpty
          ? '${version}_$buildNumber'
          : version;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_storageKeyPrefix$versionKey');
    } catch (e) {
      debugPrint('UpdatePopupService.resetCurrentVersion error: $e');
    }
  }

  static Future<void> resetAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final keys = prefs
          .getKeys()
          .where((key) => key.startsWith(_storageKeyPrefix))
          .toList();

      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      debugPrint('UpdatePopupService.resetAll error: $e');
    }
  }
}

class _UpdatePopupDialog extends StatelessWidget {
  final String version;
  final String buildNumber;
  final String title;
  final List<String> updates;

  const _UpdatePopupDialog({
    required this.version,
    required this.buildNumber,
    required this.title,
    required this.updates,
  });

  static const Color _primaryBlue = Color(0xFF079BD3);
  static const Color _navyBlue = Color(0xFF173F6B);
  static const Color _textDark = Color(0xFF182632);
  static const Color _textMedium = Color(0xFF687682);

  @override
  Widget build(BuildContext context) {
    final versionText = buildNumber.isNotEmpty
        ? 'Version $version ($buildNumber)'
        : 'Version $version';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Image.asset(
                      'assets/images/stride_favicon.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(
                        Icons.business_rounded,
                        color: _primaryBlue,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: _textDark,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          versionText,
                          style: const TextStyle(
                            color: _textMedium,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                "What's new",
                style: TextStyle(
                  color: _navyBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 11),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: SingleChildScrollView(
                  child: Column(
                    children: updates.map((text) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE7F7EF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Color(0xFF218C5B),
                                size: 13,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                text,
                                style: const TextStyle(
                                  color: _textMedium,
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Got it',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
