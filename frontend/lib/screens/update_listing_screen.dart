import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/property_service.dart';
import 'package:provider/provider.dart';
import '../providers/property_provider.dart';
import '../theme/language_provider.dart';
import '../widgets/location_picker_map.dart';
import '../data/properties_data.dart';

class UpdateListingScreen extends StatefulWidget {
  final int propertyId;
  final Map<String, dynamic>? propertyData;

  const UpdateListingScreen({
    super.key,
    required this.propertyId,
    this.propertyData,
  });

  @override
  State<UpdateListingScreen> createState() => _UpdateListingScreenState();
}

class _UpdateListingScreenState extends State<UpdateListingScreen> {
  bool _showSuccessModal = false;
  bool _isSubmitting = false;
  String? _submissionError;

  // Form data
  late String _title;
  late String _listingType;
  late String _category;
  late String _location;
  late String _price;
  late String _area;
  late int _bedrooms;
  late int _bathrooms;
  late int _balcony;
  late int _totalRooms;
  late int _kitchens;
  late int _toilets;
  late int _livingRooms;
  late String _phoneNumber;
  late List<String> _facilities;
  late List<String> _existingPhotos;
  final List<XFile> _newPhotos = [];
  final ImagePicker _picker = ImagePicker();
  late int _categoryId;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    final p = widget.propertyData ?? {};
    _title = p['title'] ?? 'House For Rent';
    _listingType = p['type'] == 'sale' ? 'Sell' : 'Rent';
    
    // Map category from data
    final categoryData = p['category'];
    if (categoryData != null && categoryData is Map) {
      _categoryId = categoryData['id'] ?? 4;
    } else {
      _categoryId = 4;
    }
    try {
      _category = PropertiesData.propertyTypes.firstWhere((e) => e.id == _categoryId).value;
    } catch (e) {
      _category = 'house';
    }
    
    _location = p['location'] ?? 'Laayoune, Bloc H';
    if (p['latitude'] != null) _latitude = double.tryParse(p['latitude'].toString());
    if (p['longitude'] != null) _longitude = double.tryParse(p['longitude'].toString());
    
    // Formatting price from double to string safely
    final rawPrice = p['price'] ?? p['price_per_month'] ?? '3500';
    _price = rawPrice.toString();
    _area = (p['area'] ?? '120').toString();
    
    _bedrooms = p['bedrooms'] ?? 2;
    _bathrooms = p['bathrooms'] ?? 1;
    _balcony = p['balcony'] ?? 0;
    _totalRooms = p['total_rooms'] ?? 1;
    _kitchens = p['kitchens'] ?? 0;
    _toilets = p['toilets'] ?? 0;
    _livingRooms = p['living_rooms'] ?? 0;
    
    // Parse facilities cleanly
    _facilities = [];
    if (p['facilities'] != null && p['facilities'] is List) {
       _facilities = List<String>.from(p['facilities']);
    } else {
       _facilities = ['Parking Lot'];
    }

    _phoneNumber = p['phone_number'] ?? '+212 600000000';
    
    // Parse photos based on backend structure
    _existingPhotos = [];
    final rawImages = (p['photos'] as List?) ?? (p['images'] as List?) ?? [];
    for (var img in rawImages) {
      if (img is String) {
        _existingPhotos.add(img);
      } else if (img is Map) {
        final url = img['full_url'] ?? img['url'] ?? img['image'];
        if (url != null) _existingPhotos.add(url.toString());
      }
    }
  }

  final List<PropertyType> _categories = PropertiesData.propertyTypes;
  final List<String> _facilityOptions = ['Parking Lot', 'Pet Allowed', 'Garden', 'Gym', 'Park', 'Home theatre', 'Kid\'s Friendly', 'WIFI'];

  void _toggleFacility(String facility) {
    setState(() {
      if (_facilities.contains(facility)) {
        _facilities.remove(facility);
      } else {
        _facilities.add(facility);
      }
    });
  }

  void _removeExistingPhoto(int index) {
    setState(() {
      _existingPhotos.removeAt(index);
    });
  }

  void _removeNewPhoto(int index) {
    setState(() {
      _newPhotos.removeAt(index);
    });
  }

  Future<void> _handleUpdate() async {
    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });
    try {
      final priceRaw = _price.replaceAll(RegExp(r'[^0-9.]'), '');
      final price = double.tryParse(priceRaw) ?? 0;
      final listingType = _listingType.toLowerCase() == 'sell' ? 'sale' : 'rent';

      await PropertyService.updateProperty(widget.propertyId, {
        'title': _title,
        'description': 'Beautiful $_category for ${_listingType.toLowerCase()} located in $_location.',
        'type': listingType,
        'category_id': _categoryId,
        'status': 'available',
        'location': _location,
        'price': listingType == 'sale' ? price : null,
        'price_per_month': listingType == 'rent' ? price : null,
        'area': double.tryParse(_area.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0,
        'bedrooms': _bedrooms,
        'bathrooms': _bathrooms,
        'balcony': _balcony,
        'kitchens': _kitchens,
        'toilets': _toilets,
        'living_rooms': _livingRooms,
        'total_rooms': _totalRooms,
        'facilities': _facilities,
        'phone_number': _phoneNumber,
        'existing_photos': _existingPhotos,
        if (_latitude != null) 'latitude': _latitude,
        if (_longitude != null) 'longitude': _longitude,
      });

      if (_newPhotos.isNotEmpty) {
        try {
          await PropertyService.uploadPhotos(widget.propertyId, _newPhotos);
        } catch (e) {
          debugPrint('Error uploading photos: $e');
          throw Exception('Photos error: $e');
        }
      }

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _showSuccessModal = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submissionError = e.toString();
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (image != null) {
      setState(() {
        _newPhotos.add(image);
      });
    }
  }

  void _handleCloseModal() {
    setState(() => _showSuccessModal = false);
    if (mounted) {
      context.read<PropertyProvider>().loadHomeScreenData();
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Error Banner
                if (_submissionError != null)
                  Container(
                    width: double.infinity,
                    color: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_submissionError!, style: const TextStyle(color: Colors.white, fontSize: 13))),
                        GestureDetector(
                          onTap: () => setState(() => _submissionError = null),
                          child: const Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                  ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Icon(Icons.chevron_left, size: 28, color: theme.textTheme.bodyLarge?.color),
                        ),
                      ),
                      Text(
                      context.tr('update_listing'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Handle delete
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          child: const Icon(Icons.delete_outline, size: 24, color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    children: [
                      // Listing Title
                      _buildSectionTitle(context.tr('listing_title'), theme),
                      _buildTextField(
                        value: _title,
                        onChanged: (val) => _title = val,
                        placeholder: context.tr('enter_title'),
                        icon: Icons.edit_outlined,
                        theme: theme,
                        isDark: isDark,
                      ),

                      // Listing Type
                      _buildSectionTitle(context.tr('listing_type'), theme),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock_outline, size: 18, color: theme.textTheme.bodyMedium?.color),
                            const SizedBox(width: 8),
                            Text(
                              _listingType == 'Rent' ? context.tr('for_rent') ?? 'For Rent' : context.tr('for_sale') ?? 'For Sale',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Property Category
                      _buildSectionTitle(context.tr('property_category'), theme),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _categories.map((catType) {
                            final isActive = _category == catType.value;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _category = catType.value;
                                _categoryId = catType.id;
                              }),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? const Color(0xFF0D5C63)
                                      : (isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  context.tr(catType.value) ?? catType.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isActive ? AppColors.white : theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Location
                      _buildSectionTitle(context.tr('location'), theme),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: TextEditingController(text: _location)..selection = TextSelection.collapsed(offset: _location.length),
                          onChanged: (val) => _location = val,
                          style: TextStyle(fontSize: 15, color: theme.textTheme.bodyLarge?.color),
                          decoration: InputDecoration(
                            hintText: context.tr('enter_location'),
                            hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.location_on_outlined, color: theme.textTheme.bodyMedium?.color, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      LocationPickerMap(
                        initialLatitude: _latitude,
                        initialLongitude: _longitude,
                        onLocationSelected: (lat, lng) {
                          setState(() {
                            _latitude = lat;
                            _longitude = lng;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Listing Photos
                      _buildSectionTitle(context.tr('listing_photos'), theme),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ..._existingPhotos.asMap().entries.map((entry) {
                              final index = entry.key;
                              final photo = entry.value;
                              return Container(
                                width: 100,
                                height: 100,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CachedNetworkImage(
                                      imageUrl: photo,
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => _removeExistingPhoto(index),
                                        child: const Icon(Icons.cancel, color: AppColors.error, size: 24),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            ..._newPhotos.asMap().entries.map((entry) {
                              final index = entry.key;
                              final XFile photo = entry.value;
                              return Container(
                                width: 100,
                                height: 100,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    kIsWeb 
                                      ? Image.network(
                                          photo.path,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          File(photo.path),
                                          fit: BoxFit.cover,
                                        ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => _removeNewPhoto(index),
                                        child: const Icon(Icons.cancel, color: AppColors.error, size: 24),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? DarkColors.border : LightColors.border,
                                    style: BorderStyle.none,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Icon(Icons.add, size: 32, color: isDark ? const Color(0xFF1ABC9C) : AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Price
                      _buildSectionTitle(_listingType == 'Rent' ? context.tr('rent_price_label') : context.tr('sell_price_label'), theme),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Text(context.tr('mad'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue: _price,
                                onChanged: (val) => _price = val,
                                keyboardType: TextInputType.number,
                                style: TextStyle(fontSize: 15, color: theme.textTheme.bodyLarge?.color),
                                decoration: InputDecoration(
                                  hintText: _listingType == 'Rent' ? '3500' : '1,500,000',
                                  hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Area
                      _buildSectionTitle(context.tr('area_label'), theme),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.crop_square_outlined, size: 20, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                initialValue: _area,
                                onChanged: (val) => _area = val,
                                keyboardType: TextInputType.number,
                                style: TextStyle(fontSize: 15, color: theme.textTheme.bodyLarge?.color),
                                decoration: InputDecoration(
                                  hintText: '120',
                                  hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            Text('m²', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Property Features
                      _buildSectionTitle(context.tr('features'), theme),
                      _buildFeatureRow(context.tr('bedroom'), _bedrooms, (val) => setState(() => _bedrooms = val), theme, isDark),
                      _buildFeatureRow(context.tr('bathroom'), _bathrooms, (val) => setState(() => _bathrooms = val), theme, isDark),
                      _buildFeatureRow(context.tr('balcony'), _balcony, (val) => setState(() => _balcony = val), theme, isDark),
                      _buildFeatureRow(context.tr('kitchen'), _kitchens, (val) => setState(() => _kitchens = val), theme, isDark),
                      _buildFeatureRow(context.tr('toilet'), _toilets, (val) => setState(() => _toilets = val), theme, isDark),
                      _buildFeatureRow(context.tr('living_room'), _livingRooms, (val) => setState(() => _livingRooms = val), theme, isDark),
                      const SizedBox(height: 8),

                      // Total Rooms
                      _buildSectionTitle(context.tr('total_rooms'), theme),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _totalRooms = _totalRooms > 1 ? _totalRooms - 1 : 1),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              alignment: Alignment.center,
                              child: Icon(Icons.remove, size: 20, color: theme.textTheme.bodyLarge?.color),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D5C63),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _totalRooms.toString(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _totalRooms++),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              alignment: Alignment.center,
                              child: Icon(Icons.add, size: 20, color: theme.textTheme.bodyLarge?.color),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Environment / Facilities
                      _buildSectionTitle(context.tr('environment_facilities'), theme),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _facilityOptions.map((facility) {
                          final isActive = _facilities.contains(facility);
                          final key = facility.toLowerCase().replaceAll(' ', '_');
                          final translated = context.tr(key);
                          return GestureDetector(
                            onTap: () => _toggleFacility(facility),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFF0D5C63)
                                    : (isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                translated != key ? translated : facility,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isActive ? AppColors.white : theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),



                      // Update Button
                      GestureDetector(
                        onTap: _isSubmitting ? null : _handleUpdate,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0D5C63).withValues(alpha: 0.3),
                                offset: const Offset(0, 4),
                                blurRadius: 8,
                              ),
                            ],
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0D5C63), Color(0xFF16A085)],
                            ),
                          ),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  context.tr('update_listing'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),

            // Success Modal
            if (_showSuccessModal)
              Container(
                color: Colors.black54,
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 12, left: 32, right: 32, bottom: 40),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 50,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        margin: const EdgeInsets.only(bottom: 32),
                      ),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF0D5C63).withValues(alpha: 0.3),
                                  const Color(0xFF0D5C63).withValues(alpha: 0.1),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF0D5C63), Color(0xFF16A085)],
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.check, size: 40, color: AppColors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: context.tr('listing_updated_1')),
                            TextSpan(
                              text: context.tr('listing_updated_2'),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF1ABC9C) : const Color(0xFF0D5C63),
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          color: theme.textTheme.bodyLarge?.color,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.tr('listing_success_desc'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 28),
                      GestureDetector(
                        onTap: _handleCloseModal,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D5C63),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Close',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: theme.textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String value,
    required ValueChanged<String> onChanged,
    required String placeholder,
    required IconData icon,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: TextEditingController(text: value)..selection = TextSelection.collapsed(offset: value.length),
        onChanged: onChanged,
        style: TextStyle(fontSize: 15, color: theme.textTheme.bodyLarge?.color),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
          suffixIcon: Icon(icon, color: theme.textTheme.bodyMedium?.color, size: 20),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String text, bool isActive, VoidCallback onTap, ThemeData theme, bool isDark) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF0D5C63)
                : (isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isActive ? AppColors.white : theme.textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceTypeButton(String text, bool isActive, VoidCallback onTap, ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF0D5C63)
              : (isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isActive ? AppColors.white : theme.textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String label, int value, ValueChanged<int> onChanged, ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => onChanged(value > 0 ? value - 1 : 0),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7A8B99),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.remove, size: 18, color: AppColors.white),
                ),
              ),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => onChanged(value + 1),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7A8B99),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.add, size: 18, color: AppColors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

