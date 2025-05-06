import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'PollProvider.dart'; // Corrected import

class DisplayPoll extends StatelessWidget {
  const DisplayPoll({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Provider.of<Pollproviders>(context, listen: false).fetchPolls(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final polls = Provider.of<Pollproviders>(context).getPolls;

        if (polls.isEmpty) {
          return const Center(
            child: Text('No polls available. Add a poll to get started!'),
          );
        }

        return ListView.builder(
          itemCount: polls.length,
          itemBuilder: (context, index) {
            final poll = polls[index];
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(poll.question),
                subtitle: Text('Created by: ${poll.createdBy}'),
                trailing: Text(
                  '${poll.createdAt.day}/${poll.createdAt.month}/${poll.createdAt.year}',
                ),
              ),
            );
          },
        );
      },
    );
  }
}
