import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

// ── Intents ───────────────────────────────────────────────────────────────────

/// Intent fired by ⌘N — opens new-task creation flow.
class NewTaskIntent extends Intent {
  const NewTaskIntent();
}

/// Intent fired by ⌘↩ — marks the focused task complete.
///
/// Placeholder for V2 (real task logic lives in Story 2.x).
class CompleteTaskIntent extends Intent {
  const CompleteTaskIntent();
}

/// Intent fired by Space — toggles the timer for the focused task.
///
/// Placeholder for V2 (real timer logic lives in Story 2.x).
class ToggleTimerIntent extends Intent {
  const ToggleTimerIntent();
}

/// Intent fired by ⌘K — opens the command palette.
class CommandPaletteIntent extends Intent {
  const CommandPaletteIntent();
}

/// Intent fired by ⌘1–⌘4 — navigates to the given sidebar [section].
///
/// [section]: 0 = Now, 1 = Today, 2 = Lists, 3 = Settings.
class NavigateSectionIntent extends Intent {
  final int section;
  const NavigateSectionIntent(this.section);
}

/// Intent fired by ⌘, — opens the Settings pane (section 3).
class OpenSettingsIntent extends Intent {
  const OpenSettingsIntent();
}

// ── Shortcut map ──────────────────────────────────────────────────────────────

/// All macOS keyboard shortcuts for [MacosShell].
///
/// Guard usage with [Platform.isMacOS] — these shortcuts must NOT be
/// registered on iOS.
///
/// Command key = `meta: true` on macOS (NOT `control: true`).
const Map<ShortcutActivator, Intent> macosShortcuts = {
  SingleActivator(LogicalKeyboardKey.keyN, meta: true): NewTaskIntent(),
  SingleActivator(LogicalKeyboardKey.enter, meta: true): CompleteTaskIntent(),
  SingleActivator(LogicalKeyboardKey.space): ToggleTimerIntent(),
  SingleActivator(LogicalKeyboardKey.keyK, meta: true): CommandPaletteIntent(),
  SingleActivator(LogicalKeyboardKey.digit1, meta: true):
      NavigateSectionIntent(0),
  SingleActivator(LogicalKeyboardKey.digit2, meta: true):
      NavigateSectionIntent(1),
  SingleActivator(LogicalKeyboardKey.digit3, meta: true):
      NavigateSectionIntent(2),
  SingleActivator(LogicalKeyboardKey.digit4, meta: true):
      NavigateSectionIntent(3),
  SingleActivator(LogicalKeyboardKey.comma, meta: true): OpenSettingsIntent(),
};
