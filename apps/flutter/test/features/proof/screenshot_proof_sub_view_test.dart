import 'dart:async';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/proof/data/proof_repository.dart';
import 'package:ontask/features/proof/domain/proof_verification_result.dart';
import 'package:ontask/features/proof/presentation/screenshot_proof_sub_view.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Widget tests for ScreenshotProofSubView — Story 7.3 (FR36, AC: 1–2).
//
// FilePicker.platform is stubbed via MockFilePicker to avoid native file picker access.
// ProofRepository is mocked via mocktail.

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockProofRepository extends Mock implements ProofRepository {}

/// FilePicker mock that bypasses PlatformInterface token verification.
/// Uses [MockPlatformInterfaceMixin] to satisfy [PlatformInterface.verifyToken].
class MockFilePicker extends Mock
    with MockPlatformInterfaceMixin
    implements FilePicker {}

// ── Pump helper ───────────────────────────────────────────────────────────────

Future<void> pumpSubView(
  WidgetTester tester, {
  required MockProofRepository mockRepo,
  MockFilePicker? mockFilePicker,
  String taskId = 'task-001',
  String taskName = 'Send the report',
}) async {
  if (mockFilePicker != null) {
    FilePicker.platform = mockFilePicker;
  }

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
      home: Scaffold(
        body: ScreenshotProofSubView(
          taskId: taskId,
          taskName: taskName,
          proofRepository: mockRepo,
        ),
      ),
    ),
  );

  await tester.pump();
}

// ── Helper to build a FilePickerResult ────────────────────────────────────────

FilePickerResult makeResult({
  required String name,
  required int size,
  String path = '/tmp/proof.png',
}) {
  return FilePickerResult([
    PlatformFile(
      name: name,
      size: size,
      path: path,
    ),
  ]);
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(XFile(''));
    // FilePicker.pickFiles uses named params with specific types.
    registerFallbackValue(FileType.any);
    registerFallbackValue(<String>[]);
  });

  group('ScreenshotProofSubView — picking state (AC: 1)', () {
    testWidgets(
        '1. Picking state renders proofScreenshotPickCta CTA button',
        (tester) async {
      final mockRepo = MockProofRepository();
      await pumpSubView(tester, mockRepo: mockRepo);

      expect(find.text(AppStrings.proofScreenshotPickCta), findsOneWidget);
    });

    testWidgets(
        '2. Picking state renders proofScreenshotPickSubtitle format hint',
        (tester) async {
      final mockRepo = MockProofRepository();
      await pumpSubView(tester, mockRepo: mockRepo);

      expect(find.text(AppStrings.proofScreenshotPickSubtitle), findsOneWidget);
    });

    testWidgets(
        '3. Tapping CTA when picker returns null stays in picking state',
        (tester) async {
      final mockRepo = MockProofRepository();
      final mockPicker = MockFilePicker();

      when(
        () => mockPicker.pickFiles(
          type: any(named: 'type'),
          allowedExtensions: any(named: 'allowedExtensions'),
          withData: any(named: 'withData'),
          withReadStream: any(named: 'withReadStream'),
        ),
      ).thenAnswer((_) async => null);

      await pumpSubView(tester, mockRepo: mockRepo, mockFilePicker: mockPicker);

      await tester.tap(find.text(AppStrings.proofScreenshotPickCta));
      await tester.pumpAndSettle();

      // Still in picking state — CTA still visible.
      expect(find.text(AppStrings.proofScreenshotPickCta), findsOneWidget);
    });

    testWidgets(
        '4. Tapping CTA when picker returns PNG transitions to preview state',
        (tester) async {
      final mockRepo = MockProofRepository();
      final mockPicker = MockFilePicker();

      when(
        () => mockPicker.pickFiles(
          type: any(named: 'type'),
          allowedExtensions: any(named: 'allowedExtensions'),
          withData: any(named: 'withData'),
          withReadStream: any(named: 'withReadStream'),
        ),
      ).thenAnswer(
        (_) async => makeResult(
          name: 'proof.png',
          size: 1024,
          path: '/tmp/proof.png',
        ),
      );

      await pumpSubView(tester, mockRepo: mockRepo, mockFilePicker: mockPicker);

      await tester.tap(find.text(AppStrings.proofScreenshotPickCta));
      await tester.pumpAndSettle();

      // In preview state — Submit button visible.
      expect(find.text(AppStrings.proofSubmitCta), findsOneWidget);
      expect(find.text(AppStrings.proofScreenshotRetakeCta), findsOneWidget);
    });

    testWidgets(
        '7. File over 25 MB shows proofScreenshotFileTooLargeTitle alert',
        (tester) async {
      final mockRepo = MockProofRepository();
      final mockPicker = MockFilePicker();

      const oversizeBytes = 26 * 1024 * 1024; // 26 MB > 25 MB limit

      when(
        () => mockPicker.pickFiles(
          type: any(named: 'type'),
          allowedExtensions: any(named: 'allowedExtensions'),
          withData: any(named: 'withData'),
          withReadStream: any(named: 'withReadStream'),
        ),
      ).thenAnswer(
        (_) async => makeResult(
          name: 'huge.png',
          size: oversizeBytes,
          path: '/tmp/huge.png',
        ),
      );

      await pumpSubView(tester, mockRepo: mockRepo, mockFilePicker: mockPicker);

      await tester.tap(find.text(AppStrings.proofScreenshotPickCta));
      await tester.pumpAndSettle();

      // Alert dialog with too-large title should be shown.
      expect(
        find.text(AppStrings.proofScreenshotFileTooLargeTitle),
        findsOneWidget,
      );
    });
  });

  group('ScreenshotProofSubView — preview state (AC: 1)', () {
    testWidgets(
        '5. Preview state for PNG shows Image.file widget',
        (tester) async {
      final mockRepo = MockProofRepository();
      final mockPicker = MockFilePicker();

      when(
        () => mockPicker.pickFiles(
          type: any(named: 'type'),
          allowedExtensions: any(named: 'allowedExtensions'),
          withData: any(named: 'withData'),
          withReadStream: any(named: 'withReadStream'),
        ),
      ).thenAnswer(
        (_) async => makeResult(
          name: 'proof.png',
          size: 1024,
          path: '/tmp/proof.png',
        ),
      );

      await pumpSubView(tester, mockRepo: mockRepo, mockFilePicker: mockPicker);
      await tester.tap(find.text(AppStrings.proofScreenshotPickCta));
      await tester.pumpAndSettle();

      // Image.file is present in preview state for a PNG.
      expect(find.byType(Image), findsWidgets);
    });

    testWidgets(
        '6. Preview state for PDF shows doc_fill icon, not Image.file',
        (tester) async {
      final mockRepo = MockProofRepository();
      final mockPicker = MockFilePicker();

      when(
        () => mockPicker.pickFiles(
          type: any(named: 'type'),
          allowedExtensions: any(named: 'allowedExtensions'),
          withData: any(named: 'withData'),
          withReadStream: any(named: 'withReadStream'),
        ),
      ).thenAnswer(
        (_) async => makeResult(
          name: 'report.pdf',
          size: 4096,
          path: '/tmp/report.pdf',
        ),
      );

      await pumpSubView(tester, mockRepo: mockRepo, mockFilePicker: mockPicker);
      await tester.tap(find.text(AppStrings.proofScreenshotPickCta));
      await tester.pumpAndSettle();

      // PDF shows doc_fill icon — no Image.file in PDF preview.
      expect(find.byIcon(CupertinoIcons.doc_fill), findsWidgets);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets(
        '8. Tapping "Choose another" in preview state returns to picking state',
        (tester) async {
      final mockRepo = MockProofRepository();
      final mockPicker = MockFilePicker();

      when(
        () => mockPicker.pickFiles(
          type: any(named: 'type'),
          allowedExtensions: any(named: 'allowedExtensions'),
          withData: any(named: 'withData'),
          withReadStream: any(named: 'withReadStream'),
        ),
      ).thenAnswer(
        (_) async => makeResult(
          name: 'proof.png',
          size: 1024,
          path: '/tmp/proof.png',
        ),
      );

      await pumpSubView(tester, mockRepo: mockRepo, mockFilePicker: mockPicker);

      // Get to preview state.
      await tester.tap(find.text(AppStrings.proofScreenshotPickCta));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.proofScreenshotRetakeCta), findsOneWidget);

      // Tap "Choose another" to return to picking.
      await tester.tap(find.text(AppStrings.proofScreenshotRetakeCta));
      await tester.pumpAndSettle();

      // Back in picking state.
      expect(find.text(AppStrings.proofScreenshotPickCta), findsOneWidget);
    });
  });

  group('ScreenshotProofSubView — verifying state (AC: 2)', () {
    testWidgets(
        '9. Tapping Submit in preview state shows proofVerifyingCopy (verifying state)',
        (tester) async {
      final mockRepo = MockProofRepository();
      final mockPicker = MockFilePicker();

      // Use a delayed completer so widget stays in verifying state for the assertion.
      final completer = Completer<ProofVerificationResult>();
      when(
        () => mockPicker.pickFiles(
          type: any(named: 'type'),
          allowedExtensions: any(named: 'allowedExtensions'),
          withData: any(named: 'withData'),
          withReadStream: any(named: 'withReadStream'),
        ),
      ).thenAnswer(
        (_) async => makeResult(
          name: 'proof.png',
          size: 1024,
          path: '/tmp/proof.png',
        ),
      );

      when(() => mockRepo.submitScreenshotProof(any(), any()))
          .thenAnswer((_) => completer.future);

      await pumpSubView(tester, mockRepo: mockRepo, mockFilePicker: mockPicker);

      // Get to preview state.
      await tester.tap(find.text(AppStrings.proofScreenshotPickCta));
      await tester.pumpAndSettle();

      // Tap Submit.
      await tester.tap(find.text(AppStrings.proofSubmitCta));
      await tester.pump();

      // Verifying state — shows verifying copy.
      expect(find.text(AppStrings.proofVerifyingCopy), findsOneWidget);

      // Complete + pump through timeout timer and auto-dismiss delay.
      completer.complete(const ProofVerificationApproved());
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets(
        '10. Verifying state — approved result — shows proofAcceptedLabel',
        (tester) async {
      final mockRepo = MockProofRepository();
      final mockPicker = MockFilePicker();

      when(
        () => mockPicker.pickFiles(
          type: any(named: 'type'),
          allowedExtensions: any(named: 'allowedExtensions'),
          withData: any(named: 'withData'),
          withReadStream: any(named: 'withReadStream'),
        ),
      ).thenAnswer(
        (_) async => makeResult(
          name: 'proof.png',
          size: 1024,
          path: '/tmp/proof.png',
        ),
      );

      when(() => mockRepo.submitScreenshotProof(any(), any()))
          .thenAnswer((_) async => const ProofVerificationApproved());

      await pumpSubView(tester, mockRepo: mockRepo, mockFilePicker: mockPicker);

      await tester.tap(find.text(AppStrings.proofScreenshotPickCta));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.proofSubmitCta));
      // Pump once to let the async submission complete.
      await tester.pump();
      await tester.pump();

      // Approved state shows accepted label (before auto-dismiss timer fires).
      expect(find.text(AppStrings.proofAcceptedLabel), findsOneWidget);

      // Pump through the 2-second auto-dismiss to clean up pending timers.
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets(
        '11. Verifying state — rejected result — shows rejection reason text',
        (tester) async {
      final mockRepo = MockProofRepository();
      final mockPicker = MockFilePicker();
      const reason = 'The document does not show the completed task.';

      when(
        () => mockPicker.pickFiles(
          type: any(named: 'type'),
          allowedExtensions: any(named: 'allowedExtensions'),
          withData: any(named: 'withData'),
          withReadStream: any(named: 'withReadStream'),
        ),
      ).thenAnswer(
        (_) async => makeResult(
          name: 'proof.pdf',
          size: 4096,
          path: '/tmp/proof.pdf',
        ),
      );

      when(() => mockRepo.submitScreenshotProof(any(), any())).thenAnswer(
        (_) async => const ProofVerificationRejected(reason: reason),
      );

      await pumpSubView(tester, mockRepo: mockRepo, mockFilePicker: mockPicker);

      await tester.tap(find.text(AppStrings.proofScreenshotPickCta));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.proofSubmitCta));
      await tester.pumpAndSettle();

      expect(find.text(reason), findsOneWidget);
    });

    testWidgets(
        '12. Verifying state — rejected result — shows proofDisputeCta button',
        (tester) async {
      final mockRepo = MockProofRepository();
      final mockPicker = MockFilePicker();
      const reason = 'Cannot verify from this document.';

      when(
        () => mockPicker.pickFiles(
          type: any(named: 'type'),
          allowedExtensions: any(named: 'allowedExtensions'),
          withData: any(named: 'withData'),
          withReadStream: any(named: 'withReadStream'),
        ),
      ).thenAnswer(
        (_) async => makeResult(
          name: 'proof.pdf',
          size: 4096,
          path: '/tmp/proof.pdf',
        ),
      );

      when(() => mockRepo.submitScreenshotProof(any(), any())).thenAnswer(
        (_) async => const ProofVerificationRejected(reason: reason),
      );

      await pumpSubView(tester, mockRepo: mockRepo, mockFilePicker: mockPicker);

      await tester.tap(find.text(AppStrings.proofScreenshotPickCta));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.proofSubmitCta));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.proofDisputeCta), findsOneWidget);
    });
  });

  group('ScreenshotProofSubView — rejected state (AC: 2)', () {
    testWidgets(
        '13. "Try another" in rejected state returns to picking state',
        (tester) async {
      final mockRepo = MockProofRepository();
      final mockPicker = MockFilePicker();
      const reason = 'Cannot verify.';

      when(
        () => mockPicker.pickFiles(
          type: any(named: 'type'),
          allowedExtensions: any(named: 'allowedExtensions'),
          withData: any(named: 'withData'),
          withReadStream: any(named: 'withReadStream'),
        ),
      ).thenAnswer(
        (_) async => makeResult(
          name: 'proof.png',
          size: 1024,
          path: '/tmp/proof.png',
        ),
      );

      when(() => mockRepo.submitScreenshotProof(any(), any())).thenAnswer(
        (_) async => const ProofVerificationRejected(reason: reason),
      );

      await pumpSubView(tester, mockRepo: mockRepo, mockFilePicker: mockPicker);

      await tester.tap(find.text(AppStrings.proofScreenshotPickCta));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.proofSubmitCta));
      await tester.pumpAndSettle();

      // In rejected state — "Try another" visible.
      expect(find.text(AppStrings.proofScreenshotRetakeCta), findsOneWidget);

      await tester.tap(find.text(AppStrings.proofScreenshotRetakeCta));
      await tester.pumpAndSettle();

      // Back in picking state.
      expect(find.text(AppStrings.proofScreenshotPickCta), findsOneWidget);
    });
  });

  group('ScreenshotProofSubView — timeout state (AC: 2)', () {
    testWidgets(
        '14. Timeout state shows proofTimeoutCopy after 10s',
        (tester) async {
      final mockRepo = MockProofRepository();
      final mockPicker = MockFilePicker();

      // Never completes — timeout fires after 10 seconds.
      final completer = Completer<ProofVerificationResult>();

      when(
        () => mockPicker.pickFiles(
          type: any(named: 'type'),
          allowedExtensions: any(named: 'allowedExtensions'),
          withData: any(named: 'withData'),
          withReadStream: any(named: 'withReadStream'),
        ),
      ).thenAnswer(
        (_) async => makeResult(
          name: 'proof.png',
          size: 1024,
          path: '/tmp/proof.png',
        ),
      );

      when(() => mockRepo.submitScreenshotProof(any(), any()))
          .thenAnswer((_) => completer.future);

      await pumpSubView(tester, mockRepo: mockRepo, mockFilePicker: mockPicker);

      await tester.tap(find.text(AppStrings.proofScreenshotPickCta));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.proofSubmitCta));
      // Pump once to let the submit handler fire and move to verifying state.
      await tester.pump();

      // Advance fake time past the 10-second timeout.
      await tester.pump(const Duration(seconds: 11));

      expect(find.text(AppStrings.proofTimeoutCopy), findsOneWidget);

      // Complete the pending completer — with the timeout guard, the result is
      // discarded since we've already left the verifying state.
      completer.complete(const ProofVerificationApproved());
      await tester.pump();
    });
  });

  group('ScreenshotProofSubView — string constants (AC: 1–2)', () {
    testWidgets('proofScreenshotPickCta is "Choose a file"', (tester) async {
      expect(AppStrings.proofScreenshotPickCta, 'Choose a file');
    });

    testWidgets(
        'proofScreenshotPickSubtitle contains PNG, JPG, PDF and 25 MB',
        (tester) async {
      expect(AppStrings.proofScreenshotPickSubtitle, contains('PNG'));
      expect(AppStrings.proofScreenshotPickSubtitle, contains('PDF'));
      expect(AppStrings.proofScreenshotPickSubtitle, contains('25 MB'));
    });

    testWidgets(
        'proofScreenshotRetakeCta is "Choose another"', (tester) async {
      expect(AppStrings.proofScreenshotRetakeCta, 'Choose another');
    });

    testWidgets(
        'proofScreenshotFileTooLargeTitle is "File too large"', (tester) async {
      expect(AppStrings.proofScreenshotFileTooLargeTitle, 'File too large');
    });
  });
}
