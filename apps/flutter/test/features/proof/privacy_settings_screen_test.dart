import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/proof/data/proof_prefs_provider.dart';
import 'package:ontask/features/settings/presentation/privacy_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Widget tests for PrivacySettingsScreen — Story 7.7 (AC: 2, FR38).
//
// Tests the retention toggle rendering, provider binding, and write behaviour.

// ── Mock notifier ─────────────────────────────────────────────────────────────

class MockProofRetainSettings extends Mock {}

// ── Pump helpers ──────────────────────────────────────────────────────────────

/// Pumps [PrivacySettingsScreen] with an overridden [proofRetainDefaultProvider]
/// returning [initialValue]. Captures calls to [ProofRetainSettings.setRetainDefault]
/// via [onSetRetainDefault].
Future<void> pumpPrivacyScreen(
  WidgetTester tester, {
  bool initialValue = true,
  bool isLoading = false,
  void Function(bool)? onSetRetainDefault,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        proofRetainDefaultProvider.overrideWith(
          (ref) async {
            if (isLoading) {
              // Simulate never-resolving future for loading state.
              await Future<bool>.delayed(const Duration(minutes: 1));
            }
            return initialValue;
          },
        ),
        proofRetainSettingsProvider.overrideWith(
          () => _FakeProofRetainSettings(
            onSetRetainDefault: onSetRetainDefault,
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: const PrivacySettingsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// ── Fake notifier ─────────────────────────────────────────────────────────────

class _FakeProofRetainSettings extends ProofRetainSettings {
  _FakeProofRetainSettings({this.onSetRetainDefault});

  final void Function(bool)? onSetRetainDefault;

  @override
  void build() {}

  @override
  Future<void> setRetainDefault(bool retain) async {
    onSetRetainDefault?.call(retain);
  }
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  group('PrivacySettingsScreen — AC: 2, FR38', () {
    testWidgets(
        '1. Screen renders "Keep proof by default" toggle',
        (tester) async {
      await pumpPrivacyScreen(tester);

      expect(
        find.text(AppStrings.privacyKeepProofByDefault),
        findsOneWidget,
      );
      expect(find.byType(CupertinoSwitch), findsOneWidget);
    });

    testWidgets(
        '2. Toggle reflects proofRetainDefaultProvider value (default: true)',
        (tester) async {
      await pumpPrivacyScreen(tester, initialValue: true);

      final switchWidget = tester.widget<CupertinoSwitch>(
        find.byType(CupertinoSwitch),
      );
      expect(switchWidget.value, isTrue);
    });

    testWidgets(
        '2b. Toggle reflects proofRetainDefaultProvider value when false',
        (tester) async {
      await pumpPrivacyScreen(tester, initialValue: false);

      final switchWidget = tester.widget<CupertinoSwitch>(
        find.byType(CupertinoSwitch),
      );
      expect(switchWidget.value, isFalse);
    });

    testWidgets(
        '3. Tapping toggle calls ProofRetainSettings.setRetainDefault(false) when previously true',
        (tester) async {
      bool? capturedValue;

      await pumpPrivacyScreen(
        tester,
        initialValue: true,
        onSetRetainDefault: (v) => capturedValue = v,
      );

      await tester.tap(find.byType(CupertinoSwitch));
      await tester.pumpAndSettle();

      expect(capturedValue, isFalse);
    });

    testWidgets(
        '4. CupertinoActivityIndicator shown while proofRetainDefaultProvider is loading',
        (tester) async {
      // Use a completer so we can control exactly when the future resolves.
      final completer = Completer<bool>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            proofRetainDefaultProvider.overrideWith(
              (ref) => completer.future,
            ),
            proofRetainSettingsProvider.overrideWith(
              () => _FakeProofRetainSettings(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
            home: const PrivacySettingsScreen(),
          ),
        ),
      );
      // Pump once to allow the widget tree to build but NOT resolve the future.
      await tester.pump();

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);

      // Resolve the future to avoid pending timer warnings.
      completer.complete(true);
      await tester.pumpAndSettle();
    });
  });

  group('PrivacySettingsScreen — navigation bar', () {
    testWidgets('navigation bar title is "Privacy"', (tester) async {
      await pumpPrivacyScreen(tester);

      expect(find.text(AppStrings.settingsPrivacy), findsAtLeastNWidgets(1));
    });
  });

  group('PrivacySettingsScreen — subtitle text', () {
    testWidgets('subtitle copy is present', (tester) async {
      await pumpPrivacyScreen(tester);

      expect(find.text(AppStrings.privacyKeepProofSubtitle), findsOneWidget);
    });
  });
}
