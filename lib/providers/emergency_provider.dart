import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/emergency_contact.dart';

class EmergencyProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  
  List<EmergencyContact> _emergencyContacts = [];
  bool _isAdmin = false;
  
  List<EmergencyContact> get emergencyContacts => _emergencyContacts;
  bool get isAdmin => _isAdmin;

  /// Initializes the provider by setting up notification permissions,
  /// FCM token, and listeners for emergency contacts and problem reports
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
      // Create or update user document
      final userDocRef = _firestore.collection('users').doc('current_user_id');
      final userDoc = await userDocRef.get();
      
      if (!userDoc.exists) {
        // Create new user document
        await userDocRef.set({
          'fcmToken': token,
          'role': 'citizen', // Default role
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing user document
        await userDocRef.update({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    // Listen for emergency contacts changes
    _firestore
        .collection('EmergencyContacts')
        .snapshots()
        .listen((snapshot) {
      _emergencyContacts = snapshot.docs.map((doc) => EmergencyContact.fromMap(doc.id, doc.data())).toList();
      notifyListeners();
    });
    // Check if user is admin
    final userDoc = await _firestore.collection('users').doc('current_user_id').get();
    _isAdmin = userDoc.data()?['role'] == 'government';
    notifyListeners();
  }

  /// Fetches all emergency contacts from Firestore
  Future<void> fetchEmergencyContacts() async {
    try {
      final snapshot = await _firestore.collection('EmergencyContacts').get();
      _emergencyContacts = snapshot.docs.map((doc) => EmergencyContact.fromMap(doc.id, doc.data())).toList();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to fetch emergency contacts: $e');
    }
  }

  /// Adds a new emergency contact to Firestore
  Future<void> addEmergencyContact(EmergencyContact contact) async {
    try {
      // First, validate the data
      if (contact.title.isEmpty || contact.phoneNumber.isEmpty || contact.category.isEmpty) {
        throw Exception('Invalid contact data: All fields are required');
      }

      // Add to Firestore
      final docRef = await _firestore.collection('EmergencyContacts').add(contact.toMap());
      
      if (docRef.id.isEmpty) {
        throw Exception('Failed to get document ID after adding contact');
      }

      print('Successfully added emergency contact with ID: ${docRef.id}');
      
      // Refresh the list
      await fetchEmergencyContacts();
    } catch (e) {
      print('Error adding emergency contact: $e');
      throw Exception('Failed to add emergency contact: $e');
    }
  }

  /// Updates an existing emergency contact in Firestore
  Future<void> updateEmergencyContact(String contactId, EmergencyContact contact) async {
    try {
      await _firestore.collection('EmergencyContacts').doc(contactId).update(contact.toMap());
      await fetchEmergencyContacts(); // Refresh the list
    } catch (e) {
      throw Exception('Failed to update emergency contact: $e');
    }
  }

  /// Deletes an emergency contact from Firestore
  Future<void> deleteEmergencyContact(String contactId) async {
    try {
      await _firestore.collection('EmergencyContacts').doc(contactId).delete();
      _emergencyContacts.removeWhere((contact) => contact.id == contactId);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to delete emergency contact: $e');
    }
  }
}