import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

class AddListingScreen extends StatefulWidget {
  const AddListingScreen({super.key});

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  int _currentStep = 1;
  bool _showSuccessModal = false;

  // Form data
  String _title = 'House for sale';
  String _listingType = 'Sell';
  String _category = 'House';
  String _location = 'Laayoune Hay El Wahda Bloc I';
  List<String> _photos = [
    'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=400',
    'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=400',
    'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=400',
  ];
  String _price = '4,000,000';
  int _bedrooms = 3;
  int _bathrooms = 2;
  int _balcony = 2;
  int _totalRooms = 4;
  List<String> _facilities = ['Parking Lot', 'Pet Allowed', 'Garden', 'Gym'];
  String _phoneNumber = '+212 | 624425449';

  final List<String> _categories = ['House', 'Apartment', 'Land'];
  final List<String> _facilityOptions = ['Parking Lot', 'Pet Allowed', 'Garden', 'Gym', 'Park', 'Home theatre', 'Kid\'s Friendly'];
  final List<int> _roomOptions = [4, 6];

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
    if (_currentStep < 4) {
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

  void _handleFinish() {
    setState(() => _showSuccessModal = true);
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
                        'Add Listing',
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
                          onTap: _currentStep < 4 ? _handleNext : _handleFinish,
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D5C63),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _currentStep < 4 ? 'Next' : 'Finish',
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
                                  const Color(0xFF0D5C63).withOpacity(0.3),
                                  const Color(0xFF0D5C63).withOpacity(0.1),
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
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'Your listing is now\n'),
                            TextSpan(
                              text: 'published',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF1ABC9C) : const Color(0xFF0D5C63),
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          color: theme.textTheme.bodyLarge?.color,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Lorem ipsum dolor sit amet, consectetur.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textTheme.bodyMedium?.color,
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
                                  'Add More',
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
                                child: const Text(
                                  'Finish',
                                  style: TextStyle(
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
              hintText: 'House for sale',
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
          'Listing type',
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
                onTap: () => setState(() => _listingType = 'Rent'),
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
                onTap: () => setState(() => _listingType = 'Sell'),
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
          children: _categories.map((cat) {
            final isActive = _category == cat;
            return GestureDetector(
              onTap: () => setState(() => _category = cat),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF0D5C63)
                      : (isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  cat,
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
              hintText: 'Enter location',
              hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.location_on_outlined, color: theme.textTheme.bodyMedium?.color),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Map View
        Container(
          height: 400,
          decoration: BoxDecoration(
            color: isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Center(child: Text("Map Placeholder")),
              // Pin
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0D5C63),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 4,
                    height: 8,
                    color: const Color(0xFF0D5C63),
                  ),
                ],
              ),
              Positioned(
                bottom: 20,
                child: Text(
                  'Select on the map',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            ],
          ),
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
                        child: CachedNetworkImage(
                          imageUrl: photo,
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
            }).toList(),
            SizedBox(
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

        // Sell Price
        Text(
          'Sell Price',
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
                    hintText: '4,000,000',
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
        const SizedBox(height: 28),

        // Property Features
        Text(
          'Property Features',
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
        const SizedBox(height: 28),

        // Total Rooms
        Text(
          'Total Rooms',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ..._roomOptions.map((room) {
              final isActive = _totalRooms == room;
              return GestureDetector(
                onTap: () => setState(() => _totalRooms = room),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF0D5C63)
                        : (isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.bed_outlined,
                        size: 16,
                        color: isActive ? AppColors.white : theme.textTheme.bodyMedium?.color,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '< $room',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isActive ? AppColors.white : theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            GestureDetector(
              onTap: () => setState(() => _totalRooms = 6),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: _totalRooms == 6
                      ? const Color(0xFF0D5C63)
                      : (isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.bed_outlined,
                      size: 16,
                      color: _totalRooms == 6 ? AppColors.white : theme.textTheme.bodyMedium?.color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '6',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _totalRooms == 6 ? AppColors.white : theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
             GestureDetector(
              onTap: () => setState(() => _totalRooms = 7),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: _totalRooms > 6
                      ? const Color(0xFF0D5C63)
                      : (isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.bed_outlined,
                      size: 16,
                      color: _totalRooms > 6 ? AppColors.white : theme.textTheme.bodyMedium?.color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '6+',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _totalRooms > 6 ? AppColors.white : theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
        const SizedBox(height: 28),

        // Phone Number
        Text(
          'Add Phone Number',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: TextEditingController(text: _phoneNumber)..selection = TextSelection.collapsed(offset: _phoneNumber.length),
            onChanged: (val) => _phoneNumber = val,
            keyboardType: TextInputType.phone,
            style: TextStyle(fontSize: 16, color: theme.textTheme.bodyLarge?.color),
            decoration: InputDecoration(
              hintText: '+212 | 624425449',
              hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: InputBorder.none,
            ),
          ),
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
}
