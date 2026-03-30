/// 4pt grid spacing constants.
///
/// Widgets in feature layers use [AppSpacing.lg] etc. — never literal
/// [SizedBox(height: 16)] or similar hardcoded values.
class AppSpacing {
  AppSpacing._();

  /// 4pt
  static const double xs = 4.0;

  /// 8pt
  static const double sm = 8.0;

  /// 12pt
  static const double md = 12.0;

  /// 16pt
  static const double lg = 16.0;

  /// 24pt
  static const double xl = 24.0;

  /// 32pt
  static const double xxl = 32.0;

  /// 48pt
  static const double xxxl = 48.0;

  /// 64pt
  static const double max = 64.0;
}
