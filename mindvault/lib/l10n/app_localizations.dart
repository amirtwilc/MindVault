import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_he.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppStrings
/// returned by `AppStrings.of(context)`.
///
/// Applications need to include `AppStrings.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppStrings.localizationsDelegates,
///   supportedLocales: AppStrings.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppStrings.supportedLocales
/// property.
abstract class AppStrings {
  AppStrings(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppStrings of(BuildContext context) {
    return Localizations.of<AppStrings>(context, AppStrings)!;
  }

  static const LocalizationsDelegate<AppStrings> delegate =
      _AppStringsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('he'),
    Locale('hi')
  ];

  /// Brand name. Should NOT be translated.
  ///
  /// In en, this message translates to:
  /// **'MindVault'**
  String get appBrand;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get actionCreate;

  /// No description provided for @actionRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get actionRename;

  /// No description provided for @actionApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get actionApply;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get actionDiscard;

  /// No description provided for @actionTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionTryAgain;

  /// No description provided for @actionUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get actionUnlock;

  /// No description provided for @actionRecoverContinue.
  ///
  /// In en, this message translates to:
  /// **'Recover & Continue'**
  String get actionRecoverContinue;

  /// No description provided for @actionSetupContinue.
  ///
  /// In en, this message translates to:
  /// **'Set Up & Continue'**
  String get actionSetupContinue;

  /// No description provided for @actionStartFresh.
  ///
  /// In en, this message translates to:
  /// **'Start fresh'**
  String get actionStartFresh;

  /// No description provided for @actionContactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get actionContactUs;

  /// No description provided for @actionOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get actionOk;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Your thoughts, safely encrypted.'**
  String get splashTagline;

  /// No description provided for @splashLoading.
  ///
  /// In en, this message translates to:
  /// **'Securing your vault…'**
  String get splashLoading;

  /// No description provided for @authSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your encrypted AI-powered notes'**
  String get authSubtitle;

  /// No description provided for @authSignInGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get authSignInGoogle;

  /// No description provided for @authSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get authSigningIn;

  /// No description provided for @authDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Your notes are end-to-end encrypted.\nOnly you can read them.'**
  String get authDisclaimer;

  /// No description provided for @pinSetupAppBar.
  ///
  /// In en, this message translates to:
  /// **'Set Up Encryption'**
  String get pinSetupAppBar;

  /// No description provided for @pinRecoveryAppBar.
  ///
  /// In en, this message translates to:
  /// **'Recover Encryption Key'**
  String get pinRecoveryAppBar;

  /// No description provided for @pinSetupHeading.
  ///
  /// In en, this message translates to:
  /// **'Create a Recovery PIN'**
  String get pinSetupHeading;

  /// No description provided for @pinRecoveryHeading.
  ///
  /// In en, this message translates to:
  /// **'Enter Your Recovery PIN'**
  String get pinRecoveryHeading;

  /// No description provided for @pinSetupBody.
  ///
  /// In en, this message translates to:
  /// **'This PIN protects your encryption key. You\'ll need it if you sign in on a new device.'**
  String get pinSetupBody;

  /// No description provided for @pinRecoveryBody.
  ///
  /// In en, this message translates to:
  /// **'Your notes are encrypted. Enter your recovery PIN to unlock them on this device.'**
  String get pinRecoveryBody;

  /// No description provided for @pinLabel.
  ///
  /// In en, this message translates to:
  /// **'Recovery PIN (4–8 digits)'**
  String get pinLabel;

  /// No description provided for @pinConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get pinConfirmLabel;

  /// No description provided for @pinSetupDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Your PIN never leaves this device. Your encrypted key is stored on our servers so you can recover it on reinstall.'**
  String get pinSetupDisclaimer;

  /// No description provided for @pinRecoveryDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Your PIN never leaves this device. Only your encrypted key is stored on our servers — it cannot be read without the PIN.'**
  String get pinRecoveryDisclaimer;

  /// No description provided for @pinForgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN? Start fresh'**
  String get pinForgot;

  /// No description provided for @pinSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get pinSignOut;

  /// No description provided for @pinTooShort.
  ///
  /// In en, this message translates to:
  /// **'PIN must be at least 4 characters.'**
  String get pinTooShort;

  /// No description provided for @pinMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match.'**
  String get pinMismatch;

  /// No description provided for @pinRecoverError.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN. Could not recover your encryption key.'**
  String get pinRecoverError;

  /// No description provided for @pinServerError.
  ///
  /// In en, this message translates to:
  /// **'Server error: {message}'**
  String pinServerError(Object message);

  /// No description provided for @pinStartFreshTitle.
  ///
  /// In en, this message translates to:
  /// **'Start fresh?'**
  String get pinStartFreshTitle;

  /// No description provided for @pinStartFreshBody.
  ///
  /// In en, this message translates to:
  /// **'This will generate a new encryption key. Your existing notes will be lost.\n\nThis cannot be undone.'**
  String get pinStartFreshBody;

  /// No description provided for @pinEntryAppBar.
  ///
  /// In en, this message translates to:
  /// **'Enter Recovery PIN'**
  String get pinEntryAppBar;

  /// No description provided for @pinEntryHeading.
  ///
  /// In en, this message translates to:
  /// **'Enter your Recovery PIN'**
  String get pinEntryHeading;

  /// No description provided for @pinEntryLabel.
  ///
  /// In en, this message translates to:
  /// **'Recovery PIN'**
  String get pinEntryLabel;

  /// No description provided for @pinEntryNoKey.
  ///
  /// In en, this message translates to:
  /// **'No key found. Please contact support.'**
  String get pinEntryNoKey;

  /// No description provided for @pinEntryIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN. Please try again.'**
  String get pinEntryIncorrect;

  /// No description provided for @pinSetupError.
  ///
  /// In en, this message translates to:
  /// **'Encryption setup failed. Please try again.'**
  String get pinSetupError;

  /// No description provided for @pinLockedSeconds.
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts. Try again in {seconds}s.'**
  String pinLockedSeconds(int seconds);

  /// No description provided for @pinLockedMinutes.
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts. Try again in {minutes}m.'**
  String pinLockedMinutes(int minutes);

  /// No description provided for @navAllNotes.
  ///
  /// In en, this message translates to:
  /// **'All Notes'**
  String get navAllNotes;

  /// No description provided for @navCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get navCategories;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @homeNoCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'No categories yet.\nTap + to create one.'**
  String get homeNoCategoriesTitle;

  /// No description provided for @newCategoryDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get newCategoryDialogTitle;

  /// No description provided for @categoryNameHint.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryNameHint;

  /// No description provided for @categoryColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get categoryColorLabel;

  /// No description provided for @categoryNameInUse.
  ///
  /// In en, this message translates to:
  /// **'Name already in use'**
  String get categoryNameInUse;

  /// No description provided for @categoryLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Category limit reached ({max}). {upgradeHint}'**
  String categoryLimitReached(int max, Object upgradeHint);

  /// No description provided for @noteLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Note limit reached ({max}). {upgradeHint}'**
  String noteLimitReached(int max, Object upgradeHint);

  /// No description provided for @upgradeHintFree.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro for more.'**
  String get upgradeHintFree;

  /// No description provided for @upgradeHintNone.
  ///
  /// In en, this message translates to:
  /// **''**
  String get upgradeHintNone;

  /// No description provided for @notesListTitleFallback.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesListTitleFallback;

  /// No description provided for @notesListEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get notesListEmptyTitle;

  /// No description provided for @notesListEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap + to create your first note'**
  String get notesListEmptyBody;

  /// No description provided for @noteUntitled.
  ///
  /// In en, this message translates to:
  /// **'(untitled)'**
  String get noteUntitled;

  /// No description provided for @noteDeletedSnack.
  ///
  /// In en, this message translates to:
  /// **'Note deleted'**
  String get noteDeletedSnack;

  /// No description provided for @deleteNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete note?'**
  String get deleteNoteTitle;

  /// No description provided for @deleteNoteBody.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deleteNoteBody;

  /// No description provided for @privateAuthReason.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to view this private note'**
  String get privateAuthReason;

  /// No description provided for @renameCategory.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameCategory;

  /// No description provided for @changeCategoryColor.
  ///
  /// In en, this message translates to:
  /// **'Change color'**
  String get changeCategoryColor;

  /// No description provided for @deleteCategoryAction.
  ///
  /// In en, this message translates to:
  /// **'Delete category'**
  String get deleteCategoryAction;

  /// No description provided for @renameCategoryDialog.
  ///
  /// In en, this message translates to:
  /// **'Rename Category'**
  String get renameCategoryDialog;

  /// No description provided for @categoryColorDialog.
  ///
  /// In en, this message translates to:
  /// **'Category Color'**
  String get categoryColorDialog;

  /// No description provided for @deleteCategoryConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String deleteCategoryConfirmTitle(Object name);

  /// No description provided for @deleteCategoryConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'All notes in this category will also be deleted.'**
  String get deleteCategoryConfirmBody;

  /// No description provided for @allNotesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get allNotesEmptyTitle;

  /// No description provided for @allNotesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create a category and add your first note'**
  String get allNotesEmptyBody;

  /// No description provided for @allNotesCreateFirst.
  ///
  /// In en, this message translates to:
  /// **'Create a category first'**
  String get allNotesCreateFirst;

  /// No description provided for @editorNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New Note'**
  String get editorNewTitle;

  /// No description provided for @editorEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Note'**
  String get editorEditTitle;

  /// No description provided for @editorSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get editorSaving;

  /// No description provided for @editorSavedAt.
  ///
  /// In en, this message translates to:
  /// **'Saved {time}'**
  String editorSavedAt(Object time);

  /// No description provided for @editorTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get editorTitleHint;

  /// No description provided for @editorBodyHint.
  ///
  /// In en, this message translates to:
  /// **'Start writing…'**
  String get editorBodyHint;

  /// No description provided for @editorChangeCategory.
  ///
  /// In en, this message translates to:
  /// **'Change category'**
  String get editorChangeCategory;

  /// No description provided for @editorNewCategoryEntry.
  ///
  /// In en, this message translates to:
  /// **'New category…'**
  String get editorNewCategoryEntry;

  /// No description provided for @editorTooltipPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get editorTooltipPublic;

  /// No description provided for @editorTooltipPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get editorTooltipPrivate;

  /// No description provided for @editorTooltipDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete note'**
  String get editorTooltipDelete;

  /// No description provided for @editorTooltipEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get editorTooltipEdit;

  /// No description provided for @editorTooltipCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy note'**
  String get editorTooltipCopy;

  /// No description provided for @editorCopyMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Copy note'**
  String get editorCopyMenuItem;

  /// No description provided for @editorCopiedSnack.
  ///
  /// In en, this message translates to:
  /// **'Note copied'**
  String get editorCopiedSnack;

  /// No description provided for @editorSttRecord.
  ///
  /// In en, this message translates to:
  /// **'Record voice'**
  String get editorSttRecord;

  /// No description provided for @editorSttStop.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get editorSttStop;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search notes…'**
  String get searchHint;

  /// No description provided for @searchIdleTitle.
  ///
  /// In en, this message translates to:
  /// **'Search your notes'**
  String get searchIdleTitle;

  /// No description provided for @searchIdleBody.
  ///
  /// In en, this message translates to:
  /// **'Type keywords or ask a question. \nPrivate notes are ignored.'**
  String get searchIdleBody;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String searchNoResults(Object query);

  /// No description provided for @searchTryDifferent.
  ///
  /// In en, this message translates to:
  /// **'Try different keywords'**
  String get searchTryDifferent;

  /// No description provided for @searchMoreLines.
  ///
  /// In en, this message translates to:
  /// **'+{count} more lines'**
  String searchMoreLines(int count);

  /// No description provided for @searchTryAiHint.
  ///
  /// In en, this message translates to:
  /// **'Not what you were looking for? Try AI search'**
  String get searchTryAiHint;

  /// No description provided for @searchNoResultsAiCta.
  ///
  /// In en, this message translates to:
  /// **'No results found. Click to perform an AI Search'**
  String get searchNoResultsAiCta;

  /// No description provided for @searchHistoryButtonTooltip.
  ///
  /// In en, this message translates to:
  /// **'AI search history'**
  String get searchHistoryButtonTooltip;

  /// No description provided for @searchBackToResults.
  ///
  /// In en, this message translates to:
  /// **'Back to results'**
  String get searchBackToResults;

  /// No description provided for @widgetSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search your notes'**
  String get widgetSearchTitle;

  /// No description provided for @aiSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Search'**
  String get aiSearchTitle;

  /// No description provided for @aiSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Ask about your notes…'**
  String get aiSearchHint;

  /// No description provided for @aiSearchLoading.
  ///
  /// In en, this message translates to:
  /// **'Searching your notes…'**
  String get aiSearchLoading;

  /// No description provided for @aiSearchIdleTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask anything about your notes'**
  String get aiSearchIdleTitle;

  /// No description provided for @aiSearchIdleBody.
  ///
  /// In en, this message translates to:
  /// **'AI searches your notes and synthesises an answer'**
  String get aiSearchIdleBody;

  /// No description provided for @aiSearchSuggestion1.
  ///
  /// In en, this message translates to:
  /// **'Summarize my workout notes'**
  String get aiSearchSuggestion1;

  /// No description provided for @aiSearchSuggestion2.
  ///
  /// In en, this message translates to:
  /// **'What did I write about work?'**
  String get aiSearchSuggestion2;

  /// No description provided for @aiSearchSuggestion3.
  ///
  /// In en, this message translates to:
  /// **'Find notes about my goals'**
  String get aiSearchSuggestion3;

  /// No description provided for @aiSearchSuggestion4.
  ///
  /// In en, this message translates to:
  /// **'What are my travel plans?'**
  String get aiSearchSuggestion4;

  /// No description provided for @aiSearchSources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get aiSearchSources;

  /// No description provided for @aiSearchFromCache.
  ///
  /// In en, this message translates to:
  /// **'From cache'**
  String get aiSearchFromCache;

  /// No description provided for @aiSearchRateTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate limit reached'**
  String get aiSearchRateTitle;

  /// No description provided for @aiSearchRateSeconds.
  ///
  /// In en, this message translates to:
  /// **'Try again in {seconds}s'**
  String aiSearchRateSeconds(int seconds);

  /// No description provided for @aiSearchRateMinutes.
  ///
  /// In en, this message translates to:
  /// **'Try again in {minutes}m'**
  String aiSearchRateMinutes(int minutes);

  /// No description provided for @aiSearchRateResetsAt.
  ///
  /// In en, this message translates to:
  /// **'Resets at {time}'**
  String aiSearchRateResetsAt(Object time);

  /// No description provided for @aiSearchRateDefault.
  ///
  /// In en, this message translates to:
  /// **'Please wait before searching again'**
  String get aiSearchRateDefault;

  /// No description provided for @aiInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'About AI Search'**
  String get aiInfoTitle;

  /// No description provided for @aiInfoBody.
  ///
  /// In en, this message translates to:
  /// **'AI Search reads your notes to answer your question.\n\n🔒 Private notes are never sent to AI.\n\n📄 Very long notes are shortened before being sent.'**
  String get aiInfoBody;

  /// No description provided for @aiInfoDismiss.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get aiInfoDismiss;

  /// No description provided for @aiAnswerCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get aiAnswerCopied;

  /// No description provided for @aiHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Search History'**
  String get aiHistoryTitle;

  /// No description provided for @aiHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No search history yet'**
  String get aiHistoryEmpty;

  /// No description provided for @aiHistoryRelativeNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get aiHistoryRelativeNow;

  /// No description provided for @aiHistoryRelativeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String aiHistoryRelativeMinutes(int count);

  /// No description provided for @aiHistoryRelativeHours.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 hour ago} other{{count} hours ago}}'**
  String aiHistoryRelativeHours(int count);

  /// No description provided for @aiHistoryRelativeDays.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 day ago} other{{count} days ago}}'**
  String aiHistoryRelativeDays(int count);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsSectionAccount;

  /// No description provided for @settingsSectionUsage.
  ///
  /// In en, this message translates to:
  /// **'Usage'**
  String get settingsSectionUsage;

  /// No description provided for @settingsSectionUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get settingsSectionUpgrade;

  /// No description provided for @settingsSectionApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settingsSectionApp;

  /// No description provided for @settingsSectionLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsSectionLanguage;

  /// No description provided for @settingsUnknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get settingsUnknownUser;

  /// No description provided for @settingsTierFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get settingsTierFree;

  /// No description provided for @settingsTierPro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get settingsTierPro;

  /// No description provided for @settingsUsageAi.
  ///
  /// In en, this message translates to:
  /// **'AI searches today'**
  String get settingsUsageAi;

  /// No description provided for @settingsUsageNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get settingsUsageNotes;

  /// No description provided for @settingsUsageCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get settingsUsageCategories;

  /// No description provided for @settingsUpgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get settingsUpgradeTitle;

  /// No description provided for @settingsUpgradeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'50 AI searches/day · 1000 notes · 50 categories'**
  String get settingsUpgradeSubtitle;

  /// No description provided for @settingsUpgradeDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Pro gives you 50 AI searches/day, up to 1000 notes, 50 categories, and 20,000 chars per note.'**
  String get settingsUpgradeDialogBody;

  /// No description provided for @contactUsMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Your message (optional)…'**
  String get contactUsMessageHint;

  /// No description provided for @contactUsNoEmailApp.
  ///
  /// In en, this message translates to:
  /// **'No email app found. Please email us at:'**
  String get contactUsNoEmailApp;

  /// No description provided for @contactUsCopied.
  ///
  /// In en, this message translates to:
  /// **'Email address copied'**
  String get contactUsCopied;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsSignOut;

  /// No description provided for @settingsLanguageDeviceDefault.
  ///
  /// In en, this message translates to:
  /// **'Device default'**
  String get settingsLanguageDeviceDefault;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageHebrew.
  ///
  /// In en, this message translates to:
  /// **'עברית'**
  String get settingsLanguageHebrew;

  /// No description provided for @settingsLanguageGerman.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get settingsLanguageGerman;

  /// No description provided for @settingsLanguageHindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी'**
  String get settingsLanguageHindi;

  /// No description provided for @settingsLanguageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get settingsLanguageSpanish;

  /// No description provided for @settingsLanguageFrench.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get settingsLanguageFrench;

  /// No description provided for @widgetAddNoteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get widgetAddNoteTooltip;

  /// No description provided for @widgetComposeTitle.
  ///
  /// In en, this message translates to:
  /// **'New Note'**
  String get widgetComposeTitle;

  /// No description provided for @widgetComposeDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard note?'**
  String get widgetComposeDiscardTitle;

  /// No description provided for @widgetComposeDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'Your note will not be saved.'**
  String get widgetComposeDiscardBody;

  /// No description provided for @widgetComposeNoCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories found.\nOpen MindVault to create one first.'**
  String get widgetComposeNoCategories;

  /// No description provided for @widgetComposeCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get widgetComposeCategoryLabel;

  /// No description provided for @widgetViewEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Note'**
  String get widgetViewEditTitle;

  /// No description provided for @widgetViewEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get widgetViewEdit;

  /// No description provided for @widgetViewDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get widgetViewDelete;

  /// No description provided for @widgetViewUnlocking.
  ///
  /// In en, this message translates to:
  /// **'Unlocking…'**
  String get widgetViewUnlocking;

  /// No description provided for @widgetViewNoContent.
  ///
  /// In en, this message translates to:
  /// **'No content'**
  String get widgetViewNoContent;

  /// No description provided for @widgetViewNotFound.
  ///
  /// In en, this message translates to:
  /// **'Note not found'**
  String get widgetViewNotFound;

  /// No description provided for @widgetViewDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get widgetViewDiscardTitle;

  /// No description provided for @widgetViewDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'Your edits will not be saved.'**
  String get widgetViewDiscardBody;

  /// No description provided for @widgetViewKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get widgetViewKeepEditing;
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  Future<AppStrings> load(Locale locale) {
    return SynchronousFuture<AppStrings>(lookupAppStrings(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'de',
        'en',
        'es',
        'fr',
        'he',
        'hi'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}

AppStrings lookupAppStrings(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppStringsDe();
    case 'en':
      return AppStringsEn();
    case 'es':
      return AppStringsEs();
    case 'fr':
      return AppStringsFr();
    case 'he':
      return AppStringsHe();
    case 'hi':
      return AppStringsHi();
  }

  throw FlutterError(
      'AppStrings.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
