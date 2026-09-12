import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/utils/seed_firestore.dart';
import 'firebase_options.dart';
import 'core/app_colors.dart';
import 'features/auth/screens/welcome_page.dart';
import 'package:screen_security/screen_security.dart';

//import 'package:ash_shifa_ruqyah/utils/seed_mom_child_care.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await ScreenSecurity().disable();

  // Firestore seeding is intentionally disabled here because the current Firebase
  // project does not have a Firestore database configured yet.
  // Re-enable this only after the project is initialized.

  // ✅ Mom & Child Care fullVersion 11 Aug
  // সমস্যা সমাধান + প্যারেন্টিং গাইড Firebase-এ upload করবে
  // try {
  //    await seedMomChildCareFullVersion();
  //  } catch (e) {
  //    debugPrint('Mom & Child Care seed failed: $e');
  //  }

  runApp(const MyApp());
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
