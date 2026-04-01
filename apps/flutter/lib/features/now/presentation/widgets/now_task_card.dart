import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../proof/data/proof_repository.dart';
import '../../../proof/presentation/proof_capture_modal.dart';
import '../../domain/now_task.dart';
import '../../domain/proof_mode.dart';
import 'commitment_row.dart';
import 'proof_mode_indicator.dart';

/// Hero card for the Now tab showing the single current task.
///
/// Layout follows UX-DR5: centred card with maximum breathing room.
/// Two surface variants:
/// - Light surface for standard/non-committed tasks
/// - Dark surface (`accentCommitment`) for committed tasks with a stake
///
/// VoiceOver semantics (AC 3): wraps card in [Semantics] with conditional
/// label segments. Timer announcements fire every 60 seconds via
/// `Semantics(liveRegion: true)` on the timer display.
class NowTaskCard extends StatefulWidget {
  final NowTask task;
  final VoidCallback? onComplete;
  final VoidCallback? onStart;
  final VoidCallback? onPause;
  final VoidCallback? onStop;
  final VoidCallback? onNudge;
  final bool timerRunning;
  final int timerElapsedSeconds;
  /// Optional [ProofRepository] for photo proof submission (Story 7.2).
  /// When provided, the photo proof path submits via AI verification.
  final ProofRepository? proofRepository;

  /// When true, shows a "Verifying" badge on the card (UX-DR31, Story 7.5).
  ///
  /// This is the stub infrastructure — the parameter is always `false` in Story 7.5.
  /// A background-task story (Story 12.x) will activate this when the 30-minute
  /// HealthKit verification buffer window is active.
  final bool isHealthKitVerifying;

  const NowTaskCard({
    required this.task,
    this.onComplete,
    this.onStart,
    this.onPause,
    this.onStop,
    this.onNudge,
    this.timerRunning = false,
    this.timerElapsedSeconds = 0,
    this.proofRepository,
    this.isHealthKitVerifying = false,
    super.key,
  });

  /// Formats elapsed seconds as `M:SS` or `H:MM:SS`.
  static String formatElapsed(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  State<NowTaskCard> createState() => _NowTaskCardState();
}

class _NowTaskCardState extends State<NowTaskCard> {
  /// Timer for 60-second VoiceOver announcements.
  Timer? _announcementTimer;

  /// The announcement text, updated every 60 seconds when timer is running.
  /// Used with `Semantics(liveRegion: true)` for VoiceOver.
  String _announcementText = '';

  @override
  void initState() {
    super.initState();
    if (widget.timerRunning) {
      _startTimerAnnouncements();
    }
  }

  @override
  void didUpdateWidget(NowTaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.timerRunning && !oldWidget.timerRunning) {
      _startTimerAnnouncements();
    } else if (!widget.timerRunning && oldWidget.timerRunning) {
      _announcementTimer?.cancel();
      _announcementTimer = null;
      setState(() => _announcementText = '');
    }
  }

  @override
  void dispose() {
    _announcementTimer?.cancel();
    super.dispose();
  }

  /// Starts 60-second periodic VoiceOver announcements.
  void _startTimerAnnouncements() {
    _announcementTimer?.cancel();
    _announcementTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) {
        if (widget.timerRunning) {
          final elapsed = NowTaskCard.formatElapsed(widget.timerElapsedSeconds);
          setState(() {
            _announcementText = AppStrings.timerAnnouncementTemplate
                .replaceAll('{time}', elapsed)
                .replaceAll('{task}', widget.task.title);
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final serifFamily =
        Theme.of(context).textTheme.displayLarge?.fontFamily;
    final isCommitted = widget.task.stakeAmountCents != null;

    // Surface and text colours based on commitment state
    final backgroundColor =
        isCommitted ? colors.accentCommitment : colors.surfacePrimary;
    final textColor =
        isCommitted ? colors.surfacePrimary : colors.textPrimary;
    final secondaryTextColor =
        isCommitted ? colors.surfacePrimary.withValues(alpha: 0.7) : colors.textSecondary;

    return Semantics(
      label: _buildVoiceOverLabel(),
      customSemanticsActions: _buildCustomActions(),
      excludeSemantics: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(AppSpacing.lg),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Attribution ────────────────────────────────────────
                Text(
                  _buildAttribution(),
                  style: TextStyle(
                    fontFamily: serifFamily,
                    fontStyle: FontStyle.italic,
                    fontSize: 15,
                    color: secondaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Task title ────────────────────────────────────────
                Text(
                  widget.task.title,
                  style: TextStyle(
                    fontFamily: serifFamily,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Deadline ──────────────────────────────────────────
                if (widget.task.dueDate != null) ...[
                  Text(
                    _formatDeadline(widget.task.dueDate!),
                    style: TextStyle(
                      fontSize: 15,
                      color: secondaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // ── Timer display ─────────────────────────────────────
                if (widget.timerRunning || widget.timerElapsedSeconds > 0) ...[
                  Semantics(
                    liveRegion: widget.timerRunning,
                    child: Text(
                      widget.timerRunning
                          ? NowTaskCard.formatElapsed(widget.timerElapsedSeconds)
                          : NowTaskCard.formatElapsed(widget.timerElapsedSeconds),
                      style: TextStyle(
                        fontFeatures: const [FontFeature.tabularFigures()],
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // ── 60-second VoiceOver announcement (hidden) ─────────
                if (_announcementText.isNotEmpty)
                  Semantics(
                    liveRegion: true,
                    child: SizedBox.shrink(
                      child: Text(
                        _announcementText,
                        style: const TextStyle(fontSize: 0),
                      ),
                    ),
                  ),

                // ── Commitment row ────────────────────────────────────
                CommitmentRow(
                  stakeAmountCents: widget.task.stakeAmountCents,
                  textColor: textColor,
                ),
                if (widget.task.stakeAmountCents != null)
                  const SizedBox(height: AppSpacing.md),

                // ── Proof mode indicator ──────────────────────────────
                ProofModeIndicator(
                  proofMode: widget.task.proofMode,
                  textColor: secondaryTextColor,
                ),
                if (widget.task.proofMode != ProofMode.standard)
                  const SizedBox(height: AppSpacing.lg),

                // ── HealthKit "Verifying" badge (UX-DR31, Story 7.5) ──
                // isHealthKitVerifying is always false in Story 7.5 scope.
                // A background-task story will activate this parameter.
                if (widget.isHealthKitVerifying) ...[
                  _HealthKitVerifyingBadge(
                    reducedMotion: MediaQuery.of(context).disableAnimations,
                    colors: colors,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],

                // ── Timer action buttons ──────────────────────────────
                if (widget.task.proofMode != ProofMode.calendarEvent) ...[
                  const SizedBox(height: AppSpacing.md),
                  _buildTimerButtons(colors, isCommitted),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // ── Primary CTA ───────────────────────────────────────
                if (widget.task.proofMode != ProofMode.calendarEvent) ...[
                  _buildCta(colors, isCommitted),
                ],

                // ── Reschedule with AI (nudge) ────────────────────────
                if (widget.onNudge != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  CupertinoButton(
                    minimumSize: const Size(44, 44),
                    onPressed: widget.onNudge,
                    child: Text(
                      AppStrings.todayRowNudge,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the timer Start / Pause / Stop buttons.
  Widget _buildTimerButtons(OnTaskColors colors, bool isCommitted) {
    if (widget.timerRunning) {
      // Timer is running: show Pause and Stop
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Semantics(
            label: AppStrings.timerPauseVoiceOver,
            child: SizedBox(
              height: 44,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                onPressed: widget.onPause,
                child: Text(
                  AppStrings.timerPause,
                  style: TextStyle(
                    color: isCommitted
                        ? colors.surfacePrimary
                        : colors.accentPrimary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Semantics(
            label: AppStrings.timerStopVoiceOver,
            child: SizedBox(
              height: 44,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                onPressed: widget.onStop,
                child: Text(
                  AppStrings.timerStop,
                  style: TextStyle(
                    color: isCommitted
                        ? colors.surfacePrimary.withValues(alpha: 0.7)
                        : colors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Timer not running: show Start
    return Semantics(
      label: AppStrings.timerStartVoiceOver,
      child: SizedBox(
        height: 44,
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
          ),
          onPressed: widget.onStart,
          child: Text(
            AppStrings.timerStart,
            style: TextStyle(
              color: isCommitted
                  ? colors.surfacePrimary
                  : colors.accentPrimary,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the primary CTA button based on proof mode.
  Widget _buildCta(OnTaskColors colors, bool isCommitted) {
    final (label, icon) = _ctaConfig;

    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        color: isCommitted ? colors.surfacePrimary : colors.accentPrimary,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        onPressed: () async {
          HapticFeedback.mediumImpact();
          if (widget.task.proofMode == ProofMode.photo) {
            // Open proof capture modal — returns non-null if proof submitted.
            final result = await showCupertinoModalPopup<Object?>(
              context: context,
              builder: (_) => ProofCaptureModal(
                taskName: widget.task.title,
                taskId: widget.task.id,
                proofMode: widget.task.proofMode,
                proofRepository: widget.proofRepository,
              ),
            );
            if (!mounted) return;
            if (result != null) {
              widget.onComplete?.call();
            }
          } else if (widget.task.proofMode == ProofMode.watchMode) {
            // Open proof capture modal with watchMode path for Watch Mode.
            // Watch Mode is iOS-only (UX-DR10) — macOS guard is in ProofCaptureModal path selector
            final result = await showCupertinoModalPopup<Object?>(
              context: context,
              builder: (_) => ProofCaptureModal(
                taskName: widget.task.title,
                taskId: widget.task.id,
                proofMode: widget.task.proofMode,
                proofRepository: widget.proofRepository,
              ),
            );
            if (!mounted) return;
            if (result != null) {
              widget.onComplete?.call();
            }
          } else if (widget.task.proofMode == ProofMode.healthKit) {
            // Open proof capture modal with HealthKit path pre-selected (Story 7.5).
            // HealthKit is iOS-only (UX-DR31) — macOS guard is in ProofCaptureModal path selector.
            final result = await showCupertinoModalPopup<Object?>(
              context: context,
              builder: (_) => ProofCaptureModal(
                taskName: widget.task.title,
                taskId: widget.task.id,
                proofMode: widget.task.proofMode,
                proofRepository: widget.proofRepository,
              ),
            );
            if (!mounted) return;
            if (result != null) {
              widget.onComplete?.call();
            }
          } else {
            // For standard + calendarEvent: mark done directly.
            widget.onComplete?.call();
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: AppSpacing.sm),
            ],
            Text(
              label,
              style: TextStyle(
                color: isCommitted ? colors.accentCommitment : colors.surfacePrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns the CTA label and optional icon for the current proof mode.
  (String, IconData?) get _ctaConfig {
    switch (widget.task.proofMode) {
      case ProofMode.standard:
        return (AppStrings.nowCardMarkDone, null);
      case ProofMode.photo:
        return (AppStrings.nowCardSubmitProof, CupertinoIcons.camera);
      case ProofMode.watchMode:
        return (AppStrings.nowCardStartWatchMode, CupertinoIcons.eye);
      case ProofMode.healthKit:
        return (AppStrings.nowCardProofHealthKit, CupertinoIcons.heart);
      case ProofMode.calendarEvent:
        return ('', null); // No CTA for calendar events
    }
  }

  /// Builds the custom semantic actions for VoiceOver.
  Map<CustomSemanticsAction, VoidCallback>? _buildCustomActions() {
    final actions = <CustomSemanticsAction, VoidCallback>{};

    if (!widget.timerRunning && widget.onStart != null) {
      actions[const CustomSemanticsAction(
        label: AppStrings.timerStartVoiceOver,
      )] = widget.onStart!;
    }

    if (widget.timerRunning && widget.onPause != null) {
      actions[const CustomSemanticsAction(
        label: AppStrings.timerPauseVoiceOver,
      )] = widget.onPause!;
    }

    if (widget.timerRunning && widget.onStop != null) {
      actions[const CustomSemanticsAction(
        label: AppStrings.timerStopVoiceOver,
      )] = widget.onStop!;
    }

    return actions.isEmpty ? null : actions;
  }

  /// Builds the attribution text.
  String _buildAttribution() {
    if (widget.task.listName != null && widget.task.assignorName != null) {
      return AppStrings.nowCardAttributionFromListAndAssignor
          .replaceAll('{listName}', widget.task.listName!)
          .replaceAll('{assignor}', widget.task.assignorName!);
    }
    if (widget.task.listName != null) {
      return AppStrings.nowCardAttributionFromList
          .replaceAll('{listName}', widget.task.listName!);
    }
    return AppStrings.nowCardAttribution;
  }

  /// Builds the VoiceOver label with conditional segments (AC 3).
  ///
  /// Full: "Buy groceries, from Shared Errands, $25 staked, due tomorrow 2pm, photo proof, 5:30 elapsed"
  /// Minimal: "Buy groceries" (no list, no stake, no deadline, standard proof mode)
  String _buildVoiceOverLabel() {
    final parts = <String>[widget.task.title];

    if (widget.task.listName != null) {
      parts.add(AppStrings.nowCardVoiceOverFrom
          .replaceAll('{listName}', widget.task.listName!));
    }

    if (widget.task.stakeAmountCents != null) {
      final formatted = CommitmentRow.formatAmount(widget.task.stakeAmountCents!);
      parts.add(AppStrings.nowCardVoiceOverStaked
          .replaceAll('{amount}', formatted));
    }

    if (widget.task.dueDate != null) {
      parts.add(AppStrings.nowCardVoiceOverDue
          .replaceAll('{deadline}', _formatDeadline(widget.task.dueDate!)));
    }

    if (widget.task.proofMode != ProofMode.standard) {
      parts.add(_proofModeLabel(widget.task.proofMode));
    }

    if (widget.timerRunning && widget.timerElapsedSeconds > 0) {
      final elapsed = NowTaskCard.formatElapsed(widget.timerElapsedSeconds);
      parts.add(AppStrings.nowCardVoiceOverTimerElapsed
          .replaceAll('{time}', elapsed));
    }

    return parts.join(', ');
  }

  /// Returns the human-readable proof mode label for VoiceOver.
  String _proofModeLabel(ProofMode mode) {
    switch (mode) {
      case ProofMode.photo:
        return AppStrings.nowCardProofPhoto;
      case ProofMode.watchMode:
        return AppStrings.nowCardProofWatchMode;
      case ProofMode.healthKit:
        return AppStrings.nowCardProofHealthKit;
      case ProofMode.calendarEvent:
        return AppStrings.nowCardProofCalendarEvent;
      case ProofMode.standard:
        return '';
    }
  }

  /// Formats a [DateTime] deadline for display.
  String _formatDeadline(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    String dayPart;
    if (dateOnly == today) {
      dayPart = AppStrings.dateToday;
    } else if (dateOnly == tomorrow) {
      dayPart = AppStrings.dateTomorrow;
    } else {
      dayPart =
          '${_monthName(date.month)} ${date.day}';
    }

    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12
        ? AppStrings.todayTimePm
        : AppStrings.todayTimeAm;
    final minute =
        date.minute > 0 ? ':${date.minute.toString().padLeft(2, '0')}' : '';

    return '$dayPart $hour$minute$period';
  }

  String _monthName(int month) {
    const months = [
      AppStrings.monthJan, AppStrings.monthFeb, AppStrings.monthMar,
      AppStrings.monthApr, AppStrings.monthMay, AppStrings.monthJun,
      AppStrings.monthJul, AppStrings.monthAug, AppStrings.monthSep,
      AppStrings.monthOct, AppStrings.monthNov, AppStrings.monthDec,
    ];
    return months[month - 1];
  }
}

// ── HealthKit Verifying Badge ─────────────────────────────────────────────────

/// Small badge shown on the Now tab task card while HealthKit verification is
/// in-progress (UX-DR31, Story 7.5).
///
/// Shows a subtle pulsing opacity animation (1.0 ↔ 0.5, 2s period).
/// If [reducedMotion] is true, shows a static opacity of 0.7.
///
/// Note: [NowTaskCard.isHealthKitVerifying] is always `false` in Story 7.5 scope.
/// This widget is stub infrastructure for the background-task story (Story 12.x).
class _HealthKitVerifyingBadge extends StatefulWidget {
  const _HealthKitVerifyingBadge({
    required this.reducedMotion,
    required this.colors,
  });

  final bool reducedMotion;
  final OnTaskColors colors;

  @override
  State<_HealthKitVerifyingBadge> createState() =>
      _HealthKitVerifyingBadgeState();
}

class _HealthKitVerifyingBadgeState extends State<_HealthKitVerifyingBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _opacity = Tween<double>(begin: 1.0, end: 0.5).animate(_controller);
    if (!widget.reducedMotion) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.colors.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Text(
        AppStrings.healthKitVerifyingBadge,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: widget.colors.textSecondary,
            ),
      ),
    );

    if (widget.reducedMotion) {
      return Opacity(opacity: 0.7, child: badge);
    }

    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) => Opacity(
        opacity: _opacity.value,
        child: child,
      ),
      child: badge,
    );
  }
}
