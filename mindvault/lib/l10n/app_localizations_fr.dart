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
  String get authSubtitle => 'Vos notes chiffrées propulsées par l\'IA';

  @override
  String get authSignInGoogle => 'Se connecter avec Google';

  @override
  String get authSigningIn => 'Connexion en cours...';

  @override
  String get authDisclaimer =>
      'Vos notes sont chiffrées de bout en bout.\nSeul vous pouvez les lire.';

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
      'Ce code PIN protège votre clé de chiffrement. Vous en aurez besoin si vous vous connectez sur un nouvel appareil.';

  @override
  String get pinRecoveryBody =>
      'Vos notes sont chiffrées. Saisissez votre code PIN de récupération pour les déverrouiller sur cet appareil.';

  @override
  String get pinLabel => 'Code PIN de récupération (4–8 chiffres)';

  @override
  String get pinConfirmLabel => 'Confirmer le PIN';

  @override
  String get pinSetupDisclaimer =>
      'Votre code PIN ne quitte jamais cet appareil. Votre clé chiffrée est stockée sur nos serveurs pour que vous puissiez la récupérer après une réinstallation.';

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
      'Cela générera une nouvelle clé de chiffrement. Vos notes existantes seront perdues.\n\nCette action est irréversible.';

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
  String get navAllNotes => 'Toutes les notes';

  @override
  String get navCategories => 'Catégories';

  @override
  String get navSearch => 'Rechercher';

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
    return 'Limite de notes atteinte ($max). $upgradeHint';
  }

  @override
  String get upgradeHintFree => 'Passez à Pro pour plus.';

  @override
  String get upgradeHintNone => '';

  @override
  String get notesListTitleFallback => 'Notes';

  @override
  String get notesListEmptyTitle => 'Aucune note pour l\'instant';

  @override
  String get notesListEmptyBody =>
      'Appuyez sur + pour créer votre première note';

  @override
  String get noteUntitled => '(sans titre)';

  @override
  String get noteDeletedSnack => 'Note supprimée';

  @override
  String get deleteNoteTitle => 'Supprimer la note ?';

  @override
  String get deleteNoteBody => 'Cette action est irréversible.';

  @override
  String get privateAuthReason =>
      'Authentifiez-vous pour voir cette note privée';

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
      'Toutes les notes de cette catégorie seront également supprimées.';

  @override
  String get allNotesEmptyTitle => 'Aucune note pour l\'instant';

  @override
  String get allNotesEmptyBody =>
      'Créez une catégorie et ajoutez votre première note';

  @override
  String get allNotesCreateFirst => 'Créez d\'abord une catégorie';

  @override
  String get editorNewTitle => 'Nouvelle note';

  @override
  String get editorEditTitle => 'Modifier la note';

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
  String get editorTooltipDelete => 'Supprimer la note';

  @override
  String get editorTooltipEdit => 'Modifier la note';

  @override
  String get editorTooltipCopy => 'Copier la note';

  @override
  String get editorCopyMenuItem => 'Copier la note';

  @override
  String get editorCopiedSnack => 'Note copiée';

  @override
  String get editorSttRecord => 'Enregistrer la voix';

  @override
  String get editorSttStop => 'Arrêter l\'enregistrement';

  @override
  String get searchHint => 'Rechercher dans les notes…';

  @override
  String get searchIdleTitle => 'Recherchez dans vos notes';

  @override
  String get searchIdleBody =>
      'Tapez des mots-clés ou posez une question. \nLes notes privées sont ignorées.';

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
      'Pas ce que vous cherchiez ? Essayez la recherche IA';

  @override
  String get searchNoResultsAiCta =>
      'Aucun résultat. Cliquez pour effectuer une recherche IA';

  @override
  String get searchHistoryButtonTooltip => 'Historique de recherche IA';

  @override
  String get searchBackToResults => 'Retour aux résultats';

  @override
  String get widgetSearchTitle => 'Recherchez dans vos notes';

  @override
  String get aiSearchTitle => 'Recherche IA';

  @override
  String get aiSearchHint => 'Posez une question sur vos notes…';

  @override
  String get aiSearchLoading => 'Recherche dans vos notes…';

  @override
  String get aiSearchIdleTitle =>
      'Posez n\'importe quelle question sur vos notes';

  @override
  String get aiSearchIdleBody =>
      'L\'IA recherche dans vos notes et synthétise une réponse';

  @override
  String get aiSearchSuggestion1 => 'Résumé de mes notes d\'entraînement';

  @override
  String get aiSearchSuggestion2 => 'Qu\'ai-je écrit sur le travail ?';

  @override
  String get aiSearchSuggestion3 => 'Trouver des notes sur mes objectifs';

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
  String get aiHistoryTitle => 'Historique de recherche IA';

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
  String get settingsUsageNotes => 'Notes';

  @override
  String get settingsUsageCategories => 'Catégories';

  @override
  String get settingsUpgradeTitle => 'Passer à Pro';

  @override
  String get settingsUpgradeSubtitle =>
      '50 recherches IA/jour · 1000 notes · 50 catégories';

  @override
  String get settingsUpgradeDialogBody =>
      'Pro vous offre 50 recherches IA/jour, jusqu\'à 1000 notes, 50 catégories et 20 000 caractères par note.';

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
  String get widgetComposeTitle => 'Nouvelle note';

  @override
  String get widgetComposeDiscardTitle => 'Ignorer la note ?';

  @override
  String get widgetComposeDiscardBody => 'Votre note ne sera pas enregistrée.';

  @override
  String get widgetComposeNoCategories =>
      'Aucune catégorie trouvée.\nOuvrez MindVault pour en créer une d\'abord.';

  @override
  String get widgetComposeCategoryLabel => 'Catégorie';

  @override
  String get widgetViewEditTitle => 'Modifier la note';

  @override
  String get widgetViewEdit => 'Modifier';

  @override
  String get widgetViewDelete => 'Supprimer';

  @override
  String get widgetViewUnlocking => 'Déverrouillage…';

  @override
  String get widgetViewNoContent => 'Aucun contenu';

  @override
  String get widgetViewNotFound => 'Note introuvable';

  @override
  String get widgetViewDiscardTitle => 'Ignorer les modifications ?';

  @override
  String get widgetViewDiscardBody =>
      'Vos modifications ne seront pas enregistrées.';

  @override
  String get widgetViewKeepEditing => 'Continuer à modifier';
}
