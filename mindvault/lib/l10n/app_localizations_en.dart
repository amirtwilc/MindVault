// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppStringsEn extends AppStrings {
  AppStringsEn([String locale = 'en']) : super(locale);

  @override
  String get appBrand => 'MindVault';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionCreate => 'Create';

  @override
  String get actionRename => 'Rename';

  @override
  String get actionApply => 'Apply';

  @override
  String get actionClose => 'Close';

  @override
  String get actionNotNow => 'Not now';

  @override
  String get actionDiscard => 'Discard';

  @override
  String get actionTryAgain => 'Try again';

  @override
  String get actionUnlock => 'Unlock';

  @override
  String get actionRecoverContinue => 'Recover & Continue';

  @override
  String get actionSetupContinue => 'Set Up & Continue';

  @override
  String get actionStartFresh => 'Start fresh';

  @override
  String get actionContactUs => 'Contact us';

  @override
  String get actionOk => 'OK';

  @override
  String get splashTagline => 'Your thoughts, safely encrypted.';

  @override
  String get splashLoading => 'Securing your vault…';

  @override
  String get authSubtitle => 'Your encrypted AI-powered memories';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authEmailRequired => 'Email is required.';

  @override
  String get authEmailInvalid => 'Enter a valid email address.';

  @override
  String get authPasswordRequired => 'Password is required.';

  @override
  String get authPasswordTooShort => 'Password must be at least 6 characters.';

  @override
  String get authSignInEmail => 'Sign in with email';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authNeedAccount => 'Need an account? Create one';

  @override
  String get authHaveAccount => 'Already have an account? Sign in';

  @override
  String get authOr => 'or';

  @override
  String get authCheckEmail =>
      'Check your email to confirm your account, then sign in.';

  @override
  String get authCheckEmailOtp =>
      'We emailed you a confirmation code. Enter it here to finish creating your account.';

  @override
  String get authOtpResent => 'A new confirmation code has been sent.';

  @override
  String get authRecoveryCodeSent => 'We emailed you a recovery code.';

  @override
  String get authRecoveryCodeResent => 'A new recovery code has been sent.';

  @override
  String get authInvalidCredentials => 'The email or password is incorrect.';

  @override
  String get authEmailAlreadyUsed =>
      'An account already exists for this email. Try signing in instead.';

  @override
  String get authWeakPassword => 'Choose a stronger password and try again.';

  @override
  String get authEmailNotConfirmed =>
      'Please confirm your email before signing in.';

  @override
  String get authInvalidOtp => 'That code is invalid. Check it and try again.';

  @override
  String get authExpiredOtp =>
      'That code has expired. Request a new one and try again.';

  @override
  String get authRateLimited =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get authNetworkError =>
      'Could not reach the sign-in server. Check your connection and try again.';

  @override
  String get authGenericError => 'Sign-in failed. Please try again.';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authForgotPasswordTitle => 'Reset your password';

  @override
  String get authVerifyEmailTitle => 'Confirm your email';

  @override
  String get authVerifyRecoveryTitle => 'Verify your recovery code';

  @override
  String get authSetNewPasswordTitle => 'Choose a new password';

  @override
  String get authVerifyEmailCode => 'Verify email code';

  @override
  String get authVerifyRecoveryCode => 'Verify recovery code';

  @override
  String get authOtpHelper => 'Enter the code from your confirmation email.';

  @override
  String get authRecoveryOtpHelper =>
      'Enter the code from your recovery email.';

  @override
  String get authOtpLabel => 'Email code';

  @override
  String get authOtpRequired => 'Verification code is required.';

  @override
  String get authOtpInvalidFormat => 'Enter the code from your email.';

  @override
  String get authResendCode => 'Resend code';

  @override
  String get authSendingCode => 'Sending code...';

  @override
  String get authVerifyingCode => 'Verifying code...';

  @override
  String get authSendRecoveryCode => 'Send recovery code';

  @override
  String get authBackToSignIn => 'Back to sign in';

  @override
  String get authSetNewPasswordBody => 'Enter a new password for your account.';

  @override
  String get authNewPasswordLabel => 'New password';

  @override
  String get authConfirmPasswordLabel => 'Confirm new password';

  @override
  String get authConfirmPasswordRequired => 'Please confirm your password.';

  @override
  String get authPasswordsDoNotMatch => 'Passwords do not match.';

  @override
  String get authUpdatingPassword => 'Updating password...';

  @override
  String get authUpdatePassword => 'Update password';

  @override
  String get authCancelRecovery => 'Cancel recovery';

  @override
  String get authPasswordUpdated => 'Password updated. Finishing sign-in...';

  @override
  String get authSignInGoogle => 'Sign in with Google';

  @override
  String get authSigningIn => 'Signing in...';

  @override
  String get authDisclaimer =>
      'Your memories are end-to-end encrypted.\nOnly you can read them.';

  @override
  String get pinSetupAppBar => 'Set Up Encryption';

  @override
  String get pinRecoveryAppBar => 'Recover Encryption Key';

  @override
  String get pinSetupHeading => 'Create a Recovery PIN';

  @override
  String get pinRecoveryHeading => 'Enter Your Recovery PIN';

  @override
  String get pinSetupBody =>
      'This PIN protects your memories from being read by anyone but you. You\'ll need it if you sign in on a new device.';

  @override
  String get pinRecoveryBody =>
      'Your memories are encrypted. Enter your recovery PIN to unlock them on this device.';

  @override
  String get pinLabel => 'Recovery PIN (4–8 digits)';

  @override
  String get pinConfirmLabel => 'Confirm PIN';

  @override
  String get pinSetupDisclaimer =>
      'Your PIN never leaves this device. Your encrypted key is stored on our servers so you can recover it on reinstall, but it cannot be read without the PIN.';

  @override
  String get pinRecoveryDisclaimer =>
      'Your PIN never leaves this device. Only your encrypted key is stored on our servers — it cannot be read without the PIN.';

  @override
  String get pinForgot => 'Forgot PIN? Start fresh';

  @override
  String get pinSignOut => 'Sign out';

  @override
  String get pinTooShort => 'PIN must be at least 4 characters.';

  @override
  String get pinMismatch => 'PINs do not match.';

  @override
  String get pinRecoverError =>
      'Incorrect PIN. Could not recover your encryption key.';

  @override
  String pinServerError(Object message) {
    return 'Server error: $message';
  }

  @override
  String get pinStartFreshTitle => 'Start fresh?';

  @override
  String get pinStartFreshBody =>
      'This will generate a new encryption key. Your existing memories will be lost.\n\nThis cannot be undone.';

  @override
  String get pinEntryAppBar => 'Enter Recovery PIN';

  @override
  String get pinEntryHeading => 'Enter your Recovery PIN';

  @override
  String get pinEntryLabel => 'Recovery PIN';

  @override
  String get pinEntryNoKey => 'No key found. Please contact support.';

  @override
  String get pinEntryIncorrect => 'Incorrect PIN. Please try again.';

  @override
  String get pinSetupError => 'Encryption setup failed. Please try again.';

  @override
  String pinLockedSeconds(int seconds) {
    return 'Too many failed attempts. Try again in ${seconds}s.';
  }

  @override
  String pinLockedMinutes(int minutes) {
    return 'Too many failed attempts. Try again in ${minutes}m.';
  }

  @override
  String get navAllNotes => 'Archive';

  @override
  String get navJots => 'Sparks';

  @override
  String get navCategories => 'Clusters';

  @override
  String get navSearch => 'Recall';

  @override
  String get navSettings => 'Settings';

  @override
  String get homeNoCategoriesTitle => 'No clusters yet.\nTap + to create one.';

  @override
  String get newCategoryDialogTitle => 'New Cluster';

  @override
  String get categoryNameHint => 'Cluster name';

  @override
  String get categoryColorLabel => 'Color';

  @override
  String get categoryNameInUse => 'Name already in use';

  @override
  String categoryLimitReached(int max, Object upgradeHint) {
    return 'Cluster limit reached ($max). $upgradeHint';
  }

  @override
  String noteLimitReached(int max, Object upgradeHint) {
    return 'Memory limit reached ($max). $upgradeHint';
  }

  @override
  String get upgradeHintFree => 'Upgrade to Pro for more.';

  @override
  String get upgradeHintNone => '';

  @override
  String get notesListTitleFallback => 'Memories';

  @override
  String get notesListEmptyTitle => 'No memories yet';

  @override
  String get notesListEmptyBody => 'Tap + to create your first memory';

  @override
  String get noteUntitled => '(untitled)';

  @override
  String get noteDeletedSnack => 'Memory deleted';

  @override
  String get deleteNoteTitle => 'Delete memory?';

  @override
  String get deleteNoteBody => 'This action cannot be undone.';

  @override
  String get privateAuthReason => 'Authenticate to view this private memory';

  @override
  String get renameCategory => 'Rename';

  @override
  String get changeCategoryColor => 'Change color';

  @override
  String get deleteCategoryAction => 'Delete cluster';

  @override
  String get renameCategoryDialog => 'Rename Cluster';

  @override
  String get categoryColorDialog => 'Cluster Color';

  @override
  String deleteCategoryConfirmTitle(Object name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get deleteCategoryConfirmBody =>
      'All memories in this cluster will also be deleted.';

  @override
  String get allNotesEmptyTitle => 'No memories yet';

  @override
  String get allNotesEmptyBody => 'Create a cluster and add your first memory';

  @override
  String get allNotesCreateFirst => 'Create a cluster first';

  @override
  String get editorNewTitle => 'New Memory';

  @override
  String get editorEditTitle => 'Edit Memory';

  @override
  String get editorSaving => 'Saving…';

  @override
  String editorSavedAt(Object time) {
    return 'Saved $time';
  }

  @override
  String get editorTitleHint => 'Title';

  @override
  String get editorBodyHint => 'Start writing…';

  @override
  String get editorChangeCategory => 'Change cluster';

  @override
  String get editorNewCategoryEntry => 'New cluster…';

  @override
  String get editorTooltipPublic => 'Public';

  @override
  String get editorTooltipPrivate => 'Private';

  @override
  String get editorTooltipDelete => 'Delete memory';

  @override
  String get editorTooltipEdit => 'Edit memory';

  @override
  String get editorTooltipCopy => 'Copy memory';

  @override
  String get reminderTooltipSet => 'Set reminder';

  @override
  String get reminderTooltipActive => 'Reminder set';

  @override
  String get reminderDialogTitle => 'Reminder';

  @override
  String reminderScheduledFor(Object time) {
    return 'Scheduled for $time';
  }

  @override
  String get reminderEdit => 'Edit';

  @override
  String get reminderRemove => 'Remove';

  @override
  String get reminderSaveNoteFirst =>
      'Add a title or memory body before setting a reminder.';

  @override
  String get reminderNotificationsRequired =>
      'Notification permission must be granted for reminders.';

  @override
  String get reminderMayBeDelayed =>
      'Exact alarms are not enabled. This reminder may be delayed.';

  @override
  String get reminderBackgroundPermissionTitle => 'Allow background reminders';

  @override
  String get reminderBackgroundPermissionBody =>
      'Some devices require MindVault to be allowed to work in the background or autostart so exact reminders can fire when the app is closed. If a settings page opens, enable MindVault and return to the app.';

  @override
  String get reminderBackgroundPermissionOpenSettings => 'Open settings';

  @override
  String get reminderMustBeFuture => 'Choose a future date and time.';

  @override
  String get reminderNoteNotFound => 'That reminder memory could not be found.';

  @override
  String get reminderNotificationBody => 'Tap to open this memory';

  @override
  String get editorCopyMenuItem => 'Copy memory';

  @override
  String get editorCopiedSnack => 'Memory copied';

  @override
  String get editorSttStop => 'Stop recording';

  @override
  String get searchHint => 'Search memories…';

  @override
  String get searchIdleTitle => 'Search your memories';

  @override
  String get searchIdleBody =>
      'Type keywords or ask a question. \nPrivate memories are ignored.';

  @override
  String searchNoResults(Object query) {
    return 'No results for \"$query\"';
  }

  @override
  String get searchTryDifferent => 'Try different keywords';

  @override
  String searchMoreLines(int count) {
    return '+$count more lines';
  }

  @override
  String get searchTryAiHint => 'Not what you were looking for? Try AI recall';

  @override
  String get searchNoResultsAiCta =>
      'No results found. Click to perform an AI Recall';

  @override
  String get searchHistoryButtonTooltip => 'AI recall history';

  @override
  String get searchBackToResults => 'Back to results';

  @override
  String get widgetSearchTitle => 'Recall your memories';

  @override
  String get aiSearchTitle => 'AI Recall';

  @override
  String get aiSearchHint => 'Ask about your memories…';

  @override
  String get aiSearchLoading => 'Recalling your memories…';

  @override
  String get aiSearchIdleTitle => 'Ask anything about your memories';

  @override
  String get aiSearchIdleBody =>
      'AI recalls your memories and synthesises an answer';

  @override
  String get aiSearchSuggestion1 => 'Summarize my workout memories';

  @override
  String get aiSearchSuggestion2 => 'What did I write about work?';

  @override
  String get aiSearchSuggestion3 => 'Find memories about my goals';

  @override
  String get aiSearchSuggestion4 => 'What are my travel plans?';

  @override
  String get aiSearchSources => 'Sources';

  @override
  String get aiSearchFromCache => 'From cache';

  @override
  String get aiSearchRateTitle => 'Rate limit reached';

  @override
  String aiSearchRateSeconds(int seconds) {
    return 'Try again in ${seconds}s';
  }

  @override
  String aiSearchRateMinutes(int minutes) {
    return 'Try again in ${minutes}m';
  }

  @override
  String aiSearchRateResetsAt(Object time) {
    return 'Resets at $time';
  }

  @override
  String get aiSearchRateDefault => 'Please wait before searching again';

  @override
  String get aiSearchErrorDailyLimit =>
      'Daily AI limit reached. Try again tomorrow.';

  @override
  String get aiSearchErrorSessionExpired =>
      'Session expired. Please sign in again.';

  @override
  String get aiSearchErrorUnavailable => 'AI is not available right now.';

  @override
  String get aiSearchErrorNetwork =>
      'No connection. Check your internet and try again.';

  @override
  String get aiSearchErrorGeneric => 'AI request failed. Please try again.';

  @override
  String get aiInfoTitle => 'About AI Recall';

  @override
  String get aiInfoBody =>
      'AI Recall reads your memories to answer your question.\n\n🔒 Private memories are never sent to AI.\n\n📄 Very long memories are shortened before being sent.';

  @override
  String get aiInfoDismiss => 'Got it';

  @override
  String get aiAnswerCopied => 'Copied to clipboard';

  @override
  String get aiHistoryTitle => 'AI Recall History';

  @override
  String get aiHistoryEmpty => 'No recall history yet';

  @override
  String get aiHistoryRelativeNow => 'Just now';

  @override
  String aiHistoryRelativeMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String aiHistoryRelativeHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String aiHistoryRelativeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String get settingsSectionUsage => 'Usage';

  @override
  String get settingsSectionUpgrade => 'Upgrade';

  @override
  String get settingsSectionApp => 'App';

  @override
  String get settingsSectionLanguage => 'Language';

  @override
  String get settingsUnknownUser => 'Unknown';

  @override
  String get settingsTierFree => 'Free';

  @override
  String get settingsTierPro => 'Pro';

  @override
  String get settingsUsageAi => 'AI recalls today';

  @override
  String get settingsUsageJotsAi => 'Spark AI organizes today';

  @override
  String get settingsUsageNotes => 'Memories';

  @override
  String get settingsUsageCategories => 'Clusters';

  @override
  String get settingsUpgradeTitle => 'Upgrade to Pro';

  @override
  String get settingsUpgradeSubtitle =>
      '30 AI recalls/day · 1000 memories · 50 clusters';

  @override
  String get settingsUpgradeDialogBody =>
      'Pro gives you 30 AI recalls/day, up to 1000 memories, 50 clusters, and 20,000 chars per memory.';

  @override
  String get contactUsMessageHint => 'Your message (optional)…';

  @override
  String get contactUsNoEmailApp => 'No email app found. Please email us at:';

  @override
  String get contactUsCopied => 'Email address copied';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsLanguageDeviceDefault => 'Device default';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageHebrew => 'עברית';

  @override
  String get settingsLanguageGerman => 'Deutsch';

  @override
  String get settingsLanguageHindi => 'हिन्दी';

  @override
  String get settingsLanguageSpanish => 'Español';

  @override
  String get settingsLanguageFrench => 'Français';

  @override
  String get jotsAddTooltip => 'Add spark';

  @override
  String get jotAddDialogTitle => 'New Spark';

  @override
  String get jotInputHint => 'Capture a quick thought';

  @override
  String get jotSavedSnack => 'Thought saved';

  @override
  String get jotSaveUnavailable =>
      'Thought could not be saved. Please try again.';

  @override
  String jotCharCounter(int count, int max) {
    return '$count/$max characters';
  }

  @override
  String get jotsEmptyTitle => 'No sparks waiting';

  @override
  String get jotsEmptyBody => 'Tap + whenever a thought pops up.';

  @override
  String get jotsSortOldestFirst => 'Oldest first';

  @override
  String get jotsSortNewestFirst => 'Newest first';

  @override
  String get jotsOrganizeAi => 'Organize with AI';

  @override
  String get jotsAcceptAll => 'Accept all suggestions';

  @override
  String get jotsAiInfoTitle => 'About Sparks AI';

  @override
  String get jotsAiInfoBody =>
      'Sparks AI suggests how to organize unhandled thoughts. Only unsent sparks, cluster names, and memory titles are sent. Memory bodies and private memories are not sent, and long lists may be limited.';

  @override
  String get jotsAiNoNew => 'No new thoughts to organize.';

  @override
  String get jotsAiQuota => 'Daily Sparks AI limit reached.';

  @override
  String get jotsAiFailed => 'Could not organize sparks. Try again.';

  @override
  String jotsAiSuggestionsProvided(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count suggestions were provided.',
      one: '1 suggestion was provided.',
      zero:
          '0 suggestions were provided. Try writing more specific thoughts next time.',
    );
    return '$_temp0';
  }

  @override
  String get jotsAiLimitedTo30 => 'Only the oldest 30 new sparks were sent.';

  @override
  String jotsSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get jotsDeleteSelectedTitle => 'Delete selected sparks?';

  @override
  String get jotsDeleteSelectedBody =>
      'Selected thoughts will be permanently deleted.';

  @override
  String jotCreatedAt(Object time) {
    return 'Created $time';
  }

  @override
  String get jotActionsTooltip => 'Handle spark';

  @override
  String get jotActionsTitle => 'Handle thought';

  @override
  String get jotActionCreateNote => 'Create new memory';

  @override
  String get jotActionAddToNote => 'Add to existing memory';

  @override
  String get jotActionCreateAlert => 'Create alert';

  @override
  String get jotActionDeleteThought => 'Delete thought';

  @override
  String get jotActionSuggestedByAi => 'These actions were suggested by AI.';

  @override
  String get jotActionUpdateThought => 'Update thought text';

  @override
  String get jotActionUpdatedThoughtText => 'Updated thought';

  @override
  String get jotActionUpdatedThoughtHint => 'Example: Lord of the Rings';

  @override
  String get jotActionNewNoteTitle => 'Memory title';

  @override
  String get jotActionCategory => 'Cluster';

  @override
  String get jotActionNewCategory => 'New cluster';

  @override
  String get jotActionNote => 'Memory';

  @override
  String get jotActionNoNotes => 'No memories in this cluster';

  @override
  String get jotActionLock => 'Lock memory';

  @override
  String jotActionReminderWhen(Object time) {
    return 'Alert at $time';
  }

  @override
  String get jotActionPickReminder => 'Choose date and time';

  @override
  String get jotActionAccept => 'Accept';

  @override
  String get jotActionChooseFuture => 'Choose a future date and time.';

  @override
  String get jotNotificationBody => 'Tap to organize this thought';

  @override
  String get jotReminderNotFound => 'That thought could not be found.';

  @override
  String get widgetAddNoteTooltip => 'Add memory';

  @override
  String get widgetComposeTitle => 'New Memory';

  @override
  String get widgetComposeDiscardTitle => 'Discard memory?';

  @override
  String get widgetComposeDiscardBody => 'Your memory will not be saved.';

  @override
  String get widgetComposeNoCategories =>
      'No clusters found.\nOpen MindVault to create one first.';

  @override
  String get widgetComposeCategoryLabel => 'Cluster';

  @override
  String get noteTypeLabel => 'Type';

  @override
  String get noteTypeText => 'Record';

  @override
  String get noteTypeChecklist => 'Plan';

  @override
  String get removeDoneTasksLabel => 'Remove done tasks';

  @override
  String get removeDoneTasksTitle => 'Remove done tasks?';

  @override
  String get removeDoneTasksBody =>
      'Completed tasks will be permanently removed.';

  @override
  String get widgetViewEditTitle => 'Edit Memory';

  @override
  String get widgetViewEdit => 'Edit';

  @override
  String get widgetViewDelete => 'Delete';

  @override
  String get widgetViewUnlocking => 'Unlocking…';

  @override
  String get widgetViewNoContent => 'No content';

  @override
  String get widgetViewNotFound => 'Memory not found';

  @override
  String get widgetViewDiscardTitle => 'Discard changes?';

  @override
  String get widgetViewDiscardBody => 'Your edits will not be saved.';

  @override
  String get widgetViewKeepEditing => 'Keep editing';

  @override
  String get editorSttRecord => 'Record voice';
}
