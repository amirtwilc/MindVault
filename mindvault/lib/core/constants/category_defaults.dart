/// The canonical name used when the General category is created — both by
/// the Supabase trigger and by the local failsafe in CategoriesNotifier.
/// Insert sites should write this literal so the failsafe and DB trigger
/// agree on a single spelling.
const String kGeneralCategoryName = 'General';

/// True for the protected "General" category, which is created automatically
/// for every user and cannot be renamed, recolored, or deleted. Compares
/// case-insensitively because the DB unique index is case-sensitive but the
/// app guards against accidental capitalization variants from older clients.
bool isGeneralCategoryName(String name) =>
    name.toLowerCase() == kGeneralCategoryName.toLowerCase();
