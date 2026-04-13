import 'package:flutter/material.dart';
import '../services/property_service.dart';
import '../data/properties_data.dart';

class PropertyProvider with ChangeNotifier {
  List<Property> _featuredProperties = [];
  List<Property> _rentalProperties = [];
  List<Property> _recentProperties = [];
  
  bool _isLoading = false;
  String? _error;

  List<Property> get featuredProperties => List.unmodifiable(_featuredProperties);
  List<Property> get rentalProperties => List.unmodifiable(_rentalProperties);
  List<Property> get recentProperties => List.unmodifiable(_recentProperties);
  
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadHomeScreenData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load featured, rental, and all recent properties concurrently
      final featuredFuture = PropertyService.getProperties(filters: {'featured': true});
      final rentalFuture = PropertyService.getProperties(filters: {'listing_type': 'rent'});
      final recentFuture = PropertyService.getProperties();

      final results = await Future.wait([featuredFuture, rentalFuture, recentFuture]);
      
      final featuredData = List<Map<String, dynamic>>.from(results[0]['data'] ?? []);
      _featuredProperties = featuredData.map((e) => Property.fromJson(e)).toList();

      final rentalData = List<Map<String, dynamic>>.from(results[1]['data'] ?? []);
      _rentalProperties = rentalData.map((e) => Property.fromJson(e)).toList();

      final recentData = List<Map<String, dynamic>>.from(results[2]['data'] ?? []);
      _recentProperties = recentData.map((e) => Property.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
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
}


