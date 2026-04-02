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

  // ── Shared proof visibility (FR21) ──────────────────────────────────────────
  /// Shown on task row when proof is retained (own task — completedByName is null).
  static const String proofRetainedLabel = 'Proof submitted';

  /// Shown on task row when another member submitted proof. Use {name} substitution.
  static const String proofCompletedByLabel = '{name} submitted proof';

  /// Metadata line in proof sheet. Use {name} and {dateTime} substitutions.
  static const String proofCompletedByAtLabel = 'Completed by {name} · {dateTime}';

  /// Bottom sheet header title.
  static const String proofDetailTitle = 'Proof';

  /// Shown in proof sheet when proofMediaUrl is null.
  static const String proofNotAvailableMessage = 'Proof not available or was discarded.';

  /// Error message when proof fails to load.
  static const String proofLoadError = 'Could not load proof. Please try again.';

  /// Footer note in proof sheet — privacy scoping (NFR-S4).
  static const String proofPrivacyNote = 'Visible to list members only.';

  // ── Member management & shared ownership (FR62, FR75) ──────────────────────
  /// Section header in List Settings.
  static const String membersSettingsLabel = 'Members';

  /// Role badge for owner members.
  static const String memberRoleOwner = 'Owner';

  /// Role badge for regular members.
  static const String memberRoleMember = 'Member';

  /// Action sheet option — grant owner role to member.
  static const String memberGrantOwner = 'Grant Owner';

  /// Action sheet option — revoke owner role from member.
  static const String memberRevokeOwner = 'Revoke Owner';

  /// Action sheet option — remove member from list.
  static const String memberRemoveFromList = 'Remove from list';

  /// Confirmation dialog title when removing a member.
  static const String removeMemberConfirmTitle = 'Remove member?';

  /// Confirmation dialog message when removing a member.
  static const String removeMemberConfirmMessage =
      'This member will lose access to the list immediately and their assigned tasks will be unassigned.';

  /// Button label for leaving a list.
  static const String leaveListButton = 'Leave list';

  /// Confirmation dialog title when leaving a list.
  static const String leaveListConfirmTitle = 'Leave list?';

  /// Confirmation dialog message when leaving a list.
  static const String leaveListConfirmMessage =
      'You will lose access to this list. Your assigned tasks will be unassigned. You cannot rejoin without a new invitation.';

  /// Tooltip shown on disabled "Leave list" button when user is the last owner.
  static const String leaveListLastOwnerNote =
      'You cannot leave as the last owner. Promote another member to owner first.';

  /// Error shown when a member management action fails.
  static const String memberManagementError = 'Could not update member. Please try again.';

  /// Error shown when leaving a list fails.
  static const String leaveListError = 'Could not leave list. Please try again.';

  // ── Payment method setup (FR23, FR64) ──────────────────────────────────────
  /// Settings tile label — Settings → Payments navigation entry.
  static const String settingsPayments = 'Payments';

  /// Screen title for the PaymentSettingsScreen navigation bar.
  static const String paymentSetupTitle = 'Payment Method';

  /// CTA button label when no payment method is stored.
  static const String paymentSetupButton = 'Set up payment method';

  /// CTA button label when a payment method is already stored (update path).
  static const String paymentUpdateButton = 'Update payment method';

  /// Destructive action button label to remove stored payment method.
  static const String paymentRemoveButton = 'Remove payment method';

  /// Confirmation dialog title shown before removing a payment method.
  static const String paymentRemoveConfirmTitle = 'Remove payment method?';

  /// Confirmation dialog message shown before removing a payment method.
  static const String paymentRemoveConfirmMessage =
      'Your stored card will be removed. You will need to set up a new payment method before adding a commitment stake.';

  /// Inline note shown when "Remove" is blocked because of active stakes.
  static const String paymentRemoveBlockedByStakes =
      'You have active commitment stakes. Remove all stakes before removing your payment method.';

  /// Generic error shown when payment setup fails unexpectedly.
  static const String paymentSetupError =
      'Could not complete payment setup. Please try again.';

  /// Section label above the stored payment method display row.
  static const String paymentMethodDisplay = 'Payment method';

  // ── Stake setting UI (FR22, FR28, UX-DR7) ─────────────────────────────────
  static const String stakeAddButton = 'Add stake';
  static const String stakeSliderTitle = 'Set your stake';
  static const String stakeZoneLowLabel = 'Low';
  static const String stakeZoneMidLabel = 'Mid';
  static const String stakeZoneHighLabel = 'High';
  static const String stakeHighZoneGuidance =
      "This amount will cause real financial pain if missed. That's the point — but only if you're sure.";
  static const String stakeConfirmButton = 'Lock it in.';
  static const String stakeRemoveConfirmTitle = 'Remove stake?';
  static const String stakeRemoveConfirmMessage =
      'Your financial commitment will be cancelled. The task will continue as a normal unstaked task.';
  static const String stakeSetError = 'Could not set stake. Please try again.';
  static const String stakePaymentMethodRequired =
      "To lock in a stake, you'll need to add a payment method.";
  static const String stakeSetupPaymentCta = 'Set up payment';
  static const String stakeAmountPlaceholder = 'e.g. 25';
  // NOTE: AppStrings.actionDelete, AppStrings.actionCancel, AppStrings.actionOk,
  //       AppStrings.dialogErrorTitle already exist — do NOT recreate.
  // NOTE: AppStrings.nowCardStakeLabel ('at stake') and
  //       AppStrings.chapterBreakStakeLabel already exist.

  // ── Stake modification & cancellation (FR63) ──────────────────────────────
  /// Prefix for the modification window label. Full text rendered as:
  /// "You can adjust or cancel this stake until Apr 2 at 3:00 PM"
  static const String stakeModificationWindowPrefix =
      'You can adjust or cancel this stake until';
  static const String stakeModificationWindowAt = 'at';
  static const String stakeLockedMessage =
      "This stake is locked — the deadline is too close to change it";
  static const String stakeLockedError =
      'This stake is locked and can no longer be modified.';
  static const String stakeCancelError =
      'Could not cancel stake. Please try again.';

  // ── Charity selection (FR26, UX-DR8) ──────────────────────────────────────
  static const String charitySheetTitle = 'Choose a cause';
  static const String charitySearchPlaceholder = 'Search nonprofits…';
  static const String charityConfirmButton = 'Confirm';
  static const String charitySelectCta = 'Choose a cause';
  static const String charityChangeCta = 'Change';
  static const String charityLoadError = 'Could not load nonprofits. Please try again.';
  static const String charitySetError = 'Could not save your charity selection. Please try again.';
  static const String charitySearchEmpty = 'No nonprofits found. Try a different search.';

  // ── Impact Dashboard (FR27, UX-DR19) ──────────────────────────────────────
  static const String impactDashboardTitle = 'Your impact';
  static const String impactLoadError = 'Could not load your impact data. Please try again.';
  static const String impactEmptyMessage =
      'Your story is just beginning. Complete your first staked commitment to see your impact here.';
  static const String impactShareButton = 'Share';
  static const String impactCharityBreakdownTitle = 'Where your money went';
  static const String impactTotalDonatedLabel = 'donated to charity';
  static const String impactCommitmentsKeptLabel = 'commitments kept';
  static const String settingsImpact = 'Impact';

  // ── Commitment lock ceremony (UX-DR8, UX-DR20, UX-DR32) ─────────────────────
  /// Eyebrow label on the full-screen Commitment Ceremony Card.
  static const String commitmentCeremonyEyebrow = 'YOUR COMMITMENT';

  /// Sub-copy on the Commitment Ceremony Card — future self voice (UX-DR32).
  static const String commitmentCeremonyCopy =
      'Your future self is counting on you.';

  /// Error shown if the lock API call fails (for future implementation).
  static const String lockConfirmError =
      'Could not lock your commitment. Please try again.';

  // ── Group commitments & pool mode (FR29, FR30) ──────────────────────────────
  static const String groupCommitmentProposalTitle = 'Group commitment';
  static const String groupCommitmentReviewTitle = 'Review commitment';
  static const String groupCommitmentApproveButton = 'Approve & set stake';
  static const String groupCommitmentPendingStatus = 'Pending approval';
  static const String groupCommitmentActiveStatus = 'All approved';
  static const String groupCommitmentMembersApprovedLabel = 'members approved';
  static const String groupCommitmentProposeError =
      'Could not propose group commitment. Please try again.';
  static const String groupCommitmentApproveError =
      'Could not approve commitment. Please try again.';
  static const String poolModeSectionTitle = 'Pool mode';
  static const String poolModeDescription =
      'In pool mode, everyone is charged if any opted-in member misses their task. '
      "This is separate from approving the commitment — opt in only if you're sure.";
  static const String poolModeToggleLabel = 'Join pool mode';
  static const String poolModeOptInError =
      'Could not update pool mode preference. Please try again.';

  // ── Billing history (FR65, Story 6.9) ────────────────────────────────────────
  /// Navigation entry label in PaymentSettingsScreen.
  static const String billingHistoryNavLabel = 'Billing History';

  /// Screen title for BillingHistoryScreen navigation bar.
  static const String billingHistoryTitle = 'Billing History';

  /// Empty state message when no billing entries exist.
  static const String billingHistoryEmpty =
      'No charges or cancellations yet.';

  /// Error message shown when billing history fails to load.
  static const String billingHistoryLoadError =
      'Could not load billing history. Please try again.';

  /// Disbursement status label — charge forwarded to charity.
  static const String billingStatusDonated = 'Donated';

  /// Disbursement status label — charge awaiting processing.
  static const String billingStatusPending = 'Pending';

  /// Disbursement status label — charge processing failed.
  static const String billingStatusFailed = 'Failed';

  /// Disbursement status label — stake was cancelled, no charge.
  static const String billingStatusCancelled = 'Cancelled';

  /// Subtitle shown for cancelled stake entries in billing history.
  static const String billingCancelledNoCharge = 'cancelled — no charge';

  // ── Proof Capture Modal (FR31, Story 7.1) ────────────────────────────────────
  /// Sheet title — "Submit proof for [task name]"
  static const String proofModalTitle = 'Submit proof for';

  /// Photo/Video path title.
  static const String proofPathPhotoTitle = 'Photo or Video';

  /// Photo/Video path subtitle.
  static const String proofPathPhotoSubtitle = 'Capture with your camera';

  /// HealthKit Auto path title (iOS only — hidden on macOS).
  static const String proofPathHealthKitTitle = 'HealthKit';

  /// HealthKit Auto path subtitle.
  static const String proofPathHealthKitSubtitle = 'Auto-verify from Apple Health';

  /// Screenshot/Document path title.
  static const String proofPathScreenshotTitle = 'Screenshot or Document';

  /// Screenshot/Document path subtitle.
  static const String proofPathScreenshotSubtitle = 'Upload PNG, JPG, or PDF';

  /// Offline path title (shown only when device is offline).
  static const String proofPathOfflineTitle = 'Save for Later';

  /// Offline path subtitle.
  static const String proofPathOfflineSubtitle =
      "Proof saved — will sync when you're back online";

  /// Back button label in sub-view.
  static const String proofModalBack = 'Back';

  /// Stub sub-view placeholder (shown until Stories 7.2–7.6 implement real sub-views).
  static const String proofPathComingSoon = 'This proof path is coming soon.';

  // ── Photo Proof & AI Verification (FR31-32, Story 7.2) ──────────────────────
  /// Verifying animation copy (UX-DR30) — "Reviewing your proof…"
  static const String proofVerifyingCopy = 'Reviewing your proof\u2026';

  /// Approved state label.
  static const String proofAcceptedLabel = 'Proof accepted';

  /// Rejected state label.
  static const String proofRejectedLabel = "Couldn't verify \u2014 dispute or resubmit";

  /// Timeout error copy.
  static const String proofTimeoutCopy = 'Verification timed out \u2014 try again.';

  /// Retry CTA.
  static const String proofRetakeCta = 'Take another';

  /// Dispute CTA.
  static const String proofDisputeCta = 'Request review';

  /// Submit captured media CTA.
  static const String proofSubmitCta = 'Submit';

  /// Shutter button accessibility label.
  static const String proofShutterLabel = 'Take photo';

  // ── Screenshot & Document Proof (FR36, Story 7.3) ──────────────────────────
  /// CTA to open the system file picker.
  static const String proofScreenshotPickCta = 'Choose a file';

  /// Subtitle below the pick CTA showing accepted formats and size limit.
  static const String proofScreenshotPickSubtitle =
      'PNG, JPG, or PDF \u2014 up to 25 MB';

  /// "Choose another file" button in preview state.
  static const String proofScreenshotRetakeCta = 'Choose another';

  /// Alert title when the chosen file exceeds the 25 MB limit.
  static const String proofScreenshotFileTooLargeTitle = 'File too large';

  /// Alert message shown when the chosen file exceeds the 25 MB limit.
  static const String proofScreenshotFileTooLargeMessage =
      'Please choose a file smaller than 25 MB.';

  // ── Watch Mode / Live Session (FR33-34, FR66-67, Story 7.4) ─────────────────
  /// Watch Mode sub-view title.
  static const String watchModeTitle = 'Watch Mode';

  /// Privacy note shown before starting a Watch Mode session.
  static const String watchModePrivacyNote =
      'Your camera is used to check you\u2019re working. No footage is recorded or stored.';

  /// Error shown when no camera is available.
  static const String watchModeNoCameraError = 'No camera found on this device.';

  /// CTA to start a Watch Mode session.
  static const String watchModeStartCta = 'Start Watch Mode';

  /// Button to end an active Watch Mode session.
  static const String watchModeEndSessionCta = 'End Session';

  /// Session summary screen title (FR67).
  static const String watchModeSummaryTitle = 'Session complete';

  /// CTA to submit session data as proof (FR67).
  static const String watchModeSubmitProofCta = 'Submit as proof';

  /// CTA to dismiss session summary without submitting (FR67).
  static const String watchModeDoneCta = 'Done';

  /// Copy shown during session data submission animation.
  static const String watchModeSubmittingCopy = 'Submitting session\u2026';

  /// Approved state label for Watch Mode session verification.
  static const String watchModeApprovedLabel = 'Session verified';

  /// Copy shown while session is ending.
  static const String watchModeEndingCopy = 'Ending session\u2026';

  /// "Try again" CTA in Watch Mode timeout state.
  static const String watchModeTryAgainCta = 'Try again';

  // ── Watch Mode path selector strings (Story 7.5 enum split) ────────────────
  /// Watch Mode path row title in path selector (was proofPathHealthKitTitle pre-7.5 split).
  static const String proofPathWatchModeTitle = 'Watch Mode';

  /// Watch Mode path row subtitle in path selector.
  static const String proofPathWatchModeSubtitle = 'Focus session with camera';

  // ── HealthKit Auto-Verification (FR35, FR47, Story 7.5) ─────────────────────
  /// HealthKit proof sub-view title.
  static const String healthKitProofTitle = 'HealthKit Auto-Verify';

  /// Body copy shown in idle state.
  static const String healthKitProofBody =
      'We\u2019ll check your recent Apple Health data to verify this task was completed.';

  /// CTA to trigger HealthKit permission + read.
  static const String healthKitProofCheckCta = 'Check Apple Health';

  /// Title shown when matching HealthKit data was found.
  static const String healthKitProofFoundTitle = 'Activity found';

  /// Title shown when no matching HealthKit data was found.
  static const String healthKitProofNotFoundTitle = 'No activity found';

  /// Body copy shown in not-found state.
  static const String healthKitProofNotFoundBody =
      'We couldn\u2019t find matching Apple Health data. Try submitting photo proof instead.';

  /// CTA to fall back to photo proof when HealthKit data is not found.
  static const String healthKitProofPhotoFallbackCta = 'Submit photo instead';

  /// Badge shown on Now tab card while HealthKit verification is in-progress (UX-DR31).
  static const String healthKitVerifyingBadge = 'Verifying';

  /// Badge shown on Now tab card when HealthKit buffer window expired without data (UX-DR31).
  static const String healthKitVerifyManuallyBadge = 'Verify manually';

  // ── Offline Proof Queue (FR37, ARCH-26, Story 7.6) ──────────────────────────

  /// OfflineProofSubView title.
  static const String offlineProofTitle = 'Save for Later';

  /// Body copy explaining offline queuing.
  static const String offlineProofBody =
      'Your proof will be saved on this device and submitted automatically when you\u2019re back online.';

  /// CTA to save proof for later sync.
  static const String offlineProofSaveCta = 'Save for Later';

  /// Copy shown while the enqueue write is in progress.
  static const String offlineProofQueueingCopy = 'Saving\u2026';

  /// Confirmation shown after successful enqueue (NFR-UX1).
  static const String offlineProofQueuedConfirmation =
      'Proof saved \u2014 will sync when you\u2019re back online';

  /// Error copy when enqueue write fails.
  static const String offlineProofErrorCopy =
      'Couldn\u2019t save your proof. Please try again.';

  // ── Proof Retention Settings (FR38, NFR-R8, Story 7.7) ──────────────────────

  /// Toggle label on the proof confirmation screen.
  static const String proofRetainLabel = 'Keep as completion record';

  /// Secondary label explaining retention on the proof confirmation screen.
  static const String proofRetainSubtitle =
      'Proof stays attached to this task until it\u2019s deleted';

  /// Secondary label explaining discard on the proof confirmation screen.
  static const String proofDiscardSubtitle =
      'Proof will be deleted within 24 hours of verification';

  /// Confirm CTA after choosing retention preference.
  static const String proofRetainConfirmCta = 'Done';

  /// Settings screen Privacy tile label.
  static const String settingsPrivacy = 'Privacy';

  /// Privacy settings: keep proof toggle label.
  static const String privacyKeepProofByDefault = 'Keep proof by default';

  /// Privacy settings: keep proof toggle subtitle.
  static const String privacyKeepProofSubtitle =
      'Proof photos and files are kept as completion records. Turn off to discard after verification.';

  // ── AI Verification Dispute (FR39, FR40, Story 7.8) ─────────────────────────

  /// Heading on the dispute confirmation screen (UX-DR33).
  static const String disputeConfirmationTitle = 'Review requested';

  /// Trust-critical point 1 on dispute confirmation (UX-DR33).
  static const String disputeConfirmationPoint1 =
      'Your dispute was received and is being reviewed';

  /// Trust-critical point 2 on dispute confirmation (UX-DR33).
  static const String disputeConfirmationPoint2 =
      'Your stake will not be charged during review';

  /// Trust-critical point 3 on dispute confirmation (UX-DR33).
  static const String disputeConfirmationPoint3 =
      'You\u2019ll have a response within 24 hours';

  /// Done CTA on the dispute confirmation screen.
  static const String disputeConfirmationDoneCta = 'Done';

  /// "Under review" label on the task card when a dispute is pending.
  static const String taskUnderReview = 'Under review';

  // ── Dispute Resolution Notifications (FR41, FR42, Story 7.9) ────────────────

  /// Push notification body when a dispute is approved (stake cancelled).
  static const String disputeApprovedNotificationBody =
      'Your dispute was approved \u2014 your stake is safe.';

  /// Push notification body when a dispute is rejected (charge processed).
  static const String disputeRejectedNotificationBody =
      'Your dispute was reviewed \u2014 your stake has been charged.';

  // ── Push Notifications (FR42, FR43, Story 8.1) ───────────────────────────────

  /// System permission request — never shown as a pre-permission dialog in this
  /// story; the OS dialog fires after requestPermissionAndRegisterToken() is called.
  /// These strings are for future Settings → Notifications UI (Story 8.x).

  /// Label for global notifications toggle in Settings.
  static const String notificationsGlobalToggleLabel = 'Push Notifications';

  /// Subtitle when global notifications are enabled.
  static const String notificationsGlobalEnabledSubtitle = 'Notifications are on for all devices.';

  /// Subtitle when global notifications are disabled.
  static const String notificationsGlobalDisabledSubtitle = 'All push notifications are off.';

  /// Label for per-device toggle (used in a future per-device settings screen).
  static const String notificationsThisDeviceLabel = 'This device';

  /// Error shown when device token registration fails.
  static const String notificationsTokenRegistrationError =
      'Couldn\u2019t register for notifications \u2014 try again later.';

  // ── Task Reminder & Deadline Notifications (FR42, FR72, Story 8.2) ────────────

  /// Reminder notification body — shown X minutes before task scheduled time.
  /// Usage: '${task.title} ${AppStrings.notificationReminderBody(formattedTime)}'
  static String notificationReminderBody(String time) => 'Coming up at $time';

  /// Deadline notification body — task due today.
  static const String notificationDeadlineToday = 'is due today';

  /// Deadline notification body — task due tomorrow.
  static const String notificationDeadlineTomorrow = 'is due tomorrow';

  /// Stake warning notification title prefix (warm tone, UX-DR32).
  static const String notificationStakeWarningTitlePrefix = '⚠';

  /// Stake warning notification body template.
  /// Usage: '$stakeAmount staked, deadline in ${hours}h. $charityName gets half if it\'s not done.'
  static String notificationStakeWarningBody(String stakeAmount, int hours, String charityName) =>
      '$stakeAmount staked, deadline in ${hours}h. $charityName gets half if it\'s not done.';

  // ── Commitment, Charge & Verification Notifications (FR42, Story 8.3) ────────

  /// Charge notification body (UX-DR36 — affirming, not punitive).
  /// Usage: '${task.title} — ${AppStrings.notificationChargeBody(amount, charityName, charityAmount)}'
  static String notificationChargeBody(String amount, String charityName, String charityAmount) =>
      '— $amount charged. $charityName receives $charityAmount. Thanks for trying.';

  /// Verification approved notification body.
  /// Usage: '${task.title} ${AppStrings.notificationVerificationApprovedBody(amount)}'
  static String notificationVerificationApprovedBody(String amount) =>
      '— proof accepted. Your $amount stake is safe.';

  /// Dispute filed notification body.
  /// Usage: '${task.title} ${AppStrings.notificationDisputeFiledBody}'
  static const String notificationDisputeFiledBody =
      '— dispute filed. Your stake is on hold while we review.';

  /// Dispute approved notification body (stake cancelled).
  /// Usage: '${task.title} ${AppStrings.notificationDisputeApprovedBody(amount)}'
  static String notificationDisputeApprovedBody(String amount) =>
      '— dispute approved. Your $amount stake has been cancelled.';

  /// Dispute rejected notification body (charge processed, affirming).
  /// Usage: '${task.title} ${AppStrings.notificationDisputeRejectedBody(amount, charityName, charityAmount)}'
  static String notificationDisputeRejectedBody(String amount, String charityName, String charityAmount) =>
      '— dispute reviewed. $amount charged. $charityName receives $charityAmount. Thanks for trying.';

  // ── Social & Schedule Change Notifications (FR42, FR43, Story 8.4) ──────────

  /// Social completion notification body.
  /// Usage: AppStrings.notificationSocialCompletionBody(completedByName, taskTitle)
  /// Server builds the push payload; this mirrors the server copy for in-app display.
  static String notificationSocialCompletionBody(String completedByName, String taskTitle) =>
      '$completedByName completed $taskTitle';

  /// Schedule change notification body.
  /// Usage: AppStrings.notificationScheduleChangeBody(count)
  static String notificationScheduleChangeBody(int count) =>
      'Your schedule was updated \u2014 $count tasks were rescheduled';

  // ── In-App Notification Centre (Story 8.5) ───────────────────────────────────

  /// Navigation bar title for notification centre screen.
  static const String notificationCentreTitle = 'Notifications';

  /// Shown when notification history is empty.
  static const String notificationCentreEmpty = 'No notifications yet';

  /// Shown when notification history fails to load.
  static const String notificationCentreLoadError = 'Couldn\u2019t load notifications';

  /// Toolbar badge tooltip / accessibility label for unread count icon.
  /// Usage: AppStrings.notificationBadgeLabel(count)
  static String notificationBadgeLabel(int count) =>
      '$count unread notification${count == 1 ? '' : 's'}';

  // ── Subscriptions — Trial Status & Settings (FR82, FR87, Story 9.1) ─────────

  /// Navigation bar title for subscription settings screen.
  static const String subscriptionSettingsTitle = 'Subscription';

  /// Shown when subscription settings fail to load.
  static const String subscriptionSettingsLoadError = 'Couldn\u2019t load subscription status';

  /// Section label for trial status.
  static const String subscriptionTrialStatusLabel = 'Free Trial';

  /// Trial days remaining message — AC: 2, FR87.
  /// Usage: AppStrings.subscriptionTrialDaysRemaining(days)
  static String subscriptionTrialDaysRemaining(int days) =>
      days == 0
          ? 'Your free trial expires today'
          : days == 1
              ? '1 day remaining in your free trial'
              : '$days days remaining in your free trial';

  /// Shown when trial has expired and no subscription active.
  static const String subscriptionExpiredLabel = 'Your free trial has ended';

  /// Persistent trial countdown banner text (final 3 days).
  /// Usage: AppStrings.trialCountdownBannerText(days)
  static String trialCountdownBannerText(int days) =>
      days == 0
          ? 'Your free trial ends today \u2014 subscribe to keep access'
          : days == 1
              ? '1 day left in your free trial \u2014 subscribe to keep access'
              : '$days days left in your free trial \u2014 subscribe to keep access';

  // ── Subscriptions — Paywall Screen (FR88, Story 9.2) ─────────────────────────

  /// Main headline — benefit-focused, not urgency-driven.
  static const String paywallHeadline = 'Continue doing your best work';

  /// Subheadline — describes the value proposition briefly.
  static const String paywallSubheadline =
      'Choose a plan to keep full access to scheduling, shared lists, and commitment contracts.';

  /// Individual tier name.
  static const String paywallTierIndividualName = 'Individual';

  /// Individual tier price — approximate; exact price TBD at launch.
  static const String paywallTierIndividualPrice = r'~$10 / month';

  /// Individual tier one-line feature description.
  static const String paywallTierIndividualFeature =
      'Full access for one person';

  /// Couple tier name.
  static const String paywallTierCoupleName = 'Couple';

  /// Couple tier price — placeholder; exact pricing TBD.
  static const String paywallTierCouplePrice = 'Coming soon';

  /// Couple tier one-line feature description.
  static const String paywallTierCoupleFeature =
      'Shared lists and commitments for two';

  /// Family & Friends tier name.
  static const String paywallTierFamilyName = 'Family & Friends';

  /// Family & Friends tier price — placeholder; exact pricing TBD.
  static const String paywallTierFamilyPrice = 'Coming soon';

  /// Family & Friends tier one-line feature description.
  static const String paywallTierFamilyFeature =
      'Up to five people, shared accountability';

  /// "Subscribe" button label on tier cards.
  static const String paywallSubscribeCta = 'Subscribe';

  /// "Restore purchase" button label.
  static const String paywallRestorePurchase = 'Restore purchase';

  /// Cancellation terms shown below tier cards — honest and clear.
  static const String paywallCancellationTerms =
      'Cancel any time. Active commitment contracts continue until their individual deadlines regardless of subscription status.';

  // ── Subscriptions — Activation & Settings (FR83, Story 9.3) ─────────────────

  /// Error shown when subscription restore fails.
  static const String subscriptionRestoreError =
      'Couldn\u2019t restore your subscription. Please try again.';

  /// Error shown when subscription activation fails after Stripe Checkout.
  static const String subscriptionActivationError =
      'Couldn\u2019t activate your subscription. Please contact support if the issue continues.';

  /// Settings → Subscription section title when subscription is active.
  static const String subscriptionActiveStatusLabel = 'Active Subscription';

  /// Settings → Subscription renewal date label.
  /// Usage: AppStrings.subscriptionRenewalDate(date)
  static String subscriptionRenewalDate(String date) =>
      'Renews on $date';

  /// Settings → Subscription tier label.
  /// Usage: AppStrings.subscriptionTierLabel(tierName)
  static String subscriptionTierLabel(String tierName) =>
      '$tierName plan';

  /// "Manage subscription" CTA in Settings → Subscription (opens ontaskhq.com/account).
  static const String subscriptionManageCta = 'Manage subscription';
}
