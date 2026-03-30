import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/settings_repository.dart';
import 'farewell_screen.dart';

/// Settings → Account → Delete Account screen.
///
/// Presents a warning about account deletion and requires the user to type
/// the exact confirmation string "delete my account" (case-sensitive) before
/// the destructive CTA is enabled (FR60, AC #2).
///
/// On confirmation:
///   1. Calls `DELETE /v1/users/me` (server queues 30-day soft-delete, NFR-R7)
///   2. Signs out the user via [AuthStateNotifier.signOut]
///   3. Pushes [FarewellScreen] — a terminal route with no back navigation
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _confirmController = TextEditingController();
  bool _isDeleting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _confirmController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  bool get _confirmationMatches =>
      _confirmController.text == AppStrings.deleteAccountConfirmMatch;

  Future<void> _deleteAccount() async {
    if (!_confirmationMatches) return;

    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(settingsRepositoryProvider).deleteAccount();

      // Sign out — clears tokens and resets auth state.
      await ref.read(authStateProvider.notifier).signOut();

      if (mounted) {
        // Push farewell screen as terminal route — no back navigation.
        await Navigator.of(context).pushAndRemoveUntil(
          CupertinoPageRoute<void>(
            builder: (_) => const FarewellScreen(),
          ),
          (_) => false,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
          _errorMessage = 'Something went wrong. Please try again.';
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
        middle: Text(AppStrings.deleteAccountTitle),
        backgroundColor: colors.surfacePrimary,
      ),
      backgroundColor: colors.surfacePrimary,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // ── Warning ────────────────────────────────────────────────────
              Text(
                AppStrings.deleteAccountWarning,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.deleteAccountContractsNote,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.deleteAccountIrreversibleNote,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              // ── Confirmation text field ────────────────────────────────────
              Text(
                AppStrings.deleteAccountConfirmHint,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _confirmController,
                placeholder: AppStrings.deleteAccountConfirmPlaceholder,
                autocorrect: false,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: colors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _confirmationMatches
                        ? CupertinoColors.destructiveRed
                        : colors.surfaceSecondary,
                  ),
                ),
                placeholderStyle: TextStyle(color: colors.textSecondary),
                style: TextStyle(color: colors.textPrimary),
              ),
              const SizedBox(height: 24),
              // ── Destructive CTA — enabled only when text matches exactly ───
              if (_isDeleting)
                const Center(child: CupertinoActivityIndicator())
              else
                CupertinoButton(
                  onPressed: _confirmationMatches ? _deleteAccount : null,
                  child: Text(
                    AppStrings.deleteAccountButton,
                    style: TextStyle(
                      color: _confirmationMatches
                          ? CupertinoColors.destructiveRed
                          : colors.textSecondary,
                    ),
                  ),
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
