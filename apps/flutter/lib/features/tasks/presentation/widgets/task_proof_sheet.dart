import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// Bottom sheet that displays proof media for a completed task.
///
/// Shows the proof media inline (via [Image.network]) when [proofMediaUrl] is
/// non-null, or a placeholder message otherwise.
/// Displays completion metadata (completedByName, completedAt) and a privacy note.
///
/// This is a plain [StatelessWidget] — data is passed directly via constructor.
/// No provider overrides are required in tests.
class TaskProofSheet extends StatelessWidget {
  const TaskProofSheet({
    required this.taskId,
    this.proofMediaUrl,
    this.completedByName,
    this.completedAt,
    super.key,
  });

  final String taskId;
  final String? proofMediaUrl;
  final String? completedByName;
  final DateTime? completedAt;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.proofDetailTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  CupertinoButton(
                    minimumSize: const Size(44, 44),
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child: Icon(
                      CupertinoIcons.xmark,
                      color: colors.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            // ── Proof media ───────────────────────────────────────────────
            if (proofMediaUrl != null)
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Image.network(
                    proofMediaUrl!,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Center(child: CupertinoActivityIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      child: Text(
                        AppStrings.proofLoadError,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colors.textSecondary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.lg,
                ),
                child: Text(
                  AppStrings.proofNotAvailableMessage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            // ── Metadata ──────────────────────────────────────────────────
            if (completedAt != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xs,
                ),
                child: Text(
                  _metadataLabel(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
              ),
            // ── Privacy note ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Text(
                AppStrings.proofPrivacyNote,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _metadataLabel() {
    final dateStr = completedAt != null
        ? '${completedAt!.month}/${completedAt!.day}/${completedAt!.year}'
        : '';

    if (completedByName != null) {
      return AppStrings.proofCompletedByAtLabel
          .replaceAll('{name}', completedByName!)
          .replaceAll('{dateTime}', dateStr);
    }
    // No name available — use simpler "Completed · date" form
    return dateStr.isNotEmpty ? 'Completed · $dateStr' : 'Completed';
  }
}
