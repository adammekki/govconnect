import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Ads.dart';

class AdProvider extends ChangeNotifier {
  final List<AdModel> _ads = [];
  bool _isLoading = false;
  
  List<AdModel> get ads => _ads;
  bool get isLoading => _isLoading;
  
  Future<void> fetchApprovedAds() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('ads')
          .where('isApproved', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
      
      _ads.clear();
      for (var doc in snapshot.docs) {
        final ad = AdModel.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        _ads.add(ad);
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error fetching ads: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<AdModel>> fetchUserAds(String userId) async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('ads')
          .where('postedBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      final userAds = snapshot.docs.map((doc) => 
        AdModel.fromJson(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();
      
      return userAds;
    } catch (e) {
      print('Error fetching user ads: $e');
      return [];
    }
  }
  
  // Listen for real-time updates to ads
  void setupAdListener() {
    FirebaseFirestore.instance
        .collection('ads')
        .where('isApproved', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _ads.clear();
      for (var doc in snapshot.docs) {
        final ad = AdModel.fromJson(
          doc.data(),
          doc.id,
        );
        _ads.add(ad);
      }
      notifyListeners();
    });
  }
}