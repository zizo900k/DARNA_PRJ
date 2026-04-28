import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/property_service.dart';
import 'package:provider/provider.dart';
import '../providers/property_provider.dart';
import '../theme/language_provider.dart';
import '../widgets/location_picker_map.dart';
import '../data/properties_data.dart';

class AddListingScreen extends StatefulWidget {
  const AddListingScreen({super.key});

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  int _currentStep = 1;
  bool _showSuccessModal = false;
  bool _isSubmitting = false;
  String? _submissionError;

  // Form data
  String _title = '';
  String _listingType = 'Sell';
  String _category = '';
  int _categoryId = 0;
  String _location = '';
  final List<XFile> _photos = [];
  final ImagePicker _picker = ImagePicker();
  String _price = '';
  String _area = '';
  int _bedrooms = 1;
  int _bathrooms = 1;
  int _balcony = 0;
  int _kitchens = 1;
  int _toilets = 1;
  int _livingRooms = 1;
  final List<String> _facilities = [];
  double? _latitude;
  double? _longitude;

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

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  void _handleNext() {
    setState(() {
      _submissionError = null;
    });

    if (_currentStep == 1) {
      if (_title.trim().isEmpty) {
        setState(() => _submissionError = context.tr('fill_required_fields') ?? 'Please enter a listing title');
        return;
      }
      if (_category.isEmpty || _categoryId == 0) {
        setState(() => _submissionError = context.tr('fill_required_fields') ?? 'Please select a property category');
        return;
      }
    } else if (_currentStep == 2) {
      if (_location.trim().isEmpty) {
        setState(() => _submissionError = context.tr('fill_required_fields') ?? 'Please enter a location');
        return;
      }
      if (_latitude == null || _longitude == null) {
        setState(() => _submissionError = context.tr('fill_required_fields') ?? 'Please select a location on the map');
        return;
      }
    } else if (_currentStep == 3) {
      if (_photos.isEmpty) {
        setState(() => _submissionError = context.tr('fill_required_fields') ?? 'Please add at least one photo');
        return;
      }
    } else if (_currentStep == 4) {
      if (_price.trim().isEmpty) {
        setState(() => _submissionError = context.tr('fill_required_fields') ?? 'Please enter a price');
        return;
      }
      if (_area.trim().isEmpty) {
        setState(() => _submissionError = context.tr('fill_required_fields') ?? 'Please enter the area');
        return;
      }
      if (_facilities.isEmpty) {
        setState(() => _submissionError = context.tr('fill_required_fields') ?? 'Please select at least one facility');
        return;
      }
    }

    if (_currentStep < 5) {
      setState(() => _currentStep++);
    }
  }

  void _handleBack() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  Future<void> _handleFinish() async {
    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });
    try {
      // Parse price removing commas/spaces
      final priceRaw = _price.replaceAll(RegExp(r'[^0-9.]'), '');
      final price = double.tryParse(priceRaw) ?? 0;

      final listingType = _listingType.toLowerCase() == 'sell' ? 'sale' : 'rent';

      // Backend expects certain required fields that might not be fully present in the UI
      final response = await PropertyService.createProperty({
        'title': _title,
        'description': 'Beautiful $_category for $_listingType located in $_location.',
        'type': listingType,
        'category_id': _categoryId,
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
        'total_rooms': _bedrooms + _livingRooms + _kitchens,
        'facilities': _facilities,
        if (_latitude != null) 'latitude': _latitude,
        if (_longitude != null) 'longitude': _longitude,
      });

      // Upload photos after property is created
      // Backend returns { message, property } not { data }
      final propertyData = response['property'] ?? response['data'];
      if (propertyData != null && propertyData['id'] != null) {
        final propertyId = propertyData['id'];
        if (_photos.isNotEmpty) {
          try {
            await PropertyService.uploadPhotos(propertyId, _photos);
          } catch (e) {
            debugPrint('Error uploading photos: $e');
            // If photos fail, we want to know what the error is
            throw Exception('Photos error: $e');
          }
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
        _photos.add(image);
      });
    }
  }

  void _handleAddMore() {
    setState(() {
      _showSuccessModal = false;
      _currentStep = 1;
      // You could reset data here as well
    });
  }

  void _handleComplete() {
    setState(() => _showSuccessModal = false);
    // Reload home screen data so newly added property shows up
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
                        onTap: _handleBack,
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
                        context.tr('add_listing'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(width: 40), // Placeholder
                    ],
                  ),
                ),

                // Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Row(
                        children: List.generate(5, (i) {
                          final stepNum = i + 1;
                          final isActive = stepNum <= _currentStep;
                          return Expanded(
                            child: Container(
                              height: 4,
                              margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.primary
                                    : (isDark ? DarkColors.border : LightColors.border),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Step $_currentStep of 5',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Steps Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildCurrentStep(theme, isDark),
                  ),
                ),

                // Bottom Navigation
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDark ? DarkColors.border : LightColors.border,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _handleBack,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: isDark ? DarkColors.border : LightColors.border,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(Icons.arrow_back, color: theme.textTheme.bodyLarge?.color),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: _isSubmitting ? null : (_currentStep < 5 ? _handleNext : _handleFinish),
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D5C63),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: AppColors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _currentStep < 5 ? 'Next' : 'Submit for Review',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
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
                              color: Color(0xFF0D5C63),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.check, size: 40, color: AppColors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Your listing has been\nsubmitted for review',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: theme.textTheme.bodyLarge?.color,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Our team will review your property and publish it shortly. You can track its status in My Listings.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textTheme.bodyMedium?.color,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _handleAddMore,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  context.tr('add_more'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: _handleComplete,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D5C63),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  context.tr('finish'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildCurrentStep(ThemeData theme, bool isDark) {
    switch (_currentStep) {
      case 1:
        return _buildStep1(theme, isDark);
      case 2:
        return _buildStep2(theme, isDark);
      case 3:
        return _buildStep3(theme, isDark);
      case 4:
        return _buildStep4(theme, isDark);
      case 5:
        return _buildStep5Review(theme, isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1(ThemeData theme, bool isDark) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Hi Mohamed, Fill detail of your\n'),
              TextSpan(
                text: 'real estate',
                style: TextStyle(color: isDark ? const Color(0xFF1ABC9C) : AppColors.primary),
              ),
            ],
          ),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: theme.textTheme.bodyLarge?.color,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 32),

        // Title Input
        Container(
          decoration: BoxDecoration(
            color: isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextFormField(
            initialValue: _title,
            onChanged: (val) => _title = val,
            style: TextStyle(fontSize: 16, color: theme.textTheme.bodyLarge?.color),
            decoration: InputDecoration(
              hintText: context.tr('house_for_sale'),
              hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: InputBorder.none,
              suffixIcon: Icon(Icons.home_outlined, color: theme.textTheme.bodyMedium?.color),
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Listing Type
        Text(
          context.tr('listing_type'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _listingType = 'Rent';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _listingType == 'Rent'
                        ? const Color(0xFF0D5C63)
                        : (isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Rent',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _listingType == 'Rent' ? AppColors.white : theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _listingType = 'Sell';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _listingType == 'Sell'
                        ? const Color(0xFF0D5C63)
                        : (isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Sell',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _listingType == 'Sell' ? AppColors.white : theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Category
        Text(
          'Property category',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _categories.map((catType) {
            final isActive = _category == catType.value;
            return GestureDetector(
              onTap: () => setState(() {
                _category = catType.value;
                _categoryId = catType.id;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF0D5C63)
                      : (isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  context.tr(catType.value) ?? catType.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppColors.white : theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStep2(ThemeData theme, bool isDark) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Where is the '),
              TextSpan(
                text: 'location',
                style: TextStyle(color: isDark ? const Color(0xFF1ABC9C) : AppColors.primary),
              ),
              const TextSpan(text: '?'),
            ],
          ),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: theme.textTheme.bodyLarge?.color,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 32),

        // Location Input
        Container(
          decoration: BoxDecoration(
            color: isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: TextEditingController(text: _location)..selection = TextSelection.collapsed(offset: _location.length),
            onChanged: (val) => _location = val,
            style: TextStyle(fontSize: 16, color: theme.textTheme.bodyLarge?.color),
            decoration: InputDecoration(
              hintText: context.tr('enter_location'),
              hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.location_on_outlined, color: theme.textTheme.bodyMedium?.color),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Map View
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
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStep3(ThemeData theme, bool isDark) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Add '),
              TextSpan(
                text: 'photos',
                style: TextStyle(color: isDark ? const Color(0xFF1ABC9C) : AppColors.primary),
              ),
              const TextSpan(text: ' to your listing'),
            ],
          ),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: theme.textTheme.bodyLarge?.color,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 32),

        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            ..._photos.asMap().entries.map((entry) {
              final index = entry.key;
              final photo = entry.value;
              return SizedBox(
                width: (MediaQuery.of(context).size.width - 48 - 16) / 2, // 2 columns
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: kIsWeb
                            ? Image.network(
                                photo.path,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(photo.path),
                                fit: BoxFit.cover,
                              ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => _removePhoto(index),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0D5C63),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.close, color: AppColors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            GestureDetector(
              onTap: _pickImage,
              child: SizedBox(
                width: (MediaQuery.of(context).size.width - 48 - 16) / 2,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.add, size: 40, color: isDark ? const Color(0xFF1ABC9C) : AppColors.primary),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStep4(ThemeData theme, bool isDark) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Almost finish',
                style: TextStyle(color: isDark ? const Color(0xFF1ABC9C) : AppColors.primary),
              ),
              const TextSpan(text: ', complete the listing'),
            ],
          ),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: theme.textTheme.bodyLarge?.color,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 32),

        // Price Label
        Text(
          _listingType == 'Rent' ? 'Rent Price / Month' : 'Sell Price',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Text(
                'MAD',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: _price)..selection = TextSelection.collapsed(offset: _price.length),
                  onChanged: (val) => _price = val,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: 16, color: theme.textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    hintText: _listingType == 'Rent' ? '4,000' : '4,000,000',
                    hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),
              Text(
                '\$',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Area m²
        Text(
          'Area (m²)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? DarkColors.border : LightColors.border),
          ),
          child: Row(
            children: [
              Icon(Icons.crop_square_outlined, size: 20, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: _area,
                  keyboardType: TextInputType.number,
                  onChanged: (val) => _area = val,
                  decoration: InputDecoration(
                    hintText: '120',
                    hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),
              Text('m²',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color)),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Property Features
        Text(
          context.tr('features'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        _buildCounterRow('Bedroom', _bedrooms, (val) => setState(() => _bedrooms = val), theme, isDark),
        _buildCounterRow('Bathroom', _bathrooms, (val) => setState(() => _bathrooms = val), theme, isDark),
        _buildCounterRow('Balcony', _balcony, (val) => setState(() => _balcony = val), theme, isDark),
        _buildCounterRow('Kitchen', _kitchens, (val) => setState(() => _kitchens = val), theme, isDark),
        _buildCounterRow('Toilet', _toilets, (val) => setState(() => _toilets = val), theme, isDark),
        _buildCounterRow('Living Room', _livingRooms, (val) => setState(() => _livingRooms = val), theme, isDark),
        const SizedBox(height: 28),

        // Environment / Facilities
        Text(
          'Environment / Facilities',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _facilityOptions.map((facility) {
            final isActive = _facilities.contains(facility);
            return GestureDetector(
              onTap: () => _toggleFacility(facility),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF0D5C63)
                      : (isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  facility,
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
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildCounterRow(String label, int value, ValueChanged<int> onChanged, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
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
                width: 48,
                alignment: Alignment.center,
                child: Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 18,
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

  // Step 5: Review & Publish
  Widget _buildStep5Review(ThemeData theme, bool isDark) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Review ',
                style: TextStyle(color: isDark ? const Color(0xFF1ABC9C) : AppColors.primary),
              ),
              const TextSpan(text: 'your listing'),
            ],
          ),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: theme.textTheme.bodyLarge?.color,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Make sure everything looks good before publishing.',
          style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
        ),
        const SizedBox(height: 24),
        _reviewItem(Icons.title, 'Title', _title, theme, isDark),
        _reviewItem(Icons.category_outlined, 'Type', '$_listingType · $_category', theme, isDark),
        _reviewItem(Icons.location_on_outlined, 'Location', _location, theme, isDark),
        _reviewItem(Icons.photo_library_outlined, 'Photos', '${_photos.length} photo(s)', theme, isDark),
        _reviewItem(Icons.attach_money, 'Price', '$_price MAD${_listingType == "Rent" ? "/mo" : ""}', theme, isDark),
        _reviewItem(Icons.crop_square_outlined, 'Area', '$_area m²', theme, isDark),
        _reviewItem(Icons.bed_outlined, 'Rooms', '$_bedrooms bed · $_bathrooms bath · $_balcony balcony · $_kitchens kitchen', theme, isDark),
        if (_facilities.isNotEmpty)
          _reviewItem(Icons.local_parking_outlined, 'Facilities', _facilities.join(', '), theme, isDark),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _reviewItem(IconData icon, String label, String value, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
