import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/disputes/presentation/dispute_confirmation_view.dart';
import '../data/proof_prefs_provider.dart';
import '../data/proof_repository.dart';
import '../domain/health_kit_verification_data.dart';
import '../domain/proof_path.dart';
import '../domain/proof_verification_result.dart';

// ── State machine ─────────────────────────────────────────────────────────────

/// States for the HealthKit Auto-Verify flow.
enum _HealthKitState {
  idle,
  requesting,
  reading,
  found,
  notFound,
  submitting,
  approved,
  rejected,
  timeout,
  disputed,
}

// ── Widget ────────────────────────────────────────────────────────────────────

/// HealthKit Auto-Verify sub-view for the Proof Capture Modal healthKit path.
///
/// Reads Apple Health data to automatically verify task completion
/// for activities like workouts and meditation.
///
/// Migrated to [ConsumerStatefulWidget] in Story 7.7 to read
/// [proofRetainDefaultProvider] and present the retention toggle after approval.
/// The [ProofRepository] is injected via constructor.
///
/// HealthKit is iOS-only (UX-DR31). The [assert] in [build] fires in debug
/// builds if this widget is somehow constructed on macOS.
///
/// On successful verification, presents the retention choice and then calls
/// [onApproved] + [Navigator.pop(context, ProofPath.healthKit)] on Confirm.
/// (Epic 7, Stories 7.5, 7.7, AC: 1–5, FR35, FR38, FR47, UX-DR31)
class HealthKitProofSubView extends ConsumerStatefulWidget {
  const HealthKitProofSubView({
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
  ConsumerState<HealthKitProofSubView> createState() =>
      _HealthKitProofSubViewState();
}

class _HealthKitProofSubViewState extends ConsumerState<HealthKitProofSubView>
    with TickerProviderStateMixin {
  // ── State machine ──────────────────────────────────────────────────────────
  _HealthKitState _state = _HealthKitState.idle;

  // ── Submission guard ───────────────────────────────────────────────────────
  bool _isSubmitting = false;

  // ── Dispute submission guard ───────────────────────────────────────────────
  bool _isDisputeSubmitting = false;

  // ── Retention preference ───────────────────────────────────────────────────
  bool _retainProof = true;

  // ── HealthKit data ─────────────────────────────────────────────────────────
  HealthKitVerificationData? _verificationData;
  String? _rejectionReason;

  // ── Timers ─────────────────────────────────────────────────────────────────
  Timer? _timeoutTimer;

  // ── Animation controllers ──────────────────────────────────────────────────
  /// Pulsing arc — submitting state (same pattern as other sub-views).
  late AnimationController _arcController;

  /// Approval fade-in — approved state (300ms ease-in).
  late AnimationController _approvalFadeController;
  late Animation<double> _approvalFadeAnimation;

  // ── Motion ─────────────────────────────────────────────────────────────────
  bool _reducedMotion = false;

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
    _timeoutTimer?.cancel();
    _arcController.dispose();
    _approvalFadeController.dispose();
    super.dispose();
  }

  // ── HealthKit read flow ────────────────────────────────────────────────────

  Future<void> _checkHealthKit() async {
    // iOS guard — HealthKit unavailable on macOS or other platforms.
    if (!Platform.isIOS) {
      setState(() => _state = _HealthKitState.notFound);
      return;
    }

    setState(() => _state = _HealthKitState.requesting);

    try {
      final health = Health();
      await health.requestAuthorization(
        [HealthDataType.WORKOUT, HealthDataType.MINDFULNESS],
        permissions: [HealthDataAccess.READ],
      );
      if (!mounted) return;

      setState(() => _state = _HealthKitState.reading);

      final data = await health.getHealthDataFromTypes(
        startTime: DateTime.now().subtract(const Duration(hours: 2)),
        endTime: DateTime.now(),
        types: [HealthDataType.WORKOUT, HealthDataType.MINDFULNESS],
      );
      if (!mounted) return;

      if (data.isEmpty) {
        setState(() => _state = _HealthKitState.notFound);
        return;
      }

      final point = data.first;
      final durationSeconds =
          point.dateTo.difference(point.dateFrom).inSeconds.abs();

      double? calories;
      String activityType = point.type.name.toLowerCase();

      if (point.value is WorkoutHealthValue) {
        final workout = point.value as WorkoutHealthValue;
        activityType = workout.workoutActivityType.name.toLowerCase();
        if (workout.totalEnergyBurned != null) {
          calories = workout.totalEnergyBurned!.toDouble();
        }
      }

      _verificationData = HealthKitVerificationData(
        activityType: activityType,
        durationSeconds: durationSeconds,
        startedAt: point.dateFrom,
        endedAt: point.dateTo,
        calories: calories,
      );

      setState(() => _state = _HealthKitState.found);
    } catch (e) {
      debugPrint('HealthKitProofSubView: HealthKit read error: $e');
      if (!mounted) return;
      setState(() {
        _state = _HealthKitState.notFound;
      });
    }
  }

  // ── Submit proof ───────────────────────────────────────────────────────────

  Future<void> _onSubmit() async {
    if (_isSubmitting) return;
    final data = _verificationData;
    if (data == null) return;

    setState(() {
      _isSubmitting = true;
      _state = _HealthKitState.submitting;
    });

    if (!_reducedMotion) {
      _arcController.repeat();
    }

    // Start 10s timeout.
    _timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      if (_state == _HealthKitState.submitting) {
        _arcController.stop();
        _timeoutTimer = null;
        setState(() => _state = _HealthKitState.timeout);
      }
    });

    final result = await widget.proofRepository.submitHealthKitProof(
      widget.taskId,
      data,
    );
    if (!mounted) return;

    // Cancel timeout — result arrived.
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _arcController.stop();

    // Guard: don't overwrite timeout state if it fired first.
    if (_state != _HealthKitState.submitting) return;

    switch (result) {
      case ProofVerificationApproved():
        setState(() {
          _state = _HealthKitState.approved;
          _isSubmitting = false;
        });
        _approvalFadeController.forward();
        // Do NOT auto-dismiss — wait for user to confirm retention choice.
      case ProofVerificationRejected(:final reason):
        setState(() {
          _state = _HealthKitState.rejected;
          _rejectionReason = reason;
          _isSubmitting = false;
        });
      case ProofVerificationError(:final message):
        setState(() {
          _state = _HealthKitState.rejected;
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
      Navigator.pop(context, ProofPath.healthKit);
    } catch (e) {
      debugPrint('HealthKitProofSubView: setProofRetention error: $e');
      if (!mounted) return;
      // Show error state — reuse proofRetakeCta or add new error string
    }
  }

  void _onDone() {
    Navigator.pop(context, null);
  }

  void _onTryAgain() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    setState(() {
      _state =
          _verificationData != null ? _HealthKitState.found : _HealthKitState.idle;
    });
  }

  void _onBack() {
    Navigator.pop(context, null);
  }

  void _onPhotoFallback() {
    // TODO(7.6): consider deep-linking directly to photo sub-view on fallback
    Navigator.pop(context, ProofPath.photo);
  }

  Future<void> _onRequestReview() async {
    if (_isDisputeSubmitting) return;
    setState(() => _isDisputeSubmitting = true);
    try {
      await widget.proofRepository.fileDispute(widget.taskId);
      if (!mounted) return;
      setState(() => _state = _HealthKitState.disputed);
    } catch (e) {
      debugPrint('HealthKitProofSubView: fileDispute error: $e');
      if (!mounted) return;
      setState(() => _isDisputeSubmitting = false);
      // Show error inline — reuse existing error pattern (timeout or rejection reason text)
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // macOS guard — HealthKit unavailable on macOS (debug-mode safety net).
    assert(
      Platform.environment.containsKey('FLUTTER_TEST') || !Platform.isMacOS,
      'HealthKitProofSubView must not be constructed on macOS',
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
    final showBack = _state == _HealthKitState.idle;
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
    switch (_state) {
      case _HealthKitState.idle:
        return _buildIdleState(colors);
      case _HealthKitState.requesting:
      case _HealthKitState.reading:
        return _buildLoadingState(colors);
      case _HealthKitState.found:
        return _buildFoundState(colors);
      case _HealthKitState.notFound:
        return _buildNotFoundState(colors);
      case _HealthKitState.submitting:
        return _buildSubmittingState(colors);
      case _HealthKitState.approved:
        return _buildApprovedState(colors);
      case _HealthKitState.rejected:
        return _buildRejectedState(colors);
      case _HealthKitState.timeout:
        return _buildTimeoutState(colors);
      case _HealthKitState.disputed:
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
            AppStrings.healthKitProofTitle,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppStrings.healthKitProofBody,
            style: TextStyle(
              fontSize: 15,
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              minimumSize: const Size(44, 44),
              color: colors.accentPrimary,
              borderRadius: BorderRadius.circular(AppSpacing.md),
              onPressed: _checkHealthKit,
              child: Text(
                AppStrings.healthKitProofCheckCta,
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

  // ── Loading state (requesting / reading) ───────────────────────────────────

  Widget _buildLoadingState(OnTaskColors colors) {
    final label = _state == _HealthKitState.reading
        ? 'Reading Apple Health\u2026'
        : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoActivityIndicator(color: colors.accentPrimary),
          if (label != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: TextStyle(color: colors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  // ── Found state ────────────────────────────────────────────────────────────

  Widget _buildFoundState(OnTaskColors colors) {
    final data = _verificationData!;
    final durationLabel = data.durationSeconds >= 60
        ? '${data.durationSeconds ~/ 60} min'
        : '${data.durationSeconds}s';
    final calLabel =
        data.calories != null ? '${data.calories!.round()} cal' : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text(
            AppStrings.healthKitProofFoundTitle,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            data.activityType,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            durationLabel,
            style: TextStyle(
              fontSize: 15,
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (calLabel != null) ...[
            const SizedBox(height: 2),
            Text(
              calLabel,
              style: TextStyle(
                fontSize: 15,
                color: colors.textSecondary,
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
              onPressed: _onSubmit,
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

  // ── Not-found state ────────────────────────────────────────────────────────

  Widget _buildNotFoundState(OnTaskColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text(
            AppStrings.healthKitProofNotFoundTitle,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppStrings.healthKitProofNotFoundBody,
            style: TextStyle(
              fontSize: 15,
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              minimumSize: const Size(44, 44),
              color: colors.accentPrimary,
              borderRadius: BorderRadius.circular(AppSpacing.md),
              onPressed: _onPhotoFallback,
              child: Text(
                AppStrings.healthKitProofPhotoFallbackCta,
                style: TextStyle(
                  color: colors.surfacePrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          CupertinoButton(
            minimumSize: const Size(44, 44),
            onPressed: _onRequestReview,
            child: Text(
              AppStrings.proofDisputeCta,
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
          // ── Retention toggle (FR38, Story 7.7) ──────────────────────────────
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
          Text(
            AppStrings.proofRejectedLabel,
            style: TextStyle(
              fontSize: 15,
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
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

// ── Custom Painter — pulsing arc ──────────────────────────────────────────────

/// Draws a sweeping arc during the submitting state.
///
/// Kept per-file per established pattern (not shared with [PhotoCaptureSubView],
/// [ScreenshotProofSubView], or [WatchModeSubView]).
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
