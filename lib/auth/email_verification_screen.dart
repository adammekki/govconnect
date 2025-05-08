import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({Key? key}) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  int _countdownSeconds = 60;
  Timer? _timer;
  bool _canResend = false;
  bool _isEmailVerified = false;

  @override
  void initState() {
    super.initState();
    _sendVerificationEmail();
    _checkEmailVerification();
    _startCountdown();
  }

  void _sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send verification email. Please try again.'),
          backgroundColor: Colors.red,
        )
      );
    } finally {
      setState(() {
        _isEmailVerified = false;
      });
    }
  }

  void _checkEmailVerification() {
    Timer.periodic(Duration(seconds: 3), (timer) async {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if(user?.emailVerified == true){
        setState(() {
          _isEmailVerified = true;
        });

        timer.cancel();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully!'),
            backgroundColor: Colors.green,
          )
        );

        Future.delayed(Duration(seconds: 2), () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false
            );
          }
        );
      }
    });
  }



  void _startCountdown() {
    setState(() {
      _countdownSeconds = 60;
      _canResend = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdownSeconds > 0) {
          _countdownSeconds--;
        } else {
          _timer?.cancel();
          _canResend = true;
        }
      });
    });
  }

  void _resendCode() {
    if (_canResend) {
      _sendVerificationEmail();
      _startCountdown();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C2F41),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Dark blue header section
          Container(
            height: 120,
            color: const Color(0xFF1C2F41),
            alignment: Alignment.center,
            child: Column(
              children: [
                const Icon(
                  Icons.account_balance,
                  size: 40,
                  color: Colors.white,
                ),
                const SizedBox(height: 5),
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
          
          // Light blue section with verification UI
          Expanded(
            child: Container(
              color: const Color(0xFF496A81),
              width: double.infinity,
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Container(
                    width: 150,
                    height: 150,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.mark_email_read,  // Or any other appropriate icon
                        size: 70,
                        color: Color(0xFF1C2F41),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Confirm Your Email',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Text(
                      'Please click the verification link we sent to your email.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Resend button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: TextButton(
                      onPressed: _canResend ? _resendCode : null,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        _canResend 
                            ? 'Resend verification email' 
                            : 'Resend in $_countdownSeconds s',
                        style: TextStyle(
                          color: _canResend 
                              ? Colors.white
                              : Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Verify button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                    child: ElevatedButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.currentUser?.reload();
                        final isVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;

                        if(isVerified) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Email not verified. Please check your inbox.'),
                            )
                          );
                        }
                      },
                      child: const Text('I have verified my email'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}