import 'package:flutter/material.dart';

class DummyProvider with ChangeNotifier {
  String _dummyData = "Initial Dummy Data";

  String get dummyData => _dummyData;

  void updateDummyData(String newData) {
    _dummyData = newData;
    notifyListeners();
  }
}