import 'package:flutter/material.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';

/// macOS sidebar navigation widget.
///
/// Displays four navigation items (Now, Today, Lists, Settings) and a
/// "New Task" button at the top. Active item is highlighted with
/// [OnTaskColors.accentPrimary]. No bottom tab bar on macOS.
class MacosSidebar extends StatelessWidget {
  /// Currently selected navigation index (0–3).
  final int selectedIndex;

  /// Called when a nav item is tapped.
  final ValueChanged<int> onItemTapped;

  /// Called when the "New Task" button is tapped.
  final VoidCallback onNewTask;

  const MacosSidebar({
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onNewTask,
    super.key,
  });

  static const _navItems = [
    (label: AppStrings.macosNavNow, icon: Icons.access_time_outlined),
    (label: AppStrings.macosNavToday, icon: Icons.list_alt_outlined),
    (label: AppStrings.macosNavLists, icon: Icons.collections_outlined),
    (label: AppStrings.macosNavSettings, icon: Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    return ColoredBox(
      color: colors.surfaceSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Toolbar area — sits below the native macOS title bar
          _NewTaskButton(onNewTask: onNewTask, colors: colors),
          const Divider(height: 1, thickness: 1),
          // Navigation items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = index == selectedIndex;
                return _SidebarNavItem(
                  label: item.label,
                  icon: item.icon,
                  isSelected: isSelected,
                  onTap: () => onItemTapped(index),
                  colors: colors,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// "New Task" button displayed at the top of the sidebar (above nav items).
class _NewTaskButton extends StatelessWidget {
  final VoidCallback onNewTask;
  final OnTaskColors colors;

  const _NewTaskButton({required this.onNewTask, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SizedBox(
        height: 36,
        child: FilledButton.icon(
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
      ),
    );
  }
}

/// A single nav item row in the sidebar.
class _SidebarNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final OnTaskColors colors;

  const _SidebarNavItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: Icon(
        icon,
        size: 20,
        color: isSelected ? colors.accentPrimary : colors.textSecondary,
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isSelected ? colors.accentPrimary : colors.textPrimary,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
      ),
      selected: isSelected,
      selectedTileColor: colors.accentPrimary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: onTap,
    );
  }
}
