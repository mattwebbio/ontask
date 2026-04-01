import 'dart:io' show Platform;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/proof_path.dart';
import '../../now/domain/proof_mode.dart';

/// Modal bottom sheet for selecting a proof path when submitting task proof.
///
/// Presented via [showCupertinoModalPopup] from [NowTaskCard].
/// Returns a [ProofPath] on submission, or null if dismissed without
/// submitting (task stays in pending completion state — UX-DR11).
///
/// NOT added to AppRouter — presented as a CupertinoModalPopup only.
/// (Epic 7, Story 7.1, AC1–2, FR31)
class ProofCaptureModal extends ConsumerStatefulWidget {
  const ProofCaptureModal({
    super.key,
    required this.taskName,
    this.proofMode,
  });

  /// The name of the task for which proof is being submitted.
  final String taskName;

  /// The proof mode pre-set on the task (used for context; does not force a path).
  final ProofMode? proofMode;

  @override
  ConsumerState<ProofCaptureModal> createState() => _ProofCaptureModalState();
}

class _ProofCaptureModalState extends ConsumerState<ProofCaptureModal> {
  ProofPath? _selectedPath;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _isOffline = result.contains(ConnectivityResult.none) &&
            result.length == 1;
      });
    }
  }

  void _onPathSelected(ProofPath path) {
    setState(() => _selectedPath = path);
  }

  void _onBack() {
    setState(() => _selectedPath = null);
  }

  void _onDismiss() {
    Navigator.pop(context, null);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: _selectedPath == null
            ? _buildPathSelector(context, colors)
            : _buildSubView(context, colors, _selectedPath!),
      ),
    );
  }

  /// Builds the path selector view — sheet heading + four path rows.
  Widget _buildPathSelector(BuildContext context, OnTaskColors colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header ───────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  // VoiceOver focus on sheet heading on open (UX spec §7, line 1679).
                  focused: true,
                  child: Text(
                    '${AppStrings.proofModalTitle} ${widget.taskName}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
              CupertinoButton(
                minimumSize: const Size(44, 44),
                padding: EdgeInsets.zero,
                onPressed: _onDismiss,
                child: Icon(
                  CupertinoIcons.xmark,
                  color: colors.textSecondary,
                  size: 20,
                ),
              ),
            ],
          ),
        ),

        // ── Path rows ────────────────────────────────────────────────────────
        _ProofPathRow(
          icon: CupertinoIcons.camera,
          title: AppStrings.proofPathPhotoTitle,
          subtitle: AppStrings.proofPathPhotoSubtitle,
          colors: colors,
          onTap: () => _onPathSelected(ProofPath.photo),
        ),

        // HealthKit — iOS only (hidden on macOS per AC2)
        if (!Platform.isMacOS)
          _ProofPathRow(
            icon: CupertinoIcons.heart,
            title: AppStrings.proofPathHealthKitTitle,
            subtitle: AppStrings.proofPathHealthKitSubtitle,
            colors: colors,
            onTap: () => _onPathSelected(ProofPath.healthKit),
          ),

        _ProofPathRow(
          icon: CupertinoIcons.doc,
          title: AppStrings.proofPathScreenshotTitle,
          subtitle: AppStrings.proofPathScreenshotSubtitle,
          colors: colors,
          onTap: () => _onPathSelected(ProofPath.screenshot),
        ),

        // Offline — shown only when device is offline (AC1)
        if (_isOffline)
          _ProofPathRow(
            icon: CupertinoIcons.wifi_slash,
            title: AppStrings.proofPathOfflineTitle,
            subtitle: AppStrings.proofPathOfflineSubtitle,
            colors: colors,
            onTap: () => _onPathSelected(ProofPath.offline),
          ),

        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  /// Builds the stub sub-view for the selected [path].
  ///
  /// Full implementations are in Stories 7.2–7.6. This is the placeholder.
  Widget _buildSubView(
    BuildContext context,
    OnTaskColors colors,
    ProofPath path,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Sub-view header with back button ─────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              CupertinoButton(
                minimumSize: const Size(44, 44),
                padding: EdgeInsets.zero,
                onPressed: _onBack,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.chevron_left,
                      color: colors.accentPrimary,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      AppStrings.proofModalBack,
                      style: TextStyle(
                        color: colors.accentPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),

        // ── Stub placeholder ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: Text(
              AppStrings.proofPathComingSoon,
              style: TextStyle(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

/// A single tappable row representing a proof path option.
class _ProofPathRow extends StatelessWidget {
  const _ProofPathRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final OnTaskColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        button: true,
        label: '$title: $subtitle',
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              // Leading icon
              SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Icon(
                    icon,
                    color: colors.accentPrimary,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                color: colors.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
