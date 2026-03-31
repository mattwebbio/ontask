import 'package:flutter/cupertino.dart';
import 'package:flutter/semantics.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_text_styles.dart';

/// Full-screen transition shown after a significant milestone.
///
/// Displays recovery-framing copy ("that one's done — what does your future
/// self need now?") using the "chapter break" motion token: 50ms fade +
/// slight upward shift (UX-DR13, UX-DR20).
///
/// Entry animation respects `MediaQuery.of(context).disableAnimations` —
/// when Reduce Motion is enabled the screen renders at full opacity
/// immediately with no offset shift (instant cut, zero duration).
///
/// No shell chrome — rendered as a TOP-LEVEL route outside [StatefulShellRoute].
/// Caller should navigate here with `context.push('/chapter-break', extra: {...})`
/// and the [onContinue] callback calls `context.go('/now')`.
///
/// VoiceOver (UX spec §9.6):
///   • [SemanticsService.announce] fires once on first frame for the initial
///     announcement (chapter break screen appears without user action).
///   • The headline is also wrapped in `Semantics(liveRegion: true, header: true)`
///     for correct VoiceOver reading order: heading → task title → CTA.
class ChapterBreakScreen extends StatefulWidget {
  /// Title of the task that was just completed.
  final String taskTitle;

  /// Optional stake amount to display (available Epic 6+).
  final String? stakeAmount;

  /// Called when the user taps the "Keep going" CTA.
  final VoidCallback onContinue;

  const ChapterBreakScreen({
    required this.taskTitle,
    required this.onContinue,
    this.stakeAmount,
    super.key,
  });

  @override
  State<ChapterBreakScreen> createState() => _ChapterBreakScreenState();
}

class _ChapterBreakScreenState extends State<ChapterBreakScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  bool _animationStarted = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    );

    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // VoiceOver announcement per UX spec §9.6 (chapter break screen appears
    // without user action — use SemanticsService.announce as the exception).
    // This is the ONE screen where both announce() AND liveRegion are used
    // together as explicitly required by the UX spec.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SemanticsService.announce(
        AppStrings.chapterBreakVoiceOverAnnounce,
        TextDirection.ltr,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery.of(context) must be accessed in didChangeDependencies (not
    // initState) because inherited widgets are not available during initState.
    if (!_animationStarted) {
      _animationStarted = true;
      final disableAnimations = MediaQuery.of(context).disableAnimations;
      if (disableAnimations) {
        // Reduce Motion: instant cut — no animation, no offset shift.
        _controller.value = 1.0;
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: CupertinoPageScaffold(
          backgroundColor: CupertinoColors.systemBackground,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Heading — New York serif 34pt, liveRegion for VoiceOver.
                  Semantics(
                    liveRegion: true,
                    header: true,
                    child: Text(
                      AppStrings.chapterBreakHeadline,
                      style: AppTextStyles.impactMilestone,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Sub-copy — New York serif 20pt.
                  Text(
                    AppStrings.chapterBreakSubcopy,
                    style: AppTextStyles.voiceCopyPrimary,
                  ),
                  const SizedBox(height: 32),
                  // Completed task title — body SF Pro.
                  Text(widget.taskTitle, style: AppTextStyles.body),
                  // Stake amount — shown only when provided (Epic 6+).
                  if (widget.stakeAmount != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${AppStrings.chapterBreakStakeLabel}: ${widget.stakeAmount}',
                      style: AppTextStyles.secondary,
                    ),
                  ],
                  const Spacer(),
                  // CTA — full-width filled Cupertino button (no Material).
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: widget.onContinue,
                      child: Text(AppStrings.chapterBreakCta),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
