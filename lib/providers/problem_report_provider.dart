import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../models/problem_report.dart';

class ProblemReportProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<ProblemReport> _problemReports = [];
  bool _isGovernment = false;
  String? _currentUserId;
  String? _userRole;

  List<ProblemReport> get problemReports => _problemReports;
  bool get isGovernment => _isGovernment;
  String? get currentUserId => _currentUserId;
  String? get userRole => _userRole;

  /// Initializes problem reports listener and checks user role
  Future<void> initialize() async {
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        _currentUserId = user.uid;
        // Get user role from Firestore
        final userDoc = await _firestore.collection('Users').doc(user.uid).get();
        if (userDoc.exists) {
          _userRole = userDoc.data()?['role'];
          _isGovernment = _userRole == 'government';
          
          // Set up problem reports listener based on role
          _setupProblemReportsListener();
          notifyListeners();
        } else {
          print('User document does not exist in Firestore');
        }
      } else {
        _currentUserId = null;
        _userRole = null;
        _isGovernment = false;
        _problemReports = [];
        notifyListeners();
      }
    });
  }

  void _setupProblemReportsListener() {
    Query query;
    if (_isGovernment) {
      // Government officials can see all reports
      query = _firestore.collection('problem_reports').orderBy('createdAt', descending: true);
    } else {
      // Citizens can only see their own reports
      query = _firestore.collection('problem_reports')
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('createdAt', descending: true);
    }

    query.snapshots().listen((snapshot) {
      _problemReports = snapshot.docs.map((doc) => ProblemReport.fromFirestore(doc)).toList();
      notifyListeners();
    });
  }

  /// Submits a new problem report to Firestore with optional image
  Future<void> submitProblemReport({
    required String title,
    required String description,
    required File? image,
    required GeoPoint location,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User must be logged in to submit a report');
      }

      String? imageUrl;
      if (image != null) {
        final ref = _storage.ref().child('problem_reports/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(image);
        imageUrl = await ref.getDownloadURL();
      }

      final report = ProblemReport(
        id: '',
        userId: _currentUserId!,
        title: title,
        description: description,
        imageUrl: imageUrl,
        location: location,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await _firestore.collection('problem_reports').add(report.toMap());
    } catch (e) {
      throw Exception('Failed to submit problem report: $e');
    }
  }

  /// Updates the status of a problem report (government only)
  Future<void> updateProblemStatus(String reportId, String newStatus) async {
    try {
      if (!_isGovernment) {
        throw Exception('Only government officials can update problem status');
      }

      await _firestore.collection('problem_reports').doc(reportId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _currentUserId,
      });

      // Get the report owner's ID to send notification
      final reportDoc = await _firestore.collection('problem_reports').doc(reportId).get();
      final reportOwnerId = reportDoc.data()?['userId'];

      // Add notification for the report owner
      if (reportOwnerId != null) {
        await _firestore.collection('notifications').add({
          'userId': reportOwnerId,
          'title': 'Problem Report Update',
          'body': 'Your report status has been updated to: ${newStatus.toUpperCase()}',
          'type': 'problem_update',
          'reportId': reportId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to update problem status: $e');
    }
  }

  /// Deletes a problem report (only owner or government can delete)
  Future<void> deleteProblemReport(String reportId) async {
    try {
      final report = await _firestore.collection('problem_reports').doc(reportId).get();
      
      if (!report.exists) {
        throw Exception('Report not found');
      }

      final reportData = report.data() as Map<String, dynamic>;
      if (reportData['userId'] != _currentUserId && !_isGovernment) {
        throw Exception('You do not have permission to delete this report');
      }

      // Delete the image from storage if it exists
      final imageUrl = reportData['imageUrl'] as String?;
      if (imageUrl != null) {
        try {
          final ref = FirebaseStorage.instance.refFromURL(imageUrl);
          await ref.delete();
        } catch (e) {
          print('Error deleting image: $e');
          // Continue with report deletion even if image deletion fails
        }
      }

      // Delete the report document
      await _firestore.collection('problem_reports').doc(reportId).delete();
    } catch (e) {
      throw Exception('Failed to delete problem report: $e');
    }
  }
}