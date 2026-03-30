import 'package:flutter/material.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_theme.dart';

/// Placeholder Settings screen — full implementation in Story 1.10.
///
/// Route path: `/settings`
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    return Scaffold(
      backgroundColor: colors.surfacePrimary,
      body: Center(
        child: Text(
          AppStrings.macosSettingsTitle,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: colors.textPrimary,
              ),
        ),
      ),
    );
  }
}
