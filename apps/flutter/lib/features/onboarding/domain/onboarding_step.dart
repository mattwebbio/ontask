/// Ordered steps in the onboarding flow.
///
/// The flow progresses forward through each step.  [complete] is the terminal
/// state that triggers navigation to the main app (/now).
enum OnboardingStep {
  sampleSchedule,
  calendarConnection,
  energyPreferences,
  workingHours,
  complete,
}
