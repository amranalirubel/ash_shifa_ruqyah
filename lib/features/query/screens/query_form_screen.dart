import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';

class QueryFormScreen extends StatefulWidget {
  const QueryFormScreen({super.key});

  @override
  State<QueryFormScreen> createState() => _QueryFormScreenState();
}

class _QueryFormScreenState extends State<QueryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final professionController = TextEditingController();
  final messageController = TextEditingController();

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF00ACC1), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 33, 55, 57),
      appBar: AppBar(
        title: const Text(
          "আপনার জিজ্ঞাসা",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryapp,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                "আপনার সমস্যা বা জিজ্ঞাসাটি নিচে বিস্তারিত লিখুন।",
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              TextFormField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("আপনার নাম"),
                validator: (v) => v!.isEmpty ? "নাম লিখুন" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: ageController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("আপনার বয়স"),
                validator: (v) => v!.isEmpty ? "বয়স লিখুন" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: professionController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("আপনার পেশা"),
                validator: (v) => v!.isEmpty ? "পেশা লিখুন" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: messageController,
                maxLines: 5,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("আপনার মেসেজ"),
                validator: (v) => v!.isEmpty ? "মেসেজ লিখুন" : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "আপনার মেসেজটি এডমিনের কাছে পাঠানো হয়েছে।",
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text(
                  "SEND MESSAGE",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
