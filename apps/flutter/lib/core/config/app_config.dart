/// Environment-based application configuration.
///
/// Override API_URL at build time:
///   flutter run --dart-define=API_URL=https://api.staging.ontaskhq.com/v1
class AppConfig {
  // Private constructor — static-only class.
  const AppConfig._();

  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api.ontaskhq.com/v1',
  );
}
