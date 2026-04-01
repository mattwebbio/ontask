import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../proof/data/proof_prefs_provider.dart';

/// Settings → Privacy screen.
///
/// Allows the user to configure whether proof is retained by default after
/// AI verification succeeds. Changes apply immediately via Riverpod state —
/// no "Save" button required.
///
/// Pushed via [CupertinoPageRoute] from [SettingsScreen] — NOT added to
/// [AppRouter] (Story 7.7, AC: 2).
///
/// All strings come from [AppStrings] — no inline literals.
/// Follows the exact pattern of [AppearanceSettingsScreen].
/// (Epic 7, Story 7.7, AC: 2, FR38, NFR-R8)
class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() =>
      _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState
    extends ConsumerState<PrivacySettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final retainAsync = ref.watch(proofRetainDefaultProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(AppStrings.settingsPrivacy),
        backgroundColor: colors.surfacePrimary,
      ),
      backgroundColor: colors.surfacePrimary,
      child: SafeArea(
        child: retainAsync.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (_, _) => const SizedBox.shrink(),
          data: (retainDefault) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Keep proof by default toggle ───────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.privacyKeepProofByDefault,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: colors.textPrimary,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.privacyKeepProofSubtitle,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  CupertinoSwitch(
                    value: retainDefault,
                    activeTrackColor: colors.accentPrimary,
                    onChanged: (value) {
                      ref
                          .read(proofRetainSettingsProvider.notifier)
                          .setRetainDefault(value);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
