/// App-wide string constants for empty states and other copy.
///
/// Full l10n via Flutter gen-l10n / ARB pipeline is deferred to a later story.
/// All copy follows the "past self / future self" warm narrative voice.
class AppStrings {
  AppStrings._();

  // ── Now tab — rest state ─────────────────────────────────────────────────────
  static const String nowEmptyTitle = "You're clear for now.";
  static const String nowEmptySubtitleTemplate =
      "Next: {task} at {time}"; // used when next task is known

  // ── Today tab — no tasks ─────────────────────────────────────────────────────
  static const String todayEmptyTitle = "Nothing scheduled.";
  static const String todayEmptyAddCta = "Add something?";

  // ── Lists tab — no lists ─────────────────────────────────────────────────────
  static const String listsEmptyTitle = "No lists yet.";
  static const String listsEmptySubtitle =
      "Create a list to start organising what matters.";

  // ── Auth screen ──────────────────────────────────────────────────────────────
  static const String authSignInWithApple = "Sign in with Apple";
  static const String authSignInWithGoogle = "Sign in with Google";
  static const String authEmailLabel = "Email";
  static const String authPasswordLabel = "Password";
  static const String authSignInButton = "Sign In";
  static const String authForgotPassword = "Forgot password?";

  /// Plain-language error for invalid credentials — never expose error codes (NFR-UX2).
  static const String authErrorInvalidCredentials =
      "That email or password isn't quite right. Try again or reset your password.";
  static const String authErrorGeneric =
      "Something went wrong. Please try again.";

  /// Subtitle — New York serif / emotional voice copy only.
  static const String authSubtitle = "your past self is counting on you";

  // ── Onboarding flow ──────────────────────────────────────────────────────────

  /// Welcome headline on the sample schedule step.
  /// New York serif — emotional voice layer only (UX-DR32).
  /// Warm, first-person framing that shows what a day with On Task could feel like.
  static const String onboardingWelcomeHeadline =
      "Here's what a day with On Task could look like.";

  /// Secondary CTA to skip all onboarding and go straight to the app.
  /// No punitive language — "take me to the app" not "skip setup" phrasing.
  static const String onboardingSkipAll = "Skip setup — take me to the app";

  /// Primary CTA on the sample schedule step.
  static const String onboardingLetSetItUp = "Let's set it up";

  /// Calendar connection step — SF Pro
  static const String onboardingCalendarTitle = "Connect your calendar";

  /// Calendar connection step subhead.
  /// "Past self / future self" narrative voice (UX-DR32).
  static const String onboardingCalendarSubtitle =
      "So your future self isn't ambushed by what past you already committed to.";

  /// Calendar connection primary CTA.
  static const String onboardingCalendarConnect = "Connect Google Calendar";

  /// "Set this up later" affordance — present on every onboarding step (AC #2).
  static const String onboardingCalendarSkip = "Set this up later";

  /// Energy preferences step — SF Pro
  static const String onboardingEnergyTitle = "When does your energy peak?";

  /// Peak focus hours range label.
  static const String onboardingEnergyPeakLabel = "Peak focus hours";

  /// Low-energy hours range label.
  /// Frames broadly around executive dysfunction — no "ADHD-specific" framing (UX-DR36).
  static const String onboardingEnergyLowLabel = "Low-energy hours";

  /// Wind-down time range label.
  static const String onboardingEnergyWindDownLabel = "Wind-down time";

  /// Working hours step — SF Pro
  static const String onboardingWorkingHoursTitle = "When does your work day run?";

  /// Work start time label.
  static const String onboardingWorkingStartLabel = "Work starts";

  /// Work end time label.
  static const String onboardingWorkingEndLabel = "Work ends";

  /// Final onboarding CTA — routes to the main app.
  static const String onboardingDoneButton = "Done — show me my plan";

  // ── macOS shell ──────────────────────────────────────────────────────────────
  static const String macosNewTask = "New Task";
  static const String macosNavNow = "Now";
  static const String macosNavToday = "Today";
  static const String macosNavLists = "Lists";
  static const String macosNavSettings = "Settings";
  static const String macosCommandPaletteTitle = "Command Palette";
  static const String macosCommandPalettePlaceholder = "Search commands…";
  static const String macosSettingsTitle = "Settings";
}
