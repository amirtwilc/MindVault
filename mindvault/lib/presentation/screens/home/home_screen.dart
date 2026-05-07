import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/category_colors.dart';
import '../../../domain/entities/tier_limits.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/categories_provider.dart';
import '../../providers/tier_provider.dart';
import '../../widgets/category_color_picker.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final tier = ref.watch(tierProvider).valueOrNull ?? TierLimits.free();
    final l = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.appBrand),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(l.homeNoCategoriesTitle, textAlign: TextAlign.center),
                ],
              ),
            );
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            onReorder: (oldIndex, newIndex) {
              final reordered = List.of(categories);
              if (newIndex > oldIndex) newIndex--;
              final item = reordered.removeAt(oldIndex);
              reordered.insert(newIndex, item);
              ref
                  .read(categoriesProvider.notifier)
                  .reorder(reordered.map((c) => c.id).toList());
            },
            itemBuilder: (context, index) {
              final category = categories[index];
              final bg = categoryColor(category.color);
              final fg = categoryTextColor(bg);
              return Card(
                key: ValueKey(category.id),
                color: bg,
                child: ListTile(
                  leading: Icon(Icons.folder, color: fg),
                  title: Text(category.name,
                      style: TextStyle(
                          color: fg, fontWeight: FontWeight.w600)),
                  trailing: Icon(Icons.drag_handle, color: fg.withOpacity(0.7)),
                  onTap: () => context.push('/home/categories/${category.id}'),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final cats = ref.read(categoriesProvider).valueOrNull ?? [];
          if (cats.length >= tier.maxCategories) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l.categoryLimitReached(
                    tier.maxCategories,
                    tier.tier == 'free' ? l.upgradeHintFree : l.upgradeHintNone,
                  ),
                ),
              ),
            );
            return;
          }
          _showCreateDialog(context, ref);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final l = AppStrings.of(context);
    final controller = TextEditingController();
    String selectedColor = kCategoryColors.first;
    String? nameError;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l.newCategoryDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: l.categoryNameHint,
                  errorText: nameError,
                ),
                autofocus: true,
                maxLength: 20,
                inputFormatters: [LengthLimitingTextInputFormatter(20)],
              ),
              const SizedBox(height: 16),
              Text(l.categoryColorLabel,
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              CategoryColorPicker(
                selected: selectedColor,
                onChanged: (c) => setDialogState(() => selectedColor = c),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l.actionCancel),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                final cats = ref.read(categoriesProvider).valueOrNull ?? [];
                if (cats.any((c) =>
                    c.name.toLowerCase() == name.toLowerCase())) {
                  setDialogState(() => nameError = l.categoryNameInUse);
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: Text(l.actionCreate),
            ),
          ],
        ),
      ),
    );

    final name = controller.text.trim();
    controller.dispose();
    if (confirmed == true && name.isNotEmpty) {
      final id = await ref
          .read(categoriesProvider.notifier)
          .createCategory(name, color: selectedColor);
      if (id != null && context.mounted) context.push('/home/categories/$id');
    }
  }
}
