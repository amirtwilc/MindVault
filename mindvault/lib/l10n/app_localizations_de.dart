// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppStringsDe extends AppStrings {
  AppStringsDe([String locale = 'de']) : super(locale);

  @override
  String get appBrand => 'MindVault';

  @override
  String get actionCancel => 'Abbrechen';

  @override
  String get actionSave => 'Speichern';

  @override
  String get actionDelete => 'Löschen';

  @override
  String get actionCreate => 'Erstellen';

  @override
  String get actionRename => 'Umbenennen';

  @override
  String get actionApply => 'Anwenden';

  @override
  String get actionClose => 'Schließen';

  @override
  String get actionDiscard => 'Verwerfen';

  @override
  String get actionTryAgain => 'Erneut versuchen';

  @override
  String get actionUnlock => 'Entsperren';

  @override
  String get actionRecoverContinue => 'Wiederherstellen & Fortfahren';

  @override
  String get actionSetupContinue => 'Einrichten & Fortfahren';

  @override
  String get actionStartFresh => 'Neu beginnen';

  @override
  String get actionContactUs => 'Kontakt';

  @override
  String get actionOk => 'OK';

  @override
  String get splashTagline => 'Deine Gedanken, sicher verschlüsselt.';

  @override
  String get splashLoading => 'Tresor wird gesichert…';

  @override
  String get authSubtitle => 'Deine verschlüsselten KI-Notizen';

  @override
  String get authEmailLabel => 'E-Mail';

  @override
  String get authPasswordLabel => 'Passwort';

  @override
  String get authEmailRequired => 'E-Mail ist erforderlich.';

  @override
  String get authEmailInvalid => 'Gib eine gültige E-Mail-Adresse ein.';

  @override
  String get authPasswordRequired => 'Passwort ist erforderlich.';

  @override
  String get authPasswordTooShort =>
      'Das Passwort muss mindestens 6 Zeichen lang sein.';

  @override
  String get authSignInEmail => 'Mit E-Mail anmelden';

  @override
  String get authCreateAccount => 'Konto erstellen';

  @override
  String get authNeedAccount => 'Noch kein Konto? Erstelle eins';

  @override
  String get authHaveAccount => 'Schon ein Konto? Anmelden';

  @override
  String get authOr => 'oder';

  @override
  String get authCheckEmail =>
      'Prüfe deine E-Mails, um dein Konto zu bestätigen, und melde dich dann an.';

  @override
  String get authCheckEmailOtp =>
      'Wir haben dir einen Bestätigungscode per E-Mail geschickt. Gib ihn hier ein, um dein Konto fertig einzurichten.';

  @override
  String get authOtpResent => 'Ein neuer Bestätigungscode wurde gesendet.';

  @override
  String get authRecoveryCodeSent =>
      'Wir haben dir einen Wiederherstellungscode per E-Mail geschickt.';

  @override
  String get authRecoveryCodeResent =>
      'Ein neuer Wiederherstellungscode wurde gesendet.';

  @override
  String get authInvalidCredentials => 'E-Mail oder Passwort ist falsch.';

  @override
  String get authEmailAlreadyUsed =>
      'Für diese E-Mail existiert bereits ein Konto. Versuche dich anzumelden.';

  @override
  String get authWeakPassword =>
      'Wähle ein stärkeres Passwort und versuche es erneut.';

  @override
  String get authEmailNotConfirmed =>
      'Bitte bestätige deine E-Mail, bevor du dich anmeldest.';

  @override
  String get authInvalidOtp =>
      'Dieser Code ist ungültig. Prüfe ihn und versuche es erneut.';

  @override
  String get authExpiredOtp =>
      'Dieser Code ist abgelaufen. Fordere einen neuen an und versuche es erneut.';

  @override
  String get authRateLimited =>
      'Zu viele Versuche. Bitte warte kurz und versuche es erneut.';

  @override
  String get authNetworkError =>
      'Der Anmeldeserver ist nicht erreichbar. Prüfe deine Verbindung und versuche es erneut.';

  @override
  String get authGenericError =>
      'Anmeldung fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String get authForgotPassword => 'Passwort vergessen?';

  @override
  String get authForgotPasswordTitle => 'Passwort zurücksetzen';

  @override
  String get authVerifyEmailTitle => 'E-Mail bestätigen';

  @override
  String get authVerifyRecoveryTitle => 'Wiederherstellungscode prüfen';

  @override
  String get authSetNewPasswordTitle => 'Neues Passwort festlegen';

  @override
  String get authVerifyEmailCode => 'E-Mail-Code prüfen';

  @override
  String get authVerifyRecoveryCode => 'Wiederherstellungscode prüfen';

  @override
  String get authOtpHelper =>
      'Gib den Code aus deiner Bestätigungs-E-Mail ein.';

  @override
  String get authRecoveryOtpHelper =>
      'Gib den Code aus deiner Wiederherstellungs-E-Mail ein.';

  @override
  String get authOtpLabel => 'E-Mail-Code';

  @override
  String get authOtpRequired => 'Ein Bestätigungscode ist erforderlich.';

  @override
  String get authOtpInvalidFormat => 'Gib den Code aus deiner E-Mail ein.';

  @override
  String get authResendCode => 'Code erneut senden';

  @override
  String get authSendingCode => 'Code wird gesendet...';

  @override
  String get authVerifyingCode => 'Code wird geprüft...';

  @override
  String get authSendRecoveryCode => 'Wiederherstellungscode senden';

  @override
  String get authBackToSignIn => 'Zurück zur Anmeldung';

  @override
  String get authSetNewPasswordBody =>
      'Gib ein neues Passwort für dein Konto ein.';

  @override
  String get authNewPasswordLabel => 'Neues Passwort';

  @override
  String get authConfirmPasswordLabel => 'Neues Passwort bestätigen';

  @override
  String get authConfirmPasswordRequired => 'Bitte bestätige dein Passwort.';

  @override
  String get authPasswordsDoNotMatch => 'Die Passwörter stimmen nicht überein.';

  @override
  String get authUpdatingPassword => 'Passwort wird aktualisiert...';

  @override
  String get authUpdatePassword => 'Passwort aktualisieren';

  @override
  String get authCancelRecovery => 'Wiederherstellung abbrechen';

  @override
  String get authPasswordUpdated =>
      'Passwort aktualisiert. Anmeldung wird abgeschlossen...';

  @override
  String get authSignInGoogle => 'Mit Google anmelden';

  @override
  String get authSigningIn => 'Anmelden...';

  @override
  String get authDisclaimer =>
      'Deine Notizen sind Ende-zu-Ende verschlüsselt.\nNur du kannst sie lesen.';

  @override
  String get pinSetupAppBar => 'Verschlüsselung einrichten';

  @override
  String get pinRecoveryAppBar => 'Verschlüsselungsschlüssel wiederherstellen';

  @override
  String get pinSetupHeading => 'Wiederherstellungs-PIN erstellen';

  @override
  String get pinRecoveryHeading => 'Gib deine Wiederherstellungs-PIN ein';

  @override
  String get pinSetupBody =>
      'Diese PIN schützt deine Notizen davor, von anderen gelesen zu werden. Du brauchst sie, wenn du dich auf einem neuen Gerät anmeldest.';

  @override
  String get pinRecoveryBody =>
      'Deine Notizen sind verschlüsselt. Gib deine Wiederherstellungs-PIN ein, um sie auf diesem Gerät zu entsperren.';

  @override
  String get pinLabel => 'Wiederherstellungs-PIN (4–8 Stellen)';

  @override
  String get pinConfirmLabel => 'PIN bestätigen';

  @override
  String get pinSetupDisclaimer =>
      'Deine PIN verlässt nie dieses Gerät. Dein verschlüsselter Schlüssel wird auf unseren Servern gespeichert, damit du ihn nach einer Neuinstallation wiederherstellen kannst, aber ohne die PIN kann er nicht gelesen werden.';

  @override
  String get pinRecoveryDisclaimer =>
      'Deine PIN verlässt nie dieses Gerät. Nur dein verschlüsselter Schlüssel liegt auf unseren Servern — er ist ohne PIN unleserlich.';

  @override
  String get pinForgot => 'PIN vergessen? Neu beginnen';

  @override
  String get pinSignOut => 'Abmelden';

  @override
  String get pinTooShort => 'Die PIN muss mindestens 4 Zeichen lang sein.';

  @override
  String get pinMismatch => 'PINs stimmen nicht überein.';

  @override
  String get pinRecoverError =>
      'Falsche PIN. Verschlüsselungsschlüssel konnte nicht wiederhergestellt werden.';

  @override
  String pinServerError(Object message) {
    return 'Serverfehler: $message';
  }

  @override
  String get pinStartFreshTitle => 'Neu beginnen?';

  @override
  String get pinStartFreshBody =>
      'Dies erzeugt einen neuen Verschlüsselungsschlüssel. Deine bestehenden Notizen gehen verloren.\n\nDieser Schritt ist endgültig.';

  @override
  String get pinEntryAppBar => 'Wiederherstellungs-PIN eingeben';

  @override
  String get pinEntryHeading => 'Gib deine Wiederherstellungs-PIN ein';

  @override
  String get pinEntryLabel => 'Wiederherstellungs-PIN';

  @override
  String get pinEntryNoKey =>
      'Kein Schlüssel gefunden. Bitte kontaktiere den Support.';

  @override
  String get pinEntryIncorrect => 'Falsche PIN. Bitte versuche es erneut.';

  @override
  String get pinSetupError =>
      'Verschlüsselung konnte nicht eingerichtet werden. Bitte versuche es erneut.';

  @override
  String pinLockedSeconds(int seconds) {
    return 'Zu viele Fehlversuche. Versuche es in ${seconds}s erneut.';
  }

  @override
  String pinLockedMinutes(int minutes) {
    return 'Zu viele Fehlversuche. Versuche es in ${minutes}m erneut.';
  }

  @override
  String get navAllNotes => 'Alle Notizen';

  @override
  String get navCategories => 'Kategorien';

  @override
  String get navSearch => 'Suche';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get homeNoCategoriesTitle =>
      'Noch keine Kategorien.\nTippe + zum Erstellen.';

  @override
  String get newCategoryDialogTitle => 'Neue Kategorie';

  @override
  String get categoryNameHint => 'Kategoriename';

  @override
  String get categoryColorLabel => 'Farbe';

  @override
  String get categoryNameInUse => 'Name bereits in Verwendung';

  @override
  String categoryLimitReached(int max, Object upgradeHint) {
    return 'Kategorienlimit erreicht ($max). $upgradeHint';
  }

  @override
  String noteLimitReached(int max, Object upgradeHint) {
    return 'Notizenlimit erreicht ($max). $upgradeHint';
  }

  @override
  String get upgradeHintFree => 'Auf Pro upgraden für mehr.';

  @override
  String get upgradeHintNone => '';

  @override
  String get notesListTitleFallback => 'Notizen';

  @override
  String get notesListEmptyTitle => 'Noch keine Notizen';

  @override
  String get notesListEmptyBody => 'Tippe +, um deine erste Notiz zu erstellen';

  @override
  String get noteUntitled => '(ohne Titel)';

  @override
  String get noteDeletedSnack => 'Notiz gelöscht';

  @override
  String get deleteNoteTitle => 'Notiz löschen?';

  @override
  String get deleteNoteBody =>
      'Dieser Vorgang kann nicht rückgängig gemacht werden.';

  @override
  String get privateAuthReason =>
      'Authentifiziere dich, um diese private Notiz zu sehen';

  @override
  String get renameCategory => 'Umbenennen';

  @override
  String get changeCategoryColor => 'Farbe ändern';

  @override
  String get deleteCategoryAction => 'Kategorie löschen';

  @override
  String get renameCategoryDialog => 'Kategorie umbenennen';

  @override
  String get categoryColorDialog => 'Kategoriefarbe';

  @override
  String deleteCategoryConfirmTitle(Object name) {
    return '\"$name\" löschen?';
  }

  @override
  String get deleteCategoryConfirmBody =>
      'Alle Notizen in dieser Kategorie werden ebenfalls gelöscht.';

  @override
  String get allNotesEmptyTitle => 'Noch keine Notizen';

  @override
  String get allNotesEmptyBody =>
      'Erstelle eine Kategorie und füge deine erste Notiz hinzu';

  @override
  String get allNotesCreateFirst => 'Erstelle zuerst eine Kategorie';

  @override
  String get editorNewTitle => 'Neue Notiz';

  @override
  String get editorEditTitle => 'Bearbeitung';

  @override
  String get editorSaving => 'Wird gespeichert…';

  @override
  String editorSavedAt(Object time) {
    return 'Gespeichert $time';
  }

  @override
  String get editorTitleHint => 'Titel';

  @override
  String get editorBodyHint => 'Schreibe los…';

  @override
  String get editorChangeCategory => 'Kategorie ändern';

  @override
  String get editorNewCategoryEntry => 'Neue Kategorie…';

  @override
  String get editorTooltipPublic => 'Öffentlich';

  @override
  String get editorTooltipPrivate => 'Privat';

  @override
  String get editorTooltipDelete => 'Notiz löschen';

  @override
  String get editorTooltipEdit => 'Notiz bearbeiten';

  @override
  String get editorTooltipCopy => 'Notiz kopieren';

  @override
  String get editorCopyMenuItem => 'Notiz kopieren';

  @override
  String get editorCopiedSnack => 'Notiz kopiert';

  @override
  String get editorSttRecord => 'Sprache aufnehmen';

  @override
  String get editorSttStop => 'Aufnahme beenden';

  @override
  String get searchHint => 'Notizen durchsuchen…';

  @override
  String get searchIdleTitle => 'Durchsuche deine Notizen';

  @override
  String get searchIdleBody =>
      'Stichwörter eingeben oder eine Frage stellen. \nPrivate Notizen werden ignoriert.';

  @override
  String searchNoResults(Object query) {
    return 'Keine Ergebnisse für \"$query\"';
  }

  @override
  String get searchTryDifferent => 'Versuche andere Stichwörter';

  @override
  String searchMoreLines(int count) {
    return '+$count weitere Zeilen';
  }

  @override
  String get searchTryAiHint => 'Nicht gefunden? KI-Suche ausprobieren';

  @override
  String get searchNoResultsAiCta => 'Keine Ergebnisse. KI-Suche starten';

  @override
  String get searchHistoryButtonTooltip => 'KI-Suchverlauf';

  @override
  String get searchBackToResults => 'Zurück zu Ergebnissen';

  @override
  String get widgetSearchTitle => 'Notizen durchsuchen';

  @override
  String get aiSearchTitle => 'KI-Suche';

  @override
  String get aiSearchHint => 'Frage etwas zu deinen Notizen…';

  @override
  String get aiSearchLoading => 'Notizen werden durchsucht…';

  @override
  String get aiSearchIdleTitle => 'Stelle eine Frage zu deinen Notizen';

  @override
  String get aiSearchIdleBody =>
      'Die KI durchsucht deine Notizen und fasst eine Antwort zusammen';

  @override
  String get aiSearchSuggestion1 => 'Fasse meine Trainingsnotizen zusammen';

  @override
  String get aiSearchSuggestion2 => 'Was habe ich über die Arbeit geschrieben?';

  @override
  String get aiSearchSuggestion3 => 'Finde Notizen zu meinen Zielen';

  @override
  String get aiSearchSuggestion4 => 'Was sind meine Reisepläne?';

  @override
  String get aiSearchSources => 'Quellen';

  @override
  String get aiSearchFromCache => 'Aus dem Cache';

  @override
  String get aiSearchRateTitle => 'Anfragelimit erreicht';

  @override
  String aiSearchRateSeconds(int seconds) {
    return 'Erneut versuchen in $seconds s';
  }

  @override
  String aiSearchRateMinutes(int minutes) {
    return 'Erneut versuchen in $minutes min';
  }

  @override
  String aiSearchRateResetsAt(Object time) {
    return 'Zurückgesetzt um $time';
  }

  @override
  String get aiSearchRateDefault => 'Bitte warte vor der nächsten Suche';

  @override
  String get aiSearchErrorDailyLimit =>
      'Tägliches KI-Limit erreicht. Versuche es morgen erneut.';

  @override
  String get aiSearchErrorSessionExpired =>
      'Sitzung abgelaufen. Bitte melde dich erneut an.';

  @override
  String get aiSearchErrorUnavailable => 'KI ist derzeit nicht verfügbar.';

  @override
  String get aiSearchErrorNetwork =>
      'Keine Verbindung. Prüfe deine Internetverbindung und versuche es erneut.';

  @override
  String get aiSearchErrorGeneric =>
      'KI-Anfrage fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String get aiInfoTitle => 'Über die KI-Suche';

  @override
  String get aiInfoBody =>
      'Die KI-Suche liest deine Notizen, um deine Frage zu beantworten.\n\n🔒 Private Notizen werden nie an die KI gesendet.\n\n📄 Sehr lange Notizen werden vor dem Senden gekürzt.';

  @override
  String get aiInfoDismiss => 'Verstanden';

  @override
  String get aiAnswerCopied => 'In die Zwischenablage kopiert';

  @override
  String get aiHistoryTitle => 'KI-Suchverlauf';

  @override
  String get aiHistoryEmpty => 'Noch kein Suchverlauf';

  @override
  String get aiHistoryRelativeNow => 'Gerade eben';

  @override
  String aiHistoryRelativeMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vor $count Minuten',
      one: 'Vor 1 Minute',
    );
    return '$_temp0';
  }

  @override
  String aiHistoryRelativeHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vor $count Stunden',
      one: 'Vor 1 Stunde',
    );
    return '$_temp0';
  }

  @override
  String aiHistoryRelativeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vor $count Tagen',
      one: 'Vor 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsSectionAccount => 'Konto';

  @override
  String get settingsSectionUsage => 'Nutzung';

  @override
  String get settingsSectionUpgrade => 'Upgrade';

  @override
  String get settingsSectionApp => 'App';

  @override
  String get settingsSectionLanguage => 'Sprache';

  @override
  String get settingsUnknownUser => 'Unbekannt';

  @override
  String get settingsTierFree => 'Kostenlos';

  @override
  String get settingsTierPro => 'Pro';

  @override
  String get settingsUsageAi => 'KI-Suchen heute';

  @override
  String get settingsUsageNotes => 'Notizen';

  @override
  String get settingsUsageCategories => 'Kategorien';

  @override
  String get settingsUpgradeTitle => 'Auf Pro upgraden';

  @override
  String get settingsUpgradeSubtitle =>
      '50 KI-Suchen/Tag · 1000 Notizen · 50 Kategorien';

  @override
  String get settingsUpgradeDialogBody =>
      'Pro bietet dir 50 KI-Suchen pro Tag, bis zu 1000 Notizen, 50 Kategorien und 20.000 Zeichen pro Notiz.';

  @override
  String get contactUsMessageHint => 'Deine Nachricht (optional)…';

  @override
  String get contactUsNoEmailApp =>
      'Keine E-Mail-App gefunden. Schreib uns an:';

  @override
  String get contactUsCopied => 'E-Mail-Adresse kopiert';

  @override
  String get settingsSignOut => 'Abmelden';

  @override
  String get settingsLanguageDeviceDefault => 'Geräteeinstellung';

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
  String get widgetAddNoteTooltip => 'Notiz hinzufügen';

  @override
  String get widgetComposeTitle => 'Neue Notiz';

  @override
  String get widgetComposeDiscardTitle => 'Notiz verwerfen?';

  @override
  String get widgetComposeDiscardBody => 'Deine Notiz wird nicht gespeichert.';

  @override
  String get widgetComposeNoCategories =>
      'Keine Kategorien gefunden.\nÖffne MindVault, um zuerst eine zu erstellen.';

  @override
  String get widgetComposeCategoryLabel => 'Kategorie';

  @override
  String get noteTypeLabel => 'Typ';

  @override
  String get noteTypeText => 'Text';

  @override
  String get noteTypeChecklist => 'Checkliste';

  @override
  String get removeDoneTasksLabel => 'Erledigte Aufgaben entfernen';

  @override
  String get removeDoneTasksTitle => 'Erledigte Aufgaben entfernen?';

  @override
  String get removeDoneTasksBody =>
      'Abgeschlossene Aufgaben werden dauerhaft entfernt.';

  @override
  String get widgetViewEditTitle => 'Notiz bearbeiten';

  @override
  String get widgetViewEdit => 'Bearbeiten';

  @override
  String get widgetViewDelete => 'Löschen';

  @override
  String get widgetViewUnlocking => 'Wird entsperrt…';

  @override
  String get widgetViewNoContent => 'Kein Inhalt';

  @override
  String get widgetViewNotFound => 'Notiz nicht gefunden';

  @override
  String get widgetViewDiscardTitle => 'Änderungen verwerfen?';

  @override
  String get widgetViewDiscardBody =>
      'Deine Änderungen werden nicht gespeichert.';

  @override
  String get widgetViewKeepEditing => 'Weiter bearbeiten';
}
