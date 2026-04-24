import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/language_provider.dart';
import '../data/properties_data.dart';
import 'custom_button.dart';

class FilterModal extends StatefulWidget {
  final Map<String, dynamic>? initialFilters;
  final Function(Map<String, dynamic>) onApply;

  const FilterModal({
    super.key,
    this.initialFilters,
    required this.onApply,
  });

  static Future<void> show(BuildContext context, {Map<String, dynamic>? initialFilters, required Function(Map<String, dynamic>) onApply}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterModal(
        initialFilters: initialFilters,
        onApply: onApply,
      ),
    );
  }

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  double _cashInHand = 4000000;
  double _monthlyInstallment = 1500;
  double _numberOfRooms = 4;
  List<String> _selectedPropertyTypes = ['apartment'];
  String _selectedPropertyStatus = 'all';
  String _listingType = 'all';

  @override
  void initState() {
    super.initState();
    if (widget.initialFilters != null) {
      _cashInHand = widget.initialFilters!['cashInHand'] ?? 4000000;
      _monthlyInstallment = widget.initialFilters!['monthlyInstallment'] ?? 1500;
      _numberOfRooms = widget.initialFilters!['numberOfRooms'] ?? 4;
      _selectedPropertyTypes = List<String>.from(widget.initialFilters!['propertyTypes'] ?? ['apartment']);
      _selectedPropertyStatus = widget.initialFilters!['propertyStatus'] ?? 'all';
      _listingType = widget.initialFilters!['listingType'] ?? 'all';
    }
  }

  void _togglePropertyType(String value) {
    setState(() {
      if (_selectedPropertyTypes.contains(value)) {
        _selectedPropertyTypes.remove(value);
      } else {
        _selectedPropertyTypes.add(value);
      }
    });
  }

  void _handleApply() {
    widget.onApply({
      'listingType': _listingType,
      'cashInHand': _listingType == 'sale' || _listingType == 'all' ? _cashInHand : null,
      'monthlyInstallment': _listingType == 'rent' || _listingType == 'all' ? _monthlyInstallment : null,
      'numberOfRooms': _numberOfRooms,
      'propertyTypes': _selectedPropertyTypes,
      'propertyStatus': _selectedPropertyStatus,
    });
    Navigator.pop(context);
  }

  void _handleClear() {
    setState(() {
      _cashInHand = 2000000;
      _monthlyInstallment = 1000;
      _numberOfRooms = 2;
      _selectedPropertyTypes = [];
      _selectedPropertyStatus = 'all';
      _listingType = 'all';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? DarkColors.border : LightColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Listing Type
            _buildSection(
              title: context.tr('listing_type') ?? 'Listing type',
              valueText: '',
              child: Row(
                children: [
                  _buildTypeOption('all', context.tr('all') ?? 'All', theme, isDark),
                  const SizedBox(width: 12),
                  _buildTypeOption('sale', context.tr('for_sale') ?? 'Sale', theme, isDark),
                  const SizedBox(width: 12),
                  _buildTypeOption('rent', context.tr('for_rent') ?? 'Rent', theme, isDark),
                ],
              ),
            ),

            // Cash in Hand (Only for Sale or All)
            if (_listingType == 'sale' || _listingType == 'all')
              _buildSection(
                title: context.tr('payment_cash'),
                valueText: '${_cashInHand.toStringAsFixed(0)} ${context.tr('mad')}',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Slider(
                      value: _cashInHand,
                      min: 500000,
                      max: 10000000,
                      divisions: 95,
                      activeColor: AppColors.primary,
                      inactiveColor: isDark ? DarkColors.border : LightColors.border,
                      onChanged: (val) => setState(() => _cashInHand = val),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        context.tr('down_payment_help'),
                        style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                      ),
                    ),
                  ],
                ),
              ),

            // Monthly Installment / Rent (Only for Rent or All)
            if (_listingType == 'rent' || _listingType == 'all')
              _buildSection(
                title: _listingType == 'rent' ? (context.tr('rent_price_label') ?? 'Rent Price') : context.tr('payment_monthly'),
                valueText: '${_monthlyInstallment.toStringAsFixed(0)} ${context.tr('mad')}',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Slider(
                      value: _monthlyInstallment,
                      min: 500,
                      max: 10000,
                      divisions: 95,
                      activeColor: AppColors.primary,
                      inactiveColor: isDark ? DarkColors.border : LightColors.border,
                      onChanged: (val) => setState(() => _monthlyInstallment = val),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _listingType == 'rent' ? (context.tr('monthly_budget_help')) : context.tr('monthly_budget_help'),
                        style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                      ),
                    ),
                  ],
                ),
              ),

            // Number of Rooms
            _buildSection(
              title: context.tr('number_of_rooms'),
              valueText: '${_numberOfRooms.toInt()} ${context.tr('rooms')}',
              child: Slider(
                value: _numberOfRooms,
                min: 1,
                max: 10,
                divisions: 9,
                activeColor: AppColors.primary,
                inactiveColor: isDark ? DarkColors.border : LightColors.border,
                onChanged: (val) => setState(() => _numberOfRooms = val),
              ),
            ),

            // Property Type
            _buildSection(
              title: context.tr('property_type'),
              valueText: '',
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: PropertiesData.propertyTypes.map((type) {
                  final isSelected = _selectedPropertyTypes.contains(type.value);
                  return InkWell(
                    onTap: () => _togglePropertyType(type.value),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : (isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : (isDark ? DarkColors.border : LightColors.border),
                        ),
                      ),
                      child: Text(
                        context.tr(type.value) ?? type.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? AppColors.white : theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Property Status
            _buildSection(
              title: context.tr('property_status'),
              valueText: '',
              child: Row(
                children: PropertiesData.propertyStatus.map((status) {
                  final isSelected = _selectedPropertyStatus == status.value;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: status == PropertiesData.propertyStatus.last ? 0 : 12),
                      child: InkWell(
                        onTap: () => setState(() => _selectedPropertyStatus = status.value),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : (isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            status.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? AppColors.white : theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 8),
            CustomButton(
              title: context.tr('find_my_home'),
              onPress: _handleApply,
              margin: const EdgeInsets.only(bottom: 12),
            ),
            
            TextButton(
              onPressed: _handleClear,
              child: Text(
                context.tr('clear_all'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String valueText, required Widget child}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              if (valueText.isNotEmpty)
                Text(
                  valueText,
                  textDirection: valueText.contains(RegExp(r'[0-9]')) ? ui.TextDirection.ltr : null,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildTypeOption(String value, String label, ThemeData theme, bool isDark) {
    final isSelected = _listingType == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _listingType = value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : (isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppColors.white : theme.textTheme.bodyMedium?.color,
            ),
          ),
        ),
      ),
    );
  }
}

