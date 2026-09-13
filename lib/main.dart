import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:screen_security/screen_security.dart';

import 'firebase_options.dart';
import 'core/app_colors.dart';
import 'core/utils/seed_firestore.dart';
import 'features/auth/screens/welcome_page.dart';
import 'utils/seed_mom_child_care.dart';

//import 'package:ash_shifa_ruqyah/utils/seed_mom_child_care.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await ScreenSecurity().disable();

  // Firestore seeding runs in the background so the app can open immediately.
  // It waits for authentication, and the Mom & Child Care helper creates only
  // missing documents without overwriting or deleting existing data.
  runApp(const MyApp());
  unawaited(_seedFirestoreInBackground());
}

Future<void> _seedFirestoreInBackground() async {
  // Current Firestore rules allow app-data writes only for authenticated users.
  await FirebaseAuth.instance.authStateChanges().firstWhere(
    (user) => user != null,
  );

  // Seed Mom & Child Care first so another collection cannot delay or prevent
  // these six documents from being created.
  try {
    await seedMomChildCareFullVersion();
    debugPrint('Mom & Child Care seed completed successfully.');
  } on FirebaseException catch (e) {
    debugPrint(
      'Mom & Child Care seed failed [${e.code}]: ${e.message ?? e.toString()}',
    );
  } catch (e) {
    debugPrint('Mom & Child Care seed failed: $e');
  }

  try {
    await seedFirestoreData();
  } catch (e) {
    debugPrint('General Firestore seed failed: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = true;
  void toggleTheme() => setState(() => isDarkMode = !isDarkMode);

  @override
  void didChangeDependencies() {
    precacheImage(const AssetImage("assets/banner.png"), context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.light),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: WelcomePage(isDarkMode: isDarkMode, toggleTheme: toggleTheme),
    );
  }
}
