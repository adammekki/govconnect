import 'package:flutter/material.dart';

class AnnouncementsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Announcements'),
      ),
      body: Center(
        child: Text(
          'Hello from Announcements',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}