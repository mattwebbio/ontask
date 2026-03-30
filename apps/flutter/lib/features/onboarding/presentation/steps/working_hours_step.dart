import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

// ── SharedPreferences keys for working hours ──────────────────────────────────
// Local-only in this story; migrated server-side in Settings (Story 1.10 / Epic 2).
const kPrefWorkStart = 'pref_work_start';
const kPrefWorkEnd = 'pref_work_end';

/// Onboarding step 4 (final): Set preferred working hours.
///
/// Two time pickers: "Work starts" and "Work ends".  Persists selections
/// locally in [SharedPreferences] then calls [onComplete] to finish onboarding.
///
/// Both the primary CTA and "Set this up later" perform the same action:
/// complete onboarding and navigate to the main app (per story spec).
class WorkingHoursStep extends StatefulWidget {
  const WorkingHoursStep({
    required this.onComplete,
    super.key,
  });

  /// Called when the user taps either CTA — saves preferences and finishes onboarding.
  final VoidCallback onComplete;

  @override
  State<WorkingHoursStep> createState() => _WorkingHoursStepState();
}

class _WorkingHoursStepState extends State<WorkingHoursStep> {
  TimeOfDay _workStart = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _workEnd = const TimeOfDay(hour: 17, minute: 0);
  bool _isSaving = false;

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _saveAndComplete() async {
    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kPrefWorkStart, _formatTime(_workStart));
      await prefs.setString(kPrefWorkEnd, _formatTime(_workEnd));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
        widget.onComplete();
      }
    }
  }

  Future<void> _showTimePicker(
    BuildContext context,
    TimeOfDay initial,
    ValueChanged<TimeOfDay> onChanged,
  ) async {
    var selected = initial;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 260,
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
        child: Column(
          children: [
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: false,
                initialDateTime: DateTime(
                  2000,
                  1,
                  1,
                  initial.hour,
                  initial.minute,
                ),
                onDateTimeChanged: (dt) {
                  selected = TimeOfDay(hour: dt.hour, minute: dt.minute);
                },
              ),
            ),
            CupertinoButton(
              child: Text(AppStrings.onboardingTimePickerDone),
              onPressed: () {
                onChanged(selected);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl),
              Text(
                AppStrings.onboardingWorkingHoursTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // Work start time
              _WorkTimeTile(
                label: AppStrings.onboardingWorkingStartLabel,
                time: _workStart,
                colors: colors,
                onTap: () => _showTimePicker(
                  context,
                  _workStart,
                  (t) => setState(() => _workStart = t),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Work end time
              _WorkTimeTile(
                label: AppStrings.onboardingWorkingEndLabel,
                time: _workEnd,
                colors: colors,
                onTap: () => _showTimePicker(
                  context,
                  _workEnd,
                  (t) => setState(() => _workEnd = t),
                ),
              ),
              const Spacer(),
              // Primary CTA: save preferences + complete onboarding
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: _isSaving ? null : _saveAndComplete,
                  child: _isSaving
                      ? const CupertinoActivityIndicator(
                          color: CupertinoColors.white,
                        )
                      : Text(AppStrings.onboardingDoneButton),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // "Set this up later" — same action as primary CTA per story spec
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  onPressed: _isSaving ? null : _saveAndComplete,
                  child: Text(
                    AppStrings.onboardingCalendarSkip,
                    style: TextStyle(color: colors.textSecondary),
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

class _WorkTimeTile extends StatelessWidget {
  const _WorkTimeTile({
    required this.label,
    required this.time,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final TimeOfDay time;
  final OnTaskColors colors;
  final VoidCallback onTap;

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            Text(
              _fmt(time),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.accentPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
