import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/problem_report.dart';

class ProblemReportProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<ProblemReport> _problemReports = [];
  bool _isAdmin = false;

  List<ProblemReport> get problemReports => _problemReports;
  bool get isAdmin => _isAdmin;

  /// Sets admin status (for testing purposes)
  void setAdminStatus(bool isAdmin) {
    _isAdmin = isAdmin;
    notifyListeners();
  }

  /// Initializes problem reports listener and checks admin status
  Future<void> initialize() async {
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

  /// Submits a new problem report to Firestore with optional image
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
    } catch (e) {
      throw Exception('Failed to submit problem report: $e');
    }
  }

  /// Fetches all problem reports from Firestore
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

  /// Updates the status of a problem report
  Future<void> updateProblemStatus(String reportId, String newStatus) async {
    try {
      await _firestore.collection('problem_reports').doc(reportId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update problem status: $e');
    }
  }

  /// Deletes a problem report and its associated image (if any)
  Future<void> deleteProblemReport(String reportId) async {
    try {
      // Get the report to check if it has an image
      final report = _problemReports.firstWhere((r) => r.id == reportId);
      
      // Delete the image from storage if it exists
      if (report.imageUrl != null) {
        try {
          final ref = FirebaseStorage.instance.refFromURL(report.imageUrl!);
          await ref.delete();
        } catch (e) {
          print('Error deleting image: $e');
          // Continue with report deletion even if image deletion fails
        }
      }

      // Delete the report document
      await _firestore.collection('problem_reports').doc(reportId).delete();
      
      // Update local state
      _problemReports.removeWhere((report) => report.id == reportId);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to delete problem report: $e');
    }
  }
}