import 'dart:async' show unawaited;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_theme.dart';
import '../data/auth_repository.dart';
import '../domain/auth_result.dart';
import 'auth_provider.dart';

/// Two-factor authentication verification screen — shown during the email login flow.
///
/// Displayed when [AuthState.twoFactorRequired] is set (i.e. the email login
/// returned `{ status: 'totp_required', tempToken }`). The user enters their
/// 6-digit TOTP code or a backup code to complete sign in (FR92, AC #3).
///
/// On success: transitions auth state to [AuthResult.authenticated], which
/// causes the router to redirect to /now.
/// On failure: displays a plain-language error (NFR-UX2).
class TwoFactorVerifyScreen extends ConsumerStatefulWidget {
  /// The temporary token returned by [POST /v1/auth/email] when 2FA is required.
  final String tempToken;

  const TwoFactorVerifyScreen({
    required this.tempToken,
    super.key,
  });

  @override
  ConsumerState<TwoFactorVerifyScreen> createState() =>
      _TwoFactorVerifyScreenState();
}

class _TwoFactorVerifyScreenState
    extends ConsumerState<TwoFactorVerifyScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ref
        .read(authRepositoryProvider.notifier)
        .verify2FA(widget.tempToken, code);

    if (!mounted) return;

    setState(() => _isLoading = false);

    switch (result) {
      case Authenticated(:final userId):
        unawaited(
          ref.read(authStateProvider.notifier).setAuthenticated(
            userId,
            provider: 'email',
          ),
        );
      case AuthError(:final message):
        setState(() => _errorMessage = message);
      case Unauthenticated():
      case TwoFactorRequired():
        setState(() => _errorMessage = AppStrings.twoFactorVerifyError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(AppStrings.twoFactorVerifyTitle),
        backgroundColor: colors.surfacePrimary,
      ),
      backgroundColor: colors.surfacePrimary,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              // ── Instructions ───────────────────────────────────────────────
              Text(
                AppStrings.twoFactorVerifyInstructions,
                textAlign: TextAlign.center,
                style:
                    textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: 32),
              // ── Code field ─────────────────────────────────────────────────
              CupertinoTextField(
                controller: _codeController,
                placeholder: AppStrings.twoFactorVerifyCodeLabel,
                keyboardType: TextInputType.number,
                maxLength: 8, // 6 for TOTP, longer for backup codes
                textAlign: TextAlign.center,
                autofocus: true,
                onSubmitted: (_) => _verify(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: colors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                placeholderStyle: TextStyle(color: colors.textSecondary),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 22,
                  fontFamily: 'monospace',
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 24),
              // ── Verify button ──────────────────────────────────────────────
              if (_isLoading)
                const Center(child: CupertinoActivityIndicator())
              else
                CupertinoButton.filled(
                  onPressed: _verify,
                  child: Text(AppStrings.twoFactorVerifyButton),
                ),
              // ── Error message ──────────────────────────────────────────────
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
              const SizedBox(height: 20),
              // ── Backup code affordance ─────────────────────────────────────
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  // Clear the field — the placeholder already says "code"
                  // which covers backup codes too. This button just signals
                  // intent; the single field accepts both formats.
                  _codeController.clear();
                  setState(() => _errorMessage = null);
                },
                child: Text(
                  AppStrings.twoFactorUseBackupCode,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.accentPrimary,
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
