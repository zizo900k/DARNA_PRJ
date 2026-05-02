import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../theme/language_provider.dart';
import '../services/property_service.dart';

class TopLocationsScreen extends StatefulWidget {
  const TopLocationsScreen({super.key});

  @override
  State<TopLocationsScreen> createState() => _TopLocationsScreenState();
}

class _TopLocationsScreenState extends State<TopLocationsScreen> {
  List<Map<String, dynamic>> _locations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    try {
      final data = await PropertyService.getTopLocations();
      if (mounted) {
        setState(() {
          _locations = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cityImages = {
      'Laayoune': 'https://images.unsplash.com/photo-1539020140153-e479b8c22e70?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80',
      'Dakhla': 'https://images.unsplash.com/photo-1563604044-f98dc71c08d1?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80',
      'Smara': 'https://images.unsplash.com/photo-1490263625983-057bb081ceee?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80',
      'Boujdour': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80',
    };

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          context.tr('top_locations'),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.iconTheme.color),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _locations.length,
              itemBuilder: (context, index) {
                final location = _locations[index];
                final name = location['name'] as String;
                final count = location['count'] as int;
                final bgUrl = cityImages[name] ?? cityImages['Laayoune']!;

                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 500 + (index * 100)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: Opacity(
                        opacity: value.clamp(0.0, 1.0),
                        child: child,
                      ),
                    );
                  },
                  child: GestureDetector(
                    onTap: () {
                      // Navigate directly to the search tab and apply filter
                      context.go('/search', extra: {'city': name});
                    },
                    child: Container(
                      height: 120,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark 
                              ? [DarkColors.backgroundSecondary, DarkColors.card] 
                              : [AppColors.primary.withValues(alpha: 0.1), AppColors.primary.withValues(alpha: 0.02)],
                        ),
                        border: Border.all(
                          color: isDark ? DarkColors.border : AppColors.primary.withValues(alpha: 0.1),
                          width: 1.5,
                        ),
                        boxShadow: [],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () {
                            context.go('/search', extra: {'city': name});
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isDark ? DarkColors.card : Colors.white,
                                        shape: BoxShape.circle,
                                        border: isDark ? null : Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                                        boxShadow: isDark ? [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(alpha: 0.15),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ] : [],
                                      ),
                                      child: const Icon(
                                        Icons.location_on, 
                                        color: AppColors.primary, 
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            color: theme.textTheme.bodyLarge?.color,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.maps_home_work, 
                                              color: theme.textTheme.bodyMedium?.color, 
                                              size: 14
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '$count ${context.tr('listings_suffix') ?? 'properties'}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: theme.textTheme.bodyMedium?.color,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
