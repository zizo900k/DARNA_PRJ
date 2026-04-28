import 'dart:convert';
import 'dart:math' show asin, atan2, cos, pi, sin, sqrt;
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/chat_service.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/language_provider.dart';
import '../theme/favorites_provider.dart';
import '../services/property_service.dart';
import '../services/request_service.dart';
import '../theme/auth_provider.dart';
import 'package:intl/intl.dart';
import '../widgets/map/mapbox_widget.dart';
import '../config/map_config.dart';
import '../widgets/user_avatar.dart';
import '../services/review_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class PropertyDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? property;
  final String? heroTag;

  const PropertyDetailScreen({super.key, this.property, this.heroTag});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  int _currentImageIndex = 0;
  late Map<String, dynamic> _property;
  String? _userDistance;
  String? _userDuration;
  double? _userLat;
  double? _userLng;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Use passed property or default mock data
    _property = widget.property ??
        {
          'id': 1,
          'title': 'Hay El Wahda',
          'price': 1500,
          'priceType': 'month',
          'location': 'Laayoune, Morocco',
          'rating': 4.9,
          'reviews': 120,
          'images': [
            'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800',
            'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800',
            'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800',
          ],
          'bedrooms': 2,
          'bathrooms': 1,
          'area': 120,
          'type': 'Apartment',
          'agent': {
            'name': 'Mohammed Abu-obaiday',
            'avatar': 'https://i.pravatar.cc/150?img=12',
            'role': 'Property Owner',
          },
          'address': 'Laayoune Morocco 18 Rue de Mekka Bloc H Num 205',
          'distance': '2.5 km',
          'duration': '22 mins',
          'facilities': [
            {
              'icon': Icons.local_hospital_outlined,
              'name': '1 Hospital',
              'distance': '2 km'
            },
            {
              'icon': Icons.local_gas_station_outlined,
              'name': '2 Gas stations',
              'distance': '4 km'
            },
            {
              'icon': Icons.school_outlined,
              'name': '2 Schools',
              'distance': '3 km'
            },
          ],
          'cost': {
            'rent': 1500,
            'description': 'Rent average (1500 MAD) + cost / 12 for calculate',
          },
          'nearbyProperties': [
            {
              'id': 2,
              'image':
                  'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=400'
            },
            {
              'id': 3,
              'image':
                  'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=400'
            },
          ],
        };

    // Fetch real data in background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPropertyDetails();
    });
  }

  Future<void> _fetchPropertyDetails() async {
    if (!mounted) return;
    try {
      final response =
          await PropertyService.getProperty(_property['id'] as int);
      if (mounted) {
        setState(() {
          // Backend returns property directly, or wrapped in 'data'
          if (response.containsKey('data') && response['data'] is Map) {
            _property = Map<String, dynamic>.from(response['data']);
          } else {
            _property = Map<String, dynamic>.from(response);
          }
          _isLoading = false;
        });
        _calculateDistance();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          debugPrint(e.toString());
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _calculateDistance() async {
    final propLat = double.tryParse(_property['latitude']?.toString() ?? '');
    final propLng = double.tryParse(_property['longitude']?.toString() ?? '');
    if (propLat == null || propLng == null) {
      if (mounted) setState(() { _userDistance = 'Location not set'; _userDuration = ''; });
      return;
    }
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (mounted) setState(() { _userDistance = 'Enable location'; _userDuration = 'to see distance'; });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _userLat = pos.latitude;
      _userLng = pos.longitude;

      // Use OSRM for exact road distance & duration
      final osrmUrl = 'https://router.project-osrm.org/route/v1/driving/'
          '${pos.longitude},${pos.latitude};$propLng,$propLat?overview=false';
      final response = await http.get(Uri.parse(osrmUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final distMeters = (route['distance'] as num).toDouble();
          final durationSecs = (route['duration'] as num).toDouble();

          final distKm = distMeters / 1000;
          final mins = (durationSecs / 60).round();

          if (mounted) {
            setState(() {
              _userDistance = distKm < 1
                  ? '${distMeters.round()} m'
                  : '${distKm.toStringAsFixed(1)} km';
              _userDuration = mins < 60
                  ? '$mins min drive'
                  : '${(mins / 60).floor()}h ${mins % 60}min drive';
            });
          }
          return;
        }
      }
      // Fallback to Haversine if OSRM fails
      final dist = _haversine(pos.latitude, pos.longitude, propLat, propLng);
      final driveMins = (dist / 50 * 60).round();
      if (mounted) {
        setState(() {
          _userDistance = dist < 1 ? '${(dist * 1000).round()} m' : '~${dist.toStringAsFixed(1)} km';
          _userDuration = driveMins < 60 ? '~$driveMins min drive' : '~${(driveMins / 60).toStringAsFixed(1)} h drive';
        });
      }
    } catch (e) {
      debugPrint('Distance calc error: $e');
      if (mounted) setState(() { _userDistance = 'Tap for directions'; _userDuration = ''; });
    }
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  Future<void> _openGoogleMapsDirections() async {
    final propLat = double.tryParse(_property['latitude']?.toString() ?? '');
    final propLng = double.tryParse(_property['longitude']?.toString() ?? '');
    if (propLat == null || propLng == null) return;

    String urlStr = 'https://www.google.com/maps/dir/?api=1&destination=$propLat,$propLng&travelmode=driving';
    // Include user's current location as origin for full route
    if (_userLat != null && _userLng != null) {
      urlStr = 'https://www.google.com/maps/dir/?api=1&origin=$_userLat,$_userLng&destination=$propLat,$propLng&travelmode=driving';
    }
    final url = Uri.parse(urlStr);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature (Coming Soon)'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool _isProcessingAction = false;

  Future<void> _handlePropertyRequest() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr('require_login'))));
      return;
    }

    if (_property['user_id'] != null &&
        _property['user_id'] == authProvider.user?['id']) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('cannot_request_own') ?? 'You cannot request your own property.')));
      return;
    }

    final isRent = _property['type'] == 'rent';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime selectedDate = today.add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    final messageController = TextEditingController();
    String requestType = 'visit'; // Default

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (stCtx, stSetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('request_visit') ?? 'Demander une visite',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: requestType,
                      decoration: InputDecoration(
                        labelText: context.tr('request_type') ?? 'Type de demande',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [
                        DropdownMenuItem(value: 'visit', child: Text(context.tr('visit') ?? 'Visite')),
                        DropdownMenuItem(
                          value: isRent ? 'rent_interest' : 'buy_interest',
                          child: Text(isRent ? (context.tr('rent_interest') ?? 'Intéressé(e) pour louer') : (context.tr('buy_interest') ?? 'Intéressé(e) pour acheter')),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          stSetState(() => requestType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.tr('preferred_date') ?? 'Date souhaitée'),
                      subtitle: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: today,
                          lastDate: today.add(const Duration(days: 90)),
                        );
                        if (picked != null) {
                          stSetState(() => selectedDate = picked);
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.tr('preferred_time') ?? 'Heure souhaitée'),
                      subtitle: Text(selectedTime.format(context)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          stSetState(() => selectedTime = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: messageController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: context.tr('message_optional') ?? 'Message (optionnel)',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          context.tr('submit_request') ?? 'Envoyer la demande',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (submitted != true) return;

    setState(() => _isProcessingAction = true);
    try {
      final res = await RequestService.createRequest(
        _property['id'] as int,
        {
          'request_type': requestType,
          'preferred_date': DateFormat('yyyy-MM-dd').format(selectedDate),
          'preferred_time': '${selectedTime.hour}:${selectedTime.minute}',
          'message': messageController.text.trim(),
        },
      );
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(context.tr('success')),
            content: Text(res['message']?.toString() ?? 'Request sent successfully.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(context.tr('ok'))),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${context.tr('error')} ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingAction = false);
      }
    }
  }

  Future<void> _openChat() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);

    if (!authProvider.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(langProvider.translate('require_login'))),
      );
      return;
    }

    final ownerId = _property['user_id'] ?? _property['user']?['id'];
    if (ownerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(langProvider.translate('error') + 'Owner not found')),
      );
      return;
    }

    if (ownerId == authProvider.user?['id']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(langProvider.translate('cannot_chat_own'))),
      );
      return;
    }

    try {
      final conv = await ChatService.getOrCreateConversation(
        user2Id: ownerId,
        propertyId: _property['id'] as int?,
      );

      // Send auto message if new conversation
      if (conv['is_new'] == true) {
        await ChatService.sendMessage(
          conv['id'] as int,
          langProvider.translate('chat_auto_message'),
        );
      }

      if (mounted) {
        context.push('/chat/${conv['id']}', extra: {
          'conversationId': conv['id'],
          'otherUser': conv['other_user'],
          'property': conv['property'],
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${langProvider.translate('error')} $e')),
        );
      }
    }
  }

  void _showReviewForm(BuildContext context,
      {Map<String, dynamic>? existingReview}) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr('require_login'))));
      return;
    }

    // Check if the current user is the owner
    final ownerId = _property['user_id'] ?? _property['user']?['id'];
    if (ownerId == authProvider.user?['id']) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('owner_review_error'))));
      return;
    }

    int selectedRating = existingReview?['rating'] ?? 5;
    final commentController =
        TextEditingController(text: existingReview?['comment'] ?? '');

    // Fallback UI keys for localized texts
    final String title = existingReview == null
        ? context.tr('leave_review')
        : context.tr('edit_review');
    final String submitBtn = context.tr('submit_review');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (stCtx, stSetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          size: 40,
                          color: index < selectedRating
                              ? const Color(0xFFFFC107)
                              : Colors.grey,
                        ),
                        onPressed: () {
                          stSetState(() => selectedRating = index + 1);
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: context.tr('comment'),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        setState(() => _isProcessingAction = true);
                        try {
                          if (existingReview == null) {
                            await ReviewService.addReview(
                                _property['id'] as int, {
                              'rating': selectedRating,
                              'comment': commentController.text,
                            });
                          } else {
                            await ReviewService.updateReview(
                                existingReview['id'] as int, {
                              'rating': selectedRating,
                              'comment': commentController.text,
                            });
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(context.tr('review_success'))));
                            _fetchPropertyDetails(); // Refresh property object to get updated reviews and rating
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())));
                          }
                        } finally {
                          if (mounted)
                            setState(() => _isProcessingAction = false);
                        }
                      },
                      child: Text(submitBtn,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (existingReview != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(
                          context.tr('delete_review'),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          setState(() => _isProcessingAction = true);
                          try {
                            await ReviewService.deleteReview(existingReview['id'] as int);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(context.tr('review_deleted_success'))));
                              _fetchPropertyDetails();
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())));
                            }
                          } finally {
                            if (mounted)
                              setState(() => _isProcessingAction = false);
                          }
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAppBarButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
    bool marginEnd = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(
          top: 8,
          bottom: 8,
          left: 12,
          right: marginEnd ? 16 : 0,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (isDark ? Colors.black : Colors.white)
                    .withValues(alpha: 0.7),
                shape: BoxShape.circle,
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color:
                    iconColor ?? Theme.of(context).textTheme.bodyLarge?.color,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final favProvider = context.watch<FavoritesProvider>();
    final isFavorite = favProvider.isFavorite(_property['id'] as int);
    final authProvider = context.watch<AuthProvider>();
    final ownerId = _property['user_id'] ?? _property['user']?['id'];
    final isOwner = authProvider.isLoggedIn && ownerId != null && ownerId == authProvider.user?['id'];
    final isAdmin = authProvider.isLoggedIn && authProvider.user?['role'] == 'admin';

    final rawImages =
        (_property['photos'] as List?) ?? (_property['images'] as List?) ?? [];
    final images = rawImages.map((img) {
      if (img is String) return img;
      if (img is Map) {
        return (img['full_url'] as String?) ??
            (img['url'] as String?) ??
            'https://placehold.co/800x600/20B2AA/FFFFFF/png?text=Darna+Image';
      }
      return 'https://placehold.co/800x600/20B2AA/FFFFFF/png?text=Darna+Image';
    }).toList();

    final agent = _property['user'] ??
        _property['agent'] ??
        {
          'name': 'Unknown Agent',
          'avatar': 'https://ui-avatars.com/api/?name=Unknown+Agent',
          'role': 'Property Owner',
        };
    final agentName = agent['name'] ?? agent['full_name'] ?? 'Unknown Agent';
    final agentAvatar =
        agent['full_avatar_url'] ?? agent['profile_picture'] ?? agent['avatar'];

    final agentRole = agent['role'] ?? 'Property Owner';
    final propertyAddress =
        _property['address'] ?? _property['location'] ?? 'Unknown location';

    final facilities = (_property['facilities'] as List?) ?? [];
    final reviews = (_property['reviews'] as List?) ?? [];
    double averageRating =
        double.tryParse(_property['rating']?.toString() ?? '0') ?? 0.0;
    final nearby = (_property['nearbyProperties'] as List?) ?? [];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      bottomNavigationBar: (isOwner || isAdmin) ? const SizedBox.shrink() : _buildBottomBar(theme, isDark),
      body: CustomScrollView(
        slivers: [
          // Image Header
          SliverAppBar(
            expandedHeight: screenHeight * 0.35,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            leading: _buildAppBarButton(
              context: context,
              icon: Icons.arrow_back,
              onTap: () => context.pop(),
            ),
            actions: isAdmin ? [] : [
              _buildAppBarButton(
                context: context,
                icon: Icons.share_outlined,
                onTap: () {
                  // Share logic
                },
              ),
              _buildAppBarButton(
                context: context,
                icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                iconColor: isFavorite ? AppColors.error : null,
                onTap: () =>
                    context.read<FavoritesProvider>().toggleFavorite(_property),
                marginEnd: true,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Swipeable photo gallery
                  images.isNotEmpty
                      ? PageView.builder(
                          itemCount: images.length,
                          onPageChanged: (i) =>
                              setState(() => _currentImageIndex = i),
                          itemBuilder: (ctx, i) => Hero(
                            tag: i == 0
                                ? (widget.heroTag ??
                                    'property_image_${_property['id']}')
                                : 'property_image_${_property['id']}_$i',
                            child: Image.network(
                              images[i],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: double.infinity,
                                color: Colors.grey.withValues(alpha: 0.2),
                                child: const Icon(Icons.image_not_supported,
                                    size: 48),
                              ),
                            ),
                          ),
                        )
                      : Hero(
                          tag: widget.heroTag ??
                              'property_image_${_property['id']}',
                          child: Image.network(
                            'https://placehold.co/800x600/20B2AA/FFFFFF/png?text=Darna+Image',
                            fit: BoxFit.cover,
                          ),
                        ),

                  // Page indicator dots
                  if (images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: images.asMap().entries.map((entry) {
                          final isActive = _currentImageIndex == entry.key;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isActive ? 20 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.primary
                                  : Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  // Photo count badge
                  if (images.length > 1)
                    Positioned(
                      bottom: 40,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1} / ${images.length}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),

                  // AR View button
                  Positioned(
                    bottom: images.length > 1 ? 60 : 16,
                    left: 16,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) =>
                          Transform.scale(scale: value, child: child),
                      child: GestureDetector(
                        onTap: () => _showComingSoon('AR View'),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [AppColors.primary, Color(0xFF16A085)]),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4))
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.view_in_ar,
                              color: AppColors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Price
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _property['title']?.toString() ?? 'Property',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                              if (_isLoading) ...[
                                const SizedBox(height: 8),
                                const LinearProgressIndicator(),
                              ],
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.location_on,
                                      size: 14,
                                      color: theme.textTheme.bodyMedium?.color),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _property['location']?.toString() ??
                                          'Location',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color:
                                            theme.textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${_property['price_per_month'] ?? _property['price'] ?? _property['pricePerMonth'] ?? 'N/A'} ${context.tr('mad')}',
                              textDirection: ui.TextDirection.ltr,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            if (_property['type'] == 'rent' ||
                                _property['price_per_month'] != null ||
                                _property['pricePerMonth'] != null)
                              Text(
                                '/${context.tr('month')}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Type Badge
                  Container(
                    margin: const EdgeInsets.only(left: 24, bottom: 20),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.home,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          _property['category'] != null
                              ? _property['category']['name']
                              : (_property['type']?.toString() ?? 'Property'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Agent Info
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 50 * (1 - value)),
                        child: Opacity(
                          opacity: value.clamp(0.0, 1.0),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24)
                          .copyWith(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? DarkColors.backgroundSecondary
                            : LightColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          UserAvatar(
                            name: agentName,
                            imageUrl: agentAvatar,
                            size: 50,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  agentName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  agentRole,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isOwner && !isAdmin) ...[
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: _openChat,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      Color(0xFF16A085)
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.chat_bubble_outline,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Features — full room details
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24)
                        .copyWith(bottom: 8),
                    child: Text(
                      context.tr('features'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24)
                        .copyWith(bottom: 24),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildFeatureTile(
                            Icons.bed_outlined,
                            '${_property['bedrooms'] ?? 0}',
                            context.tr('bedroom'),
                            theme,
                            isDark),
                        _buildFeatureTile(
                            Icons.bathtub_outlined,
                            '${_property['bathrooms'] ?? 0}',
                            context.tr('bathroom'),
                            theme,
                            isDark),
                        if ((_property['kitchens'] ?? 0) > 0)
                          _buildFeatureTile(
                              Icons.kitchen_outlined,
                              '${_property['kitchens']}',
                              context.tr('kitchen'),
                              theme,
                              isDark),
                        if ((_property['toilets'] ?? 0) > 0)
                          _buildFeatureTile(
                              Icons.wc_outlined,
                              '${_property['toilets']}',
                              context.tr('toilet'),
                              theme,
                              isDark),
                        if ((_property['living_rooms'] ?? 0) > 0)
                          _buildFeatureTile(
                              Icons.weekend_outlined,
                              '${_property['living_rooms']}',
                              context.tr('living_room'),
                              theme,
                              isDark),
                        if ((_property['balcony'] ?? 0) > 0)
                          _buildFeatureTile(
                              Icons.balcony_outlined,
                              '${_property['balcony']}',
                              context.tr('balcony'),
                              theme,
                              isDark),
                        if ((_property['area'] ?? 0) > 0)
                          _buildFeatureTile(
                              Icons.crop_square_outlined,
                              '${_property['area']} m²',
                              context.tr('area_label').split(' ').first,
                              theme,
                              isDark),
                        if ((_property['total_rooms'] ?? 0) > 0)
                          _buildFeatureTile(
                              Icons.door_sliding_outlined,
                              '${_property['total_rooms']}',
                              context.tr('total_rooms'),
                              theme,
                              isDark),
                      ],
                    ),
                  ),

                  // Location Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24)
                        .copyWith(bottom: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('location_facilities'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? DarkColors.backgroundSecondary
                                : LightColors.backgroundSecondary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 18, color: AppColors.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  propertyAddress,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _openGoogleMapsDirections(),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? DarkColors.backgroundSecondary
                                  : LightColors.backgroundSecondary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.directions_car_outlined,
                                    size: 18, color: AppColors.primary),
                                const SizedBox(width: 12),
                                Text(
                                  _userDistance ?? 'Calculating...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _userDuration ?? '',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.textTheme.bodyMedium?.color,
                                  ),
                                ),
                                const Spacer(),
                                Icon(Icons.open_in_new,
                                    size: 16,
                                    color: AppColors.primary),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: facilities.map((facility) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? DarkColors.backgroundSecondary
                                    : LightColors.backgroundSecondary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                      facility is Map
                                          ? (facility['icon'] as IconData? ??
                                              Icons.check_circle_outline)
                                          : Icons.check_circle_outline,
                                      size: 14,
                                      color: theme.textTheme.bodyMedium?.color),
                                  const SizedBox(width: 6),
                                  Text(
                                    facility is Map
                                        ? (facility['name']?.toString() ?? '')
                                        : facility.toString(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: isDark
                                ? DarkColors.backgroundSecondary
                                : LightColors.backgroundSecondary,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.3)),
                          ),
                          alignment: Alignment.center,
                          clipBehavior: Clip.antiAlias,
                          child: _property['latitude'] != null &&
                                  _property['longitude'] != null
                              ? MapboxWidget(
                                  initialLatitude: double.tryParse(
                                      _property['latitude'].toString()),
                                  initialLongitude: double.tryParse(
                                      _property['longitude'].toString()),
                                  isPicker: false,
                                  mapStyle: MapStyle.premium3D,
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.map_outlined,
                                          color: theme.dividerColor, size: 40),
                                      const SizedBox(height: 8),
                                      Text(
                                        context.tr('location_not_set'),
                                        style: TextStyle(
                                            color: theme
                                                .textTheme.bodyMedium?.color,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),

                  // View on Map button
                  if (_property['latitude'] != null && _property['longitude'] != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24).copyWith(bottom: 20),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.push('/nearby-map', extra: _property);
                          },
                          icon: const Icon(Icons.explore_rounded, size: 18),
                          label: Text(context.tr('view_on_map')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),
                      ),
                    ),

                  // Cost of Living Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24)
                        .copyWith(bottom: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.tr('cost_of_living'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            Text(
                              context.tr('see_details'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? DarkColors.backgroundSecondary
                                : LightColors.backgroundSecondary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_property['cost']?['rent'] ?? _property['price'] ?? 0} ${context.tr('mad')} /${context.tr('month')}',
                                textDirection: ui.TextDirection.ltr,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _property['cost']?['description']?.toString() ??
                                    context.tr('cost_desc_not_avail'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.textTheme.bodyMedium?.color,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Reviews
                  if (reviews.isNotEmpty ||
                      Provider.of<AuthProvider>(context, listen: false)
                          .isLoggedIn)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16)
                          .copyWith(bottom: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                context.tr('reviews'),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                              if (!isOwner)
                                Builder(builder: (context) {
                                  final auth = context.watch<AuthProvider>();
                                // Find if current user already reviewed
                                final existingReview = auth.isLoggedIn &&
                                        reviews.isNotEmpty
                                    ? reviews
                                        .cast<Map<dynamic, dynamic>>()
                                        .firstWhere(
                                          (r) =>
                                              r['user_id'] ==
                                                  auth.user?['id'] ||
                                              (r['user'] != null &&
                                                  r['user']['id'] ==
                                                      auth.user?['id']),
                                          orElse: () => <dynamic, dynamic>{},
                                        )
                                        .cast<String, dynamic>()
                                    : <String, dynamic>{};
                                final hasReviewed = existingReview.isNotEmpty;
                                return InkWell(
                                  onTap: () => _showReviewForm(context,
                                      existingReview:
                                          hasReviewed ? existingReview : null),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          hasReviewed
                                              ? Icons.edit_outlined
                                              : Icons.add_circle_outline,
                                          size: 16,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          hasReviewed
                                              ? context.tr('edit_review')
                                              : context.tr('leave_review'),
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (reviews.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0F2027),
                                    Color(0xFF203A43),
                                    Color(0xFF2C5364)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  )
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        averageRating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 36,
                                          height: 1.0,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: List.generate(5, (index) {
                                          return Icon(
                                            index < averageRating.round()
                                                ? Icons.star_rounded
                                                : Icons.star_outline_rounded,
                                            size: 18,
                                            color: const Color(0xFFFFC107),
                                          );
                                        }),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${reviews.length} ${context.tr('reviews')}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Avatars
                                  if (reviews.isNotEmpty)
                                    SizedBox(
                                      height: 44,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: reviews
                                            .take(4)
                                            .toList()
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                          final rMap = entry.value as Map;
                                          final user = rMap['user'];
                                          final avatar = (user != null
                                                  ? (user['full_avatar_url'] ??
                                                      user['profile_picture'] ??
                                                      user['avatar'])
                                                  : null) ??
                                              rMap['avatar'] ??
                                              'https://i.pravatar.cc/150?img=${33 + entry.key}';
                                          return Align(
                                            widthFactor: 0.7,
                                            child: Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                    color:
                                                        const Color(0xFF203A43),
                                                    width: 3),
                                                image: DecorationImage(
                                                  image:
                                                      CachedNetworkImageProvider(
                                                          avatar.toString()),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 24),
                          ...reviews.map((rawReview) {
                            final review = rawReview as Map;
                            final user = review['user'] ?? {};
                            final reviewerName = user['name'] ??
                                user['full_name'] ??
                                review['name'] ??
                                'Reviewer';
                            final reviewerAvatar = user['full_avatar_url'] ??
                                user['profile_picture'] ??
                                user['avatar'] ??
                                review['avatar'] ??
                                'https://i.pravatar.cc/150';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? DarkColors.backgroundSecondary
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.black.withValues(alpha: 0.03)),
                                boxShadow: [
                                  if (!isDark)
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      UserAvatar(
                                        imageUrl: reviewerAvatar.toString(),
                                        name: reviewerName.toString(),
                                        size: 46,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              reviewerName.toString(),
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: theme
                                                    .textTheme.bodyLarge?.color,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Row(
                                                  children:
                                                      List.generate(5, (index) {
                                                    return Icon(
                                                      index <
                                                              (int.tryParse(review[
                                                                              'rating']
                                                                          ?.toString() ??
                                                                      '0') ??
                                                                  0)
                                                          ? Icons.star_rounded
                                                          : Icons
                                                              .star_outline_rounded,
                                                      size: 14,
                                                      color: const Color(
                                                          0xFFFFB300),
                                                    );
                                                  }),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  review['created_at'] != null
                                                      ? DateFormat(
                                                              'MMM dd, yyyy')
                                                          .format(DateTime.parse(
                                                              review['created_at']
                                                                  .toString()))
                                                      : review['date']
                                                              ?.toString() ??
                                                          'recently',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: theme.textTheme
                                                        .bodyMedium?.color
                                                        ?.withValues(
                                                            alpha: 0.7),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (review['comment'] != null &&
                                      review['comment']
                                          .toString()
                                          .trim()
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Text(
                                      '“${review['comment']}”',
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                        fontStyle: FontStyle.italic,
                                        color: theme.textTheme.bodyMedium?.color
                                            ?.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                  // Nearby
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('nearby_location'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: nearby.map((item) {
                              return Container(
                                width: 140,
                                height: 180,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: CachedNetworkImage(
                                  imageUrl: item['image']?.toString() ??
                                      'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=400',
                                  fit: BoxFit.cover,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme, bool isDark) {
    if (_property.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isProcessingAction ? null : _handlePropertyRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isProcessingAction
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(
                    context.tr('request_visit'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTile(
      IconData icon, String value, String label, ThemeData theme, bool isDark) {
    return Container(
      width: (MediaQuery.of(context).size.width - 24 * 2 - 12) / 2,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? DarkColors.backgroundSecondary
            : LightColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: isDark ? DarkColors.border : LightColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  textDirection: ui.TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
