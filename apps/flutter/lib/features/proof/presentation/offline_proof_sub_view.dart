import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../data/proof_repository.dart';
import '../domain/proof_path.dart';

// ── State machine ─────────────────────────────────────────────────────────────

/// States for the offline proof queuing flow.
enum _OfflineProofState {
  idle,
  queuing,
  queued,
  error,
}

// ── Widget ────────────────────────────────────────────────────────────────────

/// Offline Proof sub-view for the Proof Capture Modal offline path.
///
/// Queues a 'SUBMIT_PROOF' pending operation in the local Drift database
/// so it can be synced when connectivity is restored (FR37, ARCH-26).
///
/// This is a [StatefulWidget] (NOT [ConsumerStatefulWidget]) — no Riverpod
/// provider reads at widget level. The [ProofRepository] is injected via
/// constructor. Pattern established in Stories 7.2–7.5.
///
/// No [AnimationController] — offline queuing is an instant local write with
/// no submission animation.
///
/// On successful queue, calls [Navigator.pop(context, ProofPath.offline)]
/// so [ProofCaptureModal] can call [onQueued].
/// (Epic 7, Story 7.6, AC: 1, 4, FR37, ARCH-26, NFR-UX1)
class OfflineProofSubView extends StatefulWidget {
  const OfflineProofSubView({
    super.key,
    required this.taskId,
    required this.taskName,
    required this.proofRepository,
    this.onQueued,
  });

  final String taskId;
  final String taskName;
  final ProofRepository proofRepository;
  final VoidCallback? onQueued;

  @override
  State<OfflineProofSubView> createState() => _OfflineProofSubViewState();
}

class _OfflineProofSubViewState extends State<OfflineProofSubView> {
  _OfflineProofState _state = _OfflineProofState.idle;

  // ── Enqueue ────────────────────────────────────────────────────────────────

  Future<void> _onSaveForLater() async {
    setState(() => _state = _OfflineProofState.queuing);

    try {
      await widget.proofRepository.enqueueOfflineProof(widget.taskId);
      if (!mounted) return;
      setState(() => _state = _OfflineProofState.queued);
      widget.onQueued?.call();
    } catch (e) {
      debugPrint('OfflineProofSubView: enqueue error: $e');
      if (!mounted) return;
      setState(() => _state = _OfflineProofState.error);
    }
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
    // Only show back button in idle state.
    final showBack = _state == _OfflineProofState.idle;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
      child: Row(
        children: [
          if (showBack)
            CupertinoButton(
              minimumSize: const Size(44, 44),
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context, null),
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
      case _OfflineProofState.idle:
        return _buildIdleState(colors);
      case _OfflineProofState.queuing:
        return _buildQueuingState(colors);
      case _OfflineProofState.queued:
        return _buildQueuedState(colors);
      case _OfflineProofState.error:
        return _buildErrorState(colors);
    }
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
            AppStrings.offlineProofTitle,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppStrings.offlineProofBody,
            style: TextStyle(
              fontSize: 15,
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            widget.taskName,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
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
              onPressed: _onSaveForLater,
              child: Text(
                AppStrings.offlineProofSaveCta,
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

  // ── Queuing state ──────────────────────────────────────────────────────────

  Widget _buildQueuingState(OnTaskColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoActivityIndicator(color: colors.accentPrimary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.offlineProofQueueingCopy,
            style: TextStyle(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ── Queued state ───────────────────────────────────────────────────────────

  Widget _buildQueuedState(OnTaskColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            liveRegion: true,
            child: Icon(
              CupertinoIcons.checkmark_circle_fill,
              color: colors.stakeZoneLow,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Text(
              AppStrings.offlineProofQueuedConfirmation,
              style: TextStyle(
                fontSize: 15,
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          CupertinoButton(
            minimumSize: const Size(44, 44),
            color: colors.accentPrimary,
            borderRadius: BorderRadius.circular(AppSpacing.md),
            onPressed: () => Navigator.pop(context, ProofPath.offline),
            child: Text(
              AppStrings.watchModeDoneCta,
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

  // ── Error state ────────────────────────────────────────────────────────────

  Widget _buildErrorState(OnTaskColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            liveRegion: true,
            child: Icon(
              CupertinoIcons.exclamationmark_circle,
              color: colors.scheduleCritical,
              size: 48,
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              AppStrings.offlineProofErrorCopy,
              style: TextStyle(
                fontSize: 15,
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          CupertinoButton(
            minimumSize: const Size(44, 44),
            color: colors.accentPrimary,
            borderRadius: BorderRadius.circular(AppSpacing.md),
            onPressed: () => setState(() => _state = _OfflineProofState.idle),
            child: Text(
              AppStrings.watchModeTryAgainCta,
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
}
