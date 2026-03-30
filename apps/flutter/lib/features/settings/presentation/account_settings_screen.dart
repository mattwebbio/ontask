import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/domain/auth_result.dart';
import '../../auth/presentation/auth_provider.dart';
import 'delete_account_screen.dart';
import 'export_data_screen.dart';
import 'two_factor_setup_screen.dart';

/// Settings → Account screen.
///
/// Lists account management options:
///   - Export My Data (FR81)
///   - Delete Account (FR60)
///   - Two-Factor Authentication — email/password users only (FR92, NFR-S8)
///
/// The 2FA tile is hidden entirely for Apple/Google Sign In users — those accounts
/// delegate security to their OAuth providers. The check happens at render time
/// based on the current [AuthResult] in [authStateProvider].
class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final authState = ref.watch(authStateProvider);

    // Determine whether this is an email/password account.
    // 2FA is available only for email accounts (NFR-S8).
    // Apple/Google Sign In users must never see this tile.
    final isEmailAccount =
        authState.mapOrNull(authenticated: (s) => s.provider) == 'email';

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(AppStrings.accountTitle),
        backgroundColor: colors.surfacePrimary,
      ),
      backgroundColor: colors.surfacePrimary,
      child: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 8),
            // ── Export My Data ───────────────────────────────────────────────
            _AccountTile(
              label: AppStrings.accountExportData,
              icon: CupertinoIcons.arrow_down_doc,
              onTap: () => Navigator.of(context).push(
                CupertinoPageRoute<void>(
                  builder: (_) => const ExportDataScreen(),
                ),
              ),
            ),
            // ── Delete Account ───────────────────────────────────────────────
            _AccountTile(
              label: AppStrings.accountDeleteAccount,
              icon: CupertinoIcons.trash,
              isDestructive: true,
              onTap: () => Navigator.of(context).push(
                CupertinoPageRoute<void>(
                  builder: (_) => const DeleteAccountScreen(),
                ),
              ),
            ),
            // ── Two-Factor Authentication (email/password accounts only) ─────
            if (isEmailAccount)
              _AccountTile(
                label: AppStrings.accountTwoFactorAuth,
                icon: CupertinoIcons.lock_shield,
                onTap: () => Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (_) => const TwoFactorSetupScreen(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A single navigable account settings row.
class _AccountTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  const _AccountTile({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final labelColor =
        isDestructive ? CupertinoColors.destructiveRed : colors.textPrimary;
    final iconColor =
        isDestructive ? CupertinoColors.destructiveRed : colors.accentPrimary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colors.surfaceSecondary, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: labelColor,
                    ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: colors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
