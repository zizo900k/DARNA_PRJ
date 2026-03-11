import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/language_provider.dart';
import '../theme/favorites_provider.dart';

class PropertyDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? property;

  const PropertyDetailScreen({super.key, this.property});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  int _currentImageIndex = 0;
  late Map<String, dynamic> _property;

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
          'userReviews': [
            {
              'id': 1,
              'name': 'youssof belaissaoui',
              'avatar': 'https://i.pravatar.cc/150?img=33',
              'rating': 5,
              'date': 'a month ago',
              'comment':
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
            },
            {
              'id': 2,
              'name': 'ayad boukhali',
              'avatar': 'https://i.pravatar.cc/150?img=68',
              'rating': 4,
              'date': '2 weeks ago',
              'comment':
                  'Ut enim ad minim veniam quis nostrud exercitation ullamco laboris nisi ut aliquip.',
            },
          ],
        };
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature (Coming Soon)'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _launchWhatsApp(String phone) async {
    final String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final Uri whatsappUrl = Uri.parse('whatsapp://send?phone=$cleanPhone');

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl);
      } else {
        // Fallback to web URL if app is not installed
        final Uri webUrl = Uri.parse('https://wa.me/$cleanPhone');
        if (await canLaunchUrl(webUrl)) {
          await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not launch WhatsApp')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    }
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
                color: (isDark ? Colors.black : Colors.white).withOpacity(0.7),
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
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

    final images = _property['images'] as List;
    final facilities = _property['facilities'] as List;
    final reviews = _property['userReviews'] as List;
    final nearby = _property['nearbyProperties'] as List;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
            actions: [
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
                  Hero(
                    tag: 'property_image_${_property['id']}',
                    child: CachedNetworkImage(
                      imageUrl: images[_currentImageIndex] as String,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: images.asMap().entries.map((entry) {
                        final index = entry.key;
                        final img = entry.value as String;
                        final isActive = _currentImageIndex == index;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _currentImageIndex = index),
                          child: Container(
                            margin: const EdgeInsets.only(left: 8),
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isActive
                                    ? AppColors.white
                                    : Colors.transparent,
                                width: 2,
                              ),
                              image: DecorationImage(
                                image: CachedNetworkImageProvider(img),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Positioned(
                    bottom: 80,
                    right: 16,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: child,
                        );
                      },
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
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
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
                                _property['title'] as String,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.location_on,
                                      size: 14,
                                      color: theme.textTheme.bodyMedium?.color),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _property['location'] as String,
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
                              'MAD ${_property['price']}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              '/${_property['priceType']}',
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
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.home,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          _property['type'] as String,
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
                          opacity: value,
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
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: CachedNetworkImage(
                              imageUrl: _property['agent']['avatar'] as String,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _property['agent']['name'] as String,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _property['agent']['role'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () {
                              final String phone = _property['agent']
                                      ['phone'] ??
                                  '+212600000000';
                              _launchWhatsApp(phone);
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: CachedNetworkImage(
                                imageUrl:
                                    'https://upload.wikimedia.org/wikipedia/commons/5/5e/WhatsApp_icon.png',
                                width: 28,
                                height: 28,
                                placeholder: (context, url) => const Icon(
                                    Icons.chat_bubble,
                                    color: Color(0xFF25D366),
                                    size: 24),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.chat_bubble,
                                        color: Color(0xFF25D366), size: 24),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Features
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24)
                        .copyWith(bottom: 24),
                    child: Row(
                      children: [
                        Expanded(
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
                                const Icon(Icons.bed_outlined,
                                    size: 20, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  '${_property['bedrooms']} ${context.tr('bedrooms')}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
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
                                const Icon(Icons.bathtub_outlined,
                                    size: 20, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  '${_property['bathrooms']} ${context.tr('bathroom')}',
                                  style: TextStyle(
                                    fontSize: 13,
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
                                  _property['address'] as String,
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
                              const Icon(Icons.share_location,
                                  size: 18, color: AppColors.primary),
                              const SizedBox(width: 12),
                              Text(
                                '${_property['distance']} ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                              Text(
                                '${_property['duration']} . drive',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                              const Spacer(),
                              Icon(Icons.chevron_right,
                                  size: 18,
                                  color: theme.textTheme.bodyMedium?.color),
                            ],
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
                                  Icon(facility['icon'] as IconData,
                                      size: 14,
                                      color: theme.textTheme.bodyMedium?.color),
                                  const SizedBox(width: 6),
                                  Text(
                                    facility['name'] as String,
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
                          ),
                          alignment: Alignment.center,
                          child: Text(context.tr('map_view'),
                              style: TextStyle(
                                  color: theme.textTheme.bodyMedium?.color)),
                        ),
                      ],
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
                                'MAD ${_property['cost']['rent']} /month',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _property['cost']['description'] as String,
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24)
                        .copyWith(bottom: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('reviews'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [AppColors.primary, Color(0xFF16A085)]),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star,
                                  size: 24, color: Color(0xFFFFC107)),
                              const SizedBox(width: 12),
                              Text(
                                _property['rating'].toString(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: reviews
                                    .take(3)
                                    .toList()
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  return Align(
                                    widthFactor: entry.key > 0 ? 0.75 : 1.0,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: AppColors.white, width: 2),
                                        image: DecorationImage(
                                          image: CachedNetworkImageProvider(
                                              entry.value['avatar'] as String),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...reviews.map((review) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? DarkColors.backgroundSecondary
                                  : LightColors.backgroundSecondary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: CachedNetworkImage(
                                        imageUrl: review['avatar'] as String,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            review['name'] as String,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: theme
                                                  .textTheme.bodyLarge?.color,
                                            ),
                                          ),
                                          Text(
                                            review['date'] as String,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: theme
                                                  .textTheme.bodyMedium?.color,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: List.generate(5, (index) {
                                        return Icon(
                                          Icons.star,
                                          size: 12,
                                          color:
                                              index < (review['rating'] as int)
                                                  ? const Color(0xFFFFC107)
                                                  : theme.dividerColor,
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  review['comment'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.textTheme.bodyMedium?.color,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              context.tr('view_all_reviews'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
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
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: CachedNetworkImage(
                                  imageUrl: item['image'] as String,
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
}
