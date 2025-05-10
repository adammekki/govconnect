import 'package:flutter/material.dart';
import 'package:govconnect/Polls/Polls.dart';
import 'package:provider/provider.dart';
import 'PollProvider.dart';
import 'PollCard.dart';

class DisplayPoll extends StatefulWidget {
  const DisplayPoll({super.key});

  @override
  State<DisplayPoll> createState() => _DisplayPollState();
}

class _DisplayPollState extends State<DisplayPoll> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1621),
      appBar: AppBar(
        title: const Text('Polls'),
        backgroundColor: const Color(0xFF121C2A),
      ),
      body: FutureBuilder(
        future: Provider.of<Pollproviders>(context, listen: false).fetchPolls(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final polls = Provider.of<Pollproviders>(context).getPolls;

          if (polls.isEmpty) {
            return const Center(
              child: Text(
                'No polls available. Add a poll to get started!',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            itemCount: polls.length,
            itemBuilder: (context, index) {
              final poll = polls[index];
              return Pollcard(poll: poll);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/addPoll');
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}
class PollItem extends StatelessWidget {
  final Polls poll;

  const PollItem({super.key, required this.poll});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              poll.question,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...poll.options.map((option) {
              return ListTile(title: Text(option));
            }).toList(),
            const SizedBox(height: 8),
            Text(
              'Created by: ${poll.createdBy}', // Display the full name of the creator
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              'Created on: ${poll.createdAt.day}/${poll.createdAt.month}/${poll.createdAt.year}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
