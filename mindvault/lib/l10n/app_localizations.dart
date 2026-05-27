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

  /// No description provided for @actionNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get actionNotNow;

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
  /// **'Never lose a thought'**
  String get authSubtitle;

  /// No description provided for @authIntroBody.
  ///
  /// In en, this message translates to:
  /// **'MindVault guarantees your memories are secure and are always with you, even if you change a device. To accomplish this, please sign in with your Google account'**
  String get authIntroBody;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required.'**
  String get authEmailRequired;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required.'**
  String get authPasswordRequired;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get authPasswordTooShort;

  /// No description provided for @authSignInEmail.
  ///
  /// In en, this message translates to:
  /// **'Sign in with email'**
  String get authSignInEmail;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// No description provided for @authNeedAccount.
  ///
  /// In en, this message translates to:
  /// **'Need an account? Create one'**
  String get authNeedAccount;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authHaveAccount;

  /// No description provided for @authOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOr;

  /// No description provided for @authCheckEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email to confirm your account, then sign in.'**
  String get authCheckEmail;

  /// No description provided for @authCheckEmailOtp.
  ///
  /// In en, this message translates to:
  /// **'We emailed you a confirmation code. Enter it here to finish creating your account.'**
  String get authCheckEmailOtp;

  /// No description provided for @authOtpResent.
  ///
  /// In en, this message translates to:
  /// **'A new confirmation code has been sent.'**
  String get authOtpResent;

  /// No description provided for @authRecoveryCodeSent.
  ///
  /// In en, this message translates to:
  /// **'We emailed you a recovery code.'**
  String get authRecoveryCodeSent;

  /// No description provided for @authRecoveryCodeResent.
  ///
  /// In en, this message translates to:
  /// **'A new recovery code has been sent.'**
  String get authRecoveryCodeResent;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'The email or password is incorrect.'**
  String get authInvalidCredentials;

  /// No description provided for @authEmailAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'An account already exists for this email. Try signing in instead.'**
  String get authEmailAlreadyUsed;

  /// No description provided for @authWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a stronger password and try again.'**
  String get authWeakPassword;

  /// No description provided for @authEmailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your email before signing in.'**
  String get authEmailNotConfirmed;

  /// No description provided for @authInvalidOtp.
  ///
  /// In en, this message translates to:
  /// **'That code is invalid. Check it and try again.'**
  String get authInvalidOtp;

  /// No description provided for @authExpiredOtp.
  ///
  /// In en, this message translates to:
  /// **'That code has expired. Request a new one and try again.'**
  String get authExpiredOtp;

  /// No description provided for @authRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get authRateLimited;

  /// No description provided for @authNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the sign-in server. Check your connection and try again.'**
  String get authNetworkError;

  /// No description provided for @authGenericError.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Please try again.'**
  String get authGenericError;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authForgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get authForgotPasswordTitle;

  /// No description provided for @authVerifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email'**
  String get authVerifyEmailTitle;

  /// No description provided for @authVerifyRecoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your recovery code'**
  String get authVerifyRecoveryTitle;

  /// No description provided for @authSetNewPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password'**
  String get authSetNewPasswordTitle;

  /// No description provided for @authVerifyEmailCode.
  ///
  /// In en, this message translates to:
  /// **'Verify email code'**
  String get authVerifyEmailCode;

  /// No description provided for @authVerifyRecoveryCode.
  ///
  /// In en, this message translates to:
  /// **'Verify recovery code'**
  String get authVerifyRecoveryCode;

  /// No description provided for @authOtpHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter the code from your confirmation email.'**
  String get authOtpHelper;

  /// No description provided for @authRecoveryOtpHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter the code from your recovery email.'**
  String get authRecoveryOtpHelper;

  /// No description provided for @authOtpLabel.
  ///
  /// In en, this message translates to:
  /// **'Email code'**
  String get authOtpLabel;

  /// No description provided for @authOtpRequired.
  ///
  /// In en, this message translates to:
  /// **'Verification code is required.'**
  String get authOtpRequired;

  /// No description provided for @authOtpInvalidFormat.
  ///
  /// In en, this message translates to:
  /// **'Enter the code from your email.'**
  String get authOtpInvalidFormat;

  /// No description provided for @authResendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get authResendCode;

  /// No description provided for @authSendingCode.
  ///
  /// In en, this message translates to:
  /// **'Sending code...'**
  String get authSendingCode;

  /// No description provided for @authVerifyingCode.
  ///
  /// In en, this message translates to:
  /// **'Verifying code...'**
  String get authVerifyingCode;

  /// No description provided for @authSendRecoveryCode.
  ///
  /// In en, this message translates to:
  /// **'Send recovery code'**
  String get authSendRecoveryCode;

  /// No description provided for @authBackToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get authBackToSignIn;

  /// No description provided for @authSetNewPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Enter a new password for your account.'**
  String get authSetNewPasswordBody;

  /// No description provided for @authNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authNewPasswordLabel;

  /// No description provided for @authConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get authConfirmPasswordLabel;

  /// No description provided for @authConfirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password.'**
  String get authConfirmPasswordRequired;

  /// No description provided for @authPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get authPasswordsDoNotMatch;

  /// No description provided for @authUpdatingPassword.
  ///
  /// In en, this message translates to:
  /// **'Updating password...'**
  String get authUpdatingPassword;

  /// No description provided for @authUpdatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get authUpdatePassword;

  /// No description provided for @authCancelRecovery.
  ///
  /// In en, this message translates to:
  /// **'Cancel recovery'**
  String get authCancelRecovery;

  /// No description provided for @authPasswordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated. Finishing sign-in...'**
  String get authPasswordUpdated;

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
  /// **'Your memories are end-to-end encrypted.\nOnly you can read them.'**
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
  /// **'This PIN protects your memories from being read by anyone but you. You\'ll need it if you sign in on a new device.'**
  String get pinSetupBody;

  /// No description provided for @pinRecoveryBody.
  ///
  /// In en, this message translates to:
  /// **'Your memories are encrypted. Enter your recovery PIN to unlock them on this device.'**
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
  /// **'Your PIN never leaves this device. Your encrypted key is stored on our servers so you can recover it on reinstall, but it cannot be read without the PIN.'**
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
  /// **'This will generate a new encryption key. Your existing memories will be lost.\n\nThis cannot be undone.'**
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
  /// **'Archive'**
  String get navAllNotes;

  /// No description provided for @navJots.
  ///
  /// In en, this message translates to:
  /// **'Sparks'**
  String get navJots;

  /// No description provided for @navCategories.
  ///
  /// In en, this message translates to:
  /// **'Clusters'**
  String get navCategories;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Recall'**
  String get navSearch;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @homeNoCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'No clusters yet.\nTap + to create one.'**
  String get homeNoCategoriesTitle;

  /// No description provided for @newCategoryDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'New Cluster'**
  String get newCategoryDialogTitle;

  /// No description provided for @categoryNameHint.
  ///
  /// In en, this message translates to:
  /// **'Cluster name'**
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
  /// **'Cluster limit reached ({max}). {upgradeHint}'**
  String categoryLimitReached(int max, Object upgradeHint);

  /// No description provided for @noteLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Memory limit reached ({max}). {upgradeHint}'**
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
  /// **'Memories'**
  String get notesListTitleFallback;

  /// No description provided for @notesListEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No memories yet'**
  String get notesListEmptyTitle;

  /// No description provided for @notesListEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap + to create your first memory'**
  String get notesListEmptyBody;

  /// No description provided for @noteUntitled.
  ///
  /// In en, this message translates to:
  /// **'(untitled)'**
  String get noteUntitled;

  /// No description provided for @noteDeletedSnack.
  ///
  /// In en, this message translates to:
  /// **'Memory deleted'**
  String get noteDeletedSnack;

  /// No description provided for @deleteNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete memory?'**
  String get deleteNoteTitle;

  /// No description provided for @deleteNoteBody.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deleteNoteBody;

  /// No description provided for @privateAuthReason.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to view this private memory'**
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
  /// **'Delete cluster'**
  String get deleteCategoryAction;

  /// No description provided for @renameCategoryDialog.
  ///
  /// In en, this message translates to:
  /// **'Rename Cluster'**
  String get renameCategoryDialog;

  /// No description provided for @categoryColorDialog.
  ///
  /// In en, this message translates to:
  /// **'Cluster Color'**
  String get categoryColorDialog;

  /// No description provided for @deleteCategoryConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String deleteCategoryConfirmTitle(Object name);

  /// No description provided for @deleteCategoryConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'All memories in this cluster will also be deleted.'**
  String get deleteCategoryConfirmBody;

  /// No description provided for @allNotesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No memories yet'**
  String get allNotesEmptyTitle;

  /// No description provided for @allNotesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create a cluster and add your first memory'**
  String get allNotesEmptyBody;

  /// No description provided for @allNotesCreateFirst.
  ///
  /// In en, this message translates to:
  /// **'Create a cluster first'**
  String get allNotesCreateFirst;

  /// No description provided for @editorNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New Memory'**
  String get editorNewTitle;

  /// No description provided for @editorEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Memory'**
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
  /// **'Change cluster'**
  String get editorChangeCategory;

  /// No description provided for @editorNewCategoryEntry.
  ///
  /// In en, this message translates to:
  /// **'New cluster…'**
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
  /// **'Delete memory'**
  String get editorTooltipDelete;

  /// No description provided for @editorTooltipEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit memory'**
  String get editorTooltipEdit;

  /// No description provided for @editorTooltipCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy memory'**
  String get editorTooltipCopy;

  /// No description provided for @reminderTooltipSet.
  ///
  /// In en, this message translates to:
  /// **'Set reminder'**
  String get reminderTooltipSet;

  /// No description provided for @reminderTooltipActive.
  ///
  /// In en, this message translates to:
  /// **'Reminder set'**
  String get reminderTooltipActive;

  /// No description provided for @reminderDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminderDialogTitle;

  /// No description provided for @reminderScheduledFor.
  ///
  /// In en, this message translates to:
  /// **'Scheduled for {time}'**
  String reminderScheduledFor(Object time);

  /// No description provided for @reminderEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get reminderEdit;

  /// No description provided for @reminderRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get reminderRemove;

  /// No description provided for @reminderSaveNoteFirst.
  ///
  /// In en, this message translates to:
  /// **'Add a title or memory body before setting a reminder.'**
  String get reminderSaveNoteFirst;

  /// No description provided for @reminderNotificationsRequired.
  ///
  /// In en, this message translates to:
  /// **'Notification permission must be granted for reminders.'**
  String get reminderNotificationsRequired;

  /// No description provided for @reminderMayBeDelayed.
  ///
  /// In en, this message translates to:
  /// **'Exact alarms are not enabled. This reminder may be delayed.'**
  String get reminderMayBeDelayed;

  /// No description provided for @reminderBackgroundPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow background reminders'**
  String get reminderBackgroundPermissionTitle;

  /// No description provided for @reminderBackgroundPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Some devices require MindVault to be allowed to work in the background or autostart so exact reminders can fire when the app is closed. If a settings page opens, enable MindVault and return to the app.'**
  String get reminderBackgroundPermissionBody;

  /// No description provided for @reminderBackgroundPermissionOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get reminderBackgroundPermissionOpenSettings;

  /// No description provided for @reminderMustBeFuture.
  ///
  /// In en, this message translates to:
  /// **'Choose a future date and time.'**
  String get reminderMustBeFuture;

  /// No description provided for @reminderNoteNotFound.
  ///
  /// In en, this message translates to:
  /// **'That reminder memory could not be found.'**
  String get reminderNoteNotFound;

  /// No description provided for @reminderNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Tap to open this memory'**
  String get reminderNotificationBody;

  /// No description provided for @editorCopyMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Copy memory'**
  String get editorCopyMenuItem;

  /// No description provided for @editorCopiedSnack.
  ///
  /// In en, this message translates to:
  /// **'Memory copied'**
  String get editorCopiedSnack;

  /// No description provided for @editorSttStop.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get editorSttStop;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search memories…'**
  String get searchHint;

  /// No description provided for @searchIdleTitle.
  ///
  /// In en, this message translates to:
  /// **'Search your memories'**
  String get searchIdleTitle;

  /// No description provided for @searchIdleBody.
  ///
  /// In en, this message translates to:
  /// **'Type keywords or ask a question. \nPrivate memories are ignored.'**
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
  /// **'Not what you were looking for? Try AI recall'**
  String get searchTryAiHint;

  /// No description provided for @searchNoResultsAiCta.
  ///
  /// In en, this message translates to:
  /// **'No results found. Click to perform an AI Recall'**
  String get searchNoResultsAiCta;

  /// No description provided for @searchHistoryButtonTooltip.
  ///
  /// In en, this message translates to:
  /// **'AI recall history'**
  String get searchHistoryButtonTooltip;

  /// No description provided for @searchBackToResults.
  ///
  /// In en, this message translates to:
  /// **'Back to results'**
  String get searchBackToResults;

  /// No description provided for @widgetSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Recall your memories'**
  String get widgetSearchTitle;

  /// No description provided for @aiSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Recall'**
  String get aiSearchTitle;

  /// No description provided for @aiSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Ask about your memories…'**
  String get aiSearchHint;

  /// No description provided for @aiSearchLoading.
  ///
  /// In en, this message translates to:
  /// **'Recalling your memories…'**
  String get aiSearchLoading;

  /// No description provided for @aiSearchIdleTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask anything about your memories'**
  String get aiSearchIdleTitle;

  /// No description provided for @aiSearchIdleBody.
  ///
  /// In en, this message translates to:
  /// **'AI recalls your memories and synthesises an answer'**
  String get aiSearchIdleBody;

  /// No description provided for @aiSearchSuggestion1.
  ///
  /// In en, this message translates to:
  /// **'Summarize my workout memories'**
  String get aiSearchSuggestion1;

  /// No description provided for @aiSearchSuggestion2.
  ///
  /// In en, this message translates to:
  /// **'What did I write about work?'**
  String get aiSearchSuggestion2;

  /// No description provided for @aiSearchSuggestion3.
  ///
  /// In en, this message translates to:
  /// **'Find memories about my goals'**
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

  /// No description provided for @aiSearchErrorDailyLimit.
  ///
  /// In en, this message translates to:
  /// **'Daily AI limit reached. Try again tomorrow.'**
  String get aiSearchErrorDailyLimit;

  /// No description provided for @aiSearchErrorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please sign in again.'**
  String get aiSearchErrorSessionExpired;

  /// No description provided for @aiSearchErrorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'AI is not available right now.'**
  String get aiSearchErrorUnavailable;

  /// No description provided for @aiSearchErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your internet and try again.'**
  String get aiSearchErrorNetwork;

  /// No description provided for @aiSearchErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'AI request failed. Please try again.'**
  String get aiSearchErrorGeneric;

  /// No description provided for @aiInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'About AI Recall'**
  String get aiInfoTitle;

  /// No description provided for @aiInfoBody.
  ///
  /// In en, this message translates to:
  /// **'AI Recall reads your memories to answer your question.\n\n🔒 Private memories are never sent to AI.\n\n📄 Very long memories are shortened before being sent.'**
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
  /// **'AI Recall History'**
  String get aiHistoryTitle;

  /// No description provided for @aiHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recall history yet'**
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
  /// **'AI recalls today'**
  String get settingsUsageAi;

  /// No description provided for @settingsUsageJotsAi.
  ///
  /// In en, this message translates to:
  /// **'Spark AI organizes today'**
  String get settingsUsageJotsAi;

  /// No description provided for @settingsUsageNotes.
  ///
  /// In en, this message translates to:
  /// **'Memories'**
  String get settingsUsageNotes;

  /// No description provided for @settingsUsageCategories.
  ///
  /// In en, this message translates to:
  /// **'Clusters'**
  String get settingsUsageCategories;

  /// No description provided for @settingsUpgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get settingsUpgradeTitle;

  /// No description provided for @settingsUpgradeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'30 AI recalls/day · 1000 memories · 50 clusters'**
  String get settingsUpgradeSubtitle;

  /// No description provided for @settingsUpgradeDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Pro gives you 30 AI recalls/day, up to 1000 memories, 50 clusters, and 20,000 chars per memory.\n\ncoming soon'**
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

  /// No description provided for @jotsAddTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add spark'**
  String get jotsAddTooltip;

  /// No description provided for @jotAddDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'New Spark'**
  String get jotAddDialogTitle;

  /// No description provided for @jotInputHint.
  ///
  /// In en, this message translates to:
  /// **'Capture a quick thought'**
  String get jotInputHint;

  /// No description provided for @jotSavedSnack.
  ///
  /// In en, this message translates to:
  /// **'Thought saved'**
  String get jotSavedSnack;

  /// No description provided for @jotSaveUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Thought could not be saved. Please try again.'**
  String get jotSaveUnavailable;

  /// No description provided for @jotCharCounter.
  ///
  /// In en, this message translates to:
  /// **'{count}/{max} characters'**
  String jotCharCounter(int count, int max);

  /// No description provided for @jotsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No sparks waiting'**
  String get jotsEmptyTitle;

  /// No description provided for @jotsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap + whenever a thought pops up.'**
  String get jotsEmptyBody;

  /// No description provided for @jotsSortOldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get jotsSortOldestFirst;

  /// No description provided for @jotsSortNewestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get jotsSortNewestFirst;

  /// No description provided for @jotsOrganizeAi.
  ///
  /// In en, this message translates to:
  /// **'Organize with AI'**
  String get jotsOrganizeAi;

  /// No description provided for @jotsAcceptAll.
  ///
  /// In en, this message translates to:
  /// **'Accept all suggestions'**
  String get jotsAcceptAll;

  /// No description provided for @jotsAiInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'About Sparks AI'**
  String get jotsAiInfoTitle;

  /// No description provided for @jotsAiInfoBody.
  ///
  /// In en, this message translates to:
  /// **'Sparks AI suggests how to organize unhandled thoughts. Only unsent sparks, cluster names, and memory titles are sent. Memory bodies and private memories are not sent, and long lists may be limited.'**
  String get jotsAiInfoBody;

  /// No description provided for @jotsAiNoNew.
  ///
  /// In en, this message translates to:
  /// **'No new thoughts to organize.'**
  String get jotsAiNoNew;

  /// No description provided for @jotsAiQuota.
  ///
  /// In en, this message translates to:
  /// **'Daily Sparks AI limit reached.'**
  String get jotsAiQuota;

  /// No description provided for @jotsAiFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not organize sparks. Try again.'**
  String get jotsAiFailed;

  /// No description provided for @jotsAiSuggestionsProvided.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =0{0 suggestions were provided. Try writing more specific thoughts next time.} =1{1 suggestion was provided.} other{{count} suggestions were provided.}}'**
  String jotsAiSuggestionsProvided(int count);

  /// No description provided for @jotsAiLimitedTo30.
  ///
  /// In en, this message translates to:
  /// **'Only the oldest 30 new sparks were sent.'**
  String get jotsAiLimitedTo30;

  /// No description provided for @jotsSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String jotsSelectedCount(int count);

  /// No description provided for @jotsDeleteSelectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete selected sparks?'**
  String get jotsDeleteSelectedTitle;

  /// No description provided for @jotsDeleteSelectedBody.
  ///
  /// In en, this message translates to:
  /// **'Selected thoughts will be permanently deleted.'**
  String get jotsDeleteSelectedBody;

  /// No description provided for @jotCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created {time}'**
  String jotCreatedAt(Object time);

  /// No description provided for @jotActionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Handle spark'**
  String get jotActionsTooltip;

  /// No description provided for @jotActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Handle thought'**
  String get jotActionsTitle;

  /// No description provided for @jotActionCreateNote.
  ///
  /// In en, this message translates to:
  /// **'Create new memory'**
  String get jotActionCreateNote;

  /// No description provided for @jotActionAddToNote.
  ///
  /// In en, this message translates to:
  /// **'Add to existing memory'**
  String get jotActionAddToNote;

  /// No description provided for @jotActionCreateAlert.
  ///
  /// In en, this message translates to:
  /// **'Create alert'**
  String get jotActionCreateAlert;

  /// No description provided for @jotActionDeleteThought.
  ///
  /// In en, this message translates to:
  /// **'Delete thought'**
  String get jotActionDeleteThought;

  /// No description provided for @jotActionSuggestedByAi.
  ///
  /// In en, this message translates to:
  /// **'These actions were suggested by AI.'**
  String get jotActionSuggestedByAi;

  /// No description provided for @jotActionUpdateThought.
  ///
  /// In en, this message translates to:
  /// **'Update thought text'**
  String get jotActionUpdateThought;

  /// No description provided for @jotActionUpdatedThoughtText.
  ///
  /// In en, this message translates to:
  /// **'Updated thought'**
  String get jotActionUpdatedThoughtText;

  /// No description provided for @jotActionUpdatedThoughtHint.
  ///
  /// In en, this message translates to:
  /// **'Example: Lord of the Rings'**
  String get jotActionUpdatedThoughtHint;

  /// No description provided for @jotActionNewNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Memory title'**
  String get jotActionNewNoteTitle;

  /// No description provided for @jotActionCategory.
  ///
  /// In en, this message translates to:
  /// **'Cluster'**
  String get jotActionCategory;

  /// No description provided for @jotActionNewCategory.
  ///
  /// In en, this message translates to:
  /// **'New cluster'**
  String get jotActionNewCategory;

  /// No description provided for @jotActionNote.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get jotActionNote;

  /// No description provided for @jotActionNoNotes.
  ///
  /// In en, this message translates to:
  /// **'No memories in this cluster'**
  String get jotActionNoNotes;

  /// No description provided for @jotActionLock.
  ///
  /// In en, this message translates to:
  /// **'Lock memory'**
  String get jotActionLock;

  /// No description provided for @jotActionReminderWhen.
  ///
  /// In en, this message translates to:
  /// **'Alert at {time}'**
  String jotActionReminderWhen(Object time);

  /// No description provided for @jotActionPickReminder.
  ///
  /// In en, this message translates to:
  /// **'Choose date and time'**
  String get jotActionPickReminder;

  /// No description provided for @jotActionAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get jotActionAccept;

  /// No description provided for @jotActionChooseFuture.
  ///
  /// In en, this message translates to:
  /// **'Choose a future date and time.'**
  String get jotActionChooseFuture;

  /// No description provided for @jotNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Tap to organize this thought'**
  String get jotNotificationBody;

  /// No description provided for @jotDailyDigestTitle.
  ///
  /// In en, this message translates to:
  /// **'MindVault Sparks'**
  String get jotDailyDigestTitle;

  /// No description provided for @jotDailyDigestBody.
  ///
  /// In en, this message translates to:
  /// **'You have thoughts waiting to be organized.'**
  String get jotDailyDigestBody;

  /// No description provided for @jotReminderNotFound.
  ///
  /// In en, this message translates to:
  /// **'That thought could not be found.'**
  String get jotReminderNotFound;

  /// No description provided for @widgetAddNoteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add memory'**
  String get widgetAddNoteTooltip;

  /// No description provided for @widgetComposeTitle.
  ///
  /// In en, this message translates to:
  /// **'New Memory'**
  String get widgetComposeTitle;

  /// No description provided for @widgetComposeDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard memory?'**
  String get widgetComposeDiscardTitle;

  /// No description provided for @widgetComposeDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'Your memory will not be saved.'**
  String get widgetComposeDiscardBody;

  /// No description provided for @widgetComposeNoCategories.
  ///
  /// In en, this message translates to:
  /// **'No clusters found.\nOpen MindVault to create one first.'**
  String get widgetComposeNoCategories;

  /// No description provided for @widgetComposeCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Cluster'**
  String get widgetComposeCategoryLabel;

  /// No description provided for @noteTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get noteTypeLabel;

  /// No description provided for @noteTypeText.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get noteTypeText;

  /// No description provided for @noteTypeChecklist.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get noteTypeChecklist;

  /// No description provided for @removeDoneTasksLabel.
  ///
  /// In en, this message translates to:
  /// **'Remove done tasks'**
  String get removeDoneTasksLabel;

  /// No description provided for @removeDoneTasksTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove done tasks?'**
  String get removeDoneTasksTitle;

  /// No description provided for @removeDoneTasksBody.
  ///
  /// In en, this message translates to:
  /// **'Completed tasks will be permanently removed.'**
  String get removeDoneTasksBody;

  /// No description provided for @widgetViewEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Memory'**
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
  /// **'Memory not found'**
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

  /// No description provided for @editorSttRecord.
  ///
  /// In en, this message translates to:
  /// **'Record voice'**
  String get editorSttRecord;

  /// No description provided for @walkthroughSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get walkthroughSkip;

  /// No description provided for @walkthroughBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get walkthroughBack;

  /// No description provided for @walkthroughNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get walkthroughNext;

  /// No description provided for @walkthroughDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get walkthroughDone;

  /// No description provided for @walkthroughAllowNotifications.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get walkthroughAllowNotifications;

  /// No description provided for @walkthroughOpenBackgroundSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get walkthroughOpenBackgroundSettings;

  /// No description provided for @walkthroughDoLater.
  ///
  /// In en, this message translates to:
  /// **'I will do this later'**
  String get walkthroughDoLater;

  /// No description provided for @walkthroughWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to MindVault'**
  String get walkthroughWelcomeTitle;

  /// No description provided for @walkthroughWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'MindVault helps you keep your memories and thoughts close at hand. For optimal experience, allow notifications so reminders can reach you.'**
  String get walkthroughWelcomeBody;

  /// No description provided for @walkthroughBackgroundTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep reminders reliable'**
  String get walkthroughBackgroundTitle;

  /// No description provided for @walkthroughBackgroundBody.
  ///
  /// In en, this message translates to:
  /// **'Some Android devices pause apps in the background. We can try to open the right settings; enable MindVault there, then return here.'**
  String get walkthroughBackgroundBody;

  /// No description provided for @walkthroughArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get walkthroughArchiveTitle;

  /// No description provided for @walkthroughArchiveBody.
  ///
  /// In en, this message translates to:
  /// **'Archive is your memory library. Write and revisit recipes, to-dos, ideas, and anything you do not want to lose.'**
  String get walkthroughArchiveBody;

  /// No description provided for @walkthroughClustersTitle.
  ///
  /// In en, this message translates to:
  /// **'Clusters'**
  String get walkthroughClustersTitle;

  /// No description provided for @walkthroughClustersBody.
  ///
  /// In en, this message translates to:
  /// **'Clusters keep memories organized and color coded, so related thoughts stay easy to scan.'**
  String get walkthroughClustersBody;

  /// No description provided for @walkthroughRecallTitle.
  ///
  /// In en, this message translates to:
  /// **'Recall'**
  String get walkthroughRecallTitle;

  /// No description provided for @walkthroughRecallBody.
  ///
  /// In en, this message translates to:
  /// **'Recall searches your memories by keyword or with AI. Ask something like \"How much sugar do I need for my cake?\" and MindVault will provide a straight answer, not just find the memory.'**
  String get walkthroughRecallBody;

  /// No description provided for @walkthroughSparksTitle.
  ///
  /// In en, this message translates to:
  /// **'Sparks'**
  String get walkthroughSparksTitle;

  /// No description provided for @walkthroughSparksBody.
  ///
  /// In en, this message translates to:
  /// **'Sparks are quick thoughts you are not ready to turn into memories. Capture things like \"watch that movie\", \"Jack likes strawberries\", or \"Beth is my colleague\'s daughter\'s name\". Decide later what to do or let Spark AI suggest for you.'**
  String get walkthroughSparksBody;

  /// No description provided for @walkthroughWidgetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Use MindVault widgets'**
  String get walkthroughWidgetsTitle;

  /// No description provided for @walkthroughWidgetsBody.
  ///
  /// In en, this message translates to:
  /// **'MindVault widgets are powerful tools to quickly access your memory and create thoughts on the fly. Long-press the home screen, choose Widgets, look for MindVault and drag the widgets to your home screen.'**
  String get walkthroughWidgetsBody;

  /// No description provided for @settingsReplayWalkthrough.
  ///
  /// In en, this message translates to:
  /// **'Replay walkthrough'**
  String get settingsReplayWalkthrough;

  /// No description provided for @settingsReplayWalkthroughSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See the MindVault tour again'**
  String get settingsReplayWalkthroughSubtitle;

  /// No description provided for @memoryHelpTooltip.
  ///
  /// In en, this message translates to:
  /// **'Memory help'**
  String get memoryHelpTooltip;

  /// No description provided for @memoryHelpDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Memory features'**
  String get memoryHelpDialogTitle;

  /// No description provided for @memoryHelpTitleField.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get memoryHelpTitleField;

  /// No description provided for @memoryHelpTitleFieldBody.
  ///
  /// In en, this message translates to:
  /// **'Add a short title to make the memory easier to recognize and recall.'**
  String get memoryHelpTitleFieldBody;

  /// No description provided for @memoryHelpType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get memoryHelpType;

  /// No description provided for @memoryHelpTypeBody.
  ///
  /// In en, this message translates to:
  /// **'Choose {recordType} for freeform text or {planType} for a checklist.'**
  String memoryHelpTypeBody(Object recordType, Object planType);

  /// No description provided for @memoryHelpCluster.
  ///
  /// In en, this message translates to:
  /// **'Cluster'**
  String get memoryHelpCluster;

  /// No description provided for @memoryHelpClusterBody.
  ///
  /// In en, this message translates to:
  /// **'Move the memory into a color-coded cluster.'**
  String get memoryHelpClusterBody;

  /// No description provided for @memoryHelpRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get memoryHelpRecord;

  /// No description provided for @memoryHelpRecordBody.
  ///
  /// In en, this message translates to:
  /// **'Use voice recording to dictate into the title or body.'**
  String get memoryHelpRecordBody;

  /// No description provided for @memoryHelpCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get memoryHelpCopy;

  /// No description provided for @memoryHelpCopyBody.
  ///
  /// In en, this message translates to:
  /// **'Copy the memory body to the clipboard.'**
  String get memoryHelpCopyBody;

  /// No description provided for @memoryHelpReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get memoryHelpReminder;

  /// No description provided for @memoryHelpReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Set an alert for this memory; notifications must be allowed.'**
  String get memoryHelpReminderBody;

  /// No description provided for @memoryHelpLock.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get memoryHelpLock;

  /// No description provided for @memoryHelpLockBody.
  ///
  /// In en, this message translates to:
  /// **'Mark a memory private so opening it requires device authentication.'**
  String get memoryHelpLockBody;
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
