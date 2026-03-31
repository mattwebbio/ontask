import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/template.dart';
import 'templates_provider.dart';

/// Screen showing all saved templates with title, source type, and created date.
///
/// Supports swipe-to-delete with confirmation dialog.
/// Accessible from the Lists screen.
class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final templatesState = ref.watch(templatesProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: colors.surfacePrimary,
        middle: const Text(AppStrings.templateLibraryTitle),
      ),
      child: SafeArea(
        child: templatesState.when(
          data: (templates) {
            if (templates.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    AppStrings.templatePickerEmpty,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: colors.textSecondary),
                  ),
                ),
              );
            }
            return ListView.builder(
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return Dismissible(
                  key: ValueKey(template.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) =>
                      _confirmDelete(context, ref, template),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding:
                        const EdgeInsets.only(right: AppSpacing.xl),
                    color: CupertinoColors.destructiveRed,
                    child: const Icon(
                      CupertinoIcons.delete,
                      color: CupertinoColors.white,
                    ),
                  ),
                  child: _TemplateRow(template: template),
                );
              },
            );
          },
          loading: () => const Center(
            child: CupertinoActivityIndicator(),
          ),
          error: (_, __) => Center(
            child: Text(
              AppStrings.templateApplyError,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Template template,
  ) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text(AppStrings.templateDeleteConfirmTitle),
        content: const Text(AppStrings.templateDeleteConfirmMessage),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppStrings.actionCancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(AppStrings.templateDeleteSuccess),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(templatesProvider.notifier).deleteTemplate(template.id);
      return true;
    }
    return false;
  }
}

class _TemplateRow extends StatelessWidget {
  const _TemplateRow({required this.template});

  final Template template;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colors.surfaceSecondary,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            template.sourceType == 'list'
                ? CupertinoIcons.list_bullet
                : CupertinoIcons.folder,
            color: colors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.title,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: colors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  template.sourceType == 'list'
                      ? AppStrings.templateSourceList
                      : AppStrings.templateSourceSection,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
