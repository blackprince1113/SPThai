import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:superthai/app/app.dart';
import 'package:superthai/app/providers.dart';
import 'package:superthai/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(AppProviders(child: const SuperThaiApp()));
}
