import 'package:flutter/material.dart';

class EmergenciesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emergencies'),
      ),
      body: Center(
        child: Text(
          'Hello from emergencies',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}