import 'package:flutter/material.dart';

class CommunicationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Communication'),
      ),
      body: Center(
        child: Text(
          'Hello from Communication',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}