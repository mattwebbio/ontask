import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/auth/presentation/auth_provider.dart';
import '../domain/onboarding_step.dart';
import 'steps/calendar_connection_step.dart';
import 'steps/energy_preferences_step.dart';
import 'steps/sample_schedule_step.dart';
import 'steps/working_hours_step.dart';

/// Top-level onboarding flow widget.
///
/// Renders as a full-screen experience (outside [StatefulShellRoute]) — same
/// pattern as [AuthScreen].  Manages step-to-step transitions internally via
/// [_currentStep] state.
///
/// When onboarding is completed or skipped entirely, calls
/// [AuthStateNotifier.completeOnboarding()] then routes to [/now].
class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  OnboardingStep _currentStep = OnboardingStep.sampleSchedule;

  void _advanceTo(OnboardingStep step) {
    setState(() => _currentStep = step);
  }

  Future<void> _finishOnboarding() async {
    // authStateProvider is the generated name for AuthStateNotifier (see auth_provider.g.dart)
    await ref.read(authStateProvider.notifier).completeOnboarding();
    if (mounted) {
      context.go('/now');
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_currentStep) {
      OnboardingStep.sampleSchedule => SampleScheduleStep(
          onNext: () => _advanceTo(OnboardingStep.calendarConnection),
          onSkipAll: _finishOnboarding,
        ),
      OnboardingStep.calendarConnection => CalendarConnectionStep(
          onNext: () => _advanceTo(OnboardingStep.energyPreferences),
          onSkipAll: _finishOnboarding,
        ),
      OnboardingStep.energyPreferences => EnergyPreferencesStep(
          onNext: () => _advanceTo(OnboardingStep.workingHours),
          onSkipAll: _finishOnboarding,
        ),
      OnboardingStep.workingHours => WorkingHoursStep(
          onComplete: _finishOnboarding,
        ),
      OnboardingStep.complete => const SizedBox.shrink(),
    };
  }
}
