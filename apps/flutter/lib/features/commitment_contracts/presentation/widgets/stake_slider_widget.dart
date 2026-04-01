import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/motion/motion_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../now/presentation/widgets/commitment_row.dart';

// ── Zone constants ────────────────────────────────────────────────────────────

/// Slider range: 0–20000 cents ($0–$200), 40 divisions of 500 cents ($5 each).
const double _sliderMin = 0;
const double _sliderMax = 20000;
const int _sliderDivisions = 40;

/// Zone thresholds (in cents).
const int _lowZoneMax = 2000; // $0–$20 → sage
const int _midZoneMax = 7500; // $75 → amber
const int _highZoneMin = 10000; // $100+ → terracotta

/// 5% deadband of full range = 1000 cents ($10).
const double _deadbandCents = 1000.0;

/// Zones used for haptic debouncing and icon selection.
enum _StakeZone { none, low, mid, high }

_StakeZone _zoneForCents(int cents) {
  if (cents <= 0) return _StakeZone.none;
  if (cents <= _lowZoneMax) return _StakeZone.low;
  if (cents <= _midZoneMax) return _StakeZone.mid;
  return _StakeZone.high;
}

// ── Custom track painter ──────────────────────────────────────────────────────

/// Paints a tri-colour gradient track for the stake slider.
///
/// Zones: sage ($0-$40 visually) → amber ($40-$110) → terracotta ($110+).
/// Zone boundaries at 20% and 55% of track width for visual balance.
class _StakeTrackPainter extends CustomPainter {
  _StakeTrackPainter({
    required this.lowColor,
    required this.midColor,
    required this.highColor,
  });

  final Color lowColor;
  final Color midColor;
  final Color highColor;

  @override
  void paint(Canvas canvas, Size size) {
    const trackHeight = 4.0;
    const borderRadius = 100.0;

    final rect = Rect.fromLTWH(0, (size.height - trackHeight) / 2, size.width, trackHeight);
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(borderRadius));

    final gradient = LinearGradient(
      colors: [lowColor, midColor, highColor],
      stops: const [0.0, 0.20, 0.55],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rRect, paint);
  }

  @override
  bool shouldRepaint(_StakeTrackPainter oldDelegate) =>
      oldDelegate.lowColor != lowColor ||
      oldDelegate.midColor != midColor ||
      oldDelegate.highColor != highColor;
}

// ── StakeSliderWidget ─────────────────────────────────────────────────────────

/// Pure UI widget for selecting a commitment stake amount.
///
/// Built on [CupertinoSlider] with a custom tri-colour track (sage/amber/terracotta),
/// animated lock icon, haptic zone feedback, and red-zone guidance text.
///
/// This is a stateful pure widget — no Riverpod dependency.
/// Caller ([StakeSheetScreen]) owns repository calls.
class StakeSliderWidget extends StatefulWidget {
  const StakeSliderWidget({
    super.key,
    required this.stakeAmountCents,
    required this.onChanged,
    required this.onConfirm,
  });

  /// Current stake value in cents; null or 0 = no stake set.
  final int? stakeAmountCents;

  /// Called on every slider or text-entry change with the new value in cents.
  final void Function(int? cents) onChanged;

  /// Called when the user taps the "Lock it in." confirm button.
  final VoidCallback? onConfirm;

  @override
  State<StakeSliderWidget> createState() => _StakeSliderWidgetState();
}

class _StakeSliderWidgetState extends State<StakeSliderWidget> {
  late double _sliderValue;
  _StakeZone _currentZone = _StakeZone.none;

  /// Tracks the last slider position where haptic fired, for deadband logic.
  double _lastHapticPosition = 0;

  @override
  void initState() {
    super.initState();
    _sliderValue = (widget.stakeAmountCents ?? 0).toDouble().clamp(_sliderMin, _sliderMax);
    _currentZone = _zoneForCents(_sliderValue.toInt());
    _lastHapticPosition = _sliderValue;
  }

  @override
  void didUpdateWidget(StakeSliderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stakeAmountCents != widget.stakeAmountCents) {
      _sliderValue = (widget.stakeAmountCents ?? 0).toDouble().clamp(_sliderMin, _sliderMax);
      _currentZone = _zoneForCents(_sliderValue.toInt());
      _lastHapticPosition = _sliderValue;
    }
  }

  void _onSliderChanged(double value) {
    // Snap to nearest $5 increment (500 cents).
    final snapped = (value / 500).round() * 500.0;

    final newZone = _zoneForCents(snapped.toInt());

    // Haptic with 5% deadband: only fire if moved ≥ 1000 cents past threshold.
    if (newZone != _currentZone) {
      final distanceMoved = (snapped - _lastHapticPosition).abs();
      if (distanceMoved >= _deadbandCents) {
        HapticFeedback.selectionClick();
        _currentZone = newZone;
        _lastHapticPosition = snapped;
      }
    }

    setState(() {
      _sliderValue = snapped;
    });

    final cents = snapped.toInt();
    widget.onChanged(cents == 0 ? null : cents);
  }

  void _showExactAmountDialog(BuildContext context) {
    final controller = TextEditingController(
      text: _sliderValue > 0 ? (_sliderValue ~/ 100).toString() : '',
    );

    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text(AppStrings.stakeSliderTitle),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: CupertinoTextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            placeholder: AppStrings.stakeAmountPlaceholder,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: false,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStrings.actionCancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              final entered = int.tryParse(controller.text.trim());
              if (entered != null) {
                // Convert dollars to cents, snap to nearest $5 minimum.
                var cents = entered * 100;
                if (cents < 500) cents = 500; // minimum $5
                if (cents > _sliderMax.toInt()) cents = _sliderMax.toInt();
                // Snap to $5 increment.
                cents = (cents / 500).round() * 500;
                setState(() {
                  _sliderValue = cents.toDouble();
                  _currentZone = _zoneForCents(cents);
                });
                widget.onChanged(cents);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text(AppStrings.actionDone),
          ),
        ],
      ),
    );
  }

  Color _zoneColor(OnTaskColors colors) {
    switch (_currentZone) {
      case _StakeZone.none:
        return colors.stakeZoneLow;
      case _StakeZone.low:
        return colors.stakeZoneLow;
      case _StakeZone.mid:
        return colors.stakeZoneMid;
      case _StakeZone.high:
        return colors.stakeZoneHigh;
    }
  }

  IconData _lockIcon() {
    switch (_currentZone) {
      case _StakeZone.none:
      case _StakeZone.low:
        return CupertinoIcons.lock_open;
      case _StakeZone.mid:
        return CupertinoIcons.lock_slash;
      case _StakeZone.high:
        return CupertinoIcons.lock_fill;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final reduced = isReducedMotion(context);
    final zoneColor = _zoneColor(colors);
    final centsInt = _sliderValue.toInt();
    final isHighZone = centsInt >= _highZoneMin;
    final canConfirm = centsInt >= 500;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Zone labels row ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.stakeZoneLowLabel,
                style: TextStyle(fontSize: 10, color: colors.stakeZoneLow),
              ),
              Text(
                AppStrings.stakeZoneMidLabel,
                style: TextStyle(fontSize: 10, color: colors.stakeZoneMid),
              ),
              Text(
                AppStrings.stakeZoneHighLabel,
                style: TextStyle(fontSize: 10, color: colors.stakeZoneHigh),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        // ── Custom track + CupertinoSlider ────────────────────────────────
        Stack(
          alignment: Alignment.center,
          children: [
            // Custom track painter behind the slider
            IgnorePointer(
              child: SizedBox(
                height: 32,
                child: CustomPaint(
                  painter: _StakeTrackPainter(
                    lowColor: colors.stakeZoneLow,
                    midColor: colors.stakeZoneMid,
                    highColor: colors.stakeZoneHigh,
                  ),
                ),
              ),
            ),
            CupertinoSlider(
              value: _sliderValue,
              min: _sliderMin,
              max: _sliderMax,
              divisions: _sliderDivisions,
              activeColor: zoneColor,
              thumbColor: CupertinoColors.white,
              onChanged: _onSliderChanged,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // ── Amount display + lock icon ────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lock icon with AnimatedSwitcher
            AnimatedSwitcher(
              duration: reduced ? Duration.zero : const Duration(milliseconds: 200),
              child: Icon(
                _lockIcon(),
                key: ValueKey(_lockIcon()),
                color: zoneColor,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Amount display — tappable for exact entry
            Semantics(
              label: centsInt > 0
                  ? '\$${centsInt ~/ 100} stake'
                  : AppStrings.stakeAddButton,
              child: GestureDetector(
                onTap: () => _showExactAmountDialog(context),
                child: Text(
                  centsInt > 0
                      ? CommitmentRow.formatAmount(centsInt)
                      : '\$0',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: zoneColor,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // ── Red zone guidance text ────────────────────────────────────────
        AnimatedOpacity(
          opacity: isHighZone ? 1.0 : 0.0,
          duration: reduced ? Duration.zero : const Duration(milliseconds: 200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              AppStrings.stakeHighZoneGuidance,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: colors.stakeZoneHigh,
                fontFamily: 'NewYorkSerif',
              ),
            ),
          ),
        ),

        if (isHighZone) const SizedBox(height: AppSpacing.md),

        // ── Confirm button ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: CupertinoButton(
            minimumSize: const Size(44, 44),
            color: canConfirm ? colors.stakeZoneLow : CupertinoColors.systemGrey4,
            onPressed: (canConfirm && widget.onConfirm != null) ? widget.onConfirm : null,
            child: Text(
              AppStrings.stakeConfirmButton,
              style: TextStyle(
                color: canConfirm ? CupertinoColors.white : CupertinoColors.systemGrey,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
