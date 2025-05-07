import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';
import '../models/problem_report.dart';
import '../models/emergency_contact.dart';

class EmergencyProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  List<ProblemReport> _problemReports = [];
  List<EmergencyContact> _emergencyContacts = [];
  bool _isAdmin = false;

  List<ProblemReport> get problemReports => _problemReports;
  List<EmergencyContact> get emergencyContacts => _emergencyContacts;
  bool get isAdmin => _isAdmin;

  Future<void> initialize() async {
    // Request notification permissions
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    String? token = await _messaging.getToken();
    if (token != null) {
      await _firestore.collection('users').doc('current_user_id').update({
        'fcmToken': token,
      });
    }

    // Listen for new problem reports
    _firestore
        .collection('problem_reports')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _problemReports = snapshot.docs.map((doc) => ProblemReport.fromFirestore(doc)).toList();
      notifyListeners();
    });

    // Check if user is admin
    final userDoc = await _firestore.collection('users').doc('current_user_id').get();
    _isAdmin = userDoc.data()?['role'] == 'government';
    notifyListeners();
  }

  Future<void> submitProblemReport({
    required String userId,
    required String title,
    required String description,
    required File? image,
    required GeoPoint location,
  }) async {
    try {
      String? imageUrl;
      if (image != null) {
        final ref = _storage.ref().child('problem_reports/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(image);
        imageUrl = await ref.getDownloadURL();
      }

      final report = ProblemReport(
        id: '',
        userId: userId,
        title: title,
        description: description,
        imageUrl: imageUrl,
        location: location,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await _firestore.collection('problem_reports').add(report.toMap());
      
      // Send notification to admin
      await _sendNotificationToAdmin(
        title: 'New Problem Report',
        body: 'A new problem has been reported: $title',
      );
    } catch (e) {
      throw Exception('Failed to submit problem report: $e');
    }
  }

  Future<void> _sendNotificationToAdmin({
    required String title,
    required String body,
  }) async {
    try {
      // Get admin's FCM token
      final adminDoc = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'government')
          .limit(1)
          .get();

      if (adminDoc.docs.isNotEmpty) {
        final adminToken = adminDoc.docs.first.data()['fcmToken'];
        if (adminToken != null) {
          // Send notification using Firebase Cloud Functions
          await _firestore.collection('notifications').add({
            'token': adminToken,
            'title': title,
            'body': body,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  Future<void> fetchProblemReports() async {
    try {
      final snapshot = await _firestore
          .collection('problem_reports')
          .orderBy('createdAt', descending: true)
          .get();
      _problemReports = snapshot.docs.map((doc) => ProblemReport.fromFirestore(doc)).toList();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to fetch problem reports: $e');
    }
  }

  Future<void> fetchEmergencyContacts() async {
    try {
      final snapshot = await _firestore.collection('emergency_contacts').get();
      _emergencyContacts = snapshot.docs.map((doc) => EmergencyContact.fromMap(doc.id, doc.data())).toList();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to fetch emergency contacts: $e');
    }
  }

  Future<void> updateProblemStatus(String reportId, String newStatus) async {
    try {
      await _firestore.collection('problem_reports').doc(reportId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Send notification to the user who reported the problem
      final report = _problemReports.firstWhere((r) => r.id == reportId);
      await _sendNotificationToUser(
        userId: report.userId,
        title: 'Problem Status Updated',
        body: 'Your reported problem "${report.title}" is now $newStatus',
      );
    } catch (e) {
      throw Exception('Failed to update problem status: $e');
    }
  }

  Future<void> _sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userToken = userDoc.data()?['fcmToken'];
      if (userToken != null) {
        await _firestore.collection('notifications').add({
          'token': userToken,
          'title': title,
          'body': body,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error sending notification to user: $e');
    }
  }
} 