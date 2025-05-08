import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/emergency_contact.dart';

class EmergencyProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<EmergencyContact> _emergencyContacts = [];
  bool _isGovernment = false;
  String? _currentUserId;
  String? _userRole;

  List<EmergencyContact> get emergencyContacts => _emergencyContacts;
  bool get isGovernment => _isGovernment;
  String? get currentUserId => _currentUserId;
  String? get userRole => _userRole;

  /// Initializes the provider by setting up notification permissions,
  /// FCM token, and listeners for emergency contacts
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
          
          // Set up FCM token
          String? token = await _messaging.getToken();
          if (token != null) {
            await _firestore.collection('Users').doc(user.uid).update({
              'fcmToken': token,
              'lastLogin': FieldValue.serverTimestamp(),
            });
          }

          // Set up emergency contacts listener
          _setupEmergencyContactsListener();
          notifyListeners();
        } else {
          print('User document does not exist in Firestore');
        }
      } else {
        _currentUserId = null;
        _userRole = null;
        _isGovernment = false;
        _emergencyContacts = [];
        notifyListeners();
      }
    });

    // Request notification permissions
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _setupEmergencyContactsListener() {
    _firestore
        .collection('EmergencyContacts')
        .snapshots()
        .listen((snapshot) {
      _emergencyContacts = snapshot.docs
          .map((doc) => EmergencyContact.fromMap(doc.id, doc.data()))
          .toList();
      notifyListeners();
    });
  }

  /// Fetches all emergency contacts from Firestore
  Future<void> fetchEmergencyContacts() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User must be logged in to fetch emergency contacts');
      }

      final snapshot = await _firestore.collection('EmergencyContacts').get();
      _emergencyContacts = snapshot.docs
          .map((doc) => EmergencyContact.fromMap(doc.id, doc.data()))
          .toList();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to fetch emergency contacts: $e');
    }
  }

  /// Adds a new emergency contact to Firestore (government only)
  Future<void> addEmergencyContact(EmergencyContact contact) async {
    try {
      if (!_isGovernment) {
        throw Exception('Only government officials can add emergency contacts');
      }

      if (_currentUserId == null) {
        throw Exception('User must be logged in to add emergency contacts');
      }

      // Validate the data
      if (contact.title.isEmpty || contact.phoneNumber.isEmpty || contact.category.isEmpty) {
        throw Exception('Invalid contact data: All fields are required');
      }

      // Create contact with current user ID
      final contactData = {
        ...contact.toMap(),
        'createdBy': _currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add to Firestore
      final docRef = await _firestore.collection('EmergencyContacts').add(contactData);
      
      if (docRef.id.isEmpty) {
        throw Exception('Failed to get document ID after adding contact');
      }

      print('Successfully added emergency contact with ID: ${docRef.id}');
    } catch (e) {
      print('Error adding emergency contact: $e');
      throw Exception('Failed to add emergency contact: $e');
    }
  }

  /// Updates an existing emergency contact in Firestore (government only)
  Future<void> updateEmergencyContact(String contactId, EmergencyContact contact) async {
    try {
      if (!_isGovernment) {
        throw Exception('Only government officials can update emergency contacts');
      }

      if (_currentUserId == null) {
        throw Exception('User must be logged in to update emergency contacts');
      }

      final contactData = {
        ...contact.toMap(),
        'updatedBy': _currentUserId,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('EmergencyContacts').doc(contactId).update(contactData);
    } catch (e) {
      throw Exception('Failed to update emergency contact: $e');
    }
  }

  /// Deletes an emergency contact from Firestore (government only)
  Future<void> deleteEmergencyContact(String contactId) async {
    try {
      if (!_isGovernment) {
        throw Exception('Only government officials can delete emergency contacts');
      }

      if (_currentUserId == null) {
        throw Exception('User must be logged in to delete emergency contacts');
      }

      await _firestore.collection('EmergencyContacts').doc(contactId).delete();
      _emergencyContacts.removeWhere((contact) => contact.id == contactId);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to delete emergency contact: $e');
    }
  }
}