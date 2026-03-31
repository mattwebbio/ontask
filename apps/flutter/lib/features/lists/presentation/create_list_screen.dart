import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../templates/presentation/template_picker_screen.dart';
import 'lists_provider.dart';

/// Modal/sheet for creating a new list.
///
/// Title field (required), default due date (optional).
/// Calls [ListsNotifier.createList()] on submit.
class CreateListScreen extends ConsumerStatefulWidget {
  const CreateListScreen({super.key});

  @override
  ConsumerState<CreateListScreen> createState() => _CreateListScreenState();
}

class _CreateListScreenState extends ConsumerState<CreateListScreen> {
  final _titleController = TextEditingController();
  DateTime? _defaultDueDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _createList() async {
    if (_titleController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(listsProvider.notifier).createList(
            title: _titleController.text.trim(),
            defaultDueDate: _defaultDueDate?.toIso8601String(),
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      // Error handling deferred to real implementation
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showDatePicker() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => Container(
        height: 260,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(
                  child: const Text(AppStrings.actionDone),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: DateTime.now(),
                onDateTimeChanged: (date) {
                  setState(() => _defaultDueDate = date);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.lg),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
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
              const SizedBox(height: AppSpacing.xl),

              Text(
                AppStrings.createListTitle,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: colors.textPrimary,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Title field
              CupertinoTextField(
                controller: _titleController,
                placeholder: AppStrings.createListTitlePlaceholder,
                autofocus: true,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.textPrimary,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Default due date
              GestureDetector(
                onTap: _showDatePicker,
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.calendar,
                      size: 18,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      _defaultDueDate != null
                          ? '${AppStrings.createListDefaultDueDateLabel}: ${_defaultDueDate!.month}/${_defaultDueDate!.day}/${_defaultDueDate!.year}'
                          : AppStrings.createListDefaultDueDateLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: _isSubmitting ? null : _createList,
                  child: Text(
                    _isSubmitting
                        ? AppStrings.submittingIndicator
                        : AppStrings.createListButton,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Start from template
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    showCupertinoModalPopup<void>(
                      context: context,
                      builder: (_) => const TemplatePickerScreen(),
                    );
                  },
                  child: Text(
                    AppStrings.templateStartFromTemplate,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.accentPrimary,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
