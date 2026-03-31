import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/features/today/presentation/today_view_mode_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TodayViewMode', () {
    test('defaults to list', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final mode = await container.read(todayViewModeProvider.future);
      expect(mode, TodayViewMode.list);
    });

    test('persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Write timeline mode
      await container
          .read(todayViewModeSettingsProvider.notifier)
          .setViewMode(TodayViewMode.timeline);

      // Verify it was persisted
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('today_view_mode'), 'timeline');
    });

    test('reads saved preference on load', () async {
      SharedPreferences.setMockInitialValues({
        'today_view_mode': 'timeline',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final mode = await container.read(todayViewModeProvider.future);
      expect(mode, TodayViewMode.timeline);
    });

    test('toggle switches between list and timeline', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Start as list
      var mode = await container.read(todayViewModeProvider.future);
      expect(mode, TodayViewMode.list);

      // Toggle to timeline
      await container
          .read(todayViewModeSettingsProvider.notifier)
          .setViewMode(TodayViewMode.timeline);

      mode = await container.read(todayViewModeProvider.future);
      expect(mode, TodayViewMode.timeline);

      // Toggle back to list
      await container
          .read(todayViewModeSettingsProvider.notifier)
          .setViewMode(TodayViewMode.list);

      mode = await container.read(todayViewModeProvider.future);
      expect(mode, TodayViewMode.list);
    });
  });
}
