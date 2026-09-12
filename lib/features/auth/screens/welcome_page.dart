import 'package:flutter/material.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'home_page.dart';

class WelcomePage extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback toggleTheme;

  const WelcomePage({
    super.key,
    required this.isDarkMode,
    required this.toggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/banner.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withValues(alpha: 0.6)),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "আমি নাযিল করছি এমন কোরআন,\nযা মুমিনদের পক্ষে শেফা ও রহমত।\n\nসূরাঃ ১৭ আয়াত ৮২",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    ),
                    child: const Text("Login"),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpPage()),
                    ),
                    child: const Text("Sign Up"),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomePage(
                        isDarkMode: isDarkMode,
                        toggleTheme: toggleTheme,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.home, color: Colors.white70),
                  label: const Text(
                    "Skip to Home",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
