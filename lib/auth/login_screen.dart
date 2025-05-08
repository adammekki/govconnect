import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();

  final passwordController = TextEditingController();
  var hidePass = true;

  void signUserIn() async {
    try{
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: emailController.text,
      password: passwordController.text,
      );

      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
    
      // Check verification status and navigate accordingly
      if (user != null) {
        if (user.emailVerified) {
          // User is verified, navigate to success screen
          Navigator.pushNamedAndRemoveUntil(
            context, 
            '/login_success', 
            (route) => false
          );
        } else {
          // User is not verified, navigate to verification screen
          Navigator.pushNamedAndRemoveUntil(
            context, 
            '/email_verification', 
            (route) => false
          );
        }
      }

    } on FirebaseAuthException catch (e) {
      showErrorMessage(e.code);
    }
  }

  void showErrorMessage(String message){
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
          onPressed: () {},
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo
            const SizedBox(height: 20),
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
            const SizedBox(height: 60),

            // Email field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Email',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Enter your email',
                  ),
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Password field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      onPressed: () {
                        setState( () {
                          hidePass = !hidePass;
                        });
                      },
                    ),
                  ), 
                  controller: passwordController,
                  obscureText: hidePass,
                ),
              ],
            ),
            
            const Spacer(),
            
            // Sign In button
            ElevatedButton(
              onPressed: signUserIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1C2F41),
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
              ),
              child: const Text('Sign In'),
            ),
            const SizedBox(height: 20),
            
            // Don't have account
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Don\'t have an account? ',
                  style: TextStyle(color: Colors.white70),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignupScreen()),
                    );
                  },
                  child: const Text(
                    'Create Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}