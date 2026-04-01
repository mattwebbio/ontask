import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;

import '../../../core/l10n/strings.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/theme/app_theme.dart';
import '../data/proof_repository.dart';
import '../domain/proof_path.dart';
import '../domain/proof_verification_result.dart';

// ── State machine ─────────────────────────────────────────────────────────────

/// States for the screenshot/document capture and verification flow.
enum _ScreenshotState {
  picking,
  preview,
  verifying,
  approved,
  rejected,
  timeout,
}

// ── Widget ────────────────────────────────────────────────────────────────────

/// Screenshot/document proof sub-view for the Proof Capture Modal screenshot path.
///
/// Manages its own state machine: picking → preview → verifying → result.
///
/// This is a [StatefulWidget] (NOT [ConsumerStatefulWidget]) — no Riverpod
/// provider reads are needed at widget level. The [ProofRepository] is
/// injected via constructor.
///
/// Supports PNG, JPG, and PDF files up to 25 MB (FR36, AC1).
/// Uses the same AI verification flow as [PhotoCaptureSubView] (AC2).
///
/// On successful verification, calls [Navigator.pop(context, ProofPath.screenshot)]
/// so the caller ([ProofCaptureModal]) can trigger [onApproved].
/// (Epic 7, Story 7.3, AC: 1–2, FR36)
class ScreenshotProofSubView extends StatefulWidget {
  const ScreenshotProofSubView({
    super.key,
    required this.taskId,
    required this.taskName,
    required this.proofRepository,
    this.onApproved,
  });

  /// The task ID used for proof submission.
  final String taskId;

  /// The task name shown for context (future use).
  final String taskName;

  /// Injected proof repository for API submission.
  final ProofRepository proofRepository;

  /// Called when the proof is approved, before the modal is popped.
  final VoidCallback? onApproved;

  @override
  State<ScreenshotProofSubView> createState() => _ScreenshotProofSubViewState();
}

class _ScreenshotProofSubViewState extends State<ScreenshotProofSubView>
    with TickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  _ScreenshotState _screenshotState = _ScreenshotState.picking;

  // ── Picked file ────────────────────────────────────────────────────────────
  XFile? _pickedFile;

  // ── Submission guard ───────────────────────────────────────────────────────
  bool _isSubmitting = false;

  // ── Verification result ────────────────────────────────────────────────────
  String? _rejectionReason;

  // ── Animation (pulsing arc) ────────────────────────────────────────────────
  late AnimationController _arcController;
  bool _reducedMotion = false;

  // ── Approval fade-in ──────────────────────────────────────────────────────
  late AnimationController _approvalFadeController;
  late Animation<double> _approvalFadeAnimation;

  // ── Timeout ───────────────────────────────────────────────────────────────
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _arcController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _approvalFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _approvalFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _approvalFadeController, curve: Curves.easeIn),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = isReducedMotion(context);
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _arcController.dispose();
    _approvalFadeController.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _onPickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'pdf'],
      withData: false,
      withReadStream: false,
    );
    if (!mounted) return;

    if (result == null) {
      // User cancelled — stay in picking state.
      return;
    }

    final platformFile = result.files.single;
    const maxBytes = 25 * 1024 * 1024; // 25 MB

    if (platformFile.size > maxBytes) {
      _showFileTooLargeAlert(context);
      return;
    }

    setState(() {
      _pickedFile = XFile(platformFile.path!);
      _screenshotState = _ScreenshotState.preview;
    });
  }

  void _showFileTooLargeAlert(BuildContext context) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text(AppStrings.proofScreenshotFileTooLargeTitle),
        content: const Text(AppStrings.proofScreenshotFileTooLargeMessage),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  void _onChooseAnother() {
    setState(() {
      _pickedFile = null;
      _screenshotState = _ScreenshotState.picking;
    });
  }

  Future<void> _onSubmit() async {
    if (_isSubmitting) return;
    final file = _pickedFile;
    if (file == null) return;

    setState(() {
      _isSubmitting = true;
      _screenshotState = _ScreenshotState.verifying;
    });

    // Start arc animation (UX-DR30).
    if (!_reducedMotion) {
      _arcController.repeat();
    }

    // Start 10-second timeout.
    _timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      if (_screenshotState == _ScreenshotState.verifying) {
        _arcController.stop();
        _timeoutTimer = null;
        setState(() => _screenshotState = _ScreenshotState.timeout);
      }
    });

    final result = await widget.proofRepository.submitScreenshotProof(
      widget.taskId,
      file,
    );
    if (!mounted) return;

    // Cancel timeout — we got a result.
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _arcController.stop();

    // Guard: if the timeout already fired and moved us out of verifying, ignore result.
    if (_screenshotState != _ScreenshotState.verifying) return;

    switch (result) {
      case ProofVerificationApproved():
        setState(() => _screenshotState = _ScreenshotState.approved);
        _approvalFadeController.forward();
        widget.onApproved?.call();
        // Auto-dismiss after 2 seconds.
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          Navigator.pop(context, ProofPath.screenshot);
        });
      case ProofVerificationRejected(:final reason):
        setState(() {
          _screenshotState = _ScreenshotState.rejected;
          _rejectionReason = reason;
        });
      case ProofVerificationError(:final message):
        setState(() {
          _screenshotState = _ScreenshotState.rejected;
          _rejectionReason = message;
        });
    }
  }

  void _onTryAgain() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _isSubmitting = false;
    setState(() {
      _pickedFile = null;
      _screenshotState = _ScreenshotState.picking;
    });
  }

  void _onBack() {
    Navigator.pop(context, null);
  }

  void _onRequestReview() {
    // TODO(7.8): wire dispute flow — pop with null for now.
    Navigator.pop(context, null);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(colors),
        _buildBody(colors),
      ],
    );
  }

  Widget _buildHeader(OnTaskColors colors) {
    // Show back button only in picking and preview states.
    final showBack = _screenshotState == _ScreenshotState.picking ||
        _screenshotState == _ScreenshotState.preview;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
      child: Row(
        children: [
          if (showBack)
            CupertinoButton(
              minimumSize: const Size(44, 44),
              padding: EdgeInsets.zero,
              onPressed: _onBack,
              child: Icon(
                CupertinoIcons.chevron_left,
                color: colors.accentPrimary,
                size: 20,
              ),
            )
          else
            const SizedBox(width: 44),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildBody(OnTaskColors colors) {
    switch (_screenshotState) {
      case _ScreenshotState.picking:
        return _buildPickingState(colors);
      case _ScreenshotState.preview:
        return _buildPreviewState(colors);
      case _ScreenshotState.verifying:
        return _buildVerifyingState(colors);
      case _ScreenshotState.approved:
        return _buildApprovedState(colors);
      case _ScreenshotState.rejected:
        return _buildRejectedState(colors);
      case _ScreenshotState.timeout:
        return _buildTimeoutState(colors);
    }
  }

  // ── Picking state ──────────────────────────────────────────────────────────

  Widget _buildPickingState(OnTaskColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 24),
          Icon(
            CupertinoIcons.doc,
            color: colors.accentPrimary,
            size: 56,
          ),
          const SizedBox(height: 20),
          Text(
            AppStrings.proofScreenshotPickSubtitle,
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CupertinoButton(
            minimumSize: const Size(44, 44),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
            color: colors.accentPrimary,
            onPressed: _onPickFile,
            child: Text(
              AppStrings.proofScreenshotPickCta,
              style: TextStyle(color: colors.surfacePrimary),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Preview state ──────────────────────────────────────────────────────────

  Widget _buildPreviewState(OnTaskColors colors) {
    final file = _pickedFile;
    final isPdf = file != null && file.path.toLowerCase().endsWith('.pdf');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thumbnail / icon preview.
          SizedBox(
            height: 220,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: file == null
                  ? Container(color: colors.surfacePrimary)
                  : isPdf
                      ? Container(
                          color: colors.surfacePrimary,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.doc_fill,
                                  color: colors.accentPrimary,
                                  size: 64,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  file.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        )
                      : Image.file(
                          File(file.path),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: colors.surfacePrimary,
                                child: const Icon(CupertinoIcons.photo),
                              ),
                        ),
            ),
          ),
          const SizedBox(height: 20),
          // Action buttons.
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onPressed: _onChooseAnother,
                  child: Text(
                    AppStrings.proofScreenshotRetakeCta,
                    style: TextStyle(color: colors.accentPrimary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoButton(
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  color: colors.accentPrimary,
                  onPressed: _onSubmit,
                  child: Text(
                    AppStrings.proofSubmitCta,
                    style: TextStyle(color: colors.surfacePrimary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Verifying state ────────────────────────────────────────────────────────

  Widget _buildVerifyingState(OnTaskColors colors) {
    final file = _pickedFile;
    final isPdf = file != null && file.path.toLowerCase().endsWith('.pdf');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // File thumbnail/icon + pulsing arc overlay.
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: file == null
                      ? Container(color: colors.surfacePrimary)
                      : isPdf
                          ? Container(
                              color: colors.surfacePrimary,
                              width: double.infinity,
                              height: double.infinity,
                              child: Center(
                                child: Icon(
                                  CupertinoIcons.doc_fill,
                                  color: colors.accentPrimary,
                                  size: 64,
                                ),
                              ),
                            )
                          : Image.file(
                              File(file.path),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(color: colors.surfacePrimary),
                            ),
                ),
                // Pulsing arc overlay (UX-DR30).
                _reducedMotion
                    ? CustomPaint(
                        size: const Size(220, 220),
                        painter: _ArcPainter(
                          color: colors.accentPrimary,
                          progress: 0.75,
                        ),
                      )
                    : AnimatedBuilder(
                        animation: _arcController,
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(220, 220),
                            painter: _ArcPainter(
                              color: colors.accentPrimary,
                              progress: _arcController.value,
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.proofVerifyingCopy,
            style: TextStyle(
              fontSize: 15,
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Approved state ─────────────────────────────────────────────────────────

  Widget _buildApprovedState(OnTaskColors colors) {
    final file = _pickedFile;
    final isPdf = file != null && file.path.toLowerCase().endsWith('.pdf');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: file == null
                      ? Container(color: colors.surfacePrimary)
                      : isPdf
                          ? Container(
                              color: colors.surfacePrimary,
                              width: double.infinity,
                              height: double.infinity,
                              child: Center(
                                child: Icon(
                                  CupertinoIcons.doc_fill,
                                  color: colors.accentPrimary,
                                  size: 64,
                                ),
                              ),
                            )
                          : Image.file(
                              File(file.path),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(color: colors.surfacePrimary),
                            ),
                ),
                // Green checkmark fades in (300ms).
                FadeTransition(
                  opacity: _approvalFadeAnimation,
                  child: Semantics(
                    liveRegion: true,
                    child: Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      color: colors.stakeZoneLow,
                      size: 48,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Text(
              AppStrings.proofAcceptedLabel,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: colors.stakeZoneLow,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Rejected state ─────────────────────────────────────────────────────────

  Widget _buildRejectedState(OnTaskColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            liveRegion: true,
            child: Icon(
              CupertinoIcons.exclamationmark_circle,
              color: colors.scheduleCritical,
              size: 48,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.proofRejectedLabel,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: colors.scheduleCritical,
            ),
            textAlign: TextAlign.center,
          ),
          if (_rejectionReason != null) ...[
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(
                _rejectionReason!,
                style: TextStyle(
                  fontSize: 15,
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 20),
          // "Try another" button (secondary).
          CupertinoButton(
            minimumSize: const Size(44, 44),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            onPressed: _onTryAgain,
            child: Text(
              AppStrings.proofScreenshotRetakeCta,
              style: TextStyle(color: colors.accentPrimary),
            ),
          ),
          // "Request review" (dispute) button (primary).
          CupertinoButton(
            minimumSize: const Size(44, 44),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            color: colors.scheduleCritical,
            onPressed: _onRequestReview,
            child: Text(
              AppStrings.proofDisputeCta,
              style: TextStyle(color: colors.surfacePrimary),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Timeout state ──────────────────────────────────────────────────────────

  Widget _buildTimeoutState(OnTaskColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            liveRegion: true,
            child: Icon(
              CupertinoIcons.clock,
              color: colors.scheduleCritical,
              size: 48,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.proofTimeoutCopy,
            style: TextStyle(
              fontSize: 15,
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          CupertinoButton(
            minimumSize: const Size(44, 44),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
            color: colors.accentPrimary,
            onPressed: _onTryAgain,
            child: Text(
              AppStrings.proofRetakeCta,
              style: TextStyle(color: colors.surfacePrimary),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Custom Painter — pulsing arc (UX-DR30) ────────────────────────────────────

/// Draws a sweeping arc around the preview area.
///
/// In normal mode, [progress] is driven by [AnimationController] sweeping
/// 0 → 1 (mapped to 0 → 2π). In reduced-motion mode, [progress] is fixed
/// at 0.75 (showing a static 270° arc).
///
/// Arc motif references the commitment arc (UX-DR30):
/// "Not a generic spinner — the arc references the commitment arc motif."
class _ArcPainter extends CustomPainter {
  const _ArcPainter({
    required this.color,
    required this.progress,
  });

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 6;
    final sweepAngle = progress * 2 * math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start at top (12 o'clock).
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
