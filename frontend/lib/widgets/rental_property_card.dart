import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../data/properties_data.dart';
import 'package:provider/provider.dart';
import '../theme/favorites_provider.dart';
import '../theme/app_theme.dart';
import '../theme/language_provider.dart';
import 'shimmer_placeholder.dart';

class RentalPropertyCard extends StatelessWidget {
  final Property property;
  final String? heroTag;

  const RentalPropertyCard({
    super.key,
    required this.property,
    this.heroTag,
  });

  String _formatPrice(BuildContext context) {
    if (property.pricePerMonth != null) {
      return '${property.pricePerMonth!.toStringAsFixed(0)} ${context.tr('mad')}';
    } else if (property.price != null) {
      if (property.price! >= 1000000) {
        final priceInMillions = (property.price! / 1000000).toStringAsFixed(2);
        return '${priceInMillions}M ${context.tr('mad')}';
      }
      return '${property.price!.toStringAsFixed(0)} ${context.tr('mad')}';
    }
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final favProvider = context.watch<FavoritesProvider>();
    final isFavorite = favProvider.isFavorite(property.id);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: isDark 
            ? null 
            : Border.all(
                color: const Color(0xFFE2E8F0), // Clean stroke
                width: 1.5, // Slightly thicker for sharpness
              ),
        boxShadow: isDark 
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.02), // Very subtle, sharp shadow
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      margin: const EdgeInsets.only(bottom: 16),
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
              // Image container
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: Hero(
                      tag: heroTag ?? 'property_image_${property.id}',
                      child: CachedNetworkImage(
                        imageUrl: property.image,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const ShimmerPlaceholder(
                          height: 140,
                          width: double.infinity,
                          borderRadius: 0,
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 140,
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
                    height: 140 * 0.4,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black26],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  // Badges (Featured + Type)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Row(
                      children: [
                        if (property.featured) ...[
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded, size: 12, color: AppColors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Featured',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          child: Text(
                            property.type.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Heart Icon
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.3),
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
                            size: 16,
                            color: isFavorite ? AppColors.error : AppColors.white,
                          ),
                        ),
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
                        fontWeight: FontWeight.w800,
                        color: theme.textTheme.bodyLarge?.color,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            property.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (property.bedrooms > 0) ...[
                          Icon(Icons.bed_outlined, size: 14, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
                          const SizedBox(width: 4),
                          Text('${property.bedrooms}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8))),
                          const SizedBox(width: 12),
                        ],
                        if (property.bathrooms > 0) ...[
                          Icon(Icons.water_drop_outlined, size: 14, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
                          const SizedBox(width: 4),
                          Text('${property.bathrooms}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8))),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            _formatPrice(context),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        if (property.pricePerMonth != null)
                          Text(
                            '/${context.tr('month')}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                            ),
                          ),
                      ],
                    ),
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

