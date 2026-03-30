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
