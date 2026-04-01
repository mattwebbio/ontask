/// App-wide string constants for empty states and other copy.
///
/// Full l10n via Flutter gen-l10n / ARB pipeline is deferred to a later story.
/// All copy follows the "past self / future self" warm narrative voice.
class AppStrings {
  AppStrings._();

  // ── Now tab — rest state ─────────────────────────────────────────────────────
  static const String nowEmptyTitle = "You're clear for now.";
  static const String nowEmptySubtitleTemplate =
      "Next: {task} at {time}"; // used when next task is known

  // ── Today tab — no tasks ─────────────────────────────────────────────────────
  static const String todayEmptyTitle = "Nothing scheduled.";
  static const String todayEmptyAddCta = "Add something?";

  // ── Lists tab — no lists ─────────────────────────────────────────────────────
  static const String listsEmptyTitle = "No lists yet.";
  static const String listsEmptySubtitle =
      "Create a list to start organising what matters.";

  // ── Auth screen ──────────────────────────────────────────────────────────────
  static const String authSignInWithApple = "Sign in with Apple";
  static const String authSignInWithGoogle = "Sign in with Google";
  static const String authEmailLabel = "Email";
  static const String authPasswordLabel = "Password";
  static const String authSignInButton = "Sign In";
  static const String authForgotPassword = "Forgot password?";

  /// Plain-language error for invalid credentials — never expose error codes (NFR-UX2).
  static const String authErrorInvalidCredentials =
      "That email or password isn't quite right. Try again or reset your password.";
  static const String authErrorGeneric =
      "Something went wrong. Please try again.";

  /// Subtitle — New York serif / emotional voice copy only.
  static const String authSubtitle = "your past self is counting on you";

  // ── Onboarding flow ──────────────────────────────────────────────────────────

  /// Welcome headline on the sample schedule step.
  /// New York serif — emotional voice layer only (UX-DR32).
  /// Warm, first-person framing that shows what a day with On Task could feel like.
  static const String onboardingWelcomeHeadline =
      "Here's what a day with On Task could look like.";

  /// Secondary CTA to skip all onboarding and go straight to the app.
  /// No punitive language — "take me to the app" not "skip setup" phrasing.
  static const String onboardingSkipAll = "Skip setup — take me to the app";

  /// Primary CTA on the sample schedule step.
  static const String onboardingLetSetItUp = "Let's set it up";

  /// Calendar connection step — SF Pro
  static const String onboardingCalendarTitle = "Connect your calendar";

  /// Calendar connection step subhead.
  /// "Past self / future self" narrative voice (UX-DR32).
  static const String onboardingCalendarSubtitle =
      "So your future self isn't ambushed by what past you already committed to.";

  /// Calendar connection primary CTA.
  static const String onboardingCalendarConnect = "Connect Google Calendar";

  /// "Set this up later" affordance — present on every onboarding step (AC #2).
  static const String onboardingCalendarSkip = "Set this up later";

  /// Energy preferences step — SF Pro
  static const String onboardingEnergyTitle = "When does your energy peak?";

  /// Peak focus hours range label.
  static const String onboardingEnergyPeakLabel = "Peak focus hours";

  /// Low-energy hours range label.
  /// Frames broadly around executive dysfunction — no "ADHD-specific" framing (UX-DR36).
  static const String onboardingEnergyLowLabel = "Low-energy hours";

  /// Wind-down time range label.
  static const String onboardingEnergyWindDownLabel = "Wind-down time";

  /// Working hours step — SF Pro
  static const String onboardingWorkingHoursTitle = "When does your work day run?";

  /// Work start time label.
  static const String onboardingWorkingStartLabel = "Work starts";

  /// Work end time label.
  static const String onboardingWorkingEndLabel = "Work ends";

  /// Final onboarding CTA — routes to the main app.
  static const String onboardingDoneButton = "Done — show me my plan";

  /// Confirmation message shown after Google Calendar is successfully connected (stub).
  static const String onboardingCalendarConnected = "Calendar connected!";

  /// Button label to advance past the calendar-connected confirmation screen.
  static const String onboardingCalendarContinue = "Continue";

  /// Primary CTA on the energy preferences step — saves selections and advances.
  static const String onboardingEnergySaveButton = "Save & continue";

  /// "Done" label on time picker dismiss button inside modal popups.
  static const String onboardingTimePickerDone = "Done";

  // ── macOS shell ──────────────────────────────────────────────────────────────
  static const String macosNewTask = "New Task";
  static const String macosNavNow = "Now";
  static const String macosNavToday = "Today";
  static const String macosNavLists = "Lists";
  static const String macosNavSettings = "Settings";
  static const String macosCommandPaletteTitle = "Command Palette";
  static const String macosCommandPalettePlaceholder = "Search commands…";
  static const String macosSettingsTitle = "Settings";

  // ── Settings sections ────────────────────────────────────────────────────────
  static const String settingsTitle = "Settings";
  static const String settingsAppearance = "Appearance";
  static const String settingsSecurity = "Security";
  static const String settingsActiveSessions = "Active Sessions";
  static const String settingsScheduling = "Scheduling Preferences";
  static const String settingsAccount = "Account";
  static const String settingsNotifications = "Notifications";

  // ── Appearance settings ──────────────────────────────────────────────────────
  static const String appearanceThemeLabel = "Theme";
  static const String appearanceThemeClay = "Clay";
  static const String appearanceThemeSlate = "Slate";
  static const String appearanceThemeDusk = "Dusk";
  static const String appearanceThemeMonochrome = "Monochrome";
  static const String appearanceModeLight = "Light";
  static const String appearanceModeDark = "Dark";
  static const String appearanceModeSystem = "Automatic";
  static const String appearanceTextSizeLabel = "Text Size";

  // ── Active sessions ──────────────────────────────────────────────────────────
  static const String sessionsTitle = "Active Sessions";
  static const String sessionsCurrentDevice = "This device";
  static const String sessionsSignOut = "Sign out this device";
  static const String sessionsSignOutConfirmTitle = "Sign out device?";
  static const String sessionsSignOutConfirmMessage =
      "This will sign out that device. They'll need to sign in again to access On Task.";
  static const String sessionsSignOutCancel = "Cancel";
  static const String sessionsSignOutConfirm = "Sign out";
  static const String sessionsLastActive = "Last active";
  static const String sessionsSignOutSuccessMessage =
      "That device has been signed out.";
  static const String sessionsSignOutErrorMessage =
      "Something went wrong. Please try again.";

  // ── Sync / conflict resolution ───────────────────────────────────────────────
  static const String syncConflictResolvedMessage =
      "Some changes were updated to match what's on the server.";

  // ── Account settings ─────────────────────────────────────────────────────────
  static const String accountTitle = "Account";
  static const String accountExportData = "Export My Data";
  static const String accountDeleteAccount = "Delete Account";
  static const String accountTwoFactorAuth = "Two-Factor Authentication";

  // ── Export data ──────────────────────────────────────────────────────────────
  static const String exportDataTitle = "Export My Data";
  static const String exportDataDescription =
      "Download a copy of everything you've built here — your tasks, lists, and plans — as a ZIP archive with CSV and Markdown files.";
  static const String exportDataButton = "Export My Data";
  static const String exportDataSuccess =
      "Your export is ready. Choose where to save it.";
  static const String exportDataError =
      "Something went wrong preparing your export. Please try again.";
  static const String exportDataProgressMessage = "Preparing your data…";

  // ── Delete account ───────────────────────────────────────────────────────────
  static const String deleteAccountTitle = "Delete Account";
  static const String deleteAccountWarning =
      "Deleting your account is permanent and cannot be undone. All your tasks, lists, and preferences will be removed.";
  static const String deleteAccountContractsNote =
      "Any active commitment contracts will continue to their deadlines.";
  static const String deleteAccountIrreversibleNote =
      "Once deleted, your account cannot be recovered.";
  static const String deleteAccountConfirmPlaceholder = "delete my account";
  static const String deleteAccountConfirmHint =
      "Type 'delete my account' to confirm";
  static const String deleteAccountButton = "Delete My Account";

  /// Exact confirmation string — case-sensitive match required (FR60, AC #2).
  static const String deleteAccountConfirmMatch = "delete my account";

  // ── Farewell screen ──────────────────────────────────────────────────────────
  static const String farewellTitle = "Take care.";
  static const String farewellBody =
      "Your account has been deleted. We hope On Task helped you show up for the things that mattered. Wherever you're headed next, your past self is proud.";
  static const String farewellDoneButton = "Done";

  // ── Two-factor authentication — setup ────────────────────────────────────────
  static const String twoFactorSetupTitle = "Two-Factor Authentication";
  static const String twoFactorSetupInstructions =
      "Add a second layer of security to your account. You'll need an authenticator app like 1Password, Authy, or Google Authenticator.";
  static const String twoFactorQrInstructions =
      "Scan this QR code with your authenticator app:";
  static const String twoFactorManualEntryLabel = "Or enter this code manually:";
  static const String twoFactorBackupCodesTitle = "Save your backup codes";
  static const String twoFactorBackupCodesInstructions =
      "Store these somewhere safe. Each code can be used once if you lose access to your authenticator app.";
  static const String twoFactorConfirmCodeLabel =
      "Enter the 6-digit code from your authenticator app to confirm setup:";
  static const String twoFactorConfirmButton = "Enable Two-Factor Authentication";
  static const String twoFactorSetupSuccess =
      "Two-factor authentication is now enabled on your account.";
  static const String twoFactorSetupError =
      "That code doesn't match. Check your authenticator app and try again.";

  // ── Two-factor authentication — verify (login) ───────────────────────────────
  static const String twoFactorVerifyTitle = "Two-Factor Authentication";
  static const String twoFactorVerifyInstructions =
      "Enter the 6-digit code from your authenticator app to complete sign in.";
  static const String twoFactorVerifyCodeLabel = "Authentication code";
  static const String twoFactorVerifyButton = "Verify";
  static const String twoFactorVerifyError =
      "That code isn't right. Check your authenticator app and try again.";
  static const String twoFactorUseBackupCode = "Use a backup code instead";

  // ── Two-factor authentication — disable ──────────────────────────────────────
  static const String twoFactorDisableTitle = "Disable Two-Factor Authentication";
  static const String twoFactorDisableInstructions =
      "Enter your current authenticator code to disable two-factor authentication.";
  static const String twoFactorDisableButton = "Disable Two-Factor Authentication";

  /// Label for the "copy all backup codes" affordance on the 2FA setup screen.
  static const String twoFactorCopyAllCodes = "Copy all codes";

  /// Placeholder for the confirmation code field on the 2FA setup screen.
  static const String twoFactorConfirmCodePlaceholder = "000000";

  /// Generic error shown when account deletion fails unexpectedly.
  static const String deleteAccountError =
      "Something went wrong. Please try again.";

  // ── Add tab / task creation ───────────────────────────────────────────────
  static const String addTaskTitle = "Capture a task";
  static const String addTaskTitlePlaceholder = "What do you need to do?";
  static const String addTaskNotesPlaceholder =
      "Notes for your future self (optional)";
  static const String addTaskDueDateLabel = "Due date";
  static const String addTaskListLabel = "List";
  static const String addTaskCreateButton = "Add task";
  static const String addTaskSuccess = "Task captured.";
  static const String addTaskError = "Something went wrong. Please try again.";
  static const String addTaskTitleRequired = "Give your task a title.";

  // ── Scheduling hints — time window ──────────────────────────────────────────
  static const String taskTimeWindowLabel = 'Time window';
  static const String taskTimeWindowMorning = 'Morning';
  static const String taskTimeWindowAfternoon = 'Afternoon';
  static const String taskTimeWindowEvening = 'Evening';
  static const String taskTimeWindowCustom = 'Custom';
  static const String taskTimeWindowCustomStart = 'Start time';
  static const String taskTimeWindowCustomEnd = 'End time';

  // ── Scheduling hints — energy ─────────────────────────────────────────────
  static const String taskEnergyLabel = 'Energy';
  static const String taskEnergyHighFocus = 'High focus';
  static const String taskEnergyLowEnergy = 'Low energy';
  static const String taskEnergyFlexible = 'Flexible';

  // ── Scheduling hints — priority ───────────────────────────────────────────
  static const String taskPriorityLabel = 'Priority';
  static const String taskPriorityNormal = 'Normal';
  static const String taskPriorityHigh = 'High';
  static const String taskPriorityCritical = 'Critical';

  // ── Recurring tasks ────────────────────────────────────────────────────────
  static const String taskRecurrenceLabel = 'Repeats';
  static const String taskRecurrenceDaily = 'Daily';
  static const String taskRecurrenceWeekly = 'Weekly';
  static const String taskRecurrenceMonthly = 'Monthly';
  static const String taskRecurrenceCustom = 'Custom interval';
  static const String taskRecurrenceCustomDaysLabel = 'Every how many days?';
  static const String taskRecurrenceWeeklyDaysLabel = 'Which days?';
  static const String taskRecurrenceEditThisInstance = 'Edit this task only';
  static const String taskRecurrenceEditAllFuture = 'Edit this and all future tasks';
  static const String taskRecurrenceEditChoiceTitle = 'This is a recurring task';
  static const String taskDayMonday = 'Monday';
  static const String taskDayTuesday = 'Tuesday';
  static const String taskDayWednesday = 'Wednesday';
  static const String taskDayThursday = 'Thursday';
  static const String taskDayFriday = 'Friday';
  static const String taskDaySaturday = 'Saturday';
  static const String taskDaySunday = 'Sunday';
  static const String taskRecurrenceEveryNDays = 'Every {n} days';

  // ── Lists tab ─────────────────────────────────────────────────────────────
  static const String listsTitle = "Lists";

  // ── List sharing & invitations (FR15, FR16) ───────────────────────────────
  static const String shareListAction = 'Share list';
  static const String shareListTitle = 'Invite someone';
  static const String shareListEmailPlaceholder = 'Email address';
  static const String shareListSendButton = 'Send invitation';
  static const String shareListSuccessMessage = 'Invitation sent to {email}.';
  static const String shareListErrorInvalidEmail = 'Enter a valid email address.';
  static const String shareListErrorGeneric = 'Something went wrong. Please try again.';
  static const String inviteAcceptTitle = 'You\u2019re invited';
  static const String inviteAcceptSubtitle = 'Invited by {inviterName}';
  static const String inviteAcceptButton = 'Accept & join list';
  static const String inviteDeclineButton = 'Decline';
  static const String inviteExpiredMessage = 'This invitation has expired or is no longer valid.';
  static const String inviteGoToLists = 'Go to Lists';
  static const String invitationTrialNote = 'Start a free trial to join this list and access all features.';
  static const String listSharedIndicator = 'Shared';
  static const String listMemberCount = '{count} members';
  static const String createListButton = "Create a list";
  static const String createListTitle = "New list";
  static const String createListTitlePlaceholder = "What should we call it?";
  static const String createListDefaultDueDateLabel = "Default due date";
  static const String createListSuccess = "List created.";
  static const String listDetailTitle = "List";
  static const String showArchived = "Show archived";
  static const String hideArchived = "Hide archived";
  static const String archiveTaskAction = "Archive";
  static const String addTaskInList = "Add task";
  static const String addSectionInList = "Add section";
  static const String sectionTitlePlaceholder = "Section title";
  static const String taskTitlePlaceholder = "Task title";
  static const String editTaskNotes = "Notes";
  static const String editTaskDueDate = "Due date";

  // ── Shared UI actions ──────────────────────────────────────────────────────
  static const String actionDone = "Done";
  static const String actionCancel = "Cancel";
  static const String actionNone = "None";
  static const String submittingIndicator = "…";

  // ── Lists tab — error state ────────────────────────────────────────────────
  static const String listsError = "Something went wrong loading your lists. Please try again.";

  // ── Templates ──────────────────────────────────────────────────────────────
  static const String templateSaveAsTemplate = 'Save as template';
  static const String templateSaveDialogTitle = 'Save template';
  static const String templateNamePlaceholder = 'Template name';
  static const String templateSaveSuccess = 'Template saved.';
  static const String templateSaveError =
      'Something went wrong saving the template. Please try again.';
  static const String templateStartFromTemplate = 'Start from template';
  static const String templatePickerTitle = 'Choose a template';
  static const String templatePickerEmpty =
      'No templates yet. Save a list or section as a template to get started.';
  static const String templateApplyButton = 'Use this template';
  static const String templateApplySuccess = 'Template applied.';
  static const String templateApplyError =
      'Something went wrong applying the template. Please try again.';
  static const String templateDueDateOffsetLabel =
      'Offset due dates by how many days from today?';
  static const String templateDueDateOffsetNone = 'Keep original dates';
  static const String templateLibraryTitle = 'Templates';
  static const String templateDeleteConfirmTitle = 'Delete template?';
  static const String templateDeleteConfirmMessage =
      'This template will be permanently removed.';
  static const String templateDeleteSuccess = 'Template deleted.';
  static const String templateSourceList = 'List template';
  static const String templateSourceSection = 'Section template';
  static const String templateNameSuffix = ' template';

  // ── Task Dependencies ──────────────────────────────────────────────────
  static const String taskDependenciesLabel = 'Dependencies';
  static const String taskDependsOn = 'Depends on';
  static const String taskBlocks = 'Blocks';
  static const String taskAddDependency = 'Add dependency';
  static const String taskDependencyPickerTitle = 'Choose a task';
  static const String taskDependencyPickerEmpty = 'No other tasks to link.';
  static const String taskDependencyRemoved = 'Dependency removed.';
  static const String taskDependencyAdded = 'Dependency added.';
  static const String taskDependencyError =
      'Something went wrong. Please try again.';
  static const String taskDependencySelfError =
      "A task can\u2019t depend on itself.";
  static const String taskDependsOnCount = 'Depends on {count} tasks';
  static const String taskBlocksCount = 'Blocks {count} tasks';

  // ── Bulk Operations ──────────────────────────────────────────────────────
  static const String bulkSelectCount = '{count} selected';
  static const String bulkRescheduleAction = 'Reschedule';
  static const String bulkCompleteAction = 'Complete';
  static const String bulkDeleteAction = 'Delete';
  static const String bulkAssignAction = 'Assign';
  static const String bulkAssignDisabled = 'Shared lists coming soon';
  static const String bulkCompleteConfirmTitle = 'Complete {count} tasks?';
  static const String bulkCompleteConfirmMessage =
      'These tasks will be marked as done.';
  static const String bulkDeleteConfirmTitle = 'Delete {count} tasks?';
  static const String bulkDeleteConfirmMessage =
      'These tasks will be permanently removed.';
  static const String bulkRescheduleSuccess = '{count} tasks rescheduled.';
  static const String bulkCompleteSuccess = '{count} tasks completed.';
  static const String bulkDeleteSuccess = '{count} tasks deleted.';
  static const String bulkOperationError =
      'Something went wrong. Please try again.';

  // ── Today tab — header & sections ──────────────────────────────────────
  static const String todayHeaderTitle = 'Today';
  static const String todayTaskCount = '{count} tasks';
  static const String todayHoursPlanned = '{hours}h planned';
  static const String todayMorningSection = 'Morning';
  static const String todayAfternoonSection = 'Afternoon';
  static const String todayEveningSection = 'Evening';
  static const String todayOverdueSection = 'Overdue';
  static const String todayTaskCompleted = 'Task completed.';
  static const String todayTaskRescheduled = 'Rescheduled.';
  static const String todayReschedulePickerTitle = 'Reschedule to';
  static const String todayTimeAm = 'am';
  static const String todayTimePm = 'pm';

  // ── Schedule health strip ──────────────────────────────────────────────
  static const String scheduleHealthOnTrack = 'On track';
  static const String scheduleHealthAtRisk = 'At risk';
  static const String scheduleHealthCritical = 'Critical';
  static const String scheduleHealthDetail = '{hours}h available';
  static const String scheduleHealthAtRiskDetail = 'Running tight';
  static const String scheduleHealthCriticalDetail = 'Overbooked -- {hours}h';
  static const String scheduleHealthAtRiskTasks = 'At-risk tasks';

  // ── Now tab — task card ──────────────────────────────────────────────────
  static const String nowCardAttribution =
      'Your past self planned this for now';
  static const String nowCardAttributionFromList = 'From {listName}';
  static const String nowCardAttributionFromListAndAssignor =
      'From {listName} \u00b7 assigned by {assignor}';
  static const String nowCardStakeLabel = 'at stake';
  static const String nowCardMarkDone = 'Mark done';
  static const String nowCardSubmitProof = 'Submit proof';
  static const String nowCardStartWatchMode = 'Start Watch Mode';
  static const String nowCardProofPhoto = 'Photo proof';
  static const String nowCardProofWatchMode = 'Watch Mode';
  static const String nowCardProofHealthKit = 'HealthKit';
  static const String nowCardProofCalendarEvent = 'Calendar event';
  static const String nowCardVoiceOverStaked = '{amount} staked';
  static const String nowCardVoiceOverDue = 'due {deadline}';
  static const String nowCardVoiceOverFrom = 'from {listName}';
  static const String nowCardVoiceOverTimerElapsed = '{time} elapsed';
  static const String nowCardNextTaskHint = 'Next: {task} at {time}';

  // ── Date/time labels ─────────────────────────────────────────────────────
  static const String dateToday = 'Today';
  static const String dateTomorrow = 'Tomorrow';
  static const String monthJan = 'Jan';
  static const String monthFeb = 'Feb';
  static const String monthMar = 'Mar';
  static const String monthApr = 'Apr';
  static const String monthMay = 'May';
  static const String monthJun = 'Jun';
  static const String monthJul = 'Jul';
  static const String monthAug = 'Aug';
  static const String monthSep = 'Sep';
  static const String monthOct = 'Oct';
  static const String monthNov = 'Nov';
  static const String monthDec = 'Dec';

  // ── Timeline view ──────────────────────────────────────────────────────
  static const String timelineToggleToTimeline = 'Show timeline';
  static const String timelineToggleToList = 'Show list';
  static const String timelineNowIndicator = 'Now';
  static const String timelineEmptyBlock = 'Free time';
  static const String timelineBlockDuration = '{minutes} minutes';
  static const String timelineBlockVoiceOver =
      '{title}. {startTime}. {duration} minutes.';
  static const String timelineHourLabel = "{hour} o'clock";
  static const String timelineCalendarEvent = 'Calendar event';

  // ── Search & filter ──────────────────────────────────────────────────────
  static const String searchFieldLabel = 'Search all tasks';
  static const String searchFieldPlaceholder = 'Search tasks, notes...';
  static const String searchCancel = 'Cancel';
  static const String searchNoResults = 'No results found';
  static const String searchInitialHint = 'Search across all your lists';
  static const String searchFilterList = 'List';
  static const String searchFilterDate = 'Date';
  static const String searchFilterStatus = 'Status';
  static const String searchFilterHasStake = 'Has stake';
  static const String searchFilterStatusUpcoming = 'Upcoming';
  static const String searchFilterStatusOverdue = 'Overdue';
  static const String searchFilterStatusCompleted = 'Completed';
  static const String searchFilterRemove = 'Remove filter';
  static const String searchResultCount = '{count} results';
  static const String searchResultVoiceOver = '{title}. {listName}. {status}.';
  static const String searchFilterDateRange = '{from} \u2013 {to}';
  // Review fix #1: From/To labels for date picker (no inline strings)
  static const String searchFilterDateFrom = 'From';
  static const String searchFilterDateTo = 'To';

  // ── Timer ──────────────────────────────────────────────────────────────
  static const String timerStart = 'Start';
  static const String timerPause = 'Pause';
  static const String timerStop = 'Stop';
  static const String timerRunning = 'Timer running';
  static const String timerPaused = 'Timer paused';
  static const String timerElapsedFormat = '{time} elapsed';
  static const String timerStartVoiceOver = 'Start timer';
  static const String timerPauseVoiceOver = 'Pause timer';
  static const String timerStopVoiceOver = 'Stop timer';
  static const String timerAnnouncementTemplate = '{time} elapsed on {task}';
  static const String todayRowStartTimer = 'Start timer';
  static const String todayRowWhyHere = 'Why is this scheduled here?';

  // ── Prediction badge ─────────────────────────────────────────────────────
  static const String predictionBadgeOnTrack = 'On track · {date}';
  static const String predictionBadgeAtRisk = 'At risk · {date}';
  static const String predictionBadgeBehind = 'Behind · {date}';
  static const String predictionBadgeUnknown = '—';
  static const String predictionBadgeSheetTitle = 'Forecast';
  static const String predictionBadgeTasksRemaining = '{count} tasks remaining';
  static const String predictionBadgeEstimatedTime = '{minutes} min estimated';
  static const String predictionBadgeAvailableWindows = '{count} time windows available';
  static const String predictionBadgeStatusOnTrack = 'on track';
  static const String predictionBadgeStatusAtRisk = 'at risk';
  static const String predictionBadgeStatusBehind = 'behind';
  static const String predictionBadgeStatusUnknown = 'unknown';
  static const String predictionBadgeVoiceOver =
      'Predicted completion {status}. {date}. Tap for forecast reasoning.';
  static const String predictionBadgeVoiceOverUnknown =
      'Predicted completion unknown. Tap for forecast reasoning.';

  // ── Schedule Change Banner ────────────────────────────────────────────────
  static const String scheduleChangeBannerMessage =
      'Your schedule has been updated';
  static const String scheduleChangeSeeWhat = 'See what changed';
  static const String scheduleChangeBannerDismiss = 'Dismiss';
  static const String scheduleChangeDismissVoiceOver =
      'Dismiss schedule change banner';
  static const String scheduleChangesSheetTitle = 'Schedule changes';
  static const String scheduleChangeMovedFormat = '{title} · moved to {time}';
  static const String scheduleChangeRemovedFormat =
      '{title} · removed from schedule';
  static const String scheduleChangeBannerVoiceOver =
      'Schedule updated. {count} tasks changed. Double-tap to see what changed.';

  // ── Overbooking Warning Banner ────────────────────────────────────────────
  static const String overbookingWarningMessage =
      'Schedule overloaded · {percent}% capacity';
  static const String overbookingWarningAtRisk = 'At risk';
  static const String overbookingWarningCritical = 'Critical';
  static const String overbookingReschedule = 'Reschedule';
  static const String overbookingExtendDeadline = 'Extend deadline';
  static const String overbookingAcknowledge = 'Acknowledge';
  static const String overbookingRequestExtension =
      'Request deadline extension from partner';
  static const String overbookingWarningVoiceOver =
      'Schedule overloaded at {percent}% capacity. Available actions: Reschedule, Extend deadline, Acknowledge.';

  // ── Chapter Break Screen ─────────────────────────────────────────────────
  /// Headline — New York serif, 34pt. Warm completion framing (UX-DR13).
  static const String chapterBreakHeadline = "that one's done.";

  /// Sub-copy — New York serif, 20pt. Future-self framing.
  static const String chapterBreakSubcopy =
      'What does your future self need now?';

  /// CTA button label.
  static const String chapterBreakCta = 'Keep going';

  /// VoiceOver announcement for the chapter break screen (UX spec §9.6).
  static const String chapterBreakVoiceOverAnnounce =
      "A task has been completed. You're on a roll.";

  /// Label prefix for the stake-returned row (shown when stakeAmount != null).
  static const String chapterBreakStakeLabel = 'Stake returned';

  // ── NLP task capture (FR1b) ──────────────────────────────────────────────

  /// Placeholder for the Quick Capture NLP input field.
  /// Uses "future self" voice per UX-DR spec line 1427.
  static const String addTaskNlpPlaceholder = 'What does your future self need to do?';

  /// Inline warning shown when the AI returns low confidence for a task utterance.
  static const String addTaskNlpLowConfidence =
      "I couldn't understand that — try something like 'call dentist Thursday at 2pm'";

  /// Generic error shown when the NLP parse request fails unexpectedly.
  static const String addTaskNlpError = 'Something went wrong. Please try again.';

  /// Loading indicator label shown while the NLP parse is in progress.
  static const String addTaskNlpParsing = 'Understanding your task\u2026';

  /// Mode toggle label for Quick Capture NLP mode.
  static const String addTaskModeQuickCapture = 'Quick Capture';

  /// Mode toggle label for Form mode.
  static const String addTaskModeForm = 'Form';

  /// Pill label for the parsed task title.
  static const String addTaskNlpTitle = 'Task';

  /// Pill label for the parsed due date.
  static const String addTaskNlpDueDate = 'Due';

  /// Pill label for the parsed estimated duration.
  static const String addTaskNlpDuration = 'Duration';

  /// Pill label for the parsed energy requirement.
  static const String addTaskNlpEnergy = 'Energy';

  /// Pill label for the parsed list assignment.
  static const String addTaskNlpList = 'List';

  // ── Guided Chat task capture (FR14/UX-DR15) ──────────────────────────────

  /// Mode toggle label for Guided Chat mode.
  static const String addTaskModeGuided = 'Guided';

  /// Placeholder for the Guided Chat reply input field.
  static const String guidedChatInputPlaceholder = 'Reply\u2026';

  /// Generic error shown when the guided chat request fails unexpectedly.
  static const String guidedChatError = 'Something went wrong. Please try again.';

  /// Error shown when the guided chat LLM times out.
  static const String guidedChatTimeoutError = 'The assistant timed out. Please try again.';

  /// Label for the create task button shown in the guided chat confirmation card.
  static const String guidedChatCreateButton = 'Create task';

  /// Brief description shown in the AddTabSheet body when Guided mode is active.
  /// "Future self" voice (UX spec line 1488).
  static const String guidedChatDescription = 'Let\u2019s build your task together.';

  /// VoiceOver announcement when guided chat is dismissed without saving.
  static const String guidedChatDismissed = 'Chat dismissed.';

  // ── Scheduling nudge (FR14) ──────────────────────────────────────────────
  /// CTA label on TodayTaskRow swipe action that opens the AI nudge sheet.
  static const String todayRowNudge = 'Reschedule with AI';

  /// Title shown at the top of the NudgeInputSheet bottom sheet.
  static const String nudgeSheetTitle = 'When would you like to move this?';

  /// Inline warning shown when the AI returns low confidence (user can retry).
  static const String nudgeConfidenceLow =
      "I couldn't understand that — try something like 'move to tomorrow morning'";

  /// Generic error shown when the nudge request fails unexpectedly.
  static const String nudgeError = 'Something went wrong. Please try again.';

  // ── Task assignment strategies (FR17-18) ──────────────────────────────────
  static const String listSettingsTitle = 'List Settings';
  static const String assignmentStrategyLabel = 'Assignment strategy';
  static const String assignmentStrategyNone = 'None';
  static const String assignmentStrategyRoundRobin = 'Round-robin';
  static const String assignmentStrategyLeastBusy = 'Least busy';
  static const String assignmentStrategyAiAssisted = 'AI-assisted';
  static const String assignmentStrategyRoundRobinDesc = 'Tasks rotate through members in join order.';
  static const String assignmentStrategyLeastBusyDesc = 'Assigns to the member with fewest tasks in the due-date window.';
  static const String assignmentStrategyAiAssistedDesc = 'Considers task duration, workload, and energy preferences.';
  static const String assignmentAutoAssignButton = 'Auto-assign now';
  static const String assignmentAutoAssignSuccess = '{count} tasks assigned.';
  static const String assignmentStrategyUpdateError = 'Could not update strategy. Please try again.';
  static const String taskAssignedToLabel = 'Assigned';

  // ── Shared tasks in personal schedule (FR19) ─────────────────────────────
  /// Today-tab attribution chip for tasks from shared lists.
  static const String taskFromListLabel = 'from {listName}';

  /// Accessibility label for assignor attribution on an assigned task.
  static const String taskAssignedByLabel = 'Assigned by {name}';

  /// Feedback toast after successfully unassigning a task.
  static const String taskUnassignSuccess = 'Task unassigned.';

  /// Error message shown when unassignment fails.
  static const String taskUnassignError =
      'Could not unassign task. Please try again.';

  // ── Accountability settings cascade (FR20) ──────────────────────────────
  /// Section header in List Settings and section accountability pickers.
  static const String accountabilitySettingsLabel = 'Proof requirement';

  /// No proof required option.
  static const String accountabilityNone = 'None';

  /// Photo proof option.
  static const String accountabilityPhoto = 'Photo proof';

  /// Watch Mode option.
  static const String accountabilityWatchMode = 'Watch Mode';

  /// HealthKit option.
  static const String accountabilityHealthKit = 'HealthKit';

  /// Description for None option.
  static const String accountabilityNoneDesc = 'No proof required for tasks in this list.';

  /// Description for Photo proof option.
  static const String accountabilityPhotoDesc = 'Members must submit a photo when completing tasks.';

  /// Description for Watch Mode option.
  static const String accountabilityWatchModeDesc = 'Tasks require a Watch Mode session to complete.';

  /// Description for HealthKit option.
  static const String accountabilityHealthKitDesc = 'Completion is verified via HealthKit data.';

  /// Badge shown on task row when proofModeIsCustom = true.
  static const String accountabilityCustomBadge = 'Custom';

  /// Accessibility label for inherited proof mode indicators.
  static const String accountabilityInheritedLabel = 'Inherited';

  /// Error message when proof requirement update fails.
  static const String accountabilityUpdateError = 'Could not update proof requirement. Please try again.';

  /// Note shown in task edit when user overrides to None/standard while section has a requirement.
  static const String accountabilityOverrideToStandardNote = 'This overrides the section default.';

  // ── Shared actions ──────────────────────────────────────────────────────
  static const String actionNotImplemented =
      'This action is not yet available in this version.';
  static const String actionDelete = 'Delete';
  static const String actionRename = 'Rename';
  static const String actionOk = 'OK';
  static const String dialogErrorTitle = 'Error';

  // ── Proof mode display ───────────────────────────────────────────────────
  static const String proofModeStandard = 'Standard (no proof)';
  static const String proofModeCalendarEvent = 'Calendar event';
}
