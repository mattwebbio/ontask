import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

// ── SharedPreferences keys for energy preference times ────────────────────────
// These are local-only in this story.  The scheduling engine (Epic 3) and
// Settings (Story 1.10) will migrate them server-side later.
const kPrefPeakStart = 'pref_peak_start';
const kPrefPeakEnd = 'pref_peak_end';
const kPrefLowEnergyStart = 'pref_low_energy_start';
const kPrefLowEnergyEnd = 'pref_low_energy_end';
const kPrefWindDownStart = 'pref_wind_down_start';
const kPrefWindDownEnd = 'pref_wind_down_end';

/// Onboarding step 3: Set energy preferences.
///
/// Three time-range pickers: "Peak focus hours", "Low-energy hours", and
/// "Wind-down time".  Selections are persisted locally in [SharedPreferences]
/// using [kPrefPeak*], [kPrefLowEnergy*], and [kPrefWindDown*] keys.
///
/// The API persistence is deferred to the Settings feature (Story 1.10 / Epic 2).
class EnergyPreferencesStep extends StatefulWidget {
  const EnergyPreferencesStep({
    required this.onNext,
    required this.onSkipAll,
    super.key,
  });

  /// Called when the "Set this up later" button is tapped.
  final VoidCallback onNext;

  /// Called when the user wants to skip all remaining onboarding.
  final VoidCallback onSkipAll;

  @override
  State<EnergyPreferencesStep> createState() => _EnergyPreferencesStepState();
}

class _EnergyPreferencesStepState extends State<EnergyPreferencesStep> {
  // Default values
  TimeOfDay _peakStart = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _peakEnd = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _lowEnergyStart = const TimeOfDay(hour: 13, minute: 0);
  TimeOfDay _lowEnergyEnd = const TimeOfDay(hour: 15, minute: 0);
  TimeOfDay _windDownStart = const TimeOfDay(hour: 17, minute: 0);
  TimeOfDay _windDownEnd = const TimeOfDay(hour: 18, minute: 0);

  bool _isSaving = false;

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _saveAndContinue() async {
    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kPrefPeakStart, _formatTime(_peakStart));
      await prefs.setString(kPrefPeakEnd, _formatTime(_peakEnd));
      await prefs.setString(kPrefLowEnergyStart, _formatTime(_lowEnergyStart));
      await prefs.setString(kPrefLowEnergyEnd, _formatTime(_lowEnergyEnd));
      await prefs.setString(kPrefWindDownStart, _formatTime(_windDownStart));
      await prefs.setString(kPrefWindDownEnd, _formatTime(_windDownEnd));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
        widget.onNext();
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
              child: const Text('Done'),
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
                AppStrings.onboardingEnergyTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // Peak focus hours picker
              _TimeRangeTile(
                label: AppStrings.onboardingEnergyPeakLabel,
                start: _peakStart,
                end: _peakEnd,
                colors: colors,
                onTapStart: () => _showTimePicker(
                  context,
                  _peakStart,
                  (t) => setState(() => _peakStart = t),
                ),
                onTapEnd: () => _showTimePicker(
                  context,
                  _peakEnd,
                  (t) => setState(() => _peakEnd = t),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Low-energy hours picker
              _TimeRangeTile(
                label: AppStrings.onboardingEnergyLowLabel,
                start: _lowEnergyStart,
                end: _lowEnergyEnd,
                colors: colors,
                onTapStart: () => _showTimePicker(
                  context,
                  _lowEnergyStart,
                  (t) => setState(() => _lowEnergyStart = t),
                ),
                onTapEnd: () => _showTimePicker(
                  context,
                  _lowEnergyEnd,
                  (t) => setState(() => _lowEnergyEnd = t),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Wind-down time picker
              _TimeRangeTile(
                label: AppStrings.onboardingEnergyWindDownLabel,
                start: _windDownStart,
                end: _windDownEnd,
                colors: colors,
                onTapStart: () => _showTimePicker(
                  context,
                  _windDownStart,
                  (t) => setState(() => _windDownStart = t),
                ),
                onTapEnd: () => _showTimePicker(
                  context,
                  _windDownEnd,
                  (t) => setState(() => _windDownEnd = t),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: _isSaving ? null : _saveAndContinue,
                  child: _isSaving
                      ? const CupertinoActivityIndicator(
                          color: CupertinoColors.white,
                        )
                      : const Text('Save & continue'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // "Set this up later" — advance to next step without saving
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  onPressed: widget.onNext,
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

/// A labelled time-range row with tappable start/end time chips.
class _TimeRangeTile extends StatelessWidget {
  const _TimeRangeTile({
    required this.label,
    required this.start,
    required this.end,
    required this.colors,
    required this.onTapStart,
    required this.onTapEnd,
  });

  final String label;
  final TimeOfDay start;
  final TimeOfDay end;
  final OnTaskColors colors;
  final VoidCallback onTapStart;
  final VoidCallback onTapEnd;

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _TimeChip(
                label: _fmt(start),
                colors: colors,
                onTap: onTapStart,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  '–',
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
              _TimeChip(
                label: _fmt(end),
                colors: colors,
                onTap: onTapEnd,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.label,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final OnTaskColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: colors.surfacePrimary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.accentPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}
