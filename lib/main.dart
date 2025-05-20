import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:govconnect/models/problem_report.dart';
//providers
import 'package:provider/provider.dart';
import 'package:govconnect/providers/emergency_provider.dart';
import 'package:govconnect/providers/notification_provider.dart';
import 'package:govconnect/providers/problem_report_provider.dart';
import 'providers/announcementProvider.dart';
import 'package:govconnect/providers/AdProvider.dart';
import 'package:govconnect/providers/PollProvider.dart';

//auth
import 'package:govconnect/auth/login_screen.dart';
import 'package:govconnect/auth/signup_screen.dart';
import 'package:govconnect/auth/login_success_screen.dart';
import 'package:govconnect/auth/email_verification_screen.dart';
import 'package:govconnect/auth/auth_page.dart';

//screens
import 'package:govconnect/homePage_screen.dart';
import 'package:govconnect/screens/profile_screen.dart';
import 'package:govconnect/screens/edit_profile_screen.dart';
import 'package:govconnect/screens/settings.dart';

import 'package:govconnect/screens/advertisements/file.dart';
import 'package:govconnect/screens/announcements/file.dart';
import 'package:govconnect/screens/communication/chat/chatGrid.dart';
import 'package:govconnect/screens/communication/chat/chatProvider.dart';
import 'package:govconnect/screens/emergencies/emergency.dart';
import 'package:govconnect/screens/problems/problem_detail.dart';
import 'package:govconnect/screens/problems/problems.dart';
import 'package:govconnect/screens/problems/report_problem.dart';
import 'package:govconnect/screens/notifications/notifications_screen.dart';
import 'package:govconnect/Polls/AddPollScreen.dart';
import 'package:govconnect/Polls/DisplayPoll.dart';
import 'package:govconnect/screens/Feed/FeedScreen.dart';
import 'package:govconnect/screens/advertisements/AdsReview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => AnnouncementsProvider()),
        ChangeNotifierProvider(create: (ctx) => AdProvider()),
        ChangeNotifierProvider(create: (ctx) => ChatProvider()..init()),
        ChangeNotifierProvider(create: (_) => EmergencyProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ProblemReportProvider()),
        ChangeNotifierProvider(create: (ctx) => Pollproviders()),
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
      initialRoute: '/feed',
      routes: {
        '/auth': (context) => const AuthPage(),
        '/signup': (context) => SignupScreen(),
        '/email_verification': (context) => EmailVerificationScreen(),
        '/login': (context) => LoginScreen(),
        '/login_success': (context) => const LoginSuccessScreen(),
        '/home': (context) => HomePage(title: 'GovConnect'),
        '/chat': (context) => const ChatGrid(),
        '/emergencyContacts': (context) => EmergencyContactsScreen(),
        '/reportProblem': (context) => ReportProblemScreen(),
        '/problems': (context) => ProblemsScreen(),
        '/problemDetail': (context) => ProblemDetailScreen(
         report: ModalRoute.of(context)!.settings.arguments as ProblemReport,
         ),
        '/announcements': (context) => AnnouncementsScreen(),
        '/polls': (context) =>  DisplayPoll(),
        '/addPoll': (context) => Addpollscreen(),
        '/feed': (context) => FeedScreen(),
        '/adReview': (context) => AdReviewScreen(),
        '/notifications': (context) => NotificationsScreen(),
        '/advertisements': (context) =>  AdvertisementsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/editProfile': (context) => const EditProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
