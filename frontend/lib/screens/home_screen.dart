import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../theme/language_provider.dart';
import '../providers/property_provider.dart';
import '../data/properties_data.dart';
import '../widgets/category_pill.dart';
import '../widgets/property_card.dart';
import '../widgets/rental_property_card.dart';
import '../widgets/filter_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      Future.microtask(() {
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        context.read<PropertyProvider>().loadHomeScreenData();
      });
    }
  }

  void _showFilterModal() {
    FilterModal.show(
      context,
      onApply: (filters) {
        debugPrint('Filters applied: $filters');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();
    final propertyProvider = context.watch<PropertyProvider>();

    final featuredProperties = propertyProvider.featuredProperties;
    final rentalProperties = propertyProvider.rentalProperties;
    final recentProperties = propertyProvider.recentProperties;
    final isLoading = propertyProvider.isLoading;

    return Scaffold(
      backgroundColor: isDark
          ? DarkColors.backgroundSecondary
          : LightColors.backgroundSecondary,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.only(
                  top: 12, left: 24, right: 24, bottom: 20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('hello'),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: theme.textTheme.bodyLarge?.color,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('${context.tr('change_location')} (${context.tr('coming_soon')})'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 16, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Morocco, Laayoune',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.textTheme.bodyMedium?.color,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.keyboard_arrow_down,
                                    size: 16,
                                    color: theme.textTheme.bodyMedium?.color),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Theme Toggle Button - KEEPING THIS IN HOME PAGE
                          GestureDetector(
                            onTap: () => themeProvider.toggleTheme(),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? DarkColors.backgroundSecondary
                                    : LightColors.backgroundSecondary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isDark
                                    ? Icons.light_mode_outlined
                                    : Icons.dark_mode_outlined,
                                size: 24,
                                color: isDark
                                    ? Colors.orangeAccent
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Notification Icon
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context.tr('coming_soon')),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? DarkColors.backgroundSecondary
                                    : LightColors.backgroundSecondary,
                                shape: BoxShape.circle,
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(Icons.notifications_outlined,
                                      size: 24,
                                      color: theme.textTheme.bodyLarge?.color),
                                  Positioned(
                                    top: 10,
                                    right: 12,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: theme.cardColor, width: 2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Search Bar
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: isDark
                                ? DarkColors.backgroundSecondary
                                : LightColors.backgroundSecondary,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: isDark
                                    ? DarkColors.border
                                    : LightColors.border),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Icon(Icons.search,
                                  size: 20, color: AppColors.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  readOnly: true,
                                  onTap: () {
                                    context.go('/search');
                                  },
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: theme.textTheme.bodyLarge?.color,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: context.tr('search_properties'),
                                    hintStyle: TextStyle(
                                        color: theme.textTheme.bodyMedium?.color
                                            ?.withValues(alpha: 0.5)),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              if (_searchQuery.isNotEmpty)
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _searchQuery = ''),
                                  child: Icon(Icons.cancel,
                                      size: 20,
                                      color: theme.textTheme.bodyMedium?.color
                                          ?.withValues(alpha: 0.5)),
                                )
                            ],
                          ),
                        ),
                      ),
                      if (_searchQuery.isEmpty) ...[
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _showFilterModal,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryDark
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child:
                                const Icon(Icons.tune, color: AppColors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Categories
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                        context.tr('categories'), context.tr('see_all')),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: PropertiesData.categories.map((category) {
                          String translatedName = context.tr(category.name.toLowerCase());
                          if (translatedName == category.name.toLowerCase()) translatedName = category.name;
                          return CategoryPill(
                            name: translatedName,
                            isActive: _selectedCategory == category.name,
                            onPress: () => setState(
                                () => _selectedCategory = category.name),
                          );
                        }).toList(),
                      ),
                    ),

                    // Stats Banner
                    Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 24, horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                              Icons.home, '5K+', context.tr('properties')),
                          _buildStatDivider(),
                          _buildStatItem(
                              Icons.people, '2K+', context.tr('customers')),
                          _buildStatDivider(),
                          _buildStatItem(
                              Icons.business, '500+', context.tr('agents')),
                        ],
                      ),
                    ),

                    // Featured Properties
                    _buildSectionHeader(context.tr('featured_properties'),
                        context.tr('see_all'),
                        subtitle: context.tr('best_deals')),
                    if (isLoading)
                       const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                    else if (featuredProperties.isEmpty)
                       Padding(
                         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                         child: Center(child: Text(context.tr('no_featured_found'), style: TextStyle(color: theme.textTheme.bodyMedium?.color))),
                       )
                    else 
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children:
                            featuredProperties.asMap().entries.map((entry) {
                          final index = entry.key;
                          final property = entry.value;
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration:
                                Duration(milliseconds: 400 + (index * 150)),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(50 * (1 - value), 0),
                                child: Opacity(
                                  opacity: value.clamp(0.0, 1.0),
                                  child: child,
                                ),
                              );
                            },
                            child: PropertyCard(
                              property: property,
                              variant: PropertyCardVariant.horizontal,
                              showRating: true,
                              heroTag: 'featured_property_image_${property.id}',
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Top Locations
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                        context.tr('top_locations'), context.tr('explore'),
                        subtitle: context.tr('explore_popular')),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          'Laayoune',
                          'Dakhla',
                          'Casablanca',
                          'Marrakech'
                        ].asMap().entries.map((entry) {
                          final index = entry.key;
                          final location = entry.value;
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration:
                                Duration(milliseconds: 400 + (index * 150)),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(50 * (1 - value), 0),
                                child: Opacity(
                                  opacity: value.clamp(0.0, 1.0),
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              width: 140,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color:
                                    isDark ? DarkColors.card : AppColors.white,
                                border: Border.all(
                                  color: isDark
                                      ? DarkColors.border
                                      : LightColors.border,
                                  width: 0.5,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () {},
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: AppColors.primary
                                          .withValues(alpha: isDark ? 0.1 : 0.05),
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? DarkColors.backgroundSecondary
                                                : AppColors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          margin:
                                              const EdgeInsets.only(bottom: 12),
                                          child: const Icon(Icons.location_on,
                                              size: 24,
                                              color: AppColors.primary),
                                        ),
                                        Text(
                                          location,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: theme
                                                .textTheme.bodyLarge?.color,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '20+ ${context.tr('listings_suffix')}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: theme
                                                .textTheme.bodyMedium?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Best For Rent
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                        context.tr('best_for_rent'), context.tr('see_all'),
                        subtitle: context.tr('monthly_rental')),
                    if (isLoading)
                       const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                    else if (rentalProperties.isEmpty)
                       Padding(
                         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                         child: Center(child: Text(context.tr('no_rental_found'), style: TextStyle(color: theme.textTheme.bodyMedium?.color))),
                       )
                    else 
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: rentalProperties.asMap().entries.map((entry) {
                          final index = entry.key;
                          final property = entry.value;
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration:
                                Duration(milliseconds: 400 + (index * 150)),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(50 * (1 - value), 0),
                                child: Opacity(
                                  opacity: value.clamp(0.0, 1.0),
                                  child: child,
                                ),
                              );
                            },
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.65,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: RentalPropertyCard(
                                  property: property,
                                  heroTag: 'rental_property_image_${property.id}',
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Recent / All Properties
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                        context.tr('recent_properties'), context.tr('see_all'),
                        subtitle: context.tr('recently_added')),
                    if (isLoading)
                       const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                    else if (recentProperties.isEmpty)
                       Padding(
                         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                         child: Center(child: Text(context.tr('no_properties_found'), style: TextStyle(color: theme.textTheme.bodyMedium?.color))),
                       )
                    else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: recentProperties.asMap().entries.map((entry) {
                          final index = entry.key;
                          final property = entry.value;
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration:
                                Duration(milliseconds: 300 + (index * 100)),
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
                            child: RentalPropertyCard(
                              property: property,
                              heroTag: 'recent_property_image_${property.id}',
                            ),
                          );
                        }).toList(),
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

  Widget _buildSectionHeader(String title, String action, {String? subtitle}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24).copyWith(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: theme.textTheme.bodyLarge?.color,
                  letterSpacing: -0.5,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ],
          ),
          GestureDetector(
            onTap: () => context.go('/search'),
            child: Text(
              action,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String number, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 24, color: AppColors.white),
          const SizedBox(height: 8),
          Text(
            number,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withValues(alpha: 0.25),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

