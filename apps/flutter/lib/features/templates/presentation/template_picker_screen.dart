import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/template.dart';
import 'templates_provider.dart';

/// Modal screen that lists saved templates and allows the user to apply one.
///
/// Tapping a template shows a confirmation bottom sheet with an optional
/// due date offset picker. After apply, pops the picker.
class TemplatePickerScreen extends ConsumerWidget {
  const TemplatePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final templatesState = ref.watch(templatesProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.lg),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Center(
                child: Container(
                  width: AppSpacing.xxxl,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Title
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                AppStrings.templatePickerTitle,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: colors.textPrimary,
                    ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Template list
            Expanded(
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
                      return _TemplateCard(template: template);
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
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends ConsumerWidget {
  const _TemplateCard({required this.template});

  final Template template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    return GestureDetector(
      onTap: () => _showApplySheet(context, ref),
      child: Container(
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

  void _showApplySheet(BuildContext context, WidgetRef ref) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => _ApplyTemplateSheet(template: template),
    );
  }
}

class _ApplyTemplateSheet extends ConsumerStatefulWidget {
  const _ApplyTemplateSheet({required this.template});

  final Template template;

  @override
  ConsumerState<_ApplyTemplateSheet> createState() =>
      _ApplyTemplateSheetState();
}

class _ApplyTemplateSheetState extends ConsumerState<_ApplyTemplateSheet> {
  bool _keepOriginalDates = true;
  int _offsetDays = 0;
  bool _isApplying = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.lg),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: AppSpacing.xxxl,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Template name
            Text(
              widget.template.title,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: colors.textPrimary,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Keep original dates toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    AppStrings.templateDueDateOffsetNone,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: colors.textPrimary),
                  ),
                ),
                CupertinoSwitch(
                  value: _keepOriginalDates,
                  onChanged: (value) {
                    setState(() => _keepOriginalDates = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Offset days picker (shown when not keeping original dates)
            if (!_keepOriginalDates) ...[
              Text(
                AppStrings.templateDueDateOffsetLabel,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 120,
                child: CupertinoPicker(
                  itemExtent: 32,
                  scrollController: FixedExtentScrollController(
                    initialItem: _offsetDays,
                  ),
                  onSelectedItemChanged: (index) {
                    setState(() => _offsetDays = index);
                  },
                  children: List.generate(
                    366,
                    (i) => Center(
                      child: Text(
                        '$i',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: colors.textPrimary),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Apply button
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                onPressed: _isApplying ? null : _applyTemplate,
                child: Text(
                  _isApplying
                      ? AppStrings.submittingIndicator
                      : AppStrings.templateApplyButton,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Future<void> _applyTemplate() async {
    setState(() => _isApplying = true);
    try {
      final result =
          await ref.read(templatesProvider.notifier).applyTemplate(
                widget.template.id,
                dueDateOffsetDays:
                    _keepOriginalDates ? null : _offsetDays,
              );
      if (mounted) {
        // Pop the apply sheet
        Navigator.of(context).pop();
        // Pop the picker screen
        Navigator.of(context).pop();

        // Navigate to the newly created list if present
        final listData = result['list'] as Map<String, dynamic>?;
        if (listData != null && listData['id'] != null) {
          context.push('/lists/${listData['id']}');
        }
      }
    } catch (_) {
      // Error handling deferred to real implementation
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }
}
