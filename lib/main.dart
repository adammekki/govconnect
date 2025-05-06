import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Polls/PollProvider.dart';
import 'Polls/AddPollScreen.dart';
import 'Polls/DisplayPoll.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(
    ChangeNotifierProvider(
      create: (context) => Pollproviders(),
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(),
      routes: {'/addPoll': (context) => const Addpollscreen()},
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Polls')),
      body: const DisplayPoll(), // Display the list of polls
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/addPoll'); // Navigate to AddPollScreen
        },
        tooltip: 'Add Poll',
        child: const Icon(Icons.add),
      ),
    );
  }
}
