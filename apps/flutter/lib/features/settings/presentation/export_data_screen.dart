import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_theme.dart';
import '../data/settings_repository.dart';

/// Settings → Account → Export My Data screen.
///
/// Presents a single CTA that triggers the data export API call.
/// On success, opens the system share sheet so the user can save the
/// export ZIP to Files, AirDrop it, or share it as needed (FR81, AC #1).
///
/// The export URL returned by the API is a signed R2 URL — the Flutter client
/// shares the URL directly rather than downloading the file itself.
class ExportDataScreen extends ConsumerStatefulWidget {
  const ExportDataScreen({super.key});

  @override
  ConsumerState<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends ConsumerState<ExportDataScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _requestExport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url = await ref.read(settingsRepositoryProvider).requestDataExport();

      if (mounted) {
        setState(() => _isLoading = false);
        // Present system share sheet (iOS: share sheet → Save to Files / AirDrop etc.)
        // (macOS: opens NSSavePanel via NSSavePanel)
        await Share.share(url, subject: 'My OnTask Data Export');
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = AppStrings.exportDataError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(AppStrings.exportDataTitle),
        backgroundColor: colors.surfacePrimary,
      ),
      backgroundColor: colors.surfacePrimary,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                AppStrings.exportDataDescription,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                Column(
                  children: [
                    const CupertinoActivityIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.exportDataProgressMessage,
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                )
              else
                CupertinoButton.filled(
                  onPressed: _requestExport,
                  child: Text(AppStrings.exportDataButton),
                ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.scheduleAtRisk,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
