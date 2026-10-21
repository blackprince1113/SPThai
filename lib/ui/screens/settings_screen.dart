import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:superthai/core/services/theme_service.dart';
import 'package:superthai/core/services/auth_service.dart';
import 'package:superthai/ui/theme/app_theme.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';

import 'package:superthai/ui/screens/login_screen.dart';
import 'package:superthai/ui/screens/edit_profile_screen.dart';
import 'package:superthai/features/lessons/presentation/screens/manage_lessons_screen.dart';
import 'package:superthai/ui/screens/add_admin_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        final user = AuthService.instance.currentUser;
        final isGuest = user == null;
        final name = user?.displayName;
        final email = user?.email;
        final isAdmin = AuthService.instance.isAdmin;
        final role =
            AuthService.instance.role ?? (isGuest ? "Trial" : "Member");

        return Scaffold(
          appBar: const ThaiAppBar(
            title: "Settings",
            showProfile: false,
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(context, name, email, role, isGuest),
                  const SizedBox(height: 32),

                  if (isAdmin) ...[
                    _buildSectionTitle(context, "Admin Management"),
                    ThaiSettingsGroup(children: [
                      ThaiSettingsTile(
                        icon: Icons.reorder_rounded,
                        title: "Manage Lesson Order",
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ManageLessonsScreen(),
                            ),
                          );
                        },
                      ),
                      ThaiSettingsTile(
                        icon: Icons.admin_panel_settings_rounded,
                        title: "Add New Admin",
                        color: Colors.deepPurple,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddAdminScreen(),
                            ),
                          );
                        },
                      ),
                    ]),
                    const SizedBox(height: 32),
                  ],

                  _buildSectionTitle(context, "General"),
                  ThaiSettingsGroup(children: [
                    ThaiSettingsTile(
                      icon: Icons.person_outline_rounded,
                      title: "Edit Profile",
                      color: Colors.blue,
                      onTap: isGuest
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EditProfileScreen(),
                                ),
                              );
                            },
                    ),
                  ]),
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, "Appearance"),
                  ThaiSettingsGroup(children: [
                    Consumer<ThemeService>(
                      builder: (context, theme, _) {
                        return ThaiSettingsTile(
                          icon: Icons.dark_mode_outlined,
                          title: "Dark Mode",
                          color: Colors.indigo,
                          isSwitch: true,
                          switchValue: theme.isDarkMode,
                          onSwitchChanged: (val) => theme.toggleTheme(val),
                        );
                      },
                    ),
                    Consumer<ThemeService>(
                      builder: (context, theme, _) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.palette_outlined, color: theme.primaryColor, size: 22),
                                  ),
                                  const SizedBox(width: 16),
                                  const Expanded(
                                    child: Text(
                                      "Theme Color",
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 45,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    _buildColorOption(context, theme, const Color(0xFFFF9800)),
                                    _buildColorOption(context, theme, Colors.blue),
                                    _buildColorOption(context, theme, Colors.teal),
                                    _buildColorOption(context, theme, Colors.pink),
                                    _buildColorOption(context, theme, Colors.purple),
                                    _buildColorOption(context, theme, Colors.green),
                                    _buildColorOption(context, theme, Colors.red),
                                    _buildColorOption(context, theme, Colors.indigo),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ]),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
                        if (isGuest) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        } else {
                          AuthService.instance.logout();
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor:
                            (isGuest ? Theme.of(context).primaryColor : Colors.red)
                                .withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      icon: Icon(
                        isGuest ? Icons.login_rounded : Icons.logout_rounded,
                        color: isGuest ? Theme.of(context).primaryColor : Colors.red,
                      ),
                      label: Text(
                        isGuest ? "Login / Sign Up" : "Logout",
                        style: TextStyle(
                          color: isGuest ? Theme.of(context).primaryColor : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, snapshot) {
                        final version = snapshot.data?.version ?? "1.2.8";
                        final buildNumber = snapshot.data?.buildNumber;
                        final buildText = (buildNumber != null && buildNumber.isNotEmpty)
                            ? " (Build $buildNumber)"
                            : "";
                        return Text(
                          "Version $version$buildText",
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    String? name,
    String? email,
    String role,
    bool isGuest,
  ) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isAdmin = role.toLowerCase() == 'admin';
    final hasName = name != null && name.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.light ? 0.05 : 0.2,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isAdmin ? Colors.deepPurple : primaryColor,
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: isGuest
                  ? primaryColor.withValues(alpha: 0.15)
                  : (isAdmin ? Colors.deepPurple : primaryColor).withValues(
                      alpha: 0.15,
                    ),
              child: Icon(
                isGuest
                    ? Icons.person_outline
                    : (isAdmin ? Icons.shield_rounded : Icons.person_rounded),
                size: 40,
                color: isAdmin ? Colors.deepPurple : primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isGuest ? "Welcome!" : "Sawatdee!",
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        theme.textTheme.bodySmall?.color ??
                        AppTheme.lightTextColor,
                  ),
                ),
                Text(
                  hasName ? name : (email ?? "Guest User"),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (isAdmin ? Colors.deepPurple : primaryColor)
                        .withValues(
                          alpha: theme.brightness == Brightness.light
                              ? 0.1
                              : 0.2,
                        ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: TextStyle(
                      color: isAdmin ? Colors.deepPurple : primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildColorOption(BuildContext context, ThemeService theme, Color color) {
    final isSelected = theme.primaryColor.toARGB32() == color.toARGB32();
    return GestureDetector(
      onTap: () => theme.setPrimaryColor(color),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).textTheme.bodyLarge?.color ??
                      Colors.black,
                  width: 3,
                )
              : Border.all(
                  color: Colors.black.withValues(alpha: 0.05),
                  width: 1,
                ),
        ),
        child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
      ),
    );
  }
}
