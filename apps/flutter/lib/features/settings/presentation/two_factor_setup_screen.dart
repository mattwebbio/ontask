import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_theme.dart';
import '../data/settings_repository.dart';
import '../domain/two_factor_setup_data.dart';

part 'two_factor_setup_screen.g.dart';

/// Riverpod provider that loads 2FA setup data from the API.
///
/// Called once on screen load — provides [TwoFactorSetupData] containing
/// the TOTP secret, QR code URI, and backup codes. Cached for the lifetime
/// of the screen; re-fetched on invalidation.
@riverpod
Future<TwoFactorSetupData> twoFactorSetup(Ref ref) {
  return ref.watch(settingsRepositoryProvider).setup2FA();
}

/// Settings → Account → Two-Factor Authentication setup screen.
///
/// Guides the user through TOTP 2FA setup in three logical steps:
///   1. QR code display + manual secret entry
///   2. Backup codes display with copy affordance
///   3. Confirmation step — user enters first TOTP code to activate 2FA
///
/// Only accessible for email/password accounts (FR92, NFR-S8).
/// Apple/Google Sign In users are not shown the 2FA tile in [AccountSettingsScreen].
class TwoFactorSetupScreen extends ConsumerStatefulWidget {
  const TwoFactorSetupScreen({super.key});

  @override
  ConsumerState<TwoFactorSetupScreen> createState() =>
      _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends ConsumerState<TwoFactorSetupScreen> {
  final _confirmController = TextEditingController();
  bool _isConfirming = false;
  bool _setupComplete = false;
  String? _errorMessage;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _confirmSetup(TwoFactorSetupData data) async {
    final code = _confirmController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isConfirming = true;
      _errorMessage = null;
    });

    final success =
        await ref.read(settingsRepositoryProvider).confirm2FA(code);

    if (mounted) {
      if (success) {
        setState(() {
          _isConfirming = false;
          _setupComplete = true;
        });
      } else {
        setState(() {
          _isConfirming = false;
          _errorMessage = AppStrings.twoFactorSetupError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final setupAsync = ref.watch(twoFactorSetupProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(AppStrings.twoFactorSetupTitle),
        backgroundColor: colors.surfacePrimary,
      ),
      backgroundColor: colors.surfacePrimary,
      child: SafeArea(
        child: setupAsync.when(
          data: (data) => _buildContent(context, data, colors, textTheme),
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                AppStrings.twoFactorSetupError,
                textAlign: TextAlign.center,
                style:
                    textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    TwoFactorSetupData data,
    OnTaskColors colors,
    TextTheme textTheme,
  ) {
    if (_setupComplete) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.checkmark_seal_fill,
                size: 64,
                color: colors.accentCompletion,
              ),
              const SizedBox(height: 20),
              Text(
                AppStrings.twoFactorSetupSuccess,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: 32),
              CupertinoButton.filled(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppStrings.farewellDoneButton),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          // ── Instructions ─────────────────────────────────────────────────
          Text(
            AppStrings.twoFactorSetupInstructions,
            style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 28),

          // ── QR code ──────────────────────────────────────────────────────
          Text(
            AppStrings.twoFactorQrInstructions,
            style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 16),
          Center(
            child: QrImageView(
              data: data.otpauthUri,
              version: QrVersions.auto,
              size: 200,
              semanticsLabel: 'QR code for authenticator app setup',
            ),
          ),
          const SizedBox(height: 16),

          // ── Manual entry secret ───────────────────────────────────────────
          Text(
            AppStrings.twoFactorManualEntryLabel,
            style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: data.secret));
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colors.surfaceSecondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      data.secret,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textPrimary,
                        fontFamily: 'monospace',
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Icon(
                    CupertinoIcons.doc_on_clipboard,
                    size: 18,
                    color: colors.accentPrimary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ── Backup codes ─────────────────────────────────────────────────
          Text(
            AppStrings.twoFactorBackupCodesTitle,
            style: textTheme.titleSmall?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.twoFactorBackupCodesInstructions,
            style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceSecondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final code in data.backupCodes)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                      code,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textPrimary,
                        fontFamily: 'monospace',
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(text: data.backupCodes.join('\n')),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.doc_on_clipboard,
                        size: 16,
                        color: colors.accentPrimary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppStrings.twoFactorCopyAllCodes,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.accentPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Confirmation code entry ───────────────────────────────────────
          Text(
            AppStrings.twoFactorConfirmCodeLabel,
            style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: _confirmController,
            placeholder: AppStrings.twoFactorConfirmCodePlaceholder,
            keyboardType: TextInputType.number,
            maxLength: 6,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colors.surfaceSecondary,
              borderRadius: BorderRadius.circular(10),
            ),
            placeholderStyle: TextStyle(color: colors.textSecondary),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontFamily: 'monospace',
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 20),

          // ── Confirm button ────────────────────────────────────────────────
          if (_isConfirming)
            const Center(child: CupertinoActivityIndicator())
          else
            CupertinoButton.filled(
              onPressed: () => _confirmSetup(data),
              child: Text(AppStrings.twoFactorConfirmButton),
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
