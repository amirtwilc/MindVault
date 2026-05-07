import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/tier_limits.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/categories_provider.dart';
import '../../providers/encryption_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/tier_provider.dart';
import '../../../services/widget_data_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final tierAsync = ref.watch(tierProvider);
    final tier = tierAsync.valueOrNull ?? TierLimits.free();
    final aiTodayAsync = ref.watch(aiSearchesTodayProvider);
    final aiToday = aiTodayAsync.valueOrNull ?? 0;
    final allNotes = ref.watch(allNotesProvider).valueOrNull ?? [];
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final currentLocale = ref.watch(localeProvider);

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── Account ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(l.settingsSectionAccount,
                style: tt.labelSmall?.copyWith(color: cs.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1)),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      _initials(user?.email ?? ''),
                      style: tt.titleMedium?.copyWith(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.email ?? l.settingsUnknownUser,
                            style: tt.bodyMedium,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        _TierBadge(tier: tier.tier),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Tier & Usage ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(l.settingsSectionUsage,
                style: tt.labelSmall?.copyWith(color: cs.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1)),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _UsageRow(
                    icon: Icons.auto_awesome_rounded,
                    label: l.settingsUsageAi,
                    used: aiToday,
                    max: tier.aiSearchesPerDay,
                    cs: cs,
                    tt: tt,
                  ),
                  const SizedBox(height: 14),
                  _UsageRow(
                    icon: Icons.notes_rounded,
                    label: l.settingsUsageNotes,
                    used: allNotes.length,
                    max: tier.maxNotes,
                    cs: cs,
                    tt: tt,
                  ),
                  const SizedBox(height: 14),
                  _UsageRow(
                    icon: Icons.folder_outlined,
                    label: l.settingsUsageCategories,
                    used: categories.length,
                    max: tier.maxCategories,
                    cs: cs,
                    tt: tt,
                  ),
                ],
              ),
            ),
          ),

          if (tier.tier == 'free') ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(l.settingsSectionUpgrade,
                  style: tt.labelSmall?.copyWith(color: cs.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1)),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                leading: Icon(Icons.rocket_launch_outlined,
                    color: cs.primary),
                title: Text(l.settingsUpgradeTitle),
                subtitle: Text(l.settingsUpgradeSubtitle),
                trailing: Icon(Icons.chevron_right, color: cs.outline),
                onTap: () => _showUpgradeDialog(context),
              ),
            ),
          ],

          const SizedBox(height: 8),

          // ── Language ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(l.settingsSectionLanguage,
                style: tt.labelSmall?.copyWith(color: cs.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1)),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: Icon(Icons.translate, color: cs.primary),
              title: Text(_languageLabel(currentLocale, l)),
              trailing: Icon(Icons.chevron_right, color: cs.outline),
              onTap: () => _showLanguagePicker(context, ref, currentLocale),
            ),
          ),

          const SizedBox(height: 8),

          // ── App ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(l.settingsSectionApp,
                style: tt.labelSmall?.copyWith(color: cs.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1)),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: Icon(Icons.logout, color: cs.error),
              title: Text(l.settingsSignOut,
                  style: TextStyle(color: cs.error)),
              onTap: () async {
                await ref.read(encryptionServiceProvider).deleteKey();
                ref.read(aesKeyProvider.notifier).state = null;
                ref.invalidate(encryptionReadyProvider);
                await WidgetDataService().clearWidget();
                await ref.read(authDatasourceProvider).signOut();
              },
            ),
          ),
        ],
      ),
    );
  }

  String _languageLabel(Locale? locale, AppStrings l) {
    if (locale == null) return l.settingsLanguageDeviceDefault;
    switch (locale.languageCode) {
      case 'en':
        return l.settingsLanguageEnglish;
      case 'he':
        return l.settingsLanguageHebrew;
      case 'de':
        return l.settingsLanguageGerman;
      case 'hi':
        return l.settingsLanguageHindi;
      case 'es':
        return l.settingsLanguageSpanish;
      case 'fr':
        return l.settingsLanguageFrench;
      default:
        return locale.languageCode;
    }
  }

  Future<void> _showLanguagePicker(
      BuildContext context, WidgetRef ref, Locale? current) async {
    final l = AppStrings.of(context);
    final notifier = ref.read(localeProvider.notifier);

    final entries = <(Locale?, String)>[
      (null, l.settingsLanguageDeviceDefault),
      (const Locale('en'), l.settingsLanguageEnglish),
      (const Locale('de'), l.settingsLanguageGerman),
      (const Locale('es'), l.settingsLanguageSpanish),
      (const Locale('fr'), l.settingsLanguageFrench),
      (const Locale('he'), l.settingsLanguageHebrew),
      (const Locale('hi'), l.settingsLanguageHindi),
    ];

    await showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.settingsSectionLanguage),
        children: entries
            .map((e) => RadioListTile<String?>(
                  value: e.$1?.languageCode,
                  groupValue: current?.languageCode,
                  title: Text(e.$2),
                  onChanged: (_) {
                    notifier.setLocale(e.$1);
                    Navigator.pop(ctx);
                  },
                ))
            .toList(),
      ),
    );
  }

  String _initials(String email) {
    if (email.isEmpty) return '?';
    return email[0].toUpperCase();
  }

  void _showUpgradeDialog(BuildContext context) {
    final l = AppStrings.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.settingsUpgradeTitle),
        content: Text(l.settingsUpgradeDialogBody),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l.actionOk),
          ),
        ],
      ),
    );
  }
}

// ── Tier badge ────────────────────────────────────────────────────────────────

class _TierBadge extends StatelessWidget {
  final String tier;
  const _TierBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppStrings.of(context);
    final isPro = tier == 'pro';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isPro ? cs.primaryContainer : cs.secondaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPro ? Icons.rocket_launch_rounded : Icons.auto_awesome_rounded,
            size: 12,
            color: isPro ? cs.onPrimaryContainer : cs.onSecondaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            isPro ? l.settingsTierPro : l.settingsTierFree,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isPro
                      ? cs.onPrimaryContainer
                      : cs.onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Usage row ─────────────────────────────────────────────────────────────────

class _UsageRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int used;
  final int max;
  final ColorScheme cs;
  final TextTheme tt;

  const _UsageRow({
    required this.icon,
    required this.label,
    required this.used,
    required this.max,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (used / max).clamp(0.0, 1.0);
    final isNearLimit = ratio >= 0.8;
    final isAtLimit = ratio >= 1.0;
    final barColor = isAtLimit
        ? cs.error
        : isNearLimit
            ? cs.tertiary
            : cs.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: tt.bodySmall),
            ),
            Text(
              '$used / $max',
              style: tt.bodySmall?.copyWith(
                color: isAtLimit ? cs.error : cs.onSurfaceVariant,
                fontWeight: isAtLimit ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 5,
            backgroundColor: cs.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}
