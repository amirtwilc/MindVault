// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppStringsHe extends AppStrings {
  AppStringsHe([String locale = 'he']) : super(locale);

  @override
  String get appBrand => 'MindVault';

  @override
  String get actionCancel => 'ביטול';

  @override
  String get actionSave => 'שמירה';

  @override
  String get actionDelete => 'מחיקה';

  @override
  String get actionCreate => 'יצירה';

  @override
  String get actionRename => 'שינוי שם';

  @override
  String get actionApply => 'החל';

  @override
  String get actionClose => 'סגירה';

  @override
  String get actionDiscard => 'התעלם';

  @override
  String get actionTryAgain => 'נסה שוב';

  @override
  String get actionUnlock => 'פתח';

  @override
  String get actionRecoverContinue => 'שחזר והמשך';

  @override
  String get actionSetupContinue => 'הגדר והמשך';

  @override
  String get actionStartFresh => 'התחל מחדש';

  @override
  String get actionContactUs => 'צור קשר';

  @override
  String get actionOk => 'אישור';

  @override
  String get splashTagline => 'המחשבות שלך, מוצפנות בבטחה.';

  @override
  String get splashLoading => 'מאבטח את הכספת שלך…';

  @override
  String get authSubtitle => 'פתקים מוצפנים מבוססי בינה מלאכותית';

  @override
  String get authEmailLabel => 'אימייל';

  @override
  String get authPasswordLabel => 'סיסמה';

  @override
  String get authEmailRequired => 'נדרש אימייל.';

  @override
  String get authEmailInvalid => 'הזן כתובת אימייל תקינה.';

  @override
  String get authPasswordRequired => 'נדרשת סיסמה.';

  @override
  String get authPasswordTooShort => 'הסיסמה חייבת להכיל לפחות 6 תווים.';

  @override
  String get authSignInEmail => 'התחבר עם אימייל';

  @override
  String get authCreateAccount => 'צור חשבון';

  @override
  String get authNeedAccount => 'צריך חשבון? צור אחד';

  @override
  String get authHaveAccount => 'כבר יש לך חשבון? התחבר';

  @override
  String get authOr => 'או';

  @override
  String get authCheckEmail => 'בדוק את האימייל כדי לאשר את החשבון, ואז התחבר.';

  @override
  String get authCheckEmailOtp =>
      'שלחנו אליך קוד אישור באימייל. הזן אותו כאן כדי להשלים את יצירת החשבון.';

  @override
  String get authOtpResent => 'קוד אישור חדש נשלח.';

  @override
  String get authRecoveryCodeSent => 'שלחנו אליך קוד שחזור באימייל.';

  @override
  String get authRecoveryCodeResent => 'קוד שחזור חדש נשלח.';

  @override
  String get authInvalidCredentials => 'האימייל או הסיסמה שגויים.';

  @override
  String get authEmailAlreadyUsed =>
      'כבר קיים חשבון עם האימייל הזה. נסה להתחבר.';

  @override
  String get authWeakPassword => 'בחר סיסמה חזקה יותר ונסה שוב.';

  @override
  String get authEmailNotConfirmed => 'יש לאשר את האימייל לפני ההתחברות.';

  @override
  String get authInvalidOtp => 'הקוד הזה לא תקין. בדוק אותו ונסה שוב.';

  @override
  String get authExpiredOtp => 'הקוד הזה פג תוקף. בקש קוד חדש ונסה שוב.';

  @override
  String get authRateLimited => 'יותר מדי ניסיונות. המתן רגע ונסה שוב.';

  @override
  String get authNetworkError =>
      'לא ניתן להתחבר לשרת ההתחברות. בדוק את החיבור ונסה שוב.';

  @override
  String get authGenericError => 'ההתחברות נכשלה. נסה שוב.';

  @override
  String get authForgotPassword => 'שכחת סיסמה?';

  @override
  String get authForgotPasswordTitle => 'איפוס סיסמה';

  @override
  String get authVerifyEmailTitle => 'אימות האימייל';

  @override
  String get authVerifyRecoveryTitle => 'אימות קוד השחזור';

  @override
  String get authSetNewPasswordTitle => 'בחירת סיסמה חדשה';

  @override
  String get authVerifyEmailCode => 'אמת קוד אימייל';

  @override
  String get authVerifyRecoveryCode => 'אמת קוד שחזור';

  @override
  String get authOtpHelper => 'הזן את הקוד מהאימייל לאישור.';

  @override
  String get authRecoveryOtpHelper => 'הזן את הקוד מהאימייל לשחזור.';

  @override
  String get authOtpLabel => 'קוד אימייל';

  @override
  String get authOtpRequired => 'נדרש קוד אימות.';

  @override
  String get authOtpInvalidFormat => 'הזן את הקוד מהאימייל.';

  @override
  String get authResendCode => 'שלח קוד מחדש';

  @override
  String get authSendingCode => 'שולח קוד...';

  @override
  String get authVerifyingCode => 'מאמת קוד...';

  @override
  String get authSendRecoveryCode => 'שלח קוד שחזור';

  @override
  String get authBackToSignIn => 'חזרה להתחברות';

  @override
  String get authSetNewPasswordBody => 'הזן סיסמה חדשה לחשבון שלך.';

  @override
  String get authNewPasswordLabel => 'סיסמה חדשה';

  @override
  String get authConfirmPasswordLabel => 'אימות סיסמה חדשה';

  @override
  String get authConfirmPasswordRequired => 'נא לאשר את הסיסמה.';

  @override
  String get authPasswordsDoNotMatch => 'הסיסמאות אינן תואמות.';

  @override
  String get authUpdatingPassword => 'מעדכן סיסמה...';

  @override
  String get authUpdatePassword => 'עדכן סיסמה';

  @override
  String get authCancelRecovery => 'בטל שחזור';

  @override
  String get authPasswordUpdated => 'הסיסמה עודכנה. משלים את ההתחברות...';

  @override
  String get authSignInGoogle => 'התחבר עם Google';

  @override
  String get authSigningIn => 'מתחבר...';

  @override
  String get authDisclaimer =>
      'הפתקים שלך מוצפנים מקצה לקצה.\nרק אתה יכול לקרוא אותם.';

  @override
  String get pinSetupAppBar => 'הגדרת הצפנה';

  @override
  String get pinRecoveryAppBar => 'שחזור מפתח הצפנה';

  @override
  String get pinSetupHeading => 'צור קוד שחזור';

  @override
  String get pinRecoveryHeading => 'הזן את קוד השחזור שלך';

  @override
  String get pinSetupBody =>
      'הקוד הזה מגן על ההערות שלך כך שאף אחד מלבדך לא יוכל לקרוא אותן. תזדקק לו אם תתחבר ממכשיר חדש.';

  @override
  String get pinRecoveryBody =>
      'הפתקים שלך מוצפנים. הזן את קוד השחזור כדי לפתוח אותם במכשיר זה.';

  @override
  String get pinLabel => 'קוד שחזור (4–8 ספרות)';

  @override
  String get pinConfirmLabel => 'אימות קוד';

  @override
  String get pinSetupDisclaimer =>
      'הקוד שלך לעולם לא יוצא מהמכשיר. המפתח המוצפן שלך מאוחסן בשרתים שלנו כדי שתוכל לשחזר אותו לאחר התקנה מחדש, אבל אי אפשר לקרוא אותו בלי הקוד.';

  @override
  String get pinRecoveryDisclaimer =>
      'הקוד שלך לעולם לא יוצא מהמכשיר. רק המפתח המוצפן מאוחסן בשרתים שלנו — לא ניתן לקרוא אותו ללא הקוד.';

  @override
  String get pinForgot => 'שכחת את הקוד? התחל מחדש';

  @override
  String get pinSignOut => 'התנתק';

  @override
  String get pinTooShort => 'הקוד חייב להיות לפחות 4 תווים.';

  @override
  String get pinMismatch => 'הקודים אינם תואמים.';

  @override
  String get pinRecoverError => 'קוד שגוי. לא ניתן לשחזר את מפתח ההצפנה.';

  @override
  String pinServerError(Object message) {
    return 'שגיאת שרת: $message';
  }

  @override
  String get pinStartFreshTitle => 'להתחיל מחדש?';

  @override
  String get pinStartFreshBody =>
      'פעולה זו תיצור מפתח הצפנה חדש. הפתקים הקיימים שלך יאבדו.\n\nלא ניתן לבטל פעולה זו.';

  @override
  String get pinEntryAppBar => 'הזן קוד שחזור';

  @override
  String get pinEntryHeading => 'הזן את קוד השחזור שלך';

  @override
  String get pinEntryLabel => 'קוד שחזור';

  @override
  String get pinEntryNoKey => 'לא נמצא מפתח. אנא פנה לתמיכה.';

  @override
  String get pinEntryIncorrect => 'קוד שגוי. אנא נסה שוב.';

  @override
  String get pinSetupError => 'הגדרת ההצפנה נכשלה. אנא נסה שוב.';

  @override
  String pinLockedSeconds(int seconds) {
    return 'יותר מדי ניסיונות כושלים. נסה שוב בעוד $secondsש\'.';
  }

  @override
  String pinLockedMinutes(int minutes) {
    return 'יותר מדי ניסיונות כושלים. נסה שוב בעוד $minutesד\'.';
  }

  @override
  String get navAllNotes => 'כל הפתקים';

  @override
  String get navCategories => 'קטגוריות';

  @override
  String get navSearch => 'חיפוש';

  @override
  String get navSettings => 'הגדרות';

  @override
  String get homeNoCategoriesTitle => 'אין עדיין קטגוריות.\nהקש + ליצירה.';

  @override
  String get newCategoryDialogTitle => 'קטגוריה חדשה';

  @override
  String get categoryNameHint => 'שם הקטגוריה';

  @override
  String get categoryColorLabel => 'צבע';

  @override
  String get categoryNameInUse => 'השם כבר בשימוש';

  @override
  String categoryLimitReached(int max, Object upgradeHint) {
    return 'הגעת למגבלת הקטגוריות ($max). $upgradeHint';
  }

  @override
  String noteLimitReached(int max, Object upgradeHint) {
    return 'הגעת למגבלת הפתקים ($max). $upgradeHint';
  }

  @override
  String get upgradeHintFree => 'שדרג ל-Pro לקבלת יותר.';

  @override
  String get upgradeHintNone => '';

  @override
  String get notesListTitleFallback => 'פתקים';

  @override
  String get notesListEmptyTitle => 'אין עדיין פתקים';

  @override
  String get notesListEmptyBody => 'הקש + כדי ליצור את הפתק הראשון שלך';

  @override
  String get noteUntitled => '(ללא כותרת)';

  @override
  String get noteDeletedSnack => 'הפתק נמחק';

  @override
  String get deleteNoteTitle => 'למחוק את הפתק?';

  @override
  String get deleteNoteBody => 'לא ניתן לבטל פעולה זו.';

  @override
  String get privateAuthReason => 'אמת את זהותך כדי לצפות בפתק פרטי זה';

  @override
  String get renameCategory => 'שנה שם';

  @override
  String get changeCategoryColor => 'שנה צבע';

  @override
  String get deleteCategoryAction => 'מחק קטגוריה';

  @override
  String get renameCategoryDialog => 'שנה שם קטגוריה';

  @override
  String get categoryColorDialog => 'צבע קטגוריה';

  @override
  String deleteCategoryConfirmTitle(Object name) {
    return 'למחוק את \"$name\"?';
  }

  @override
  String get deleteCategoryConfirmBody => 'כל הפתקים בקטגוריה זו יימחקו גם הם.';

  @override
  String get allNotesEmptyTitle => 'אין עדיין פתקים';

  @override
  String get allNotesEmptyBody => 'צור קטגוריה והוסף את הפתק הראשון שלך';

  @override
  String get allNotesCreateFirst => 'צור קטגוריה תחילה';

  @override
  String get editorNewTitle => 'פתק חדש';

  @override
  String get editorEditTitle => 'עריכת פתק';

  @override
  String get editorSaving => 'שומר…';

  @override
  String editorSavedAt(Object time) {
    return 'נשמר $time';
  }

  @override
  String get editorTitleHint => 'כותרת';

  @override
  String get editorBodyHint => 'התחל לכתוב…';

  @override
  String get editorChangeCategory => 'שנה קטגוריה';

  @override
  String get editorNewCategoryEntry => 'קטגוריה חדשה…';

  @override
  String get editorTooltipPublic => 'ציבורי';

  @override
  String get editorTooltipPrivate => 'פרטי';

  @override
  String get editorTooltipDelete => 'מחק פתק';

  @override
  String get editorTooltipEdit => 'ערוך פתק';

  @override
  String get editorTooltipCopy => 'העתק פתק';

  @override
  String get editorCopyMenuItem => 'העתק פתק';

  @override
  String get editorCopiedSnack => 'הפתק הועתק';

  @override
  String get editorSttRecord => 'הקלט קול';

  @override
  String get editorSttStop => 'הפסק הקלטה';

  @override
  String get searchHint => 'חפש פתקים…';

  @override
  String get searchIdleTitle => 'חפש בפתקים שלך';

  @override
  String get searchIdleBody =>
      'הקלד מילות מפתח או שאל שאלה.\nפתקים פרטיים אינם נכללים.';

  @override
  String searchNoResults(Object query) {
    return 'אין תוצאות עבור \"$query\"';
  }

  @override
  String get searchTryDifferent => 'נסה מילות מפתח אחרות';

  @override
  String searchMoreLines(int count) {
    return '+$count שורות נוספות';
  }

  @override
  String get searchTryAiHint => 'לא מצאת מה שחיפשת? נסה חיפוש AI';

  @override
  String get searchNoResultsAiCta => 'לא נמצאו תוצאות. לחץ לחיפוש AI';

  @override
  String get searchHistoryButtonTooltip => 'היסטוריית חיפוש AI';

  @override
  String get searchBackToResults => 'חזרה לתוצאות';

  @override
  String get widgetSearchTitle => 'חפש בפתקים שלך';

  @override
  String get aiSearchTitle => 'חיפוש AI';

  @override
  String get aiSearchHint => 'שאל על הפתקים שלך…';

  @override
  String get aiSearchLoading => 'מחפש בפתקים שלך…';

  @override
  String get aiSearchIdleTitle => 'שאל כל דבר על הפתקים שלך';

  @override
  String get aiSearchIdleBody => 'ה-AI מחפש בפתקים שלך ומסכם תשובה';

  @override
  String get aiSearchSuggestion1 => 'סכם את פתקי האימון שלי';

  @override
  String get aiSearchSuggestion2 => 'מה כתבתי על העבודה?';

  @override
  String get aiSearchSuggestion3 => 'מצא פתקים על המטרות שלי';

  @override
  String get aiSearchSuggestion4 => 'מהן תוכניות הנסיעה שלי?';

  @override
  String get aiSearchSources => 'מקורות';

  @override
  String get aiSearchFromCache => 'מהמטמון';

  @override
  String get aiSearchRateTitle => 'הגעת למגבלת השימוש';

  @override
  String aiSearchRateSeconds(int seconds) {
    return 'נסה שוב בעוד $seconds שניות';
  }

  @override
  String aiSearchRateMinutes(int minutes) {
    return 'נסה שוב בעוד $minutes דקות';
  }

  @override
  String aiSearchRateResetsAt(Object time) {
    return 'מתאפס ב-$time';
  }

  @override
  String get aiSearchRateDefault => 'אנא המתן לפני חיפוש נוסף';

  @override
  String get aiInfoTitle => 'על חיפוש AI';

  @override
  String get aiInfoBody =>
      'חיפוש AI קורא את הפתקים שלך כדי לענות על שאלתך.\n\n🔒 פתקים פרטיים לעולם אינם נשלחים ל-AI.\n\n📄 פתקים ארוכים מאוד מקוצרים לפני השליחה.';

  @override
  String get aiInfoDismiss => 'הבנתי';

  @override
  String get aiAnswerCopied => 'הועתק ללוח';

  @override
  String get aiHistoryTitle => 'היסטוריית חיפוש AI';

  @override
  String get aiHistoryEmpty => 'אין היסטוריית חיפוש עדיין';

  @override
  String get aiHistoryRelativeNow => 'עכשיו';

  @override
  String aiHistoryRelativeMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'לפני $count דקות',
      one: 'לפני דקה',
    );
    return '$_temp0';
  }

  @override
  String aiHistoryRelativeHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'לפני $count שעות',
      one: 'לפני שעה',
    );
    return '$_temp0';
  }

  @override
  String aiHistoryRelativeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'לפני $count ימים',
      one: 'לפני יום',
    );
    return '$_temp0';
  }

  @override
  String get settingsTitle => 'הגדרות';

  @override
  String get settingsSectionAccount => 'חשבון';

  @override
  String get settingsSectionUsage => 'שימוש';

  @override
  String get settingsSectionUpgrade => 'שדרוג';

  @override
  String get settingsSectionApp => 'אפליקציה';

  @override
  String get settingsSectionLanguage => 'שפה';

  @override
  String get settingsUnknownUser => 'לא ידוע';

  @override
  String get settingsTierFree => 'חינם';

  @override
  String get settingsTierPro => 'Pro';

  @override
  String get settingsUsageAi => 'חיפושי AI היום';

  @override
  String get settingsUsageNotes => 'פתקים';

  @override
  String get settingsUsageCategories => 'קטגוריות';

  @override
  String get settingsUpgradeTitle => 'שדרג ל-Pro';

  @override
  String get settingsUpgradeSubtitle =>
      '50 חיפושי AI ביום · 1000 פתקים · 50 קטגוריות';

  @override
  String get settingsUpgradeDialogBody =>
      'Pro מעניק לך 50 חיפושי AI ביום, עד 1000 פתקים, 50 קטגוריות ו-20,000 תווים בפתק.';

  @override
  String get contactUsMessageHint => 'הודעתך (אופציונלי)…';

  @override
  String get contactUsNoEmailApp =>
      'לא נמצאה אפליקציית דוא\"ל. אנא פנה אלינו בכתובת:';

  @override
  String get contactUsCopied => 'כתובת הדוא\"ל הועתקה';

  @override
  String get settingsSignOut => 'התנתק';

  @override
  String get settingsLanguageDeviceDefault => 'ברירת מחדל של המכשיר';

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
  String get widgetAddNoteTooltip => 'הוסף פתק';

  @override
  String get widgetComposeTitle => 'פתק חדש';

  @override
  String get widgetComposeDiscardTitle => 'להתעלם מהפתק?';

  @override
  String get widgetComposeDiscardBody => 'הפתק שלך לא יישמר.';

  @override
  String get widgetComposeNoCategories =>
      'לא נמצאו קטגוריות.\nפתח את MindVault כדי ליצור אחת תחילה.';

  @override
  String get widgetComposeCategoryLabel => 'קטגוריה';

  @override
  String get noteTypeLabel => 'סוג';

  @override
  String get noteTypeText => 'טקסט';

  @override
  String get noteTypeChecklist => 'רשימת משימות';

  @override
  String get removeDoneTasksLabel => 'הסר משימות שהושלמו';

  @override
  String get removeDoneTasksTitle => 'להסיר משימות שהושלמו?';

  @override
  String get removeDoneTasksBody => 'משימות שהושלמו יימחקו לצמיתות.';

  @override
  String get widgetViewEditTitle => 'עריכת פתק';

  @override
  String get widgetViewEdit => 'ערוך';

  @override
  String get widgetViewDelete => 'מחק';

  @override
  String get widgetViewUnlocking => 'פותח…';

  @override
  String get widgetViewNoContent => 'אין תוכן';

  @override
  String get widgetViewNotFound => 'הפתק לא נמצא';

  @override
  String get widgetViewDiscardTitle => 'להתעלם מהשינויים?';

  @override
  String get widgetViewDiscardBody => 'העריכות שלך לא יישמרו.';

  @override
  String get widgetViewKeepEditing => 'המשך לערוך';
}
