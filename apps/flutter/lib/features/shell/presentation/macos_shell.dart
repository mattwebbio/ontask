import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../now/presentation/now_provider.dart';
import '../../now/presentation/timer_provider.dart';
import 'add_tab_sheet.dart';
import 'command_palette_sheet.dart';
import 'macos_keyboard_shortcuts.dart';
import 'macos_sidebar.dart';
import 'shell_providers.dart';

/// macOS-specific navigation shell.
///
/// Implements a two/three-pane layout with a sidebar, optional detail panel,
/// and main content area driven by go_router's [StatefulNavigationShell].
///
/// Layout breakpoints:
/// - width > 1100pt → three-pane (sidebar + detail + main)
/// - 900pt–1100pt   → two-pane (sidebar + main; detail hidden)
///
/// Keyboard shortcuts (⌘N, ⌘K, ⌘1–4, ⌘,, etc.) are registered via Flutter's
/// [Shortcuts] + [Actions] widgets. All shortcuts are guarded to macOS only
/// in [AppShell] via [Platform.isMacOS].
///
/// Tab pane focus traversal (AC-11) is handled by [FocusTraversalGroup] on
/// each pane, ordered sidebar=1, detail=2, main=3.
class MacosShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MacosShell({required this.navigationShell, super.key});

  @override
  ConsumerState<MacosShell> createState() => _MacosShellState();
}

class _MacosShellState extends ConsumerState<MacosShell> {
  int _selectedIndex = 0; // 0=Now, 1=Today, 2=Lists, 3=Settings

  static const double _sidebarWidth = 260.0;
  static const double _detailMinWidth = 320.0;
  static const double _twoPaneBreakpoint = 1100.0;
  static const double _toolbarHeight = 52.0;

  // ── Branch mapping ──────────────────────────────────────────────────────────
  // iOS branches: now=0, today=1, add=2 (stub), lists=3, settings=4 (new)
  // Sidebar:      0=Now,   1=Today,  2=Lists,  3=Settings
  // Branch index: 0,       1,        3,         4
  int _sidebarIndexToBranch(int sidebarIndex) {
    switch (sidebarIndex) {
      case 0:
        return 0; // Now
      case 1:
        return 1; // Today
      case 2:
        return 3; // Lists (skips add stub at 2)
      case 3:
        return 4; // Settings
      default:
        return 0;
    }
  }

  void _onSidebarItemTapped(int index) {
    setState(() => _selectedIndex = index);
    widget.navigationShell.goBranch(_sidebarIndexToBranch(index));
  }

  void _openAddSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTabSheet(),
    );
  }

  void _openCommandPalette() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const CommandPaletteSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the Add sheet request signal (same provider as iOS shell).
    ref.listen<int>(openAddSheetRequestProvider, (previous, next) {
      if (previous != null && next > previous) {
        _openAddSheet();
      }
    });

    final colors = Theme.of(context).extension<OnTaskColors>()!;
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: colors.surfacePrimary,
      body: Shortcuts(
        shortcuts: macosShortcuts,
        child: Actions(
          actions: {
            NewTaskIntent: CallbackAction<NewTaskIntent>(
              onInvoke: (_) => _openAddSheet(),
            ),
            CompleteTaskIntent: CallbackAction<CompleteTaskIntent>(
              onInvoke: (_) => null, // placeholder — real logic in Story 2.x
            ),
            ToggleTimerIntent: CallbackAction<ToggleTimerIntent>(
              onInvoke: (_) {
                final task = ref.read(nowProvider).value;
                if (task != null) {
                  ref.read(taskTimerProvider.notifier).toggleTimer(task.id);
                }
                return null;
              },
            ),
            CommandPaletteIntent: CallbackAction<CommandPaletteIntent>(
              onInvoke: (_) => _openCommandPalette(),
            ),
            SearchFilterIntent: CallbackAction<SearchFilterIntent>(
              onInvoke: (_) => _openCommandPalette(),
            ),
            NavigateSectionIntent: CallbackAction<NavigateSectionIntent>(
              onInvoke: (intent) => _onSidebarItemTapped(intent.section),
            ),
            OpenSettingsIntent: CallbackAction<OpenSettingsIntent>(
              onInvoke: (_) => _onSidebarItemTapped(3),
            ),
          },
          child: Focus(
            autofocus: true,
            child: Column(
              children: [
                _MacosToolbar(
                  height: _toolbarHeight,
                  onNewTask: _openAddSheet,
                  colors: colors,
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isTwoPane =
                          constraints.maxWidth <= _twoPaneBreakpoint;
                      return _buildPaneLayout(
                        isTwoPane: isTwoPane,
                        disableAnimations: disableAnimations,
                        colors: colors,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaneLayout({
    required bool isTwoPane,
    required bool disableAnimations,
    required OnTaskColors colors,
  }) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Row(
        children: [
          // Sidebar pane — focus traversal order: 1
          FocusTraversalOrder(
            order: const NumericFocusOrder(1),
            child: SizedBox(
              width: _sidebarWidth,
              child: Focus(
                child: MacosSidebar(
                  selectedIndex: _selectedIndex,
                  onItemTapped: _onSidebarItemTapped,
                  onNewTask: _openAddSheet,
                ),
              ),
            ),
          ),
          // Detail panel — focus traversal order: 2; collapses in two-pane mode
          FocusTraversalOrder(
            order: const NumericFocusOrder(2),
            child: AnimatedContainer(
              duration: disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              width: isTwoPane ? 0.0 : _detailMinWidth,
              child: Offstage(
                offstage: isTwoPane,
                child: Focus(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: colors.surfaceSecondary,
                          width: 1,
                        ),
                        right: BorderSide(
                          color: colors.surfaceSecondary,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Detail panel — coming in future story.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Main content area — focus traversal order: 3
          Expanded(
            child: FocusTraversalOrder(
              order: const NumericFocusOrder(3),
              child: Focus(
                child: widget.navigationShell,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Flutter-rendered toolbar (replaces native NSToolbar in V1).
///
/// Height ~52pt, sits below the native macOS title bar (traffic lights).
/// Contains a right-aligned "New Task" button as per AC-4.
class _MacosToolbar extends StatelessWidget {
  final double height;
  final VoidCallback onNewTask;
  final OnTaskColors colors;

  const _MacosToolbar({
    required this.height,
    required this.onNewTask,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        border: Border(
          bottom: BorderSide(color: colors.surfaceSecondary, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: colors.accentPrimary,
              foregroundColor: colors.surfacePrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: onNewTask,
            icon: const Icon(Icons.add, size: 18),
            label: const Text(AppStrings.macosNewTask),
          ),
        ],
      ),
    );
  }
}
