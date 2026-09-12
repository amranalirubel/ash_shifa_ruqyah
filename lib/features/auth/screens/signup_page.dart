import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController(); // Phone → Email
  final passwordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      // Firestore-এ ইউজারের নাম সেভ করা
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'name': nameController.text.trim(),
            'email': emailController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = e.code == 'email-already-in-use'
          ? 'এই ইমেইলটি আগেই আছে'
          : e.message ?? 'কিছু সমস্যা হয়েছে';

      // Wrapped the statement below in a block
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
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
                    controller: nameController,
                    style: const TextStyle(color: Colors.black),
                    decoration: _inputDecoration("Full Name"),
                    validator: (v) =>
                        v == null || v.isEmpty ? "Enter your name" : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.black),
                    decoration: _inputDecoration("Email"), // Phone → Email
                    validator: (v) =>
                        v == null || v.isEmpty ? "Enter email" : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.black),
                    decoration: _inputDecoration("Password"),
                    validator: (v) => v == null || v.isEmpty
                        ? "Enter password"
                        : v.length < 6
                        ? "Password must be 6+ characters"
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
                    onPressed: _signUp,
                    child: const Text("Submit"),
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
