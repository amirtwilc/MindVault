// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppStringsEs extends AppStrings {
  AppStringsEs([String locale = 'es']) : super(locale);

  @override
  String get appBrand => 'MindVault';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionSave => 'Guardar';

  @override
  String get actionDelete => 'Eliminar';

  @override
  String get actionCreate => 'Crear';

  @override
  String get actionRename => 'Renombrar';

  @override
  String get actionApply => 'Aplicar';

  @override
  String get actionClose => 'Cerrar';

  @override
  String get actionDiscard => 'Descartar';

  @override
  String get actionTryAgain => 'Reintentar';

  @override
  String get actionUnlock => 'Desbloquear';

  @override
  String get actionRecoverContinue => 'Recuperar y continuar';

  @override
  String get actionSetupContinue => 'Configurar y continuar';

  @override
  String get actionStartFresh => 'Empezar de nuevo';

  @override
  String get actionContactUs => 'Contactar';

  @override
  String get actionOk => 'OK';

  @override
  String get splashTagline => 'Tus pensamientos, cifrados de forma segura.';

  @override
  String get splashLoading => 'Protegiendo tu bóveda…';

  @override
  String get authSubtitle => 'Tus notas cifradas con IA';

  @override
  String get authEmailLabel => 'Correo electrónico';

  @override
  String get authPasswordLabel => 'Contraseña';

  @override
  String get authEmailRequired => 'El correo es obligatorio.';

  @override
  String get authEmailInvalid => 'Introduce un correo electrónico válido.';

  @override
  String get authPasswordRequired => 'La contraseña es obligatoria.';

  @override
  String get authPasswordTooShort =>
      'La contraseña debe tener al menos 6 caracteres.';

  @override
  String get authSignInEmail => 'Iniciar sesión con correo';

  @override
  String get authCreateAccount => 'Crear cuenta';

  @override
  String get authNeedAccount => '¿Necesitas una cuenta? Crea una';

  @override
  String get authHaveAccount => '¿Ya tienes una cuenta? Inicia sesión';

  @override
  String get authOr => 'o';

  @override
  String get authCheckEmail =>
      'Revisa tu correo para confirmar tu cuenta y luego inicia sesión.';

  @override
  String get authCheckEmailOtp =>
      'Te enviamos un código de confirmación por correo. Escríbelo aquí para terminar de crear tu cuenta.';

  @override
  String get authOtpResent => 'Se envió un nuevo código de confirmación.';

  @override
  String get authRecoveryCodeSent =>
      'Te enviamos un código de recuperación por correo.';

  @override
  String get authRecoveryCodeResent =>
      'Se envió un nuevo código de recuperación.';

  @override
  String get authInvalidCredentials =>
      'El correo o la contraseña son incorrectos.';

  @override
  String get authEmailAlreadyUsed =>
      'Ya existe una cuenta con este correo. Intenta iniciar sesión.';

  @override
  String get authWeakPassword =>
      'Elige una contraseña más segura e inténtalo de nuevo.';

  @override
  String get authEmailNotConfirmed =>
      'Confirma tu correo antes de iniciar sesión.';

  @override
  String get authInvalidOtp =>
      'Ese código no es válido. Revísalo e inténtalo de nuevo.';

  @override
  String get authExpiredOtp =>
      'Ese código ha caducado. Solicita uno nuevo e inténtalo otra vez.';

  @override
  String get authRateLimited =>
      'Demasiados intentos. Espera un momento e inténtalo de nuevo.';

  @override
  String get authNetworkError =>
      'No se pudo contactar con el servidor de inicio de sesión. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get authGenericError =>
      'No se pudo iniciar sesión. Inténtalo de nuevo.';

  @override
  String get authForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get authForgotPasswordTitle => 'Restablece tu contraseña';

  @override
  String get authVerifyEmailTitle => 'Confirma tu correo';

  @override
  String get authVerifyRecoveryTitle => 'Verifica tu código de recuperación';

  @override
  String get authSetNewPasswordTitle => 'Elige una nueva contraseña';

  @override
  String get authVerifyEmailCode => 'Verificar código del correo';

  @override
  String get authVerifyRecoveryCode => 'Verificar código de recuperación';

  @override
  String get authOtpHelper =>
      'Introduce el código de tu correo de confirmación.';

  @override
  String get authRecoveryOtpHelper =>
      'Introduce el código de tu correo de recuperación.';

  @override
  String get authOtpLabel => 'Código del correo';

  @override
  String get authOtpRequired => 'El código de verificación es obligatorio.';

  @override
  String get authOtpInvalidFormat => 'Introduce el código de tu correo.';

  @override
  String get authResendCode => 'Reenviar código';

  @override
  String get authSendingCode => 'Enviando código...';

  @override
  String get authVerifyingCode => 'Verificando código...';

  @override
  String get authSendRecoveryCode => 'Enviar código de recuperación';

  @override
  String get authBackToSignIn => 'Volver a iniciar sesión';

  @override
  String get authSetNewPasswordBody =>
      'Introduce una nueva contraseña para tu cuenta.';

  @override
  String get authNewPasswordLabel => 'Nueva contraseña';

  @override
  String get authConfirmPasswordLabel => 'Confirmar nueva contraseña';

  @override
  String get authConfirmPasswordRequired => 'Confirma tu contraseña.';

  @override
  String get authPasswordsDoNotMatch => 'Las contraseñas no coinciden.';

  @override
  String get authUpdatingPassword => 'Actualizando contraseña...';

  @override
  String get authUpdatePassword => 'Actualizar contraseña';

  @override
  String get authCancelRecovery => 'Cancelar recuperación';

  @override
  String get authPasswordUpdated =>
      'Contraseña actualizada. Terminando el inicio de sesión...';

  @override
  String get authSignInGoogle => 'Iniciar sesión con Google';

  @override
  String get authSigningIn => 'Iniciando sesión...';

  @override
  String get authDisclaimer =>
      'Tus notas están cifradas de extremo a extremo.\nSolo tú puedes leerlas.';

  @override
  String get pinSetupAppBar => 'Configurar cifrado';

  @override
  String get pinRecoveryAppBar => 'Recuperar clave de cifrado';

  @override
  String get pinSetupHeading => 'Crear un PIN de recuperación';

  @override
  String get pinRecoveryHeading => 'Ingresa tu PIN de recuperación';

  @override
  String get pinSetupBody =>
      'Este PIN protege tus notas para que nadie más que tú pueda leerlas. Lo necesitarás si inicias sesión en un nuevo dispositivo.';

  @override
  String get pinRecoveryBody =>
      'Tus notas están cifradas. Ingresa tu PIN de recuperación para desbloquearlas en este dispositivo.';

  @override
  String get pinLabel => 'PIN de recuperación (4–8 dígitos)';

  @override
  String get pinConfirmLabel => 'Confirmar PIN';

  @override
  String get pinSetupDisclaimer =>
      'Tu PIN nunca sale de este dispositivo. Tu clave cifrada se almacena en nuestros servidores para que puedas recuperarla al reinstalar, pero no se puede leer sin el PIN.';

  @override
  String get pinRecoveryDisclaimer =>
      'Tu PIN nunca sale de este dispositivo. Solo tu clave cifrada está en nuestros servidores — no puede leerse sin el PIN.';

  @override
  String get pinForgot => '¿Olvidaste el PIN? Empezar de nuevo';

  @override
  String get pinSignOut => 'Cerrar sesión';

  @override
  String get pinTooShort => 'El PIN debe tener al menos 4 caracteres.';

  @override
  String get pinMismatch => 'Los PINs no coinciden.';

  @override
  String get pinRecoverError =>
      'PIN incorrecto. No se pudo recuperar la clave de cifrado.';

  @override
  String pinServerError(Object message) {
    return 'Error del servidor: $message';
  }

  @override
  String get pinStartFreshTitle => '¿Empezar de nuevo?';

  @override
  String get pinStartFreshBody =>
      'Esto generará una nueva clave de cifrado. Tus notas existentes se perderán.\n\nEsta acción no se puede deshacer.';

  @override
  String get pinEntryAppBar => 'Ingresar PIN de recuperación';

  @override
  String get pinEntryHeading => 'Ingresa tu PIN de recuperación';

  @override
  String get pinEntryLabel => 'PIN de recuperación';

  @override
  String get pinEntryNoKey =>
      'No se encontró ninguna clave. Por favor contacta el soporte.';

  @override
  String get pinEntryIncorrect =>
      'PIN incorrecto. Por favor inténtalo de nuevo.';

  @override
  String get pinSetupError =>
      'Error al configurar el cifrado. Por favor inténtalo de nuevo.';

  @override
  String pinLockedSeconds(int seconds) {
    return 'Demasiados intentos fallidos. Inténtalo en ${seconds}s.';
  }

  @override
  String pinLockedMinutes(int minutes) {
    return 'Demasiados intentos fallidos. Inténtalo en ${minutes}m.';
  }

  @override
  String get navAllNotes => 'Todas las notas';

  @override
  String get navCategories => 'Categorías';

  @override
  String get navSearch => 'Buscar';

  @override
  String get navSettings => 'Configuración';

  @override
  String get homeNoCategoriesTitle => 'Sin categorías.\nToca + para crear una.';

  @override
  String get newCategoryDialogTitle => 'Nueva categoría';

  @override
  String get categoryNameHint => 'Nombre de la categoría';

  @override
  String get categoryColorLabel => 'Color';

  @override
  String get categoryNameInUse => 'El nombre ya está en uso';

  @override
  String categoryLimitReached(int max, Object upgradeHint) {
    return 'Límite de categorías alcanzado ($max). $upgradeHint';
  }

  @override
  String noteLimitReached(int max, Object upgradeHint) {
    return 'Límite de notas alcanzado ($max). $upgradeHint';
  }

  @override
  String get upgradeHintFree => 'Actualiza a Pro para obtener más.';

  @override
  String get upgradeHintNone => '';

  @override
  String get notesListTitleFallback => 'Notas';

  @override
  String get notesListEmptyTitle => 'Sin notas aún';

  @override
  String get notesListEmptyBody => 'Toca + para crear tu primera nota';

  @override
  String get noteUntitled => '(sin título)';

  @override
  String get noteDeletedSnack => 'Nota eliminada';

  @override
  String get deleteNoteTitle => '¿Eliminar nota?';

  @override
  String get deleteNoteBody => 'Esta acción no se puede deshacer.';

  @override
  String get privateAuthReason => 'Autentícate para ver esta nota privada';

  @override
  String get renameCategory => 'Renombrar';

  @override
  String get changeCategoryColor => 'Cambiar color';

  @override
  String get deleteCategoryAction => 'Eliminar categoría';

  @override
  String get renameCategoryDialog => 'Renombrar categoría';

  @override
  String get categoryColorDialog => 'Color de categoría';

  @override
  String deleteCategoryConfirmTitle(Object name) {
    return '¿Eliminar \"$name\"?';
  }

  @override
  String get deleteCategoryConfirmBody =>
      'Todas las notas de esta categoría también se eliminarán.';

  @override
  String get allNotesEmptyTitle => 'Sin notas aún';

  @override
  String get allNotesEmptyBody => 'Crea una categoría y agrega tu primera nota';

  @override
  String get allNotesCreateFirst => 'Crea primero una categoría';

  @override
  String get editorNewTitle => 'Nueva nota';

  @override
  String get editorEditTitle => 'Editar nota';

  @override
  String get editorSaving => 'Guardando…';

  @override
  String editorSavedAt(Object time) {
    return 'Guardado $time';
  }

  @override
  String get editorTitleHint => 'Título';

  @override
  String get editorBodyHint => 'Empieza a escribir…';

  @override
  String get editorChangeCategory => 'Cambiar categoría';

  @override
  String get editorNewCategoryEntry => 'Nueva categoría…';

  @override
  String get editorTooltipPublic => 'Pública';

  @override
  String get editorTooltipPrivate => 'Privada';

  @override
  String get editorTooltipDelete => 'Eliminar nota';

  @override
  String get editorTooltipEdit => 'Editar nota';

  @override
  String get editorTooltipCopy => 'Copiar nota';

  @override
  String get editorCopyMenuItem => 'Copiar nota';

  @override
  String get editorCopiedSnack => 'Nota copiada';

  @override
  String get editorSttRecord => 'Grabar voz';

  @override
  String get editorSttStop => 'Detener grabación';

  @override
  String get searchHint => 'Buscar notas…';

  @override
  String get searchIdleTitle => 'Busca en tus notas';

  @override
  String get searchIdleBody =>
      'Escribe palabras clave o haz una pregunta. \nLas notas privadas se ignoran.';

  @override
  String searchNoResults(Object query) {
    return 'Sin resultados para \"$query\"';
  }

  @override
  String get searchTryDifferent => 'Prueba con otras palabras clave';

  @override
  String searchMoreLines(int count) {
    return '+$count líneas más';
  }

  @override
  String get searchTryAiHint =>
      '¿No es lo que buscabas? Prueba la búsqueda con IA';

  @override
  String get searchNoResultsAiCta =>
      'Sin resultados. Haz clic para realizar una búsqueda con IA';

  @override
  String get searchHistoryButtonTooltip => 'Historial de búsqueda IA';

  @override
  String get searchBackToResults => 'Volver a los resultados';

  @override
  String get widgetSearchTitle => 'Busca en tus notas';

  @override
  String get aiSearchTitle => 'Búsqueda IA';

  @override
  String get aiSearchHint => 'Pregunta sobre tus notas…';

  @override
  String get aiSearchLoading => 'Buscando en tus notas…';

  @override
  String get aiSearchIdleTitle => 'Pregunta cualquier cosa sobre tus notas';

  @override
  String get aiSearchIdleBody =>
      'La IA busca en tus notas y elabora una respuesta';

  @override
  String get aiSearchSuggestion1 => 'Resume mis notas de entrenamiento';

  @override
  String get aiSearchSuggestion2 => '¿Qué escribí sobre el trabajo?';

  @override
  String get aiSearchSuggestion3 => 'Encuentra notas sobre mis metas';

  @override
  String get aiSearchSuggestion4 => '¿Cuáles son mis planes de viaje?';

  @override
  String get aiSearchSources => 'Fuentes';

  @override
  String get aiSearchFromCache => 'Desde caché';

  @override
  String get aiSearchRateTitle => 'Límite alcanzado';

  @override
  String aiSearchRateSeconds(int seconds) {
    return 'Inténtalo en ${seconds}s';
  }

  @override
  String aiSearchRateMinutes(int minutes) {
    return 'Inténtalo en ${minutes}m';
  }

  @override
  String aiSearchRateResetsAt(Object time) {
    return 'Se restablece a las $time';
  }

  @override
  String get aiSearchRateDefault => 'Por favor espera antes de buscar de nuevo';

  @override
  String get aiSearchErrorDailyLimit =>
      'Límite diario de IA alcanzado. Inténtalo de nuevo mañana.';

  @override
  String get aiSearchErrorSessionExpired =>
      'La sesión ha caducado. Inicia sesión de nuevo.';

  @override
  String get aiSearchErrorUnavailable =>
      'La IA no está disponible ahora mismo.';

  @override
  String get aiSearchErrorNetwork =>
      'Sin conexión. Revisa tu conexión a internet e inténtalo de nuevo.';

  @override
  String get aiSearchErrorGeneric =>
      'La solicitud de IA falló. Inténtalo de nuevo.';

  @override
  String get aiInfoTitle => 'Acerca de la búsqueda IA';

  @override
  String get aiInfoBody =>
      'La búsqueda IA lee tus notas para responder tu pregunta.\n\n🔒 Las notas privadas nunca se envían a la IA.\n\n📄 Las notas muy largas se acortan antes de enviarse.';

  @override
  String get aiInfoDismiss => 'Entendido';

  @override
  String get aiAnswerCopied => 'Copiado al portapapeles';

  @override
  String get aiHistoryTitle => 'Historial de búsqueda IA';

  @override
  String get aiHistoryEmpty => 'Sin historial de búsqueda aún';

  @override
  String get aiHistoryRelativeNow => 'Ahora mismo';

  @override
  String aiHistoryRelativeMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count minutos',
      one: 'hace 1 minuto',
    );
    return '$_temp0';
  }

  @override
  String aiHistoryRelativeHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count horas',
      one: 'hace 1 hora',
    );
    return '$_temp0';
  }

  @override
  String aiHistoryRelativeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count días',
      one: 'hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get settingsSectionAccount => 'Cuenta';

  @override
  String get settingsSectionUsage => 'Uso';

  @override
  String get settingsSectionUpgrade => 'Actualizar';

  @override
  String get settingsSectionApp => 'App';

  @override
  String get settingsSectionLanguage => 'Idioma';

  @override
  String get settingsUnknownUser => 'Desconocido';

  @override
  String get settingsTierFree => 'Gratis';

  @override
  String get settingsTierPro => 'Pro';

  @override
  String get settingsUsageAi => 'Búsquedas IA hoy';

  @override
  String get settingsUsageNotes => 'Notas';

  @override
  String get settingsUsageCategories => 'Categorías';

  @override
  String get settingsUpgradeTitle => 'Actualizar a Pro';

  @override
  String get settingsUpgradeSubtitle =>
      '50 búsquedas IA/día · 1000 notas · 50 categorías';

  @override
  String get settingsUpgradeDialogBody =>
      'Pro te da 50 búsquedas IA/día, hasta 1000 notas, 50 categorías y 20.000 caracteres por nota.';

  @override
  String get contactUsMessageHint => 'Tu mensaje (opcional)…';

  @override
  String get contactUsNoEmailApp =>
      'No se encontró ninguna app de correo. Por favor escríbenos a:';

  @override
  String get contactUsCopied => 'Dirección de correo copiada';

  @override
  String get settingsSignOut => 'Cerrar sesión';

  @override
  String get settingsLanguageDeviceDefault => 'Predeterminado del dispositivo';

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
  String get widgetAddNoteTooltip => 'Añadir nota';

  @override
  String get widgetComposeTitle => 'Nueva nota';

  @override
  String get widgetComposeDiscardTitle => '¿Descartar nota?';

  @override
  String get widgetComposeDiscardBody => 'Tu nota no se guardará.';

  @override
  String get widgetComposeNoCategories =>
      'No se encontraron categorías.\nAbre MindVault para crear una primero.';

  @override
  String get widgetComposeCategoryLabel => 'Categoría';

  @override
  String get noteTypeLabel => 'Tipo';

  @override
  String get noteTypeText => 'Texto';

  @override
  String get noteTypeChecklist => 'Lista';

  @override
  String get removeDoneTasksLabel => 'Eliminar tareas hechas';

  @override
  String get removeDoneTasksTitle => '¿Eliminar tareas hechas?';

  @override
  String get removeDoneTasksBody =>
      'Las tareas completadas se eliminarán permanentemente.';

  @override
  String get widgetViewEditTitle => 'Editar nota';

  @override
  String get widgetViewEdit => 'Editar';

  @override
  String get widgetViewDelete => 'Eliminar';

  @override
  String get widgetViewUnlocking => 'Desbloqueando…';

  @override
  String get widgetViewNoContent => 'Sin contenido';

  @override
  String get widgetViewNotFound => 'Nota no encontrada';

  @override
  String get widgetViewDiscardTitle => '¿Descartar cambios?';

  @override
  String get widgetViewDiscardBody => 'Tus ediciones no se guardarán.';

  @override
  String get widgetViewKeepEditing => 'Seguir editando';
}
