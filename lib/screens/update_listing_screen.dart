import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

class UpdateListingScreen extends StatefulWidget {
  const UpdateListingScreen({super.key});

  @override
  State<UpdateListingScreen> createState() => _UpdateListingScreenState();
}

class _UpdateListingScreenState extends State<UpdateListingScreen> {
  bool _showSuccessModal = false;

  // Form data
  String _title = 'House For sent 1';
  String _listingType = 'Rent';
  String _category = 'Apartment';
  String _location = 'Laayoune, Bloc H Rue Al Fourat';
  String _price = '3500';
  String _priceType = 'Month';
  int _bedrooms = 2;
  int _bathrooms = 1;
  int _balcony = 0;
  int _totalRooms = 1;
  String _phoneNumber = '+212  624424514';
  List<String> _facilities = ['Parking', 'Pet Allowed'];

  final List<String> _categories = ['Villa', 'Apartment', 'Hotel', 'Cottage', 'Land'];
  final List<String> _facilityOptions = ['Parking', 'Pet Allowed', 'Garden', 'Hospital', 'School', 'University'];

  List<String> _photos = [
    'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=400',
    'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=400',
    'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=400',
  ];

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

  void _handleUpdate() {
    setState(() => _showSuccessModal = true);
  }

  void _handleCloseModal() {
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
                        'Update Listing',
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
                      _buildSectionTitle('Listing Title', theme),
                      _buildTextField(
                        value: _title,
                        onChanged: (val) => _title = val,
                        placeholder: 'Enter listing title',
                        icon: Icons.edit_outlined,
                        theme: theme,
                        isDark: isDark,
                      ),

                      // Listing Type
                      _buildSectionTitle('Listing type', theme),
                      Row(
                        children: [
                          _buildTypeButton('Rent', _listingType == 'Rent', () => setState(() => _listingType = 'Rent'), theme, isDark),
                          const SizedBox(width: 12),
                          _buildTypeButton('Sell', _listingType == 'Sell', () => setState(() => _listingType = 'Sell'), theme, isDark),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Property Category
                      _buildSectionTitle('Property category', theme),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _categories.map((cat) {
                            final isActive = _category == cat;
                            return GestureDetector(
                              onTap: () => setState(() => _category = cat),
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
                                  cat,
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
                      _buildSectionTitle('Location', theme),
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
                            hintText: 'Enter location',
                            hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.location_on_outlined, color: theme.textTheme.bodyMedium?.color, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 160,
                        decoration: BoxDecoration(
                          color: isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            const Center(child: Text("Map placeholder...")),
                            Positioned(
                              bottom: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: theme.scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.location_on, size: 16, color: isDark ? const Color(0xFF1ABC9C) : AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Edit location',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Listing Photos
                      _buildSectionTitle('Listing Photos', theme),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ..._photos.asMap().entries.map((entry) {
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
                                        onTap: () => _removePhoto(index),
                                        child: const Icon(Icons.cancel, color: AppColors.error, size: 24),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? DarkColors.border : LightColors.border,
                                  style: BorderStyle.none, // Can make dotted with a package or custom painter
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(Icons.add, size: 32, color: isDark ? const Color(0xFF1ABC9C) : AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Rent Price
                      _buildSectionTitle('Rent Price', theme),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'MAD',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: TextEditingController(text: _price)..selection = TextSelection.collapsed(offset: _price.length),
                                      onChanged: (val) => _price = val,
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(fontSize: 15, color: theme.textTheme.bodyLarge?.color),
                                      decoration: InputDecoration(
                                        hintText: '3500',
                                        hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '\$',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildPriceTypeButton('Month', _priceType == 'Month', () => setState(() => _priceType = 'Month'), theme, isDark),
                          const SizedBox(width: 12),
                          _buildPriceTypeButton('Year', _priceType == 'Year', () => setState(() => _priceType = 'Year'), theme, isDark),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Property Features
                      _buildSectionTitle('Property Features', theme),
                      _buildFeatureRow('Bed room', _bedrooms, (val) => setState(() => _bedrooms = val), theme, isDark),
                      _buildFeatureRow('Bath room', _bathrooms, (val) => setState(() => _bathrooms = val), theme, isDark),
                      _buildFeatureRow('Balcony', _balcony, (val) => setState(() => _balcony = val), theme, isDark),
                      const SizedBox(height: 8),

                      // Total Rooms
                      _buildSectionTitle('Total Rooms', theme),
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
                      _buildSectionTitle('Environment / Facilities', theme),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _facilityOptions.map((facility) {
                          final isActive = _facilities.contains(facility);
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
                                facility,
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

                      // Edit Phone Number
                      _buildSectionTitle('Edit Phone Number', theme),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: TextEditingController(text: _phoneNumber)..selection = TextSelection.collapsed(offset: _phoneNumber.length),
                          onChanged: (val) => _phoneNumber = val,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(fontSize: 15, color: theme.textTheme.bodyLarge?.color),
                          decoration: InputDecoration(
                            hintText: 'Phone number',
                            hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Update Button
                      GestureDetector(
                        onTap: _handleUpdate,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0D5C63).withOpacity(0.3),
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
                          child: const Text(
                            'Update',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
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
                            const TextSpan(text: 'Your listing just\n'),
                            TextSpan(
                              text: 'successfuly updated',
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
                        'Lorem ipsum dolor sit amet, consectetur.',
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
