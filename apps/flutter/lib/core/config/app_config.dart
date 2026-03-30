/// Environment-based application configuration.
///
/// Override API_URL at build time:
///   flutter run --dart-define=API_URL=https://api.staging.ontaskhq.com/v1
///
/// Observability env vars (ARCH-30, ARCH-31):
///   flutter run --dart-define=GLITCHTIP_DSN=https://key@glitchtip.example.com/1
///   flutter run --dart-define=POSTHOG_API_KEY=phc_xxxx
///   flutter run --dart-define=POSTHOG_HOST=https://eu.posthog.com
///   flutter run --dart-define=ENVIRONMENT=staging
class AppConfig {
  // Private constructor — static-only class.
  const AppConfig._();

  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api.ontaskhq.com/v1',
  );

  /// GlitchTip DSN (Sentry-compatible). Empty string disables error reporting.
  static const String glitchtipDsn = String.fromEnvironment(
    'GLITCHTIP_DSN',
    defaultValue: '',
  );

  /// PostHog API key. Empty string disables analytics and feature flags.
  static const String posthogApiKey = String.fromEnvironment(
    'POSTHOG_API_KEY',
    defaultValue: '',
  );

  /// PostHog host — defaults to EU data residency endpoint (ARCH-30).
  static const String posthogHost = String.fromEnvironment(
    'POSTHOG_HOST',
    defaultValue: 'https://eu.posthog.com',
  );

  /// Deployment environment. Defaults to 'production'; override at build time.
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'production',
  );
}
