import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'email_verification_screen.dart';
import 'package:govconnect/homePage_screen.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // User is logged in
          if (snapshot.hasData) {
            var user = snapshot.data!;
            
            // Check if email is verified (if you're using email verification)
            // If not verified AND is a new user, show verification screen
            if (!user.emailVerified) {
              return EmailVerificationScreen();
            }
            
            // Otherwise show logged in screen
            return const HomePage(title: 'GovConnect');
          } else {
            // User is not logged in
            return LoginScreen();
          }
        },
      )
    );
  }
}