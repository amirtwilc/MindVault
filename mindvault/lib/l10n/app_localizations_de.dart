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
  String get actionNotNow => 'Nicht jetzt';

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
  String get authSubtitle => 'Verliere nie wieder einen Gedanken';

  @override
  String get authIntroBody =>
      'MindVault stellt sicher, dass deine Erinnerungen geschützt sind und immer bei dir bleiben, selbst wenn du das Gerät wechselst. Melde dich dafür bitte mit deinem Google-Konto an.';

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
      'Deine Erinnerungen sind Ende-zu-Ende verschlüsselt.\nNur du kannst sie lesen.';

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
      'Diese PIN schützt deine Erinnerungen davor, von anderen gelesen zu werden. Du brauchst sie, wenn du dich auf einem neuen Gerät anmeldest.';

  @override
  String get pinRecoveryBody =>
      'Deine Erinnerungen sind verschlüsselt. Gib deine Wiederherstellungs-PIN ein, um sie auf diesem Gerät zu entsperren.';

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
      'Dies erzeugt einen neuen Verschlüsselungsschlüssel. Deine bestehenden Erinnerungen gehen verloren.\n\nDieser Schritt ist endgültig.';

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
  String get navAllNotes => 'Archiv';

  @override
  String get navJots => 'Funken';

  @override
  String get navCategories => 'Cluster';

  @override
  String get navSearch => 'Abruf';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get homeNoCategoriesTitle =>
      'Noch keine Cluster.\nTippe + zum Erstellen.';

  @override
  String get newCategoryDialogTitle => 'Neue Cluster';

  @override
  String get categoryNameHint => 'Clusterame';

  @override
  String get categoryColorLabel => 'Farbe';

  @override
  String get categoryNameInUse => 'Name bereits in Verwendung';

  @override
  String categoryLimitReached(int max, Object upgradeHint) {
    return 'Clusterlimit erreicht ($max). $upgradeHint';
  }

  @override
  String noteLimitReached(int max, Object upgradeHint) {
    return 'Erinnerungenlimit erreicht ($max). $upgradeHint';
  }

  @override
  String get upgradeHintFree => 'Auf Pro upgraden für mehr.';

  @override
  String get upgradeHintNone => '';

  @override
  String get notesListTitleFallback => 'Erinnerungen';

  @override
  String get notesListEmptyTitle => 'Noch keine Erinnerungen';

  @override
  String get notesListEmptyBody =>
      'Tippe +, um deine erste Erinnerung zu erstellen';

  @override
  String get noteUntitled => '(ohne Titel)';

  @override
  String get noteDeletedSnack => 'Erinnerung gelöscht';

  @override
  String get deleteNoteTitle => 'Erinnerung löschen?';

  @override
  String get deleteNoteBody =>
      'Dieser Vorgang kann nicht rückgängig gemacht werden.';

  @override
  String get privateAuthReason =>
      'Authentifiziere dich, um diese private Erinnerung zu sehen';

  @override
  String get renameCategory => 'Umbenennen';

  @override
  String get changeCategoryColor => 'Farbe ändern';

  @override
  String get deleteCategoryAction => 'Cluster löschen';

  @override
  String get renameCategoryDialog => 'Cluster umbenennen';

  @override
  String get categoryColorDialog => 'Clusterfarbe';

  @override
  String deleteCategoryConfirmTitle(Object name) {
    return '\"$name\" löschen?';
  }

  @override
  String get deleteCategoryConfirmBody =>
      'Archiv in dieser Cluster werden ebenfalls gelöscht.';

  @override
  String get allNotesEmptyTitle => 'Noch keine Erinnerungen';

  @override
  String get allNotesEmptyBody =>
      'Erstelle eine Cluster und füge deine erste Erinnerung hinzu';

  @override
  String get allNotesCreateFirst => 'Erstelle zuerst eine Cluster';

  @override
  String get editorNewTitle => 'Neue Erinnerung';

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
  String get editorChangeCategory => 'Cluster ändern';

  @override
  String get editorNewCategoryEntry => 'Neue Cluster…';

  @override
  String get editorTooltipPublic => 'Öffentlich';

  @override
  String get editorTooltipPrivate => 'Privat';

  @override
  String get editorTooltipDelete => 'Erinnerung löschen';

  @override
  String get editorTooltipEdit => 'Erinnerung bearbeiten';

  @override
  String get editorTooltipCopy => 'Erinnerung kopieren';

  @override
  String get reminderTooltipSet => 'Erinnerung festlegen';

  @override
  String get reminderTooltipActive => 'Erinnerung eingestellt';

  @override
  String get reminderDialogTitle => 'Erinnerung';

  @override
  String reminderScheduledFor(Object time) {
    return 'Geplant für $time';
  }

  @override
  String get reminderEdit => 'Bearbeiten';

  @override
  String get reminderRemove => 'Entfernen';

  @override
  String get reminderSaveNoteFirst =>
      'Füge einen Titel oder Erinnerungtext hinzu, bevor du eine Erinnerung festlegst.';

  @override
  String get reminderNotificationsRequired =>
      'Die Benachrichtigungsberechtigung muss für Erinnerungen erteilt werden.';

  @override
  String get reminderMayBeDelayed =>
      'Exakte Alarme sind nicht aktiviert. Diese Erinnerung kann sich verzögern.';

  @override
  String get reminderBackgroundPermissionTitle =>
      'Hintergrund-Erinnerungen erlauben';

  @override
  String get reminderBackgroundPermissionBody =>
      'Einige Geräte erfordern, dass MindVault im Hintergrund arbeiten oder automatisch starten darf, damit genaue Erinnerungen ausgelöst werden, wenn die App geschlossen ist. Falls eine Einstellungsseite geöffnet wird, aktiviere MindVault und kehre zur App zurück.';

  @override
  String get reminderBackgroundPermissionOpenSettings => 'Einstellungen öffnen';

  @override
  String get reminderMustBeFuture =>
      'Wähle ein zukünftiges Datum und eine zukünftige Uhrzeit.';

  @override
  String get reminderNoteNotFound =>
      'Diese ErinnerungsErinnerung wurde nicht gefunden.';

  @override
  String get reminderNotificationBody =>
      'Tippen, um diese Erinnerung zu öffnen';

  @override
  String get editorCopyMenuItem => 'Erinnerung kopieren';

  @override
  String get editorCopiedSnack => 'Erinnerung kopiert';

  @override
  String get editorSttStop => 'Aufnahme beenden';

  @override
  String get searchHint => 'Erinnerungen durchsuchen…';

  @override
  String get searchIdleTitle => 'Durchsuche deine Erinnerungen';

  @override
  String get searchIdleBody =>
      'Stichwörter eingeben oder eine Frage stellen. \nPrivate Erinnerungen werden ignoriert.';

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
  String get searchTryAiHint => 'Nicht gefunden? KI-Abruf ausprobieren';

  @override
  String get searchNoResultsAiCta => 'Keine Ergebnisse. KI-Abruf starten';

  @override
  String get searchHistoryButtonTooltip => 'KI-Suchverlauf';

  @override
  String get searchBackToResults => 'Zurück zu Ergebnissen';

  @override
  String get widgetSearchTitle => 'Erinnerungen durchsuchen';

  @override
  String get aiSearchTitle => 'KI-Abruf';

  @override
  String get aiSearchHint => 'Frage etwas zu deinen Erinnerungen…';

  @override
  String get aiSearchLoading => 'Erinnerungen werden durchsucht…';

  @override
  String get aiSearchIdleTitle => 'Stelle eine Frage zu deinen Erinnerungen';

  @override
  String get aiSearchIdleBody =>
      'Die KI durchsucht deine Erinnerungen und fasst eine Antwort zusammen';

  @override
  String get aiSearchSuggestion1 =>
      'Fasse meine TrainingsErinnerungen zusammen';

  @override
  String get aiSearchSuggestion2 => 'Was habe ich über die Arbeit geschrieben?';

  @override
  String get aiSearchSuggestion3 => 'Finde Erinnerungen zu meinen Zielen';

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
  String get aiSearchRateDefault => 'Bitte warte vor der nächsten Abruf';

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
  String get aiInfoTitle => 'Über die KI-Abruf';

  @override
  String get aiInfoBody =>
      'Die KI-Abruf liest deine Erinnerungen, um deine Frage zu beantworten.\n\n🔒 Private Erinnerungen werden nie an die KI gesendet.\n\n📄 Sehr lange Erinnerungen werden vor dem Senden gekürzt.';

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
  String get settingsUsageAi => 'KI-Abrufn heute';

  @override
  String get settingsUsageJotsAi => 'Funken-KI-Organisationen heute';

  @override
  String get settingsUsageNotes => 'Erinnerungen';

  @override
  String get settingsUsageCategories => 'Cluster';

  @override
  String get settingsUpgradeTitle => 'Auf Pro upgraden';

  @override
  String get settingsUpgradeSubtitle =>
      '30 KI-Abrufn/Tag · 1000 Erinnerungen · 50 Cluster';

  @override
  String get settingsUpgradeDialogBody =>
      'Pro bietet dir 30 KI-Abrufn pro Tag, bis zu 1000 Erinnerungen, 50 Cluster und 20.000 Zeichen pro Erinnerung.\n\nbald verfügbar';

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
  String get jotsAddTooltip => 'Funke hinzuf?gen';

  @override
  String get jotAddDialogTitle => 'Neuer Funke';

  @override
  String get jotInputHint => 'Schnellen Gedanken festhalten';

  @override
  String get jotSavedSnack => 'Gedanke gespeichert';

  @override
  String get jotSaveUnavailable =>
      'Gedanke konnte nicht gespeichert werden. Bitte versuche es erneut.';

  @override
  String jotCharCounter(int count, int max) {
    return '$count/$max Zeichen';
  }

  @override
  String get jotsEmptyTitle => 'Keine Funken offen';

  @override
  String get jotsEmptyBody => 'Tippe auf +, sobald dir ein Gedanke kommt.';

  @override
  String get jotsSortOldestFirst => 'Älteste zuerst';

  @override
  String get jotsSortNewestFirst => 'Neueste zuerst';

  @override
  String get jotsOrganizeAi => 'Mit KI organisieren';

  @override
  String get jotsAcceptAll => 'Alle Vorschläge annehmen';

  @override
  String get jotsAiInfoTitle => '?ber Funken-KI';

  @override
  String get jotsAiInfoBody =>
      'Funken KI schlägt vor, wie nicht bearbeitete Gedanken organisiert werden können. Es werden nur noch nicht gesendete Funken, Clusteramen und Erinnerungtitel gesendet. Erinnerungtexte und private Erinnerungen werden nicht gesendet, und lange Listen können begrenzt werden.';

  @override
  String get jotsAiNoNew => 'Keine neuen Gedanken zum Organisieren.';

  @override
  String get jotsAiQuota => 'T?gliches Funken-KI-Limit erreicht.';

  @override
  String get jotsAiFailed => 'Funken konnten nicht organisiert werden.';

  @override
  String jotsAiSuggestionsProvided(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Vorschläge wurden bereitgestellt.',
      one: '1 Vorschlag wurde bereitgestellt.',
      zero:
          '0 Vorschläge wurden bereitgestellt. Versuche nächstes Mal, konkretere Gedanken zu schreiben.',
    );
    return '$_temp0';
  }

  @override
  String get jotsAiLimitedTo30 =>
      'Nur die ältesten 30 neuen Funken wurden gesendet.';

  @override
  String jotsSelectedCount(int count) {
    return '$count ausgewählt';
  }

  @override
  String get jotsDeleteSelectedTitle => 'Ausgewählte Funken löschen?';

  @override
  String get jotsDeleteSelectedBody =>
      'Ausgewählte Gedanken werden dauerhaft gelöscht.';

  @override
  String jotCreatedAt(Object time) {
    return 'Erstellt: $time';
  }

  @override
  String get jotActionsTooltip => 'Funke bearbeiten';

  @override
  String get jotActionsTitle => 'Gedanken bearbeiten';

  @override
  String get jotActionCreateNote => 'Neue Erinnerung erstellen';

  @override
  String get jotActionAddToNote => 'Zu bestehender Erinnerung hinzufügen';

  @override
  String get jotActionCreateAlert => 'Erinnerung erstellen';

  @override
  String get jotActionDeleteThought => 'Gedanken löschen';

  @override
  String get jotActionSuggestedByAi =>
      'Diese Aktionen wurden von der KI vorgeschlagen.';

  @override
  String get jotActionUpdateThought => 'Gedankentext aktualisieren';

  @override
  String get jotActionUpdatedThoughtText => 'Aktualisierter Gedanke';

  @override
  String get jotActionUpdatedThoughtHint => 'Beispiel: Der Herr der Ringe';

  @override
  String get jotActionNewNoteTitle => 'Erinnerungtitel';

  @override
  String get jotActionCategory => 'Cluster';

  @override
  String get jotActionNewCategory => 'Neue Cluster';

  @override
  String get jotActionNote => 'Erinnerung';

  @override
  String get jotActionNoNotes => 'Keine Erinnerungen in dieser Cluster';

  @override
  String get jotActionLock => 'Erinnerung sperren';

  @override
  String jotActionReminderWhen(Object time) {
    return 'Erinnerung um $time';
  }

  @override
  String get jotActionPickReminder => 'Datum und Uhrzeit auswählen';

  @override
  String get jotActionAccept => 'Annehmen';

  @override
  String get jotActionChooseFuture =>
      'Wähle ein Datum und eine Uhrzeit in der Zukunft.';

  @override
  String get jotNotificationBody =>
      'Tippen, um diesen Gedanken zu organisieren';

  @override
  String get jotDailyDigestTitle => 'MindVault-Funken';

  @override
  String get jotDailyDigestBody =>
      'Du hast Gedanken, die noch organisiert werden möchten.';

  @override
  String get jotReminderNotFound => 'Dieser Funke ist nicht mehr verfügbar.';

  @override
  String get widgetAddNoteTooltip => 'Erinnerung hinzuf?gen';

  @override
  String get widgetComposeTitle => 'Neue Erinnerung';

  @override
  String get widgetComposeDiscardTitle => 'Erinnerung verwerfen?';

  @override
  String get widgetComposeDiscardBody =>
      'Deine Erinnerung wird nicht gespeichert.';

  @override
  String get widgetComposeNoCategories =>
      'Keine Cluster gefunden.\n?ffne MindVault, um zuerst einen zu erstellen.';

  @override
  String get widgetComposeCategoryLabel => 'Cluster';

  @override
  String get noteTypeLabel => 'Typ';

  @override
  String get noteTypeText => 'Aufzeichnung';

  @override
  String get noteTypeChecklist => 'Plan';

  @override
  String get removeDoneTasksLabel => 'Erledigte Aufgaben entfernen';

  @override
  String get removeDoneTasksTitle => 'Erledigte Aufgaben entfernen?';

  @override
  String get removeDoneTasksBody =>
      'Abgeschlossene Aufgaben werden dauerhaft entfernt.';

  @override
  String get widgetViewEditTitle => 'Erinnerung bearbeiten';

  @override
  String get widgetViewEdit => 'Bearbeiten';

  @override
  String get widgetViewDelete => 'Löschen';

  @override
  String get widgetViewUnlocking => 'Wird entsperrt…';

  @override
  String get widgetViewNoContent => 'Kein Inhalt';

  @override
  String get widgetViewNotFound => 'Erinnerung nicht gefunden';

  @override
  String get widgetViewDiscardTitle => 'Änderungen verwerfen?';

  @override
  String get widgetViewDiscardBody =>
      'Deine Änderungen werden nicht gespeichert.';

  @override
  String get widgetViewKeepEditing => 'Weiter bearbeiten';

  @override
  String get editorSttRecord => 'Sprache aufnehmen';

  @override
  String get walkthroughSkip => 'Überspringen';

  @override
  String get walkthroughBack => 'Zurück';

  @override
  String get walkthroughNext => 'Weiter';

  @override
  String get walkthroughDone => 'Fertig';

  @override
  String get walkthroughAllowNotifications => 'Benachrichtigungen erlauben';

  @override
  String get walkthroughOpenBackgroundSettings => 'Einstellungen öffnen';

  @override
  String get walkthroughDoLater => 'Ich mache das später';

  @override
  String get walkthroughWelcomeTitle => 'Willkommen bei MindVault';

  @override
  String get walkthroughWelcomeBody =>
      'MindVault hilft dir, deine Erinnerungen und Gedanken griffbereit zu behalten. Für ein optimales Erlebnis erlaube Benachrichtigungen, damit Erinnerungen dich erreichen.';

  @override
  String get walkthroughBackgroundTitle => 'Erinnerungen zuverlässig halten';

  @override
  String get walkthroughBackgroundBody =>
      'Einige Android-Geräte pausieren Apps im Hintergrund. Wir können versuchen, die passenden Einstellungen zu öffnen; aktiviere dort MindVault und kehre dann hierher zurück.';

  @override
  String get walkthroughArchiveTitle => 'Archiv';

  @override
  String get walkthroughArchiveBody =>
      'Das Archiv ist deine Erinnerungsbibliothek. Schreibe und öffne Rezepte, To-dos, Ideen und alles, was du nicht verlieren möchtest.';

  @override
  String get walkthroughClustersTitle => 'Cluster';

  @override
  String get walkthroughClustersBody =>
      'Cluster halten Erinnerungen organisiert und farbcodiert, damit zusammengehörige Gedanken leicht zu überblicken sind.';

  @override
  String get walkthroughRecallTitle => 'Abruf';

  @override
  String get walkthroughRecallBody =>
      'Abruf durchsucht deine Erinnerungen per Stichwort oder mit KI. Frage zum Beispiel \"Wie viel Zucker brauche ich für meinen Kuchen?\" und MindVault gibt dir eine direkte Antwort, statt nur die Erinnerung zu finden.';

  @override
  String get walkthroughSparksTitle => 'Funken';

  @override
  String get walkthroughSparksBody =>
      'Funken sind schnelle Gedanken, die du noch nicht in Erinnerungen umwandeln möchtest. Halte Dinge fest wie \"diesen Film ansehen\", \"Jack mag Erdbeeren\" oder \"Beth ist die Tochter meiner Kollegin\". Entscheide später, was du tun möchtest, oder lass Spark AI Vorschläge machen.';

  @override
  String get walkthroughWidgetsTitle => 'MindVault-Widgets nutzen';

  @override
  String get walkthroughWidgetsBody =>
      'MindVault-Widgets sind leistungsstarke Werkzeuge, um schnell auf deine Erinnerungen zuzugreifen und unterwegs Gedanken zu erstellen. Drücke lange auf den Startbildschirm, wähle Widgets, suche nach MindVault und ziehe die Widgets auf deinen Startbildschirm.';

  @override
  String get settingsReplayWalkthrough => 'Einführung erneut ansehen';

  @override
  String get settingsReplayWalkthroughSubtitle =>
      'Die MindVault-Einführung noch einmal öffnen';

  @override
  String get memoryHelpTooltip => 'Hilfe zu Erinnerungen';

  @override
  String get memoryHelpDialogTitle => 'Funktionen der Erinnerung';

  @override
  String get memoryHelpTitleField => 'Titel';

  @override
  String get memoryHelpTitleFieldBody =>
      'Füge einen kurzen Titel hinzu, damit die Erinnerung leichter zu erkennen und wiederzufinden ist.';

  @override
  String get memoryHelpType => 'Typ';

  @override
  String memoryHelpTypeBody(Object recordType, Object planType) {
    return 'Wähle $recordType für freien Text oder $planType für eine Checkliste.';
  }

  @override
  String get memoryHelpCluster => 'Cluster';

  @override
  String get memoryHelpClusterBody =>
      'Verschiebe die Erinnerung in einen farbcodierten Cluster.';

  @override
  String get memoryHelpRecord => 'Aufnehmen';

  @override
  String get memoryHelpRecordBody =>
      'Nutze die Sprachaufnahme, um in den Titel oder Text zu diktieren.';

  @override
  String get memoryHelpCopy => 'Kopieren';

  @override
  String get memoryHelpCopyBody =>
      'Kopiere den Text der Erinnerung in die Zwischenablage.';

  @override
  String get memoryHelpReminder => 'Erinnerung';

  @override
  String get memoryHelpReminderBody =>
      'Lege einen Alarm für diese Erinnerung fest; Benachrichtigungen müssen erlaubt sein.';

  @override
  String get memoryHelpLock => 'Sperren';

  @override
  String get memoryHelpLockBody =>
      'Markiere eine Erinnerung als privat, damit zum Öffnen die Geräteauthentifizierung nötig ist.';
}
