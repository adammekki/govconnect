import 'package:flutter/material.dart';
import 'dart:async';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({Key? key}) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  int _countdownSeconds = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
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
      // Here you would add the actual code to resend the verification email
      // For now, we'll just restart the countdown
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
                      child: Image.asset(
                        'assets/images/verification_illustration.png',
                        width: 90,
                        height: 90,
                        // If you don't have this image, use an icon instead
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.email_outlined,
                            size: 70,
                            color: Color(0xFF1C2F41),
                          );
                        },
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
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'We\'ve sent a 5 digits verification code to maryjohnson1203@gmail.com',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Email section
                  const Text(
                    'Email',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // OTP input field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: TextField(
                      controller: _otpController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: '59382',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: TextButton(
                          onPressed: _canResend ? _resendCode : null,
                          child: Text(
                            _canResend 
                                ? 'Resend' 
                                : 'Resend in $_countdownSeconds s',
                            style: TextStyle(
                              color: _canResend 
                                  ? const Color(0xFF1C2F41)
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Verify button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text('Verify and Create Account'),
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
    _otpController.dispose();
    super.dispose();
  }
}