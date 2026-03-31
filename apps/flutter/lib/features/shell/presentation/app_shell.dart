import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../search/presentation/search_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import 'add_tab_sheet.dart';
import 'macos_shell.dart';
import 'shell_providers.dart';

/// The main navigation shell hosting the four-tab Cupertino tab bar.
///
/// Tab layout: Now (0), Today (1), Add (2), Lists (3)
///
/// The Add tab (index 2) is an ACTION tab — tapping it opens [AddTabSheet] as
/// a modal bottom sheet. It does NOT become a persistent navigation destination.
/// [StatefulNavigationShell.goBranch] is never called with index 2.
///
/// The Add sheet can also be triggered from within a tab screen (e.g. from
/// [TodayEmptyState]) via [openAddSheetRequestProvider] — [AppShell] watches
/// the provider and responds to counter increments.
///
/// [navigationShell] is provided by go_router's [StatefulShellRoute.indexedStack].
class AppShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({required this.navigationShell, super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late final CupertinoTabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialise at branch 0 (Now). Add (branch 2) is never a real active tab.
    _tabController = CupertinoTabController(
      initialIndex: widget.navigationShell.currentIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openAddSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTabSheet(),
    );
  }

  /// Handles tab bar taps.
  ///
  /// If index == 2 (Add), opens the modal sheet and resets the controller back
  /// to the previously active tab WITHOUT updating go_router branch.
  /// For all other indices, delegates to go_router.
  void _onTabTapped(int index) {
    if (index == 2) {
      // Reset the controller to the previous active tab immediately —
      // the Add tab is never a real destination
      _tabController.index = widget.navigationShell.currentIndex;

      _openAddSheet();
      return; // critical: do not call goBranch(2)
    }
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    // macOS: delegate to macOS-specific three/two-pane shell.
    // iOS: continue with CupertinoTabScaffold below — unchanged.
    if (Platform.isMacOS) {
      return MacosShell(navigationShell: widget.navigationShell);
    }

    final colors = Theme.of(context).extension<OnTaskColors>()!;

    // Watch the Add sheet request signal from within-tab CTAs (e.g. TodayEmptyState).
    // Any change in value triggers the sheet to open.
    ref.listen<int>(openAddSheetRequestProvider, (previous, next) {
      if (previous != null && next > previous) {
        _openAddSheet();
      }
    });

    return CupertinoTabScaffold(
      controller: _tabController,
      tabBar: CupertinoTabBar(
        activeColor: colors.accentPrimary,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.clock),
            label: 'Now',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.list_bullet),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.add_circled),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.collections),
            label: 'Lists',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        // Wrap the navigation shell in a scaffold that includes a persistent
        // navigation header with the settings (profile) icon (UX spec: "Settings
        // accessible via profile/account icon in the navigation header").
        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            backgroundColor: colors.surfacePrimary,
            middle: const Text('On Task'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).push(
                    CupertinoPageRoute<void>(
                      builder: (_) => const SearchScreen(),
                    ),
                  ),
                  child: Icon(
                    CupertinoIcons.search,
                    color: colors.accentPrimary,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).push(
                    CupertinoPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  ),
                  child: Icon(
                    CupertinoIcons.person_crop_circle,
                    color: colors.accentPrimary,
                  ),
                ),
              ],
            ),
          ),
          child: widget.navigationShell,
        );
      },
    );
  }
}
