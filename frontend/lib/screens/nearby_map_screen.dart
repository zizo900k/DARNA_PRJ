// ignore_for_file: avoid_web_libraries_in_flutter

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../../config/map_config.dart';
import '../../theme/app_theme.dart';
import '../../services/property_service.dart';
import '../../data/properties_data.dart';
import '../../theme/language_provider.dart';
import '../../widgets/map/nearby_map_view.dart';

class NearbyMapScreen extends StatefulWidget {
  final Map<String, dynamic> property;

  const NearbyMapScreen({super.key, required this.property});

  @override
  State<NearbyMapScreen> createState() => _NearbyMapScreenState();
}

class _NearbyMapScreenState extends State<NearbyMapScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _nearbyProperties = [];
  Map<String, dynamic>? _selectedProperty;
  bool _mainSelected = true;

  double get _mainLat => double.tryParse(widget.property['latitude']?.toString() ?? '') ?? 33.5731;
  double get _mainLng => double.tryParse(widget.property['longitude']?.toString() ?? '') ?? -7.5898;

  @override
  void initState() {
    super.initState();
    _selectedProperty = widget.property;
    _loadNearby();
  }

  Future<void> _loadNearby() async {
    try {
      final propertyId = widget.property['id'];
      final nearby = await PropertyService.getNearby(propertyId, limit: 15);
      if (mounted) {
        setState(() {
          _nearbyProperties = nearby.map((e) => e as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleMarkerClick(int id, bool isMain) {
    if (isMain) {
      _selectedProperty = widget.property;
      _mainSelected = true;
    } else {
      final found = _nearbyProperties.firstWhere(
        (p) => p['id'] == id,
        orElse: () => widget.property,
      );
      _selectedProperty = found;
      _mainSelected = false;
    }
    setState(() {});
  }

  String _getPropertyImage(Map<String, dynamic> prop) {
    if (prop['photos'] != null && (prop['photos'] as List).isNotEmpty) {
      return prop['photos'][0]['full_url'] ?? prop['photos'][0]['url'] ?? '';
    }
    if (prop['images'] != null && (prop['images'] as List).isNotEmpty) {
      final img = prop['images'][0];
      if (img is String) return img;
      if (img is Map) return img['full_url'] ?? img['url'] ?? '';
    }
    return prop['image'] ?? 'https://placehold.co/400x300/20B2AA/FFFFFF/png?text=Property';
  }

  String _getPrice(Map<String, dynamic> prop) {
    if (prop['price'] != null) {
      final p = double.tryParse(prop['price'].toString()) ?? 0;
      if (p > 0) return '${p.toStringAsFixed(0)} MAD';
    }
    if (prop['price_per_month'] != null || prop['pricePerMonth'] != null) {
      final p = double.tryParse((prop['price_per_month'] ?? prop['pricePerMonth']).toString()) ?? 0;
      if (p > 0) return '${p.toStringAsFixed(0)} MAD/mo';
    }
    return 'Price N/A';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Full screen map
          if (!_isLoading)
            Positioned.fill(
              child: buildNearbyMapView(
                mainProperty: widget.property,
                nearbyProperties: _nearbyProperties,
                onMarkerClick: _handleMarkerClick,
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),

          // Floating back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
              child: PointerInterceptor(
                child: Material(
                  elevation: 4,
                shadowColor: Colors.black38,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => context.pop(),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2B3C) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Title chip
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: PointerInterceptor(
              child: Center(
                child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2B3C).withOpacity(0.9) : Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.explore_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('nearby_properties'),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (_nearbyProperties.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_nearbyProperties.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),

          // Bottom property card
          if (_selectedProperty != null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 16,
              right: 16,
              child: PointerInterceptor(
                child: _buildBottomCard(isDark, theme),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomCard(bool isDark, ThemeData theme) {
    final prop = _selectedProperty!;
    final imageUrl = _getPropertyImage(prop);
    final title = prop['title'] ?? 'Property';
    final location = prop['location'] ?? '';
    final price = _getPrice(prop);
    final type = prop['type']?.toString().toUpperCase() ?? '';
    final category = prop['category']?['name'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Card content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 100,
                    height: 90,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type badge + Main indicator
                      Row(
                        children: [
                          if (_mainSelected)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'MAIN',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          if (type.isNotEmpty || category.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2ECC71).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                category.isNotEmpty ? category : type,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2ECC71),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              location,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        price,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // View Property button
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF16A085)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    final id = prop['id'];
                    context.push('/property/$id', extra: {'property': prop});
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.open_in_new_rounded, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        context.tr('view_property'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
