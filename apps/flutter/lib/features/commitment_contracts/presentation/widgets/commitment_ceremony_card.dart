import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/motion/motion_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../now/presentation/widgets/commitment_row.dart';

// TODO(refactor): extract CommittedTaskDisplay base widget shared between
// NowTaskCard committed variant and CommitmentCeremonyCard (deferred — see
// UX spec line 1318 and Story 6.8 Dev Notes).

/// Full-screen Commitment Ceremony Card shown at the lock confirmation step.
///
/// Displays task title, stake amount, charity name, and deadline on a dark
/// `accentCommitment` surface to signal this is a moment of weight and ceremony.
///
/// On confirmation: plays "The vault close" animation (UX-DR20) — a 600ms
/// opacity-to-close arc, degraded to a 100ms instant change when
/// [MediaQuery.disableAnimations] is true.
///
/// Haptic: [HapticFeedback.heavyImpact()] fires on the "Lock it in." tap —
/// the heaviest haptic in the product (UX spec line 1527).
class CommitmentCeremonyCard extends StatefulWidget {
  const CommitmentCeremonyCard({
    super.key,
    required this.taskTitle,
    required this.stakeAmountCents,
    required this.charityName,
    required this.deadline,
    required this.onLock,
    this.isLoading = false,
  });

  final String taskTitle;
  final int stakeAmountCents;
  final String charityName;
  final DateTime deadline;
  final VoidCallback onLock;
  final bool isLoading;

  @override
  State<CommitmentCeremonyCard> createState() => _CommitmentCeremonyCardState();
}

class _CommitmentCeremonyCardState extends State<CommitmentCeremonyCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  bool _reducedMotion = false;
  // Guards against double-tap during the vault-close animation.
  bool _tapped = false;

  @override
  void initState() {
    super.initState();
    // Duration is updated in didChangeDependencies once MediaQuery is available.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: MotionTokens.vaultCloseDurationMs),
    );
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onLock();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = isReducedMotion(context);
    _controller.duration = Duration(
      milliseconds: _reducedMotion
          ? MotionTokens.vaultCloseReducedMotionDurationMs
          : MotionTokens.vaultCloseDurationMs,
    );
    // Update the curve based on reduced motion preference.
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: _reducedMotion ? Curves.linear : Curves.easeIn,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onLockTap() async {
    if (_tapped) return;
    setState(() => _tapped = true);
    await HapticFeedback.heavyImpact();
    _controller.forward();
  }

  String _formatDeadline(DateTime deadline) {
    return DateFormat("MMM d 'at' h:mm a").format(deadline.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final formattedAmount = CommitmentRow.formatAmount(widget.stakeAmountCents);
    final formattedDeadline = _formatDeadline(widget.deadline);

    return FadeTransition(
      opacity: _opacity,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Eyebrow label
            Text(
              AppStrings.commitmentCeremonyEyebrow,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: colors.surfacePrimary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Task title — New York serif
            Text(
              widget.taskTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'NewYorkSmall',
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ).copyWith(color: colors.surfacePrimary),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Stake row — lock icon + formatted amount + "at stake"
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.lock_fill, size: 16, color: colors.accentCompletion),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  formattedAmount,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.accentCompletion,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  AppStrings.nowCardStakeLabel,
                  style: TextStyle(
                    fontSize: 15,
                    color: colors.surfacePrimary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Deadline row
            Text(
              formattedDeadline,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: colors.surfacePrimary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Charity row
            Text(
              widget.charityName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: colors.surfacePrimary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Sub-copy — New York italic, future self framing (UX-DR32)
            Text(
              AppStrings.commitmentCeremonyCopy,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'NewYorkSmall',
                fontStyle: FontStyle.italic,
                fontSize: 15,
                color: colors.surfacePrimary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // "Lock it in." button or loading indicator
            if (widget.isLoading)
              Center(
                child: CupertinoActivityIndicator(color: colors.surfacePrimary),
              )
            else
              CupertinoButton(
                minimumSize: const Size(44, 44),
                color: colors.surfacePrimary,
                onPressed: _tapped ? null : _onLockTap,
                child: Text(
                  AppStrings.stakeConfirmButton,
                  style: TextStyle(
                    fontFamily: 'NewYorkSmall',
                    fontStyle: FontStyle.italic,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.accentCommitment,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
