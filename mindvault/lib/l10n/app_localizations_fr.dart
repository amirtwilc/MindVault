// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppStringsFr extends AppStrings {
  AppStringsFr([String locale = 'fr']) : super(locale);

  @override
  String get appBrand => 'MindVault';

  @override
  String get actionCancel => 'Annuler';

  @override
  String get actionSave => 'Enregistrer';

  @override
  String get actionDelete => 'Supprimer';

  @override
  String get actionCreate => 'Créer';

  @override
  String get actionRename => 'Renommer';

  @override
  String get actionApply => 'Appliquer';

  @override
  String get actionClose => 'Fermer';

  @override
  String get actionNotNow => 'Pas maintenant';

  @override
  String get actionDiscard => 'Ignorer';

  @override
  String get actionTryAgain => 'Réessayer';

  @override
  String get actionUnlock => 'Déverrouiller';

  @override
  String get actionRecoverContinue => 'Récupérer et continuer';

  @override
  String get actionSetupContinue => 'Configurer et continuer';

  @override
  String get actionStartFresh => 'Recommencer';

  @override
  String get actionContactUs => 'Nous contacter';

  @override
  String get actionOk => 'OK';

  @override
  String get splashTagline => 'Vos pensées, chiffrées en toute sécurité.';

  @override
  String get splashLoading => 'Sécurisation de votre coffre…';

  @override
  String get authSubtitle => 'Ne perdez plus jamais une pensée';

  @override
  String get authIntroBody =>
      'MindVault garantit que vos souvenirs sont sécurisés et toujours avec vous, même si vous changez d\'appareil. Pour cela, connectez-vous avec votre compte Google.';

  @override
  String get authEmailLabel => 'E-mail';

  @override
  String get authPasswordLabel => 'Mot de passe';

  @override
  String get authEmailRequired => 'L\'e-mail est requis.';

  @override
  String get authEmailInvalid => 'Saisissez une adresse e-mail valide.';

  @override
  String get authPasswordRequired => 'Le mot de passe est requis.';

  @override
  String get authPasswordTooShort =>
      'Le mot de passe doit contenir au moins 6 caractères.';

  @override
  String get authSignInEmail => 'Se connecter par e-mail';

  @override
  String get authCreateAccount => 'Créer un compte';

  @override
  String get authNeedAccount => 'Besoin d\'un compte ? Créez-en un';

  @override
  String get authHaveAccount => 'Déjà un compte ? Connectez-vous';

  @override
  String get authOr => 'ou';

  @override
  String get authCheckEmail =>
      'Consultez vos e-mails pour confirmer votre compte, puis connectez-vous.';

  @override
  String get authCheckEmailOtp =>
      'Nous vous avons envoyé un code de confirmation par e-mail. Saisissez-le ici pour terminer la création de votre compte.';

  @override
  String get authOtpResent => 'Un nouveau code de confirmation a été envoyé.';

  @override
  String get authRecoveryCodeSent =>
      'Nous vous avons envoyé un code de récupération par e-mail.';

  @override
  String get authRecoveryCodeResent =>
      'Un nouveau code de récupération a été envoyé.';

  @override
  String get authInvalidCredentials =>
      'L\'e-mail ou le mot de passe est incorrect.';

  @override
  String get authEmailAlreadyUsed =>
      'Un compte existe déjà pour cet e-mail. Essayez de vous connecter.';

  @override
  String get authWeakPassword =>
      'Choisissez un mot de passe plus fort, puis réessayez.';

  @override
  String get authEmailNotConfirmed =>
      'Veuillez confirmer votre e-mail avant de vous connecter.';

  @override
  String get authInvalidOtp =>
      'Ce code est invalide. Vérifiez-le puis réessayez.';

  @override
  String get authExpiredOtp =>
      'Ce code a expiré. Demandez-en un nouveau puis réessayez.';

  @override
  String get authRateLimited =>
      'Trop de tentatives. Patientez un instant, puis réessayez.';

  @override
  String get authNetworkError =>
      'Impossible de joindre le serveur de connexion. Vérifiez votre connexion, puis réessayez.';

  @override
  String get authGenericError => 'La connexion a échoué. Veuillez réessayer.';

  @override
  String get authForgotPassword => 'Mot de passe oublié ?';

  @override
  String get authForgotPasswordTitle => 'Réinitialiser votre mot de passe';

  @override
  String get authVerifyEmailTitle => 'Confirmez votre e-mail';

  @override
  String get authVerifyRecoveryTitle => 'Vérifiez votre code de récupération';

  @override
  String get authSetNewPasswordTitle => 'Choisissez un nouveau mot de passe';

  @override
  String get authVerifyEmailCode => 'Vérifier le code e-mail';

  @override
  String get authVerifyRecoveryCode => 'Vérifier le code de récupération';

  @override
  String get authOtpHelper =>
      'Saisissez le code reçu dans votre e-mail de confirmation.';

  @override
  String get authRecoveryOtpHelper =>
      'Saisissez le code reçu dans votre e-mail de récupération.';

  @override
  String get authOtpLabel => 'Code e-mail';

  @override
  String get authOtpRequired => 'Le code de vérification est requis.';

  @override
  String get authOtpInvalidFormat => 'Saisissez le code reçu par e-mail.';

  @override
  String get authResendCode => 'Renvoyer le code';

  @override
  String get authSendingCode => 'Envoi du code...';

  @override
  String get authVerifyingCode => 'Vérification du code...';

  @override
  String get authSendRecoveryCode => 'Envoyer le code de récupération';

  @override
  String get authBackToSignIn => 'Retour à la connexion';

  @override
  String get authSetNewPasswordBody =>
      'Saisissez un nouveau mot de passe pour votre compte.';

  @override
  String get authNewPasswordLabel => 'Nouveau mot de passe';

  @override
  String get authConfirmPasswordLabel => 'Confirmer le nouveau mot de passe';

  @override
  String get authConfirmPasswordRequired =>
      'Veuillez confirmer votre mot de passe.';

  @override
  String get authPasswordsDoNotMatch =>
      'Les mots de passe ne correspondent pas.';

  @override
  String get authUpdatingPassword => 'Mise à jour du mot de passe...';

  @override
  String get authUpdatePassword => 'Mettre à jour le mot de passe';

  @override
  String get authCancelRecovery => 'Annuler la récupération';

  @override
  String get authPasswordUpdated =>
      'Mot de passe mis à jour. Finalisation de la connexion...';

  @override
  String get authSignInGoogle => 'Se connecter avec Google';

  @override
  String get authSigningIn => 'Connexion en cours...';

  @override
  String get authDisclaimer =>
      'Vos souvenirs sont chiffrées de bout en bout.\nSeul vous pouvez les lire.';

  @override
  String get pinSetupAppBar => 'Configurer le chiffrement';

  @override
  String get pinRecoveryAppBar => 'Récupérer la clé de chiffrement';

  @override
  String get pinSetupHeading => 'Créer un code PIN de récupération';

  @override
  String get pinRecoveryHeading => 'Saisissez votre code PIN de récupération';

  @override
  String get pinSetupBody =>
      'Ce code PIN empêche que vos souvenirs soient lues par quelqu’un d’autre que vous. Vous en aurez besoin si vous vous connectez sur un nouvel appareil.';

  @override
  String get pinRecoveryBody =>
      'Vos souvenirs sont chiffrées. Saisissez votre code PIN de récupération pour les déverrouiller sur cet appareil.';

  @override
  String get pinLabel => 'Code PIN de récupération (4–8 chiffres)';

  @override
  String get pinConfirmLabel => 'Confirmer le PIN';

  @override
  String get pinSetupDisclaimer =>
      'Votre code PIN ne quitte jamais cet appareil. Votre clé chiffrée est stockée sur nos serveurs pour que vous puissiez la récupérer après une réinstallation, mais elle ne peut pas être lue sans le code PIN.';

  @override
  String get pinRecoveryDisclaimer =>
      'Votre code PIN ne quitte jamais cet appareil. Seule votre clé chiffrée est sur nos serveurs — elle ne peut pas être lue sans le PIN.';

  @override
  String get pinForgot => 'PIN oublié ? Recommencer';

  @override
  String get pinSignOut => 'Se déconnecter';

  @override
  String get pinTooShort => 'Le PIN doit comporter au moins 4 caractères.';

  @override
  String get pinMismatch => 'Les codes PIN ne correspondent pas.';

  @override
  String get pinRecoverError =>
      'PIN incorrect. Impossible de récupérer la clé de chiffrement.';

  @override
  String pinServerError(Object message) {
    return 'Erreur serveur : $message';
  }

  @override
  String get pinStartFreshTitle => 'Recommencer ?';

  @override
  String get pinStartFreshBody =>
      'Cela générera une nouvelle clé de chiffrement. Vos souvenirs existantes seront perdues.\n\nCette action est irréversible.';

  @override
  String get pinEntryAppBar => 'Saisir le code PIN de récupération';

  @override
  String get pinEntryHeading => 'Saisissez votre code PIN de récupération';

  @override
  String get pinEntryLabel => 'Code PIN de récupération';

  @override
  String get pinEntryNoKey =>
      'Aucune clé trouvée. Veuillez contacter le support.';

  @override
  String get pinEntryIncorrect => 'PIN incorrect. Veuillez réessayer.';

  @override
  String get pinSetupError =>
      'Échec de la configuration du chiffrement. Veuillez réessayer.';

  @override
  String pinLockedSeconds(int seconds) {
    return 'Trop de tentatives échouées. Réessayez dans ${seconds}s.';
  }

  @override
  String pinLockedMinutes(int minutes) {
    return 'Trop de tentatives échouées. Réessayez dans ${minutes}m.';
  }

  @override
  String get navAllNotes => 'Archives';

  @override
  String get navJots => 'Etincelles';

  @override
  String get navCategories => 'Groupes';

  @override
  String get navSearch => 'Reminiscence';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get homeNoCategoriesTitle =>
      'Aucune catégorie.\nAppuyez sur + pour en créer une.';

  @override
  String get newCategoryDialogTitle => 'Nouvelle catégorie';

  @override
  String get categoryNameHint => 'Nom de la catégorie';

  @override
  String get categoryColorLabel => 'Couleur';

  @override
  String get categoryNameInUse => 'Nom déjà utilisé';

  @override
  String categoryLimitReached(int max, Object upgradeHint) {
    return 'Limite de catégories atteinte ($max). $upgradeHint';
  }

  @override
  String noteLimitReached(int max, Object upgradeHint) {
    return 'Limite de souvenirs atteinte ($max). $upgradeHint';
  }

  @override
  String get upgradeHintFree => 'Passez à Pro pour plus.';

  @override
  String get upgradeHintNone => '';

  @override
  String get notesListTitleFallback => 'Souvenirs';

  @override
  String get notesListEmptyTitle => 'Aucune souvenir pour l\'instant';

  @override
  String get notesListEmptyBody =>
      'Appuyez sur + pour créer votre première souvenir';

  @override
  String get noteUntitled => '(sans titre)';

  @override
  String get noteDeletedSnack => 'Souvenir supprimée';

  @override
  String get deleteNoteTitle => 'Supprimer la souvenir ?';

  @override
  String get deleteNoteBody => 'Cette action est irréversible.';

  @override
  String get privateAuthReason =>
      'Authentifiez-vous pour voir cette souvenir privée';

  @override
  String get renameCategory => 'Renommer';

  @override
  String get changeCategoryColor => 'Changer la couleur';

  @override
  String get deleteCategoryAction => 'Supprimer la catégorie';

  @override
  String get renameCategoryDialog => 'Renommer la catégorie';

  @override
  String get categoryColorDialog => 'Couleur de la catégorie';

  @override
  String deleteCategoryConfirmTitle(Object name) {
    return 'Supprimer \"$name\" ?';
  }

  @override
  String get deleteCategoryConfirmBody =>
      'Archives de cette catégorie seront également supprimées.';

  @override
  String get allNotesEmptyTitle => 'Aucune souvenir pour l\'instant';

  @override
  String get allNotesEmptyBody =>
      'Créez une catégorie et ajoutez votre première souvenir';

  @override
  String get allNotesCreateFirst => 'Créez d\'abord une catégorie';

  @override
  String get editorNewTitle => 'Nouvelle souvenir';

  @override
  String get editorEditTitle => 'Modifier la souvenir';

  @override
  String get editorSaving => 'Enregistrement…';

  @override
  String editorSavedAt(Object time) {
    return 'Enregistré $time';
  }

  @override
  String get editorTitleHint => 'Titre';

  @override
  String get editorBodyHint => 'Commencez à écrire…';

  @override
  String get editorChangeCategory => 'Changer de catégorie';

  @override
  String get editorNewCategoryEntry => 'Nouvelle catégorie…';

  @override
  String get editorTooltipPublic => 'Publique';

  @override
  String get editorTooltipPrivate => 'Privée';

  @override
  String get editorTooltipDelete => 'Supprimer la souvenir';

  @override
  String get editorTooltipEdit => 'Modifier la souvenir';

  @override
  String get editorTooltipCopy => 'Copier la souvenir';

  @override
  String get reminderTooltipSet => 'Définir un rappel';

  @override
  String get reminderTooltipActive => 'Rappel défini';

  @override
  String get reminderDialogTitle => 'Rappel';

  @override
  String reminderScheduledFor(Object time) {
    return 'Planifié pour $time';
  }

  @override
  String get reminderEdit => 'Modifier';

  @override
  String get reminderRemove => 'Supprimer';

  @override
  String get reminderSaveNoteFirst =>
      'Ajoutez un titre ou du trace à la souvenir avant de définir un rappel.';

  @override
  String get reminderNotificationsRequired =>
      'L’autorisation des notifications doit être accordée pour les rappels.';

  @override
  String get reminderMayBeDelayed =>
      'Les alarmes exactes ne sont pas activées. Ce rappel peut être retardé.';

  @override
  String get reminderBackgroundPermissionTitle =>
      'Autoriser les rappels en arrière-plan';

  @override
  String get reminderBackgroundPermissionBody =>
      'Certains appareils exigent que MindVault soit autorisé à fonctionner en arrière-plan ou au démarrage automatique afin que les rappels précis se déclenchent quand l’application est fermée. Si une page de paramètres s’ouvre, active MindVault puis reviens dans l’application.';

  @override
  String get reminderBackgroundPermissionOpenSettings =>
      'Ouvrir les paramètres';

  @override
  String get reminderMustBeFuture =>
      'Choisissez une date et une heure futures.';

  @override
  String get reminderNoteNotFound =>
      'Cette souvenir de rappel est introuvable.';

  @override
  String get reminderNotificationBody => 'Touchez pour ouvrir cette souvenir';

  @override
  String get editorCopyMenuItem => 'Copier la souvenir';

  @override
  String get editorCopiedSnack => 'Souvenir copiée';

  @override
  String get editorSttStop => 'Arrêter l\'enregistrement';

  @override
  String get searchHint => 'Rechercher des souvenirs…';

  @override
  String get searchIdleTitle => 'Recherchez dans vos souvenirs';

  @override
  String get searchIdleBody =>
      'Tapez des mots-clés ou posez une question. \nLes souvenirs privées sont ignorées.';

  @override
  String searchNoResults(Object query) {
    return 'Aucun résultat pour \"$query\"';
  }

  @override
  String get searchTryDifferent => 'Essayez d\'autres mots-clés';

  @override
  String searchMoreLines(int count) {
    return '+$count lignes supplémentaires';
  }

  @override
  String get searchTryAiHint =>
      'Pas ce que vous cherchiez ? Essayez la r?miniscence IA';

  @override
  String get searchNoResultsAiCta =>
      'Aucun résultat. Cliquez pour effectuer une r?miniscence IA';

  @override
  String get searchHistoryButtonTooltip => 'Historique de r?miniscence IA';

  @override
  String get searchBackToResults => 'Retour aux résultats';

  @override
  String get widgetSearchTitle => 'Recherchez dans vos souvenirs';

  @override
  String get aiSearchTitle => 'Reminiscence IA';

  @override
  String get aiSearchHint => 'Posez une question sur vos souvenirs…';

  @override
  String get aiSearchLoading => 'Recherche dans vos souvenirs…';

  @override
  String get aiSearchIdleTitle =>
      'Posez n\'importe quelle question sur vos souvenirs';

  @override
  String get aiSearchIdleBody =>
      'L\'IA recherche dans vos souvenirs et synthétise une réponse';

  @override
  String get aiSearchSuggestion1 => 'Résumé de mes souvenirs d\'entraînement';

  @override
  String get aiSearchSuggestion2 => 'Qu\'ai-je écrit sur le travail ?';

  @override
  String get aiSearchSuggestion3 => 'Trouver des souvenirs sur mes objectifs';

  @override
  String get aiSearchSuggestion4 => 'Quels sont mes plans de voyage ?';

  @override
  String get aiSearchSources => 'Sources';

  @override
  String get aiSearchFromCache => 'Depuis le cache';

  @override
  String get aiSearchRateTitle => 'Limite atteinte';

  @override
  String aiSearchRateSeconds(int seconds) {
    return 'Réessayez dans ${seconds}s';
  }

  @override
  String aiSearchRateMinutes(int minutes) {
    return 'Réessayez dans ${minutes}m';
  }

  @override
  String aiSearchRateResetsAt(Object time) {
    return 'Réinitialisation à $time';
  }

  @override
  String get aiSearchRateDefault =>
      'Veuillez patienter avant de relancer une recherche';

  @override
  String get aiSearchErrorDailyLimit =>
      'Limite quotidienne d\'IA atteinte. Réessayez demain.';

  @override
  String get aiSearchErrorSessionExpired =>
      'Session expirée. Veuillez vous reconnecter.';

  @override
  String get aiSearchErrorUnavailable =>
      'L\'IA n\'est pas disponible pour le moment.';

  @override
  String get aiSearchErrorNetwork =>
      'Aucune connexion. Vérifiez votre connexion internet et réessayez.';

  @override
  String get aiSearchErrorGeneric =>
      'La requête IA a échoué. Veuillez réessayer.';

  @override
  String get aiInfoTitle => 'À propos de la r?miniscence IA';

  @override
  String get aiInfoBody =>
      'La r?miniscence IA lit vos souvenirs pour répondre à votre question.\n\n🔒 Les souvenirs privées ne sont jamais envoyées à l\'IA.\n\n📄 Les souvenirs très longues sont raccourcies avant l\'envoi.';

  @override
  String get aiInfoDismiss => 'Compris';

  @override
  String get aiAnswerCopied => 'Copié dans le presse-papiers';

  @override
  String get aiHistoryTitle => 'Historique de r?miniscence IA';

  @override
  String get aiHistoryEmpty => 'Aucun historique de recherche pour l\'instant';

  @override
  String get aiHistoryRelativeNow => 'À l\'instant';

  @override
  String aiHistoryRelativeMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count minutes',
      one: 'il y a 1 minute',
    );
    return '$_temp0';
  }

  @override
  String aiHistoryRelativeHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count heures',
      one: 'il y a 1 heure',
    );
    return '$_temp0';
  }

  @override
  String aiHistoryRelativeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count jours',
      one: 'il y a 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsSectionAccount => 'Compte';

  @override
  String get settingsSectionUsage => 'Utilisation';

  @override
  String get settingsSectionUpgrade => 'Mettre à niveau';

  @override
  String get settingsSectionApp => 'App';

  @override
  String get settingsSectionLanguage => 'Langue';

  @override
  String get settingsUnknownUser => 'Inconnu';

  @override
  String get settingsTierFree => 'Gratuit';

  @override
  String get settingsTierPro => 'Pro';

  @override
  String get settingsUsageAi => 'Recherches IA aujourd\'hui';

  @override
  String get settingsUsageJotsAi => 'Organisations Etincelles IA aujourd hui';

  @override
  String get settingsUsageNotes => 'Souvenirs';

  @override
  String get settingsUsageCategories => 'Groupes';

  @override
  String get settingsUpgradeTitle => 'Passer à Pro';

  @override
  String get settingsUpgradeSubtitle =>
      '30 recherches IA/jour · 1000 souvenirs · 50 catégories';

  @override
  String get settingsUpgradeDialogBody =>
      'Pro vous offre 30 recherches IA/jour, jusqu\'à 1000 souvenirs, 50 catégories et 20 000 caractères par souvenir.\n\nbientôt disponible';

  @override
  String get contactUsMessageHint => 'Votre message (facultatif)…';

  @override
  String get contactUsNoEmailApp =>
      'Aucune application de messagerie trouvée. Veuillez nous écrire à :';

  @override
  String get contactUsCopied => 'Adresse e-mail copiée';

  @override
  String get settingsSignOut => 'Se déconnecter';

  @override
  String get settingsLanguageDeviceDefault => 'Langue du système';

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
  String get jotsAddTooltip => 'Ajouter une etincelle';

  @override
  String get jotAddDialogTitle => 'Nouvelle etincelle';

  @override
  String get jotInputHint => 'Capturez une pensée rapide';

  @override
  String get jotSavedSnack => 'Pensée enregistrée';

  @override
  String get jotSaveUnavailable =>
      'La pensée n\'a pas pu être enregistrée. Réessayez.';

  @override
  String jotCharCounter(int count, int max) {
    return '$count/$max caractères';
  }

  @override
  String get jotsEmptyTitle => 'Aucune etincelle en attente';

  @override
  String get jotsEmptyBody =>
      'Appuyez sur + pour créer votre première souvenir';

  @override
  String get jotsSortOldestFirst => 'Plus anciens d’abord';

  @override
  String get jotsSortNewestFirst => 'Plus récents d’abord';

  @override
  String get jotsOrganizeAi => 'Organiser avec l’IA';

  @override
  String get jotsAcceptAll => 'Accepter toutes les suggestions';

  @override
  String get jotsAiInfoTitle => 'A propos d Etincelles IA';

  @override
  String get jotsAiInfoBody =>
      '?tincelles IA suggère comment organiser les pensées non traitées. Seuls les ?tincelles non envoyés, les noms de catégories et les titres de souvenirs sont envoyés. Le contenu des souvenirs et les souvenirs privées ne sont pas envoyés, et les longues plans peuvent être limitées.';

  @override
  String get jotsAiNoNew => 'Aucune nouvelle pensée à organiser.';

  @override
  String get jotsAiQuota => 'Limite quotidienne d Etincelles IA atteinte.';

  @override
  String get jotsAiFailed => 'Impossible d organiser les etincelles.';

  @override
  String jotsAiSuggestionsProvided(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count suggestions fournies.',
      one: '1 suggestion fournie.',
      zero:
          '0 suggestion fournie. Essayez d’écrire des pensées plus précises la prochaine fois.',
    );
    return '$_temp0';
  }

  @override
  String get jotsAiLimitedTo30 =>
      'Seuls les 30 nouveaux ?tincelles les plus anciens ont été envoyés.';

  @override
  String jotsSelectedCount(int count) {
    return '$count sélectionné(s)';
  }

  @override
  String get jotsDeleteSelectedTitle =>
      'Supprimer les ?tincelles sélectionnés ?';

  @override
  String get jotsDeleteSelectedBody =>
      'Les pensées sélectionnées seront supprimées définitivement.';

  @override
  String jotCreatedAt(Object time) {
    return 'Créé : $time';
  }

  @override
  String get jotActionsTooltip => 'Traiter le ?tincelle';

  @override
  String get jotActionsTitle => 'Traiter la pensée';

  @override
  String get jotActionCreateNote => 'Créer une nouvelle souvenir';

  @override
  String get jotActionAddToNote => 'Ajouter à une souvenir existante';

  @override
  String get jotActionCreateAlert => 'Créer une alerte';

  @override
  String get jotActionDeleteThought => 'Supprimer la pensée';

  @override
  String get jotActionSuggestedByAi =>
      'Ces actions ont été suggérées par l’IA.';

  @override
  String get jotActionUpdateThought => 'Mettre à jour le trace de la pensée';

  @override
  String get jotActionUpdatedThoughtText => 'Pensée mise à jour';

  @override
  String get jotActionUpdatedThoughtHint => 'Exemple : Le Seigneur des anneaux';

  @override
  String get jotActionNewNoteTitle => 'Titre de la souvenir';

  @override
  String get jotActionCategory => 'Catégorie';

  @override
  String get jotActionNewCategory => 'Nouvelle catégorie';

  @override
  String get jotActionNote => 'Souvenir';

  @override
  String get jotActionNoNotes => 'Aucune souvenir dans cette catégorie';

  @override
  String get jotActionLock => 'Verrouiller la souvenir';

  @override
  String jotActionReminderWhen(Object time) {
    return 'Alerte à $time';
  }

  @override
  String get jotActionPickReminder => 'Choisir la date et l’heure';

  @override
  String get jotActionAccept => 'Accepter';

  @override
  String get jotActionChooseFuture =>
      'Choisissez une date et une heure futures.';

  @override
  String get jotNotificationBody => 'Touchez pour organiser cette pensée';

  @override
  String get jotDailyDigestTitle => 'Étincelles MindVault';

  @override
  String get jotDailyDigestBody =>
      'Vous avez des pensées qui attendent d\'être organisées.';

  @override
  String get jotReminderNotFound => 'Ce ?tincelle n’est plus disponible.';

  @override
  String get widgetAddNoteTooltip => 'Ajouter un souvenir';

  @override
  String get widgetComposeTitle => 'Nouveau souvenir';

  @override
  String get widgetComposeDiscardTitle => 'Ignorer le souvenir ?';

  @override
  String get widgetComposeDiscardBody =>
      'Votre souvenir ne sera pas enregistr?.';

  @override
  String get widgetComposeNoCategories =>
      'Aucun groupe trouv?.\nOuvrez MindVault pour en cr?er un d?abord.';

  @override
  String get widgetComposeCategoryLabel => 'Groupe';

  @override
  String get noteTypeLabel => 'Type';

  @override
  String get noteTypeText => 'Trace';

  @override
  String get noteTypeChecklist => 'Plan';

  @override
  String get removeDoneTasksLabel => 'Supprimer les tâches terminées';

  @override
  String get removeDoneTasksTitle => 'Supprimer les tâches terminées ?';

  @override
  String get removeDoneTasksBody =>
      'Les tâches terminées seront supprimées définitivement.';

  @override
  String get widgetViewEditTitle => 'Modifier le souvenir';

  @override
  String get widgetViewEdit => 'Modifier';

  @override
  String get widgetViewDelete => 'Supprimer';

  @override
  String get widgetViewUnlocking => 'Déverrouillage…';

  @override
  String get widgetViewNoContent => 'Aucun contenu';

  @override
  String get widgetViewNotFound => 'Souvenir introuvable';

  @override
  String get widgetViewDiscardTitle => 'Ignorer les modifications ?';

  @override
  String get widgetViewDiscardBody =>
      'Vos modifications ne seront pas enregistrées.';

  @override
  String get widgetViewKeepEditing => 'Continuer à modifier';

  @override
  String get editorSttRecord => 'Enregistrer la voix';

  @override
  String get walkthroughSkip => 'Ignorer';

  @override
  String get walkthroughBack => 'Retour';

  @override
  String get walkthroughNext => 'Suivant';

  @override
  String get walkthroughDone => 'Terminé';

  @override
  String get walkthroughAllowNotifications => 'Autoriser les notifications';

  @override
  String get walkthroughOpenBackgroundSettings => 'Ouvrir les paramètres';

  @override
  String get walkthroughDoLater => 'Je le ferai plus tard';

  @override
  String get walkthroughWelcomeTitle => 'Bienvenue dans MindVault';

  @override
  String get walkthroughWelcomeBody =>
      'MindVault vous aide à garder vos souvenirs et pensées à portée de main. Pour une expérience optimale, autorisez les notifications afin que les rappels puissent vous parvenir.';

  @override
  String get walkthroughBackgroundTitle => 'Rendre les rappels fiables';

  @override
  String get walkthroughBackgroundBody =>
      'Certains appareils Android mettent les apps en pause en arrière-plan. Nous pouvons essayer d\'ouvrir les bons paramètres; activez MindVault, puis revenez ici.';

  @override
  String get walkthroughArchiveTitle => 'Archives';

  @override
  String get walkthroughArchiveBody =>
      'Les archives sont votre bibliothèque de souvenirs. Notez et retrouvez recettes, tâches, idées et tout ce que vous ne voulez pas perdre.';

  @override
  String get walkthroughClustersTitle => 'Groupes';

  @override
  String get walkthroughClustersBody =>
      'Les groupes gardent vos souvenirs organisés et codés par couleur, afin que les pensées liées restent faciles à parcourir.';

  @override
  String get walkthroughRecallTitle => 'Réminiscence';

  @override
  String get walkthroughRecallBody =>
      'Réminiscence recherche vos souvenirs par mots-clés ou avec l\'IA. Demandez par exemple \"Combien de sucre me faut-il pour mon gâteau ?\" et MindVault fournira une réponse directe, pas seulement le souvenir.';

  @override
  String get walkthroughSparksTitle => 'Étincelles';

  @override
  String get walkthroughSparksBody =>
      'Les étincelles sont des pensées rapides que vous ne voulez pas encore transformer en souvenirs. Capturez des choses comme \"regarder ce film\", \"Jack aime les fraises\" ou \"Beth est la fille de ma collègue\". Décidez plus tard quoi en faire ou laissez Spark AI vous suggérer.';

  @override
  String get walkthroughWidgetsTitle => 'Utiliser les widgets MindVault';

  @override
  String get walkthroughWidgetsBody =>
      'Les widgets MindVault sont des outils puissants pour accéder rapidement à votre mémoire et créer des pensées à la volée. Appuyez longuement sur l\'écran d\'accueil, choisissez Widgets, cherchez MindVault et faites glisser les widgets vers votre écran d\'accueil.';

  @override
  String get settingsReplayWalkthrough => 'Revoir la présentation';

  @override
  String get settingsReplayWalkthroughSubtitle =>
      'Relancer la présentation de MindVault';

  @override
  String get memoryHelpTooltip => 'Aide mémoire';

  @override
  String get memoryHelpDialogTitle => 'Fonctions de la mémoire';

  @override
  String get memoryHelpTitleField => 'Titre';

  @override
  String get memoryHelpTitleFieldBody =>
      'Ajoutez un titre court pour rendre la mémoire plus facile à reconnaître et à retrouver.';

  @override
  String get memoryHelpType => 'Type';

  @override
  String memoryHelpTypeBody(Object recordType, Object planType) {
    return 'Choisissez $recordType pour du texte libre ou $planType pour une liste de tâches.';
  }

  @override
  String get memoryHelpCluster => 'Cluster';

  @override
  String get memoryHelpClusterBody =>
      'Déplacez la mémoire dans un cluster codé par couleur.';

  @override
  String get memoryHelpRecord => 'Enregistrer';

  @override
  String get memoryHelpRecordBody =>
      'Utilisez l\'enregistrement vocal pour dicter dans le titre ou le corps.';

  @override
  String get memoryHelpCopy => 'Copier';

  @override
  String get memoryHelpCopyBody =>
      'Copiez le corps de la mémoire dans le presse-papiers.';

  @override
  String get memoryHelpReminder => 'Rappel';

  @override
  String get memoryHelpReminderBody =>
      'Définissez une alerte pour cette mémoire; les notifications doivent être autorisées.';

  @override
  String get memoryHelpLock => 'Verrouiller';

  @override
  String get memoryHelpLockBody =>
      'Marquez une mémoire comme privée afin que son ouverture exige l\'authentification de l\'appareil.';
}
