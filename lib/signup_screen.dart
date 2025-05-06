import 'package:flutter/material.dart';
import 'email_verification_screen.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({Key? key}) : super(key: key);

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
      body: Padding(
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
            const Text(
              'Email',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            const TextField(
              decoration: InputDecoration(
                hintText: 'Enter your email',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),

            // Full Name field
            const Text(
              'Full Name',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            const TextField(
              decoration: InputDecoration(
                hintText: 'Enter your full name',
              ),
            ),
            const SizedBox(height: 20),

            // Password field
            const Text(
              'Password',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'Enter your password',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.visibility_off),
                  onPressed: () {},
                ),
              ),
              obscureText: true,
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
                hintText: 'Enter your password',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.visibility_off),
                  onPressed: () {},
                ),
              ),
              obscureText: true,
            ),

            const Spacer(),

            // Sign Up button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EmailVerificationScreen()),
                );
              },
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
                      'Sign up',
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
    );
  }
}