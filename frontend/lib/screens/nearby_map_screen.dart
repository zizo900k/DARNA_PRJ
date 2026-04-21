// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/map_config.dart';
import '../../theme/app_theme.dart';
import '../../services/property_service.dart';
import '../../data/properties_data.dart';
import '../../theme/language_provider.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

class NearbyMapScreen extends StatefulWidget {
  final Map<String, dynamic> property;

  const NearbyMapScreen({super.key, required this.property});

  @override
  State<NearbyMapScreen> createState() => _NearbyMapScreenState();
}

class _NearbyMapScreenState extends State<NearbyMapScreen> {
  late String _viewId;
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
        _buildMap();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _buildMap();
      }
    }
  }

  void _buildMap() {
    _viewId = 'nearby-map-${DateTime.now().millisecondsSinceEpoch}';

    // Build marker JS
    final markersJs = StringBuffer();
    
    // Main property marker (special red larger marker)
    markersJs.writeln('''
      const mainEl = document.createElement('div');
      mainEl.className = 'main-marker';
      mainEl.innerHTML = '<div class="marker-pulse"></div><div class="marker-dot"></div>';
      mainEl.addEventListener('click', () => {
        window.parent.postMessage({ type: 'markerClick', id: ${widget.property['id']}, isMain: true }, '*');
      });
      new mapboxgl.Marker({element: mainEl})
        .setLngLat([$_mainLng, $_mainLat])
        .addTo(map);
    ''');

    // Bounds to fit all
    markersJs.writeln('const bounds = new mapboxgl.LngLatBounds();');
    markersJs.writeln('bounds.extend([$_mainLng, $_mainLat]);');

    // Nearby markers
    for (final prop in _nearbyProperties) {
      final lat = double.tryParse(prop['latitude']?.toString() ?? '');
      final lng = double.tryParse(prop['longitude']?.toString() ?? '');
      if (lat == null || lng == null) continue;
      final id = prop['id'];
      
      markersJs.writeln('''
        const el_$id = document.createElement('div');
        el_$id.className = 'nearby-marker';
        el_$id.innerHTML = '<div class="nearby-dot"></div>';
        el_$id.addEventListener('click', () => {
          window.parent.postMessage({ type: 'markerClick', id: $id, isMain: false }, '*');
        });
        new mapboxgl.Marker({element: el_$id})
          .setLngLat([$lng, $lat])
          .addTo(map);
        bounds.extend([$lng, $lat]);
      ''');
    }

    // Fit bounds if we have nearby
    if (_nearbyProperties.isNotEmpty) {
      markersJs.writeln('''
        map.fitBounds(bounds, { padding: 60, maxZoom: 14, duration: 1000 });
      ''');
    }

    final String htmlContent = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="initial-scale=1,maximum-scale=1,user-scalable=no" />
    <script src="https://api.mapbox.com/mapbox-gl-js/v3.1.2/mapbox-gl.js"></script>
    <link href="https://api.mapbox.com/mapbox-gl-js/v3.1.2/mapbox-gl.css" rel="stylesheet" />
    <style>
        body { margin: 0; padding: 0; overflow: hidden; }
        #map { position: absolute; top: 0; bottom: 0; width: 100%; }
        .mapboxgl-control-container { display: none; }
        
        .main-marker {
          width: 40px; height: 40px;
          cursor: pointer;
          position: relative;
        }
        .marker-pulse {
          width: 40px; height: 40px;
          border-radius: 50%;
          background: rgba(231, 76, 60, 0.25);
          position: absolute;
          animation: pulse 2s infinite;
        }
        .marker-dot {
          width: 18px; height: 18px;
          border-radius: 50%;
          background: #E74C3C;
          border: 3px solid #fff;
          box-shadow: 0 2px 8px rgba(0,0,0,0.3);
          position: absolute;
          top: 50%; left: 50%;
          transform: translate(-50%, -50%);
        }
        @keyframes pulse {
          0% { transform: scale(0.8); opacity: 1; }
          100% { transform: scale(2); opacity: 0; }
        }
        
        .nearby-marker {
          width: 28px; height: 28px;
          cursor: pointer;
          position: relative;
        }
        .nearby-dot {
          width: 14px; height: 14px;
          border-radius: 50%;
          background: #2ECC71;
          border: 2.5px solid #fff;
          box-shadow: 0 2px 6px rgba(0,0,0,0.25);
          position: absolute;
          top: 50%; left: 50%;
          transform: translate(-50%, -50%);
          transition: all 0.2s;
        }
        .nearby-marker:hover .nearby-dot {
          transform: translate(-50%, -50%) scale(1.3);
          background: #27AE60;
        }
    </style>
</head>
<body>
    <div id="map"></div>
    <script>
        mapboxgl.accessToken = '${MapConfig.mapboxToken}';
        const map = new mapboxgl.Map({
            container: 'map',
            style: '${MapConfig.getStyleUri(MapStyle.clean)}',
            center: [$_mainLng, $_mainLat],
            zoom: 13,
            pitch: 0,
            antialias: true,
            attributionControl: false
        });
        
        map.addControl(new mapboxgl.NavigationControl({ showCompass: false }), 'bottom-right');
        
        map.on('load', () => {
            ${markersJs.toString()}
        });
    </script>
</body>
</html>
''';

    final String base64Html = base64Encode(const Utf8Encoder().convert(htmlContent));
    
    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = 'data:text/html;base64,$base64Html'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
      return iframe;
    });

    html.window.onMessage.listen((event) {
      if (event.data is Map) {
        final data = event.data as Map;
        if (data['type'] == 'markerClick') {
          final id = data['id'];
          final isMain = data['isMain'] == true;
          if (mounted) {
            setState(() {
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
            });
          }
        }
      }
    });

    if (mounted) setState(() {});
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
              child: HtmlElementView(viewType: _viewId),
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
