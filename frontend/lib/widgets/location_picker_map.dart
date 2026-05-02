import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../theme/language_provider.dart';
import '../config/map_config.dart';
import 'map/mapbox_widget.dart';

class LocationPickerMap extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final Function(double, double) onLocationSelected;

  const LocationPickerMap({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    required this.onLocationSelected,
  });

  @override
  State<LocationPickerMap> createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends State<LocationPickerMap> {
  double? _latitude;
  double? _longitude;
  int _mapKeySeed = 0;
  bool _isLoadingLocation = false;
  MapStyle _currentStyle = MapStyle.clean;

  @override
  void initState() {
    super.initState();
    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;

    // Automatically try to get location if coordinates don't exist yet
    if (_latitude == null && _longitude == null) {
      _getCurrentLocation(auto: true);
    }
  }

  Future<void> _getCurrentLocation({bool auto = false}) async {
    if (_isLoadingLocation) return;

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!auto) _showError(context.tr('location_disabled'));
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!auto) _showError(context.tr('location_denied'));
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!auto) _showError(context.tr('location_denied_forever'));
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _mapKeySeed++; // Force MapboxWidget to re-initialize at new center
      });
      widget.onLocationSelected(position.latitude, position.longitude);
      
    } catch (e) {
      if (!auto) _showError('${context.tr('error')}: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          height: 260,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isDark ? null : Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            boxShadow: isDark ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ] : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: MapboxWidget(
              key: ValueKey('map-\\$_mapKeySeed'),
              initialLatitude: _latitude,
              initialLongitude: _longitude,
              isPicker: true,
              mapStyle: _currentStyle,
              onLocationSelected: (lat, lng) {
                _latitude = lat;
                _longitude = lng;
                widget.onLocationSelected(lat, lng);
              },
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Actions row: Style toggle + Current Location
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Style Toggle
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? DarkColors.backgroundSecondary
                    : LightColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStyleBtn(context.tr('map_clean'), MapStyle.clean, Icons.map_outlined),
                  _buildStyleBtn(context.tr('map_satellite'), MapStyle.premium3D, Icons.satellite_alt),
                ],
              ),
            ),
            
            // Current location button
            GestureDetector(
              onTap: () => _getCurrentLocation(auto: false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? DarkColors.backgroundSecondary
                      : LightColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _isLoadingLocation 
                        ? const SizedBox(
                            width: 16, 
                            height: 16, 
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)
                          )
                        : const Icon(Icons.my_location, size: 18, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStyleBtn(String text, MapStyle style, IconData icon) {
    final bool isSelected = _currentStyle == style;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() {
            _currentStyle = style;
            _mapKeySeed++;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(
              icon, 
              size: 16, 
              color: isSelected ? Colors.white : AppColors.primary
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected 
                    ? Colors.white 
                    : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
