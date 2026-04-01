import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;

import '../../../core/l10n/strings.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/theme/app_theme.dart';
import '../data/proof_repository.dart';
import '../domain/proof_path.dart';
import '../domain/proof_verification_result.dart';

// ── State machine ─────────────────────────────────────────────────────────────

/// States for the photo capture and verification flow.
enum _CaptureState {
  camera,
  captured,
  verifying,
  approved,
  rejected,
  timeout,
}

// ── Widget ────────────────────────────────────────────────────────────────────

/// Camera-capture sub-view for the Proof Capture Modal photo path.
///
/// Manages its own state machine: camera → capture → review → verify → result.
///
/// This is a [StatefulWidget] (NOT [ConsumerStatefulWidget]) — no Riverpod
/// provider reads are needed at widget level. The [ProofRepository] is
/// injected via constructor.
///
/// On successful verification, calls [Navigator.pop(context, ProofPath.photo)]
/// so the caller ([ProofCaptureModal]) can trigger [onComplete].
/// (Epic 7, Story 7.2, AC: 1–5, FR31-32, UX-DR30)
class PhotoCaptureSubView extends StatefulWidget {
  const PhotoCaptureSubView({
    super.key,
    required this.taskId,
    required this.taskName,
    required this.proofRepository,
  });

  /// The task ID used for proof submission.
  final String taskId;

  /// The task name shown for context (future use).
  final String taskName;

  /// Injected proof repository for API submission.
  final ProofRepository proofRepository;

  @override
  State<PhotoCaptureSubView> createState() => _PhotoCaptureSubViewState();
}

class _PhotoCaptureSubViewState extends State<PhotoCaptureSubView>
    with TickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  _CaptureState _captureState = _CaptureState.camera;

  // ── Camera ─────────────────────────────────────────────────────────────────
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _cameraInitialized = false;
  String? _cameraError;

  // ── Captured file ──────────────────────────────────────────────────────────
  XFile? _capturedFile;

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
    _initCamera();
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
    _cameraController?.dispose();
    super.dispose();
  }

  // ── Camera lifecycle ───────────────────────────────────────────────────────

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (!mounted) return;
        setState(() => _cameraError = 'No camera found on this device.');
        return;
      }
      final controller = CameraController(
        _cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      _cameraController = controller;
      await controller.initialize();
      if (!mounted) return;
      setState(() => _cameraInitialized = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _cameraError = 'Could not access camera.');
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _onShutterTap() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      final file = await controller.takePicture();
      if (!mounted) return;
      setState(() {
        _capturedFile = file;
        _captureState = _CaptureState.captured;
      });
    } catch (e) {
      // Camera error — stay in camera state; user can retry.
    }
  }

  void _onRetake() {
    setState(() {
      _capturedFile = null;
      _captureState = _CaptureState.camera;
    });
  }

  Future<void> _onSubmit() async {
    final file = _capturedFile;
    if (file == null) return;

    setState(() => _captureState = _CaptureState.verifying);

    // Start arc animation (UX-DR30).
    if (!_reducedMotion) {
      _arcController.repeat();
    }

    // Start 10-second timeout.
    _timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      if (_captureState == _CaptureState.verifying) {
        _arcController.stop();
        _timeoutTimer = null;
        setState(() => _captureState = _CaptureState.timeout);
      }
    });

    final result = await widget.proofRepository.submitPhotoProof(
      widget.taskId,
      file,
    );
    if (!mounted) return;

    // Cancel timeout — we got a result.
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _arcController.stop();

    switch (result) {
      case ProofVerificationApproved():
        setState(() => _captureState = _CaptureState.approved);
        _approvalFadeController.forward();
        // Auto-dismiss after 2 seconds.
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          Navigator.pop(context, ProofPath.photo);
        });
      case ProofVerificationRejected(:final reason):
        setState(() {
          _captureState = _CaptureState.rejected;
          _rejectionReason = reason;
        });
      case ProofVerificationError(:final message):
        setState(() {
          _captureState = _CaptureState.rejected;
          _rejectionReason = message;
        });
    }
  }

  void _onTryAgain() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    setState(() {
      _capturedFile = null;
      _captureState = _CaptureState.camera;
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
    // Only show back button in camera and captured states.
    final showBack = _captureState == _CaptureState.camera ||
        _captureState == _CaptureState.captured;

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
    switch (_captureState) {
      case _CaptureState.camera:
        return _buildCameraState(colors);
      case _CaptureState.captured:
        return _buildCapturedState(colors);
      case _CaptureState.verifying:
        return _buildVerifyingState(colors);
      case _CaptureState.approved:
        return _buildApprovedState(colors);
      case _CaptureState.rejected:
        return _buildRejectedState(colors);
      case _CaptureState.timeout:
        return _buildTimeoutState(colors);
    }
  }

  // ── Camera state ───────────────────────────────────────────────────────────

  Widget _buildCameraState(OnTaskColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Camera preview area.
          SizedBox(
            height: 220,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildCameraPreview(colors),
            ),
          ),
          const SizedBox(height: 24),
          // Shutter button.
          Semantics(
            label: AppStrings.proofShutterLabel,
            button: true,
            child: GestureDetector(
              onTap: _cameraInitialized ? _onShutterTap : null,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _cameraInitialized
                      ? colors.accentPrimary
                      : colors.accentPrimary.withValues(alpha: 0.4),
                ),
                child: Icon(
                  CupertinoIcons.circle_fill,
                  color: colors.surfacePrimary,
                  size: 32,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCameraPreview(OnTaskColors colors) {
    if (_cameraError != null) {
      return Container(
        color: colors.surfacePrimary,
        child: Center(
          child: Text(
            _cameraError!,
            style: TextStyle(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (!_cameraInitialized || _cameraController == null) {
      return Container(
        color: colors.surfacePrimary,
        child: Center(
          child: CupertinoActivityIndicator(color: colors.accentPrimary),
        ),
      );
    }
    return CameraPreview(_cameraController!);
  }

  // ── Captured / review state ────────────────────────────────────────────────

  Widget _buildCapturedState(OnTaskColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thumbnail preview.
          SizedBox(
            height: 220,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _capturedFile != null
                  ? Image.network(
                      _capturedFile!.path,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: colors.surfacePrimary,
                        child: const Icon(CupertinoIcons.photo),
                      ),
                    )
                  : Container(color: colors.surfacePrimary),
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
                  onPressed: _onRetake,
                  child: Text(
                    AppStrings.proofRetakeCta,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thumbnail + pulsing arc overlay.
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _capturedFile != null
                      ? Image.network(
                          _capturedFile!.path,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: colors.surfacePrimary),
                        )
                      : Container(color: colors.surfacePrimary),
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
                  child: _capturedFile != null
                      ? Image.network(
                          _capturedFile!.path,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: colors.surfacePrimary),
                        )
                      : Container(color: colors.surfacePrimary),
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
          // Retake button (secondary).
          CupertinoButton(
            minimumSize: const Size(44, 44),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            onPressed: _onRetake,
            child: Text(
              AppStrings.proofRetakeCta,
              style: TextStyle(color: colors.accentPrimary),
            ),
          ),
          // Request review (dispute) button (primary).
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

/// Draws a sweeping arc around the image preview area.
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
