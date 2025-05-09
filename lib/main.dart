import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';


import 'package:govconnect/models/problem_report.dart';
//providers
import 'package:provider/provider.dart';
import 'package:govconnect/providers/emergency_provider.dart';
import 'package:govconnect/providers/notification_provider.dart';
import 'package:govconnect/providers/problem_report_provider.dart';

//auth
import 'package:govconnect/auth/login_screen.dart';
import 'package:govconnect/auth/signup_screen.dart';
import 'package:govconnect/auth/login_success_screen.dart';
import 'package:govconnect/auth/email_verification_screen.dart';
import 'package:govconnect/auth/auth_page.dart';

//screens
import 'package:govconnect/homePage_screen.dart';
import 'package:govconnect/screens/advertisements/file.dart';
import 'package:govconnect/screens/announcements/file.dart';
import 'package:govconnect/screens/communication/chat/chatGrid.dart';
import 'package:govconnect/screens/communication/chat/chatProvider.dart';
import 'package:govconnect/screens/emergencies/emergency.dart';
import 'package:govconnect/screens/problems/problem_detail.dart';
import 'package:govconnect/screens/problems/problems.dart';
import 'package:govconnect/screens/problems/report_problem.dart';
import 'package:govconnect/screens/notifications/notifications_screen.dart';




void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('userId', 'Abdelrahman');

  runApp(
    MultiProvider(
      providers: [
        // Add your providers here
        ChangeNotifierProvider(create: (ctx) => ChatProvider()..init()),
        ChangeNotifierProvider(create: (_) => EmergencyProvider()),
        ChangeNotifierProvider( create: (_) => ProblemReportProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],

      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GovConnect',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1C2F41),
          primary: const Color(0xFF1C2F41),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1C2F41),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ),
      initialRoute: '/home',
      routes: {
        '/auth': (context) => const AuthPage(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/login_success': (context) => const LoginSuccessScreen(),
        '/email_verification': (context) => EmailVerificationScreen(),
        '/home': (context) => const HomePage(title: 'GovConnect'),
        '/chat': (context) => const ChatGrid(),
        '/emergencyContacts': (context) => EmergencyContactsScreen(),
        '/reportProblem': (context) => ReportProblemScreen(),
        '/problemDetail': (context) => ProblemDetailScreen(
         report: ModalRoute.of(context)!.settings.arguments as ProblemReport,
         ),
        '/problems': (context) => ProblemsScreen(),
        '/announcements': (context) => AnnouncementsScreen(),
        '/notifications': (context) => NotificationsScreen(),
        '/advertisements': (context) =>  AdvertisementsScreen(),
      },
    );
  }
}