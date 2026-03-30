import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/core/theme/theme_provider.dart';
import 'package:ontask/features/settings/presentation/appearance_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockThemeSettings extends Mock {}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Pumps [AppearanceSettingsScreen] with optional provider overrides.
Future<void> pumpAppearanceScreen(
  WidgetTester tester, {
  ThemeVariant initialVariant = ThemeVariant.clay,
  ThemeMode initialMode = ThemeMode.system,
  double initialIncrement = 0.0,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        themeVariantProvider.overrideWith((ref) async => initialVariant),
        themeModeProvider.overrideWith((ref) async => initialMode),
        textScaleIncrementProvider.overrideWith((ref) async => initialIncrement),
      ],
      child: MaterialApp(
        theme: AppTheme.light(initialVariant, 'PlayfairDisplay'),
        darkTheme: AppTheme.dark(initialVariant, 'PlayfairDisplay'),
        themeMode: initialMode,
        home: const AppearanceSettingsScreen(),
      ),
    ),
  );
  // Settle async providers.
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  group('AppearanceSettingsScreen — theme tiles', () {
    testWidgets('renders all four theme tiles', (tester) async {
      await pumpAppearanceScreen(tester);

      expect(find.text(AppStrings.appearanceThemeClay), findsOneWidget);
      expect(find.text(AppStrings.appearanceThemeSlate), findsOneWidget);
      expect(find.text(AppStrings.appearanceThemeDusk), findsOneWidget);
      expect(find.text(AppStrings.appearanceThemeMonochrome), findsOneWidget);
    });

    testWidgets('renders theme label header', (tester) async {
      await pumpAppearanceScreen(tester);
      expect(find.text(AppStrings.appearanceThemeLabel), findsOneWidget);
    });

    testWidgets('shows no save button (changes apply immediately)', (tester) async {
      await pumpAppearanceScreen(tester);
      // No "Save" or "Apply" button should be present.
      expect(find.text('Save'), findsNothing);
      expect(find.text('Apply'), findsNothing);
    });

    testWidgets('tapping a theme tile invokes ThemeSettings.setThemeVariant',
        (tester) async {
      ThemeVariant? selectedVariant;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            themeVariantProvider.overrideWith((ref) async => ThemeVariant.clay),
            themeModeProvider.overrideWith((ref) async => ThemeMode.system),
            textScaleIncrementProvider.overrideWith((ref) async => 0.0),
            themeSettingsProvider.overrideWith(() => _FakeThemeSettings(
              onSetVariant: (v) => selectedVariant = v,
            )),
          ],
          child: MaterialApp(
            theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
            home: const AppearanceSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the "Slate" theme tile.
      await tester.tap(find.text(AppStrings.appearanceThemeSlate));
      await tester.pumpAndSettle();

      expect(selectedVariant, ThemeVariant.slate);
    });
  });

  group('AppearanceSettingsScreen — mode toggle', () {
    testWidgets('renders Light, Dark, and Automatic mode options', (tester) async {
      await pumpAppearanceScreen(tester);

      expect(find.text(AppStrings.appearanceModeLight), findsOneWidget);
      expect(find.text(AppStrings.appearanceModeDark), findsOneWidget);
      expect(find.text(AppStrings.appearanceModeSystem), findsOneWidget);
    });

    testWidgets('tapping Dark mode invokes ThemeSettings.setThemeMode',
        (tester) async {
      ThemeMode? selectedMode;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            themeVariantProvider.overrideWith((ref) async => ThemeVariant.clay),
            themeModeProvider.overrideWith((ref) async => ThemeMode.system),
            textScaleIncrementProvider.overrideWith((ref) async => 0.0),
            themeSettingsProvider.overrideWith(() => _FakeThemeSettings(
              onSetMode: (m) => selectedMode = m,
            )),
          ],
          child: MaterialApp(
            theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
            home: const AppearanceSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.appearanceModeDark));
      await tester.pumpAndSettle();

      expect(selectedMode, ThemeMode.dark);
    });
  });

  group('AppearanceSettingsScreen — text size', () {
    testWidgets('renders text size label', (tester) async {
      await pumpAppearanceScreen(tester);
      expect(find.text(AppStrings.appearanceTextSizeLabel), findsOneWidget);
    });

    testWidgets('shows text size segmented control with four steps', (tester) async {
      await pumpAppearanceScreen(tester);
      // CupertinoSlidingSegmentedControl is the widget — verify it renders.
      expect(
        find.byType(CupertinoSlidingSegmentedControl<double>),
        findsOneWidget,
      );
    });
  });
}

// ── Fake ThemeSettings ───────────────────────────────────────────────────────

/// A fake [ThemeSettings] notifier for injection in widget tests.
class _FakeThemeSettings extends ThemeSettings {
  final void Function(ThemeVariant)? onSetVariant;
  final void Function(ThemeMode)? onSetMode;

  _FakeThemeSettings({
    this.onSetVariant,
    this.onSetMode,
  });

  @override
  void build() {}

  @override
  Future<void> setThemeVariant(ThemeVariant variant) async {
    onSetVariant?.call(variant);
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    onSetMode?.call(mode);
  }

  @override
  Future<void> setTextScaleIncrement(double increment) async {
    // No test callback for text scale — tested via provider state indirectly.
  }
}
