import 'package:flutter/material.dart';

class AdvertisementsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Advertisements'),
      ),
      body: Center(
        child: Text(
          'Hello from advertisements',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}