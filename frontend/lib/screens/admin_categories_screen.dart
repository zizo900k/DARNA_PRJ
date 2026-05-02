import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/language_provider.dart';
import '../providers/category_provider.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<CategoryProvider>().fetchCategories();
    });
  }

  void _showCategoryDialog({Map<String, dynamic>? existing}) {
    final nameController = TextEditingController(text: existing?['name'] ?? '');
    final slugController = TextEditingController(text: existing?['slug'] ?? '');
    final isEditing = existing != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Text(
                  isEditing
                      ? (context.tr('edit_category'))
                      : (context.tr('add_category')),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 24),
                // Input
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? DarkColors.backgroundSecondary
                        : LightColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    decoration: InputDecoration(
                      hintText: context.tr('category_name_hint'),
                      hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.category_outlined,
                          color: theme.textTheme.bodyMedium?.color, size: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Slug Input
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? DarkColors.backgroundSecondary
                        : LightColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: slugController,
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    decoration: InputDecoration(
                      hintText: context.tr('internal_key_optional'),
                      hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.vpn_key_outlined,
                          color: theme.textTheme.bodyMedium?.color, size: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Action button
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () async {
                      final name = nameController.text.trim();
                      final slug = slugController.text.trim();
                      if (name.isEmpty) return;
                      Navigator.pop(ctx);
                      try {
                        if (isEditing) {
                          await context
                              .read<CategoryProvider>()
                              .updateCategory(existing['id'], name, slug: slug);
                        } else {
                          await context
                              .read<CategoryProvider>()
                              .createCategory(name, slug: slug);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEditing
                                  ? context.tr('category_updated')
                                  : context.tr('category_created')),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$e'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D5C63), Color(0xFF16A085)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D5C63).withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isEditing ? context.tr('save_changes') : context.tr('create'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> category) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final propCount = category['properties_count'] ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? DarkColors.card : LightColors.card,
        title: Text(
          context.tr('delete_category'),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        content: Text(
          propCount > 0
              ? context
                  .tr('category_has_properties')
                  .replaceAll('%s', propCount.toString())
                  .replaceAll('%n', category['name'] ?? '')
              : context
                  .tr('confirm_delete_category')
                  .replaceAll('%s', category['name'] ?? ''),
          style: TextStyle(
            fontSize: 14,
            color: theme.textTheme.bodyMedium?.color,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              context.tr('cancel'),
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            ),
          ),
          if (propCount == 0)
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await context
                      .read<CategoryProvider>()
                      .deleteCategory(category['id']);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.tr('category_deleted')),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$e'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              child: Text(
                context.tr('delete'),
                style: const TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('manage_categories'),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.tr('manage_categories_desc'),
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showCategoryDialog(),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D5C63), Color(0xFF16A085)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Category List
            Expanded(
              child: Consumer<CategoryProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (provider.categories.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.category_outlined,
                              size: 64, color: theme.dividerColor),
                          const SizedBox(height: 16),
                          Text(
                            context.tr('no_categories'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr('add_first_category'),
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => provider.fetchCategories(),
                    color: AppColors.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      itemCount: provider.categories.length,
                      itemBuilder: (ctx, i) {
                        final cat = provider.categories[i];
                        final propCount = cat['properties_count'] ?? 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? DarkColors.card
                                : LightColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: isDark ? null : Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                            boxShadow: isDark ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ] : [],
                          ),
                          child: Row(
                            children: [
                              // Icon
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.category_rounded,
                                    size: 20, color: AppColors.primary),
                              ),
                              const SizedBox(width: 14),
                              // Name + count
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (cat['slug'] != null && context.tr('category.${cat['slug']}') != 'category.${cat['slug']}')
                                            ? context.tr('category.${cat['slug']}')
                                            : (cat['name'] ?? ''),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: theme
                                              .textTheme.bodyLarge?.color,
                                        ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$propCount ${context.tr('properties_count')}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme
                                            .textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Edit
                              GestureDetector(
                                onTap: () =>
                                    _showCategoryDialog(existing: cat),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? DarkColors.backgroundSecondary
                                        : LightColors.backgroundSecondary,
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.edit_outlined,
                                      size: 16,
                                      color: theme
                                          .textTheme.bodyLarge?.color),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Delete
                              GestureDetector(
                                onTap: () =>
                                    _showDeleteConfirmation(cat),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.error
                                        .withValues(alpha: 0.1),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                      Icons.delete_outline,
                                      size: 16,
                                      color: AppColors.error),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
