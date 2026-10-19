import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:superthai/core/services/auth_service.dart';
import 'package:superthai/core/services/data_service.dart';
import 'package:superthai/core/services/progress_service.dart';
import 'package:superthai/core/services/theme_service.dart';

class AppProviders extends StatelessWidget {
  final Widget child;

  const AppProviders({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: AuthService.instance),
        ChangeNotifierProvider<ProgressService>.value(
          value: ProgressService.instance,
        ),
        ChangeNotifierProvider<ThemeService>.value(
          value: ThemeService.instance,
        ),
        ChangeNotifierProvider<DataService>.value(value: DataService.instance),
      ],
      child: child,
    );
  }
}
