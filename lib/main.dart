import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:screen_security/screen_security.dart';

import 'firebase_options.dart';
import 'core/app_colors.dart';
import 'core/utils/seed_firestore.dart';
import 'features/auth/screens/home_page.dart';
import 'features/auth/screens/welcome_page.dart';
import 'utils/seed_mom_child_care.dart';

const bool _seedFirestore = bool.fromEnvironment('SEED_FIRESTORE');
const bool _mergeExistingSeedData = bool.fromEnvironment(
  'MERGE_EXISTING_SEED_DATA',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    runApp(_BootstrapErrorApp(error: error));
    return;
  }

  // Screen-protection support differs by platform. A plugin failure must not
  // prevent authentication or the rest of the app from opening.
  try {
    await ScreenSecurity().disable();
  } catch (error) {
    debugPrint('Screen security initialization skipped: $error');
  }

  runApp(const MyApp());

  // Production builds never seed automatically. Run explicitly with:
  // flutter run --dart-define=SEED_FIRESTORE=true
  // The signed-in account must also be listed in app_admins/{uid}.
  if (_seedFirestore) {
    unawaited(_seedFirestoreInBackground());
  }
}

Future<void> _seedFirestoreInBackground() async {
  try {
    final user = await FirebaseAuth.instance.authStateChanges().firstWhere(
      (candidate) => candidate != null,
    );

    final admin = await FirebaseFirestore.instance
        .collection('app_admins')
        .doc(user!.uid)
        .get();

    if (admin.data()?['enabled'] != true) {
      debugPrint(
        'Firestore seed skipped: app_admins/${user.uid} is not enabled.',
      );
      return;
    }
  } catch (error) {
    debugPrint('Firestore seed authorization failed: $error');
    return;
  }

  try {
    await seedMomChildCareFullVersion(mergeExisting: _mergeExistingSeedData);
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
      home: _AuthGate(isDarkMode: isDarkMode, toggleTheme: toggleTheme),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate({required this.isDarkMode, required this.toggleTheme});

  final bool isDarkMode;
  final VoidCallback toggleTheme;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return HomePage(isDarkMode: isDarkMode, toggleTheme: toggleTheme);
        }

        return WelcomePage(isDarkMode: isDarkMode, toggleTheme: toggleTheme);
      },
    );
  }
}

class _BootstrapErrorApp extends StatelessWidget {
  const _BootstrapErrorApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 52,
                    color: Colors.amberAccent,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Firebase চালু করা যায়নি',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'ইন্টারনেট সংযোগ ও Firebase configuration পরীক্ষা করে '
                    'অ্যাপটি আবার চালু করুন।',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
