import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:superthai/core/services/auth_service.dart';
import 'package:superthai/core/services/theme_service.dart';
import 'package:superthai/ui/screens/main_container.dart';
import 'package:superthai/ui/theme/app_theme.dart';

class SuperThaiApp extends StatelessWidget {
  const SuperThaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, theme, _) {
        return MaterialApp(
          title: 'SuperThai',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getLightTheme(theme.primaryColor),
          darkTheme: AppTheme.getDarkTheme(theme.primaryColor),
          themeMode: theme.themeMode,
          home: StreamBuilder<User?>(
            stream: context.read<AuthService>().userChanges,
            builder: (context, snapshot) => const MainContainer(),
          ),
        );
      },
    );
  }
}
