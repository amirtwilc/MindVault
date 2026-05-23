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
  String get authSubtitle => 'Your encrypted AI-powered notes';

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
      'Your notes are end-to-end encrypted.\nOnly you can read them.';

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
      'This PIN protects your notes from being read by anyone but you. You\'ll need it if you sign in on a new device.';

  @override
  String get pinRecoveryBody =>
      'Your notes are encrypted. Enter your recovery PIN to unlock them on this device.';

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
      'This will generate a new encryption key. Your existing notes will be lost.\n\nThis cannot be undone.';

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
  String get navAllNotes => 'All Notes';

  @override
  String get navCategories => 'Categories';

  @override
  String get navSearch => 'Search';

  @override
  String get navSettings => 'Settings';

  @override
  String get homeNoCategoriesTitle =>
      'No categories yet.\nTap + to create one.';

  @override
  String get newCategoryDialogTitle => 'New Category';

  @override
  String get categoryNameHint => 'Category name';

  @override
  String get categoryColorLabel => 'Color';

  @override
  String get categoryNameInUse => 'Name already in use';

  @override
  String categoryLimitReached(int max, Object upgradeHint) {
    return 'Category limit reached ($max). $upgradeHint';
  }

  @override
  String noteLimitReached(int max, Object upgradeHint) {
    return 'Note limit reached ($max). $upgradeHint';
  }

  @override
  String get upgradeHintFree => 'Upgrade to Pro for more.';

  @override
  String get upgradeHintNone => '';

  @override
  String get notesListTitleFallback => 'Notes';

  @override
  String get notesListEmptyTitle => 'No notes yet';

  @override
  String get notesListEmptyBody => 'Tap + to create your first note';

  @override
  String get noteUntitled => '(untitled)';

  @override
  String get noteDeletedSnack => 'Note deleted';

  @override
  String get deleteNoteTitle => 'Delete note?';

  @override
  String get deleteNoteBody => 'This action cannot be undone.';

  @override
  String get privateAuthReason => 'Authenticate to view this private note';

  @override
  String get renameCategory => 'Rename';

  @override
  String get changeCategoryColor => 'Change color';

  @override
  String get deleteCategoryAction => 'Delete category';

  @override
  String get renameCategoryDialog => 'Rename Category';

  @override
  String get categoryColorDialog => 'Category Color';

  @override
  String deleteCategoryConfirmTitle(Object name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get deleteCategoryConfirmBody =>
      'All notes in this category will also be deleted.';

  @override
  String get allNotesEmptyTitle => 'No notes yet';

  @override
  String get allNotesEmptyBody => 'Create a category and add your first note';

  @override
  String get allNotesCreateFirst => 'Create a category first';

  @override
  String get editorNewTitle => 'New Note';

  @override
  String get editorEditTitle => 'Edit Note';

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
  String get editorChangeCategory => 'Change category';

  @override
  String get editorNewCategoryEntry => 'New category…';

  @override
  String get editorTooltipPublic => 'Public';

  @override
  String get editorTooltipPrivate => 'Private';

  @override
  String get editorTooltipDelete => 'Delete note';

  @override
  String get editorTooltipEdit => 'Edit note';

  @override
  String get editorTooltipCopy => 'Copy note';

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
      'Add a title or note body before setting a reminder.';

  @override
  String get reminderNotificationsRequired =>
      'Notification permission must be granted for reminders.';

  @override
  String get reminderMayBeDelayed =>
      'Exact alarms are not enabled. This reminder may be delayed.';

  @override
  String get reminderMustBeFuture => 'Choose a future date and time.';

  @override
  String get reminderNoteNotFound => 'That reminder note could not be found.';

  @override
  String get reminderNotificationBody => 'Tap to open this note';

  @override
  String get editorCopyMenuItem => 'Copy note';

  @override
  String get editorCopiedSnack => 'Note copied';

  @override
  String get editorSttRecord => 'Record voice';

  @override
  String get editorSttStop => 'Stop recording';

  @override
  String get searchHint => 'Search notes…';

  @override
  String get searchIdleTitle => 'Search your notes';

  @override
  String get searchIdleBody =>
      'Type keywords or ask a question. \nPrivate notes are ignored.';

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
  String get searchTryAiHint => 'Not what you were looking for? Try AI search';

  @override
  String get searchNoResultsAiCta =>
      'No results found. Click to perform an AI Search';

  @override
  String get searchHistoryButtonTooltip => 'AI search history';

  @override
  String get searchBackToResults => 'Back to results';

  @override
  String get widgetSearchTitle => 'Search your notes';

  @override
  String get aiSearchTitle => 'AI Search';

  @override
  String get aiSearchHint => 'Ask about your notes…';

  @override
  String get aiSearchLoading => 'Searching your notes…';

  @override
  String get aiSearchIdleTitle => 'Ask anything about your notes';

  @override
  String get aiSearchIdleBody =>
      'AI searches your notes and synthesises an answer';

  @override
  String get aiSearchSuggestion1 => 'Summarize my workout notes';

  @override
  String get aiSearchSuggestion2 => 'What did I write about work?';

  @override
  String get aiSearchSuggestion3 => 'Find notes about my goals';

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
  String get aiInfoTitle => 'About AI Search';

  @override
  String get aiInfoBody =>
      'AI Search reads your notes to answer your question.\n\n🔒 Private notes are never sent to AI.\n\n📄 Very long notes are shortened before being sent.';

  @override
  String get aiInfoDismiss => 'Got it';

  @override
  String get aiAnswerCopied => 'Copied to clipboard';

  @override
  String get aiHistoryTitle => 'AI Search History';

  @override
  String get aiHistoryEmpty => 'No search history yet';

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
  String get settingsUsageAi => 'AI searches today';

  @override
  String get settingsUsageNotes => 'Notes';

  @override
  String get settingsUsageCategories => 'Categories';

  @override
  String get settingsUpgradeTitle => 'Upgrade to Pro';

  @override
  String get settingsUpgradeSubtitle =>
      '50 AI searches/day · 1000 notes · 50 categories';

  @override
  String get settingsUpgradeDialogBody =>
      'Pro gives you 50 AI searches/day, up to 1000 notes, 50 categories, and 20,000 chars per note.';

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
  String get widgetAddNoteTooltip => 'Add note';

  @override
  String get widgetComposeTitle => 'New Note';

  @override
  String get widgetComposeDiscardTitle => 'Discard note?';

  @override
  String get widgetComposeDiscardBody => 'Your note will not be saved.';

  @override
  String get widgetComposeNoCategories =>
      'No categories found.\nOpen MindVault to create one first.';

  @override
  String get widgetComposeCategoryLabel => 'Category';

  @override
  String get noteTypeLabel => 'Type';

  @override
  String get noteTypeText => 'Text';

  @override
  String get noteTypeChecklist => 'Checklist';

  @override
  String get removeDoneTasksLabel => 'Remove done tasks';

  @override
  String get removeDoneTasksTitle => 'Remove done tasks?';

  @override
  String get removeDoneTasksBody =>
      'Completed tasks will be permanently removed.';

  @override
  String get widgetViewEditTitle => 'Edit Note';

  @override
  String get widgetViewEdit => 'Edit';

  @override
  String get widgetViewDelete => 'Delete';

  @override
  String get widgetViewUnlocking => 'Unlocking…';

  @override
  String get widgetViewNoContent => 'No content';

  @override
  String get widgetViewNotFound => 'Note not found';

  @override
  String get widgetViewDiscardTitle => 'Discard changes?';

  @override
  String get widgetViewDiscardBody => 'Your edits will not be saved.';

  @override
  String get widgetViewKeepEditing => 'Keep editing';
}
