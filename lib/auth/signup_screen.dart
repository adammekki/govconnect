import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final fullNameController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneNumberController = TextEditingController();
  String roleValue = 'citizen'; // Default role
  var hidePass = true;

  void createUser() async {
    try {

      if (emailController.text.isEmpty ||
        fullNameController.text.isEmpty ||
        phoneNumberController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      showErrorMessage('Please fill in all fields');
      return;
    }

      if (passwordController.text == confirmPasswordController.text) {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: emailController.text,
              password: passwordController.text,
            );

        if (userCredential.user != null) {
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(userCredential.user?.uid)
              .set({
                'email': emailController.text,
                'fullName': fullNameController.text,
                'role': roleValue, // We'll add this dropdown
                'phoneNumber':
                    phoneNumberController.text, // We'll add this field
                'isVerified': false, // Initially false until email is verified
                'createdAt': FieldValue.serverTimestamp(),
              });

          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/email_verification',
              (route) => false,
            );
          }
        }
      } else {
        showErrorMessage('Passwords do not match');
      }
    } on FirebaseAuthException catch (e) {
      showErrorMessage(e.code);
    }
  }

  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C2F41),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.account_balance,
                      size: 60,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'GovConnect',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Email field
              const Text('Email', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  filled: true,
                  fillColor: Colors.white,
                ),
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // Full Name field
              const Text('Full Name', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Enter your full name',
                  filled: true,
                  fillColor: Colors.white,
                ),
                controller: fullNameController,
              ),
              const SizedBox(height: 20),

              // Phone Number field (new)
              const Text('Phone Number', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: '+201234567890',
                  filled: true,
                  fillColor: Colors.white,
                ),
                controller: phoneNumberController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),

              // Role selector (new)
              const Text('I am a', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: roleValue,
                    items: const [
                      DropdownMenuItem(
                        value: 'citizen',
                        child: Text('Citizen'),
                      ),
                      DropdownMenuItem(
                        value: 'government',
                        child: Text('Government Official'),
                      ),
                      DropdownMenuItem(
                        value: 'advertiser',
                        child: Text('Advertiser'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        roleValue = value!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Password field
              const Text('Password', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: Icon(
                      hidePass ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        hidePass = !hidePass;
                      });
                    },
                  ),
                ),
                controller: passwordController,
                obscureText: hidePass,
              ),
              const SizedBox(height: 20),

              // Confirm Password field
              const Text(
                'Confirm Password',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Confirm your password',
                  filled: true,
                  fillColor: Colors.white,
                ),
                controller: confirmPasswordController,
                obscureText: hidePass,
              ),
              const SizedBox(height: 40),

              // Sign Up button
              ElevatedButton(
                onPressed: createUser,
                child: const Text('Sign up'),
              ),
              const SizedBox(height: 20),

              // Already have account
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: Colors.white70),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Sign in',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
