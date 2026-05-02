import 'package:flutter/material.dart';
import '../services/property_service.dart';
import '../data/properties_data.dart';

class PropertyProvider with ChangeNotifier {
  List<Property> _featuredProperties = [];
  List<Property> _rentalProperties = [];
  List<Property> _saleProperties = [];
  List<Property> _recentProperties = [];
  List<Property> _guestProperties = [];
  
  bool _isLoading = false;
  String? _error;

  List<Property> get featuredProperties => List.unmodifiable(_featuredProperties);
  List<Property> get rentalProperties => List.unmodifiable(_rentalProperties);
  List<Property> get saleProperties => List.unmodifiable(_saleProperties);
  List<Property> get recentProperties => List.unmodifiable(_recentProperties);
  List<Property> get guestProperties => List.unmodifiable(_guestProperties);
  
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadHomeScreenData({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      // Load featured, rental, sale, and all recent properties concurrently
      final featuredFuture = PropertyService.getProperties(filters: {'featured': true});
      final rentalFuture = PropertyService.getProperties(filters: {'type': 'rent'});
      final saleFuture = PropertyService.getProperties(filters: {'type': 'sale'});
      final recentFuture = PropertyService.getProperties();

      final results = await Future.wait([featuredFuture, rentalFuture, saleFuture, recentFuture]);
      
      final featuredData = List<Map<String, dynamic>>.from(results[0]['data'] ?? []);
      _featuredProperties = featuredData.map((e) => Property.fromJson(e)).toList();

      final rentalData = List<Map<String, dynamic>>.from(results[1]['data'] ?? []);
      _rentalProperties = rentalData.map((e) => Property.fromJson(e)).toList();

      final saleData = List<Map<String, dynamic>>.from(results[2]['data'] ?? []);
      _saleProperties = saleData.map((e) => Property.fromJson(e)).toList();

      final recentData = List<Map<String, dynamic>>.from(results[3]['data'] ?? []);
      _recentProperties = recentData.map((e) => Property.fromJson(e)).toList();
    } catch (e) {
      if (!silent) _error = e.toString();
    } finally {
      if (!silent) _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Property>> searchProperties(Map<String, dynamic> filters) async {
    try {
      final response = await PropertyService.getProperties(filters: filters);
      final listData = List<Map<String, dynamic>>.from(response['data'] ?? []);
      return listData.map((e) => Property.fromJson(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> loadGuestScreenData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await PropertyService.getProperties(filters: {'random': true, 'limit': 15});
      final data = List<Map<String, dynamic>>.from(response['data'] ?? []);
      
      var seenUsers = <int>{};
      List<Property> diverse = [];
      
      // First pass: 1 property per user
      for (var item in data) {
         int? userId = item['user']?['id'] ?? item['user_id'];
         if (userId != null && !seenUsers.contains(userId)) {
             seenUsers.add(userId);
             diverse.add(Property.fromJson(item));
         } else if (userId == null) {
             diverse.add(Property.fromJson(item));
         }
      }
      
      // Second pass: Fill the rest up to 15
      if (diverse.length < 15) {
          for (var item in data) {
              if (diverse.length >= 15) break;
              var prop = Property.fromJson(item);
              if (!diverse.any((p) => p.id == prop.id)) {
                  diverse.add(prop);
              }
          }
      }
      
      _guestProperties = diverse;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}


