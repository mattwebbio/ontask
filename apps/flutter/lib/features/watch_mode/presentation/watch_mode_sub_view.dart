import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../disputes/presentation/dispute_confirmation_view.dart';
import '../../now/presentation/widgets/now_task_card.dart';
import '../../proof/data/proof_prefs_provider.dart';
import '../../proof/data/proof_repository.dart';
import '../../proof/domain/proof_path.dart';
import '../../proof/domain/proof_verification_result.dart';
import '../domain/watch_mode_session.dart';

// ── State machine ─────────────────────────────────────────────────────────────

/// States for the Watch Mode live session flow.
enum _WatchModeState {
  idle,
  starting,
  active,
  ending,
  summary,
  submitting,
  approved,
  rejected,
  timeout,
  disputed,
}

// ── Constants ─────────────────────────────────────────────────────────────────

/// Frame polling interval in seconds — midpoint of 30–60s per ARCH-32.
const int _pollIntervalSeconds = 45;

// ── Widget ────────────────────────────────────────────────────────────────────

/// Watch Mode live session sub-view for the Proof Capture Modal healthKit path.
///
/// Manages its own state machine: idle → starting → active → ending → summary
/// → submitting → result.
///
/// Migrated to [ConsumerStatefulWidget] in Story 7.7 to read
/// [proofRetainDefaultProvider] and present the retention toggle after approval.
/// The retention toggle only appears in the [_WatchModeState.approved] state —
/// NOT triggered from [_onDone] (deferred bug noted in deferred-work.md).
/// The [ProofRepository] is injected via constructor.
///
/// Watch Mode is a focus mode — NOT a proof-filing mode (UX spec line 1031–1032).
/// The active state deliberately shows NO camera preview — only a minimal overlay.
///
/// Frames are captured silently and immediately discarded after stub analysis
/// (NFR-S3 — no frame stored at any point).
///
/// Watch Mode is iOS-only (UX-DR10). The [assert] in [build] fires in debug
/// builds if this widget is somehow constructed on macOS.
///
/// On successful verification, presents the retention choice and then calls
/// [onApproved] + [Navigator.pop(context, ProofPath.watchMode)] on Confirm.
/// (Epic 7, Stories 7.4, 7.7, AC: 1–4, FR33-34, FR38, FR66-67, UX-DR10)
class WatchModeSubView extends ConsumerStatefulWidget {
  const WatchModeSubView({
    super.key,
    required this.taskId,
    required this.taskName,
    required this.proofRepository,
    this.onApproved,
  });

  final String taskId;
  final String taskName;
  final ProofRepository proofRepository;
  final VoidCallback? onApproved;

  @override
  ConsumerState<WatchModeSubView> createState() => _WatchModeSubViewState();
}

class _WatchModeSubViewState extends ConsumerState<WatchModeSubView>
    with TickerProviderStateMixin {
  // ── State machine ──────────────────────────────────────────────────────────
  _WatchModeState _watchState = _WatchModeState.idle;

  // ── Submission guard ───────────────────────────────────────────────────────
  bool _isSubmitting = false;

  // ── Dispute submission guard ───────────────────────────────────────────────
  bool _isDisputeSubmitting = false;

  // ── Retention preference ───────────────────────────────────────────────────
  bool _retainProof = true;

  // ── Camera ─────────────────────────────────────────────────────────────────
  CameraController? _cameraController;
  String? _cameraError;

  // ── Session tracking ───────────────────────────────────────────────────────
  DateTime? _startedAt;
  WatchModeSession? _session;
  int _elapsedSeconds = 0;
  int _totalFrames = 0;
  int _detectedActivityFrames = 0;

  // ── Timers ─────────────────────────────────────────────────────────────────
  Timer? _sessionTimer;
  Timer? _framePollingTimer;
  Timer? _timeoutTimer;

  // ── Animation controllers ──────────────────────────────────────────────────
  /// Pulsing arc — submitting state (same pattern as PhotoCaptureSubView).
  late AnimationController _arcController;

  /// Approval fade-in — approved state (300ms ease-in).
  late AnimationController _approvalFadeController;
  late Animation<double> _approvalFadeAnimation;

  /// Camera indicator pulse — active state (red dot, 1s period).
  late AnimationController _cameraIndicatorController;

  // ── Motion ─────────────────────────────────────────────────────────────────
  bool _reducedMotion = false;

  // ── Rejection reason ───────────────────────────────────────────────────────
  String? _rejectionReason;

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
    _cameraIndicatorController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    // Read synchronously from provider cache — keepAlive provider is pre-loaded.
    // Falls back to true if not yet resolved.
    _retainProof = ref.read(proofRetainDefaultProvider).value ?? true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = isReducedMotion(context);
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _framePollingTimer?.cancel();
    _timeoutTimer?.cancel();
    _arcController.dispose();
    _approvalFadeController.dispose();
    _cameraIndicatorController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  // ── Camera init ────────────────────────────────────────────────────────────

  Future<void> _initWatchMode() async {
    setState(() => _watchState = _WatchModeState.starting);
    try {
      final cameras = await availableCameras();
      if (!mounted) return;
      if (cameras.isEmpty) {
        setState(() {
          _cameraError = AppStrings.watchModeNoCameraError;
          _watchState = _WatchModeState.idle;
        });
        return;
      }
      final controller = CameraController(
        cameras.first,
        ResolutionPreset.low,
        enableAudio: false,
      );
      _cameraController = controller;
      await controller.initialize();
      if (!mounted) return;
      _startedAt = DateTime.now();
      setState(() => _watchState = _WatchModeState.active);
      _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _elapsedSeconds++);
      });
      if (!_reducedMotion) {
        _cameraIndicatorController.repeat(reverse: true);
      }
      _startFramePolling();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cameraError = AppStrings.watchModeNoCameraError;
        _watchState = _WatchModeState.idle;
      });
    }
  }

  // ── Frame polling ──────────────────────────────────────────────────────────

  void _startFramePolling() {
    _framePollingTimer = Timer.periodic(
      Duration(seconds: _pollIntervalSeconds),
      (_) {
        if (_watchState != _WatchModeState.active) {
          _framePollingTimer?.cancel();
          return;
        }
        _captureAndAnalyzeFrame();
      },
    );
  }

  Future<void> _captureAndAnalyzeFrame() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      final frame = await controller.takePicture();
      // Stub AI analysis — real call deferred.
      // TODO(impl): call packages/ai/src/watch-mode.ts via API for real frame analysis
      _totalFrames++;
      if (math.Random().nextBool()) _detectedActivityFrames++;
      // Discard frame immediately — NFR-S3: no frame stored at any point.
      try {
        File(frame.path).deleteSync();
      } catch (e) {
        /* ignore delete errors */
      }
      if (!mounted) return;
    } catch (e) {
      debugPrint('WatchModeSubView: frame capture error: $e');
    }
  }

  // ── End session ────────────────────────────────────────────────────────────

  void _onEndSession() {
    _sessionTimer?.cancel();
    _framePollingTimer?.cancel();
    _cameraIndicatorController.stop();
    final endedAt = DateTime.now();
    _session = WatchModeSession(
      taskId: widget.taskId,
      taskName: widget.taskName,
      startedAt: _startedAt ?? endedAt,
      endedAt: endedAt,
      detectedActivityFrames: _detectedActivityFrames,
      totalFrames: _totalFrames,
    );
    setState(() => _watchState = _WatchModeState.summary);
  }

  // ── Submit proof ───────────────────────────────────────────────────────────

  Future<void> _onSubmitProof() async {
    if (_isSubmitting) return;
    final session = _session;
    if (session == null) return;
    setState(() {
      _isSubmitting = true;
      _watchState = _WatchModeState.submitting;
    });

    if (!_reducedMotion) {
      _arcController.repeat();
    }

    // Start 10s timeout.
    _timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      if (_watchState == _WatchModeState.submitting) {
        _arcController.stop();
        _timeoutTimer = null;
        setState(() => _watchState = _WatchModeState.timeout);
      }
    });

    final result = await widget.proofRepository.submitWatchModeProof(
      widget.taskId,
      session,
    );
    if (!mounted) return;

    // Cancel timeout — result arrived.
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _arcController.stop();

    // Guard: don't overwrite timeout state if it fired first.
    if (_watchState != _WatchModeState.submitting) return;

    switch (result) {
      case ProofVerificationApproved():
        setState(() {
          _watchState = _WatchModeState.approved;
          _isSubmitting = false;
        });
        _approvalFadeController.forward();
        // Do NOT auto-dismiss — wait for user to confirm retention choice.
      case ProofVerificationRejected(:final reason):
        setState(() {
          _watchState = _WatchModeState.rejected;
          _rejectionReason = reason;
          _isSubmitting = false;
        });
      case ProofVerificationError(:final message):
        setState(() {
          _watchState = _WatchModeState.rejected;
          _rejectionReason = message;
          _isSubmitting = false;
        });
    }
  }

  Future<void> _onConfirmRetention() async {
    try {
      await widget.proofRepository.setProofRetention(
        widget.taskId,
        retain: _retainProof,
      );
      if (!mounted) return;
      widget.onApproved?.call();
      Navigator.pop(context, ProofPath.watchMode);
    } catch (e) {
      debugPrint('WatchModeSubView: setProofRetention error: $e');
      if (!mounted) return;
      // Show error state — reuse proofRetakeCta or add new error string
    }
  }

  void _onDone() {
    Navigator.pop(context, ProofPath.watchMode);
  }

  void _onBack() {
    Navigator.pop(context, null);
  }

  Future<void> _onRequestReview() async {
    if (_isDisputeSubmitting) return;
    setState(() => _isDisputeSubmitting = true);
    try {
      await widget.proofRepository.fileDispute(widget.taskId);
      if (!mounted) return;
      setState(() => _watchState = _WatchModeState.disputed);
    } catch (e) {
      debugPrint('WatchModeSubView: fileDispute error: $e');
      if (!mounted) return;
      setState(() => _isDisputeSubmitting = false);
      // Show error inline — reuse existing error pattern (timeout or rejection reason text)
    }
  }

  void _onTryAgain() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    setState(() => _watchState = _WatchModeState.summary);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // macOS guard — debug-mode safety net (UX-DR10).
    // Skipped in test environments where Platform.isMacOS may be true.
    assert(
      Platform.environment.containsKey('FLUTTER_TEST') || !Platform.isMacOS,
      'WatchModeSubView must not be constructed on macOS (UX-DR10)',
    );
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
    final showBack = _watchState == _WatchModeState.idle;
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
    switch (_watchState) {
      case _WatchModeState.idle:
        return _buildIdleState(colors);
      case _WatchModeState.starting:
        return _buildStartingState(colors);
      case _WatchModeState.active:
        return _buildActiveState(colors);
      case _WatchModeState.ending:
        return _buildEndingState(colors);
      case _WatchModeState.summary:
        return _buildSummaryState(colors);
      case _WatchModeState.submitting:
        return _buildSubmittingState(colors);
      case _WatchModeState.approved:
        return _buildApprovedState(colors);
      case _WatchModeState.rejected:
        return _buildRejectedState(colors);
      case _WatchModeState.timeout:
        return _buildTimeoutState(colors);
      case _WatchModeState.disputed:
        return _buildDisputedState(colors);
    }
  }

  Widget _buildDisputedState(OnTaskColors colors) {
    return DisputeConfirmationView(
      onDone: () => Navigator.pop(context, null),
    );
  }

  // ── Idle state ─────────────────────────────────────────────────────────────

  Widget _buildIdleState(OnTaskColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Text(
            AppStrings.watchModeTitle,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppStrings.watchModePrivacyNote,
            style: TextStyle(
              fontSize: 15,
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (_cameraError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _cameraError!,
              style: TextStyle(
                fontSize: 14,
                color: colors.scheduleCritical,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              minimumSize: const Size(44, 44),
              color: colors.accentPrimary,
              borderRadius: BorderRadius.circular(AppSpacing.md),
              onPressed: _initWatchMode,
              child: Text(
                AppStrings.watchModeStartCta,
                style: TextStyle(
                  color: colors.surfacePrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  // ── Starting state ─────────────────────────────────────────────────────────

  Widget _buildStartingState(OnTaskColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
      child: Center(
        child: CupertinoActivityIndicator(color: colors.accentPrimary),
      ),
    );
  }

  // ── Active state ───────────────────────────────────────────────────────────

  Widget _buildActiveState(OnTaskColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.md),
          // Camera indicator — pulsing red dot (UX-DR10).
          _buildCameraIndicator(colors),
          const SizedBox(height: AppSpacing.md),
          // Task name.
          Text(
            widget.taskName,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          // Elapsed timer — M:SS format.
          Text(
            NowTaskCard.formatElapsed(_elapsedSeconds),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          // End Session button — secondary/critical style.
          CupertinoButton(
            minimumSize: const Size(44, 44),
            color: colors.scheduleCritical,
            borderRadius: BorderRadius.circular(AppSpacing.md),
            onPressed: _onEndSession,
            child: Text(
              AppStrings.watchModeEndSessionCta,
              style: TextStyle(
                color: colors.surfacePrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildCameraIndicator(OnTaskColors colors) {
    final dot = Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.scheduleCritical,
      ),
    );
    if (_reducedMotion) {
      return dot;
    }
    return AnimatedBuilder(
      animation: _cameraIndicatorController,
      builder: (context, child) {
        // Scale from 1.0 to ~1.17 (12pt → 14pt).
        final scale = 1.0 + (_cameraIndicatorController.value * 0.167);
        return Transform.scale(scale: scale, child: child);
      },
      child: dot,
    );
  }

  // ── Ending state ───────────────────────────────────────────────────────────

  Widget _buildEndingState(OnTaskColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoActivityIndicator(color: colors.accentPrimary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.watchModeEndingCopy,
            style: TextStyle(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ── Summary state ──────────────────────────────────────────────────────────

  Widget _buildSummaryState(OnTaskColors colors) {
    final session = _session;
    final durationLabel = session != null
        ? session.elapsed.inMinutes >= 1
            ? '${session.elapsed.inMinutes} min'
            : '${session.elapsed.inSeconds}s'
        : '0s';
    final activityLabel = session != null
        ? '${session.activityPercentage.round()}% activity detected'
        : '0% activity detected';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text(
            AppStrings.watchModeSummaryTitle,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            durationLabel,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            activityLabel,
            style: TextStyle(
              fontSize: 15,
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          // Submit as proof button — shown for staked tasks (always shown in Story 7.4).
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              minimumSize: const Size(44, 44),
              color: colors.accentPrimary,
              borderRadius: BorderRadius.circular(AppSpacing.md),
              onPressed: _onSubmitProof,
              child: Text(
                AppStrings.watchModeSubmitProofCta,
                style: TextStyle(
                  color: colors.surfacePrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Done button — secondary, exits without submitting.
          CupertinoButton(
            minimumSize: const Size(44, 44),
            onPressed: _onDone,
            child: Text(
              AppStrings.watchModeDoneCta,
              style: TextStyle(color: colors.accentPrimary),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  // ── Submitting state ───────────────────────────────────────────────────────

  Widget _buildSubmittingState(OnTaskColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _reducedMotion
                    ? CustomPaint(
                        size: const Size(160, 160),
                        painter: _ArcPainter(
                          color: colors.accentPrimary,
                          progress: 0.75,
                        ),
                      )
                    : AnimatedBuilder(
                        animation: _arcController,
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(160, 160),
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
            AppStrings.watchModeSubmittingCopy,
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
          const SizedBox(height: AppSpacing.lg),
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
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Text(
              AppStrings.watchModeApprovedLabel,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: colors.stakeZoneLow,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          // ── Retention toggle (FR38, Story 7.7) ──────────────────────────────
          // Only shown in the approved state — NOT triggered from _onDone().
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.proofRetainLabel,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _retainProof
                          ? AppStrings.proofRetainSubtitle
                          : AppStrings.proofDiscardSubtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: _retainProof,
                activeTrackColor: colors.accentPrimary,
                onChanged: (value) => setState(() => _retainProof = value),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              minimumSize: const Size(44, 44),
              color: colors.accentPrimary,
              borderRadius: BorderRadius.circular(AppSpacing.md),
              onPressed: _onConfirmRetention,
              child: Text(
                AppStrings.proofRetainConfirmCta,
                style: TextStyle(
                  color: colors.surfacePrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
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
          if (_rejectionReason != null) ...[
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
            const SizedBox(height: 20),
          ],
          CupertinoButton(
            minimumSize: const Size(44, 44),
            color: colors.scheduleCritical,
            borderRadius: BorderRadius.circular(AppSpacing.md),
            onPressed: _onRequestReview,
            child: Text(
              AppStrings.proofDisputeCta,
              style: TextStyle(
                color: colors.surfacePrimary,
                fontWeight: FontWeight.w600,
              ),
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
            borderRadius: BorderRadius.circular(AppSpacing.md),
            onPressed: _onTryAgain,
            child: Text(
              AppStrings.watchModeTryAgainCta,
              style: TextStyle(
                color: colors.surfacePrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Custom Painter — pulsing arc (UX-DR30) ────────────────────────────────────

/// Draws a sweeping arc during the submitting state.
///
/// Kept per-file per established pattern (not shared with [PhotoCaptureSubView]
/// or [ScreenshotProofSubView]).
///
/// In normal mode, [progress] is driven by [AnimationController] sweeping
/// 0 → 1 (mapped to 0 → 2π). In reduced-motion mode, [progress] is fixed
/// at 0.75 (showing a static 270° arc).
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
