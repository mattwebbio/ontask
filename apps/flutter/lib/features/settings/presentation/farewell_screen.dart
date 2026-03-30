import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_theme.dart';

/// Terminal screen shown after successful account deletion (FR60, AC #2).
///
/// Design rules (UX-DR32, UX-DR36):
///   - Warm, narrative voice — "past self / future self" framing
///   - No back navigation — uses [WillPopScope] to block Android back gesture;
///     iOS swipe-back is blocked by removing the route from history via pushAndRemoveUntil
///   - "Done" button navigates to the auth screen — uses [GoRouter.go]
///     so the user cannot navigate back to any authenticated screens
///
/// This screen is a terminal route. It is pushed via [Navigator.pushAndRemoveUntil]
/// from [DeleteAccountScreen], which clears the entire navigation stack.
class FarewellScreen extends StatelessWidget {
  const FarewellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      // Block back navigation — this is a terminal screen (no back button).
      canPop: false,
      child: CupertinoPageScaffold(
        backgroundColor: colors.surfacePrimary,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                // ── Title — emotional voice (UX-DR32) ─────────────────────────
                Text(
                  AppStrings.farewellTitle,
                  textAlign: TextAlign.center,
                  style: textTheme.displaySmall?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 20),
                // ── Body copy — warm narrative voice ─────────────────────────
                Text(
                  AppStrings.farewellBody,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const Spacer(),
                // ── Done — routes to auth screen (no pop) ────────────────────
                CupertinoButton.filled(
                  onPressed: () {
                    // Navigate to auth screen via GoRouter — clears the
                    // navigation stack so the user cannot navigate back to
                    // any authenticated screens (FR60, AC #2).
                    context.go('/auth/sign-in');
                  },
                  child: Text(AppStrings.farewellDoneButton),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
