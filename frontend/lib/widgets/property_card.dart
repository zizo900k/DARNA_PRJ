import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../data/properties_data.dart';
import 'package:provider/provider.dart';
import '../theme/favorites_provider.dart';
import '../theme/app_theme.dart';
import '../theme/language_provider.dart';
import 'shimmer_placeholder.dart';

enum PropertyCardVariant { horizontal, vertical }

class PropertyCard extends StatelessWidget {
  final Property property;
  final PropertyCardVariant variant;
  final bool showRating;
  final String? heroTag;

  const PropertyCard({
    super.key,
    required this.property,
    this.variant = PropertyCardVariant.horizontal,
    this.showRating = false,
    this.heroTag,
  });

  String _formatPrice(BuildContext context) {
    if (property.pricePerMonth != null) {
      return '${property.pricePerMonth!.toStringAsFixed(0)} ${context.tr('mad')}';
    } else if (property.price != null) {
      final priceInMillions = (property.price! / 1000000).toStringAsFixed(2);
      return '${priceInMillions}M ${context.tr('mad')}';
    }
    return 'Price N/A';
  }

  @override
  Widget build(BuildContext context) {
    final isHorizontal = variant == PropertyCardVariant.horizontal;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = isHorizontal ? screenWidth * 0.85 : screenWidth * 0.43;
    final imageHeight = isHorizontal ? 200.0 : 140.0;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final favProvider = context.watch<FavoritesProvider>();
    final isFavorite = favProvider.isFavorite(property.id);

    return Container(
      width: cardWidth,
      margin: EdgeInsets.only(
        right: isHorizontal || !isHorizontal ? 16 : 0, // Simplified standard margin
        bottom: isHorizontal ? 0 : 16,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            context.push('/property/${property.id}', extra: {'heroTag': heroTag ?? 'property_image_${property.id}'});
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Container
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: Hero(
                      tag: heroTag ?? 'property_image_${property.id}',
                      child: CachedNetworkImage(
                        imageUrl: property.image,
                        height: imageHeight,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => ShimmerPlaceholder(
                          height: imageHeight,
                          width: double.infinity,
                          borderRadius: 0,
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: imageHeight,
                          color: isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary,
                          child: const Icon(Icons.error),
                        ),
                      ),
                    ),
                  ),
                  // Gradient Overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: imageHeight * 0.5,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black45],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  // Featured Badge
                  if (property.featured)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 12, color: AppColors.white),
                            SizedBox(width: 4),
                            Text(
                              'Featured',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Favorite Button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Material(
                      color: (isDark ? DarkColors.card : Colors.white).withValues(alpha: 0.95),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          context.read<FavoritesProvider>().toggleFavorite(property.toMap());
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 18,
                            color: isFavorite ? AppColors.error : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Price Badge
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _formatPrice(context),
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (property.pricePerMonth != null)
                            Text(
                              '/${context.tr('month')}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: theme.textTheme.bodyLarge?.color,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            property.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (property.bedrooms > 0) ...[
                          Icon(Icons.bed_outlined, size: 14, color: theme.textTheme.bodyMedium?.color),
                          const SizedBox(width: 4),
                          Text('${property.bedrooms}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textTheme.bodyMedium?.color)),
                          const SizedBox(width: 12),
                        ],
                        if (property.bathrooms > 0) ...[
                          Icon(Icons.water_drop_outlined, size: 14, color: theme.textTheme.bodyMedium?.color),
                          const SizedBox(width: 4),
                          Text('${property.bathrooms}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textTheme.bodyMedium?.color)),
                          const SizedBox(width: 12),
                        ],
                        if (property.area > 0) ...[
                          Icon(Icons.square_foot_outlined, size: 14, color: theme.textTheme.bodyMedium?.color),
                          const SizedBox(width: 4),
                          Text('${property.area} mآ²', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textTheme.bodyMedium?.color)),
                        ],
                      ],
                    ),
                    if (showRating && property.rating > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Color(0xFFFFC107)),
                          const SizedBox(width: 4),
                          Text(
                            '${property.rating}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

