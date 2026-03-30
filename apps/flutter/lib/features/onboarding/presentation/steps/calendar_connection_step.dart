import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// Onboarding step 2: Connect Google Calendar.
///
/// The actual Google Calendar OAuth flow is deferred to Epic 3.
/// In this story the "Connect Google Calendar" button shows a loading indicator
/// for 1 second then shows a success confirmation (simulated stub).
///
/// TODO(story-3.x): Replace stub with real Google Calendar OAuth.
class CalendarConnectionStep extends StatefulWidget {
  const CalendarConnectionStep({
    required this.onNext,
    required this.onSkipAll,
    super.key,
  });

  /// Called when the "Set this up later" button is tapped.
  final VoidCallback onNext;

  /// Called when the user wants to skip all remaining onboarding.
  final VoidCallback onSkipAll;

  @override
  State<CalendarConnectionStep> createState() => _CalendarConnectionStepState();
}

class _CalendarConnectionStepState extends State<CalendarConnectionStep> {
  bool _isConnecting = false;
  bool _connected = false;

  Future<void> _connectCalendar() async {
    setState(() => _isConnecting = true);
    // TODO(story-3.x): Replace stub with real Google Calendar OAuth.
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _isConnecting = false;
        _connected = true;
      });
    }
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
              // Step title — SF Pro 22pt semibold
              Text(
                AppStrings.onboardingCalendarTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Subhead — SF Pro 15pt secondary colour
              Text(
                AppStrings.onboardingCalendarSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      color: colors.textSecondary,
                    ),
              ),
              const Spacer(),
              if (_connected)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.checkmark_circle_fill,
                        size: 48,
                        color: colors.accentCompletion,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Calendar connected!',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoButton.filled(
                          onPressed: widget.onNext,
                          child: const Text('Continue'),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                // CTA — Connect Google Calendar
                // Using CupertinoButton.filled with system default colour per
                // story spec: do NOT use accentPrimary for Google branding.
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: _isConnecting ? null : _connectCalendar,
                    child: _isConnecting
                        ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                        : Text(AppStrings.onboardingCalendarConnect),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // "Set this up later" — SF Pro text button
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
              ],
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
