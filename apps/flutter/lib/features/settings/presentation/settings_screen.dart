import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_theme.dart';
import 'appearance_settings_screen.dart';
import 'sessions_screen.dart';

/// Root Settings screen — accessible via profile icon in the navigation header.
///
/// Lists navigable sections: Appearance, Scheduling Preferences (stub),
/// Security → Active Sessions, Notifications (stub), Account (stub for Story 1.11).
///
/// Delivered as a `ConsumerStatefulWidget` so that future settings state
/// (e.g. notification badge counts) can be observed via Riverpod.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(AppStrings.settingsTitle),
        backgroundColor: colors.surfacePrimary,
      ),
      backgroundColor: colors.surfacePrimary,
      child: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 8),
            // ── Appearance ──────────────────────────────────────────────────
            _SettingsTile(
              label: AppStrings.settingsAppearance,
              icon: CupertinoIcons.paintbrush,
              onTap: () => Navigator.of(context).push(
                CupertinoPageRoute<void>(
                  builder: (_) => const AppearanceSettingsScreen(),
                ),
              ),
            ),
            // ── Scheduling Preferences (stub) ───────────────────────────────
            _SettingsTile(
              label: AppStrings.settingsScheduling,
              icon: CupertinoIcons.calendar,
              onTap: () {
                // Stub — full scheduling preferences API deferred to Epic 3.
                // Local SharedPreferences values from Story 1.9 are preserved.
              },
            ),
            // ── Security ────────────────────────────────────────────────────
            _SettingsTile(
              label: AppStrings.settingsSecurity,
              icon: CupertinoIcons.lock_shield,
              onTap: () => Navigator.of(context).push(
                CupertinoPageRoute<void>(
                  builder: (_) => const SessionsScreen(),
                ),
              ),
            ),
            // ── Notifications (stub) ────────────────────────────────────────
            _SettingsTile(
              label: AppStrings.settingsNotifications,
              icon: CupertinoIcons.bell,
              onTap: () {
                // Stub — Notifications implemented in Epic 8.
              },
            ),
            // ── Account (stub — Story 1.11) ─────────────────────────────────
            _SettingsTile(
              label: AppStrings.settingsAccount,
              icon: CupertinoIcons.person_crop_circle,
              onTap: () {
                // Stub — Account deletion / 2FA implemented in Story 1.11.
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A single navigable settings row.
///
/// Uses `CupertinoListTile`-style layout with a leading icon, label, and
/// trailing chevron. Colours come from [OnTaskColors] semantic tokens — no
/// hardcoded hex values.
class _SettingsTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

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
            Icon(icon, color: colors.accentPrimary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.textPrimary,
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
