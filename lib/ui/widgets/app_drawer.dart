import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:superthai/core/services/auth_service.dart';
import 'package:superthai/ui/screens/main_container.dart';
import 'package:superthai/ui/screens/settings_screen.dart';
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

          // Menu Items List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.menu_book_rounded,
                  title: 'Lessons',
                  isSelected: currentIndex == 0,
                  onTap: () {
                    Navigator.pop(context);
                    mainState?.setSelectedIndex(0);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.translate_rounded,
                  title: 'Vocabulary',
                  isSelected: currentIndex == 1,
                  onTap: () {
                    Navigator.pop(context);
                    mainState?.setSelectedIndex(1);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.explore_rounded,
                  title: 'Discover',
                  isSelected: currentIndex == 2,
                  onTap: () {
                    Navigator.pop(context);
                    mainState?.setSelectedIndex(2);
                  },
                ),
                if (isAdmin)
                  _buildDrawerItem(
                    context,
                    icon: Icons.add_circle_rounded,
                    title: 'Create',
                    isSelected: currentIndex == 3,
                    onTap: () {
                      Navigator.pop(context);
                      mainState?.setSelectedIndex(3);
                    },
                  ),
                const Divider(height: 24, indent: 16, endIndent: 16),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings_rounded,
                  title: 'Settings',
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          // Footer & Logout / Login Button
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SuperThai v1.0.0',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.5),
                  ),
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

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final primaryColor = AppTheme.primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? primaryColor : theme.iconTheme.color,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color:
                isSelected ? primaryColor : theme.textTheme.bodyLarge?.color,
          ),
        ),
        selected: isSelected,
        selectedTileColor: primaryColor.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        onTap: onTap,
      ),
    );
  }
}
