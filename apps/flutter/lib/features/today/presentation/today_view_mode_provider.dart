import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'today_view_mode_provider.g.dart';

/// View mode for the Today tab — list (default) or timeline.
enum TodayViewMode { list, timeline }

/// Async provider that loads the user's saved [TodayViewMode] from
/// [SharedPreferences].
///
/// Defaults to [TodayViewMode.list] if no preference has been stored.
/// SharedPreferences key: `'today_view_mode'`
///
/// keepAlive: prevents repeated SharedPreferences reads on every widget rebuild.
@Riverpod(keepAlive: true)
Future<TodayViewMode> todayViewMode(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getString('today_view_mode');
  return TodayViewMode.values.firstWhere(
    (v) => v.name == stored,
    orElse: () => TodayViewMode.list,
  );
}

/// Write gateway for updating the user's Today tab view mode preference.
///
/// Follows the same read/write gateway pattern as [ThemeSettings] in
/// `theme_provider.dart`. Persists to [SharedPreferences] and invalidates
/// [todayViewModeProvider] so the UI rebuilds immediately.
@Riverpod(keepAlive: true)
class TodayViewModeSettings extends _$TodayViewModeSettings {
  @override
  void build() {
    // No state — this notifier is purely a write gateway.
  }

  /// Persists the selected [TodayViewMode] and invalidates [todayViewModeProvider].
  Future<void> setViewMode(TodayViewMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('today_view_mode', mode.name);
    ref.invalidate(todayViewModeProvider);
  }
}
