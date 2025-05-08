import 'package:flutter/material.dart';
import 'package:govconnect/providers/emergency_provider.dart';
import 'package:govconnect/providers/notification_provider.dart';
import 'package:govconnect/providers/problem_report_provider.dart';
import 'package:govconnect/screens/emergencies/emergency.dart';
import 'package:govconnect/screens/problems/problem_detail.dart';
import 'package:govconnect/screens/problems/problems.dart';
import 'package:govconnect/screens/problems/report_problem.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:govconnect/models/problem_report.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EmergencyProvider()),
        ChangeNotifierProvider(create: (_) => ProblemReportProvider()),
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
      home: const MyHomePage(title: 'GovConnect Home'),
      initialRoute: '/',
      routes: {
        '/emergencyContacts': (context) => EmergencyContactsScreen(),
        '/reportProblem': (context) => ReportProblemScreen(),
        '/problemDetail': (context) => ProblemDetailScreen(
              report: ModalRoute.of(context)!.settings.arguments as ProblemReport,
            ),
        '/problems': (context) => ProblemsScreen(),
      },
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
    final problemProvider = Provider.of<ProblemReportProvider>(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFF1C2F41),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C2F41),
        title: Text(widget.title),
        actions: [
          // Admin toggle button
          IconButton(
            icon: Icon(
              problemProvider.isAdmin ? Icons.admin_panel_settings : Icons.person,
              color: problemProvider.isAdmin ? Colors.green : Colors.white,
            ),
            onPressed: () {
              problemProvider.setAdminStatus(!problemProvider.isAdmin);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    problemProvider.isAdmin ? 'Admin mode enabled' : 'Admin mode disabled'
                  ),
                  backgroundColor: problemProvider.isAdmin ? Colors.green : Colors.grey,
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/emergencyContacts');
              },
              child: const Text('Go to Emergency Contacts'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/reportProblem');
              },
              child: const Text('Go to Report Problem'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/problems');
              },
              child: const Text('Go to Problems List'),
            ),
          ],
        ),
      ),
    );
  }
}