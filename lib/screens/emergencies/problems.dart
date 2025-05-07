import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/emergency_provider.dart';
import 'problem_detail.dart';

class ProblemsScreen extends StatelessWidget {
  const ProblemsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C2F41),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C2F41),
        elevation: 0,
        title: const Text(
          'All Reported Problems',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<EmergencyProvider>(
        builder: (context, provider, child) {
          final problems = provider.problemReports;
          if (problems.isEmpty) {
            return const Center(
              child: Text('No problems reported.', style: TextStyle(color: Colors.white70)),
            );
          }
          return ListView.builder(
            itemCount: problems.length,
            itemBuilder: (context, index) {
              final report = problems[index];
              return Card(
                color: const Color(0xFF181B2C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  title: Text(report.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(report.description, style: const TextStyle(color: Colors.white70)),
                  trailing: Chip(
                    label: Text(report.status, style: const TextStyle(color: Colors.white)),
                    backgroundColor: Colors.blueGrey,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProblemDetailScreen(report: report),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
} 