import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../data/user_profile_repository.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _profiles = UserProfileRepository();

  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.w400,
    ),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.2),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Colors.green, width: 2),
    ),
  );

  Future<void> _signUp() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      final user = userCredential.user;
      if (user == null) {
        throw FirebaseException(
          plugin: 'firebase_auth',
          code: 'missing-user',
          message: 'Account was created without a user session.',
        );
      }

      await _profiles.createProfile(user: user, name: _nameController.text);

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_signUpMessage(e.code))));
      }
    } on FirebaseException catch (e) {
      // The Auth user may already exist even if the profile write failed.
      // Signing out avoids presenting a half-initialized authenticated screen;
      // logging in again will safely retry profile synchronization.
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'অ্যাকাউন্ট তৈরি হয়েছে, কিন্তু প্রোফাইল sync হয়নি (${e.code})। '
              'Rules ঠিক করে Login করুন।',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _signUpMessage(String code) {
    return switch (code) {
      'email-already-in-use' => 'এই ইমেইল দিয়ে আগে থেকেই অ্যাকাউন্ট আছে।',
      'invalid-email' => 'সঠিক ইমেইল ঠিকানা লিখুন।',
      'weak-password' => 'আরও শক্তিশালী পাসওয়ার্ড ব্যবহার করুন।',
      'operation-not-allowed' =>
        'Firebase Authentication-এ Email/Password চালু করুন।',
      'network-request-failed' => 'ইন্টারনেট সংযোগ পরীক্ষা করুন।',
      _ => 'অ্যাকাউন্ট তৈরি করা যায়নি। আবার চেষ্টা করুন।',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/banner.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.black),
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    decoration: _inputDecoration('Full Name'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'আপনার নাম লিখুন।'
                        : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.black),
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: _inputDecoration('Email'),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) return 'ইমেইল লিখুন।';
                      if (!email.contains('@') || !email.contains('.')) {
                        return 'সঠিক ইমেইল ঠিকানা লিখুন।';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    enableSuggestions: false,
                    autocorrect: false,
                    style: const TextStyle(color: Colors.black),
                    autofillHints: const [AutofillHints.newPassword],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _signUp(),
                    decoration: _inputDecoration('Password').copyWith(
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                        ),
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'পাসওয়ার্ড লিখুন।'
                        : value.length < 8
                        ? 'পাসওয়ার্ড কমপক্ষে ৮ অক্ষরের হতে হবে।'
                        : null,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _signUp,
                    child: _isSubmitting
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : const Text('Create account'),
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
