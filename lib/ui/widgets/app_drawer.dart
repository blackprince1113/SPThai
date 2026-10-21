import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/core/services/auth_service.dart';
import 'package:superthai/core/services/data_service.dart';
import 'package:superthai/ui/screens/main_container.dart';
import 'package:superthai/ui/screens/login_screen.dart';
import 'package:superthai/ui/theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser;
    final isAdmin = auth.isAdmin;
    final mainState = MainContainer.of(context);
    final currentIndex = mainState?.selectedIndex ?? 0;
    final selectedCategory = mainState?.selectedCategory;

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // Drawer Header
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.displayName?.isNotEmpty == true
                    ? user!.displayName![0].toUpperCase()
                    : (user?.email?.isNotEmpty == true
                        ? user!.email![0].toUpperCase()
                        : 'S'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            accountName: Text(
              user?.displayName ?? (user != null ? 'User' : 'Guest'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            accountEmail: Row(
              children: [
                Expanded(
                  child: Text(
                    user?.email ?? 'Welcome to SuperThai 🇹🇭',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (user != null && isAdmin)
                  Container(
                    margin: const EdgeInsets.only(right: 16, bottom: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ADMIN',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Categories List
          Expanded(
            child: FutureBuilder<List<LessonPlan>>(
              future: dataService.getAllLessonPlans(),
              builder: (context, snapshot) {
                final plans = snapshot.data ?? [];

                // Group plans by category
                final Map<String, List<LessonPlan>> categoryMap = {};
                for (var plan in plans) {
                  if (plan.category.isNotEmpty) {
                    categoryMap.putIfAbsent(plan.category, () => []).add(plan);
                  }
                }
                final categoryNames = categoryMap.keys.toList();

                return ListView(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  children: [
                    // Section Header: CATEGORIES
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.category_rounded,
                                size: 16,
                                color: theme.disabledColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'CATEGORIES',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: theme.disabledColor,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          if (categoryNames.isNotEmpty)
                            Text(
                              '${categoryNames.length}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.disabledColor,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Category Items List from Top to Bottom
                    if (categoryNames.isEmpty &&
                        snapshot.connectionState == ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    else
                      ...categoryNames.map((catName) {
                        final catPlans = categoryMap[catName]!;
                        final firstPlan = catPlans.first;
                        final emoji = firstPlan.categoryEmoji.isNotEmpty
                            ? firstPlan.categoryEmoji
                            : (firstPlan.emoji.isNotEmpty
                                ? firstPlan.emoji
                                : '📚');
                        final isSelected = currentIndex == 0 &&
                            (selectedCategory == catName ||
                                (selectedCategory == null &&
                                    catName == categoryNames.first));

                        return _buildCategoryItem(
                          context,
                          emoji: emoji,
                          title: catName,
                          count: catPlans.length,
                          isSelected: isSelected,
                          onTap: () {
                            Navigator.pop(context);
                            mainState?.selectCategory(catName);
                          },
                        );
                      }),
                  ],
                );
              },
            ),
          ),

          // Footer & Logout / Login Button
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final version = snapshot.data?.version ?? '1.2.8';
                    return Text(
                      'SuperThai v$version',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.5),
                      ),
                    );
                  },
                ),
                if (user != null)
                  TextButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await auth.logout();
                    },
                    icon: const Icon(Icons.logout_rounded,
                        size: 18, color: Colors.redAccent),
                    label: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  )
                else
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LoginScreen()),
                      );
                    },
                    icon: Icon(Icons.login_rounded,
                        size: 18, color: AppTheme.primaryColor),
                    label: Text(
                      'Login',
                      style: TextStyle(color: AppTheme.primaryColor),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
    BuildContext context, {
    required String emoji,
    required String title,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final primaryColor = AppTheme.primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.15)
                : theme.dividerColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 18),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
            color:
                isSelected ? primaryColor : theme.textTheme.bodyLarge?.color,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.15)
                : theme.dividerColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? primaryColor : theme.disabledColor,
            ),
          ),
        ),
        selected: isSelected,
        selectedTileColor: primaryColor.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        onTap: onTap,
      ),
    );
  }
}
