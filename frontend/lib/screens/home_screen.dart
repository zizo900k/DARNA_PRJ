import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../theme/language_provider.dart';
import '../providers/property_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/category_provider.dart';
import '../theme/auth_provider.dart';
import '../data/properties_data.dart';
import '../widgets/category_pill.dart';
import '../widgets/property_card.dart';
import '../widgets/rental_property_card.dart';
import '../widgets/filter_modal.dart';
import '../services/property_service.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  String _selectedCategory = 'All';
  String _selectedLocation = '';
  String _searchQuery = '';
  bool _initialized = false;
  
  List<Map<String, dynamic>> _topLocations = [];
  bool _isTopLocationsLoading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPolling();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startPolling();
      _pollData();
    } else if (state == AppLifecycleState.paused) {
      _pollTimer?.cancel();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollData();
    });
  }

  Future<void> _pollData() async {
    if (!mounted) return;
    try {
      // Fetch new properties silently
      await context.read<PropertyProvider>().loadHomeScreenData(silent: true);
    } catch (e) {
      // Ignore background error
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      Future.microtask(() {
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        context.read<PropertyProvider>().loadHomeScreenData();
        context.read<CategoryProvider>().fetchCategories();
        context.read<ChatProvider>().fetchUnreadCount();
        
        final authProvider = context.read<AuthProvider>();
        if (authProvider.isLoggedIn && authProvider.user != null) {
          final userId = authProvider.user!['id'].toString();
          context.read<NotificationProvider>().fetchNotifications();
          context.read<NotificationProvider>().initWebSocket(userId);
        }
        
        _fetchTopLocations();
      });
    }
  }

  Future<void> _fetchTopLocations() async {
    try {
      final data = await PropertyService.getTopLocations();
      if (mounted) {
        setState(() {
          _topLocations = data;
          _isTopLocationsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTopLocationsLoading = false;
        });
      }
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

  void _showLocationPicker() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cities = [
      '',
      'Agadir',
      'Boujdour',
      'Casablanca',
      'Dakhla',
      'Laayoune',
      'Marrakech',
      'Rabat',
      'Tangier',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                context.tr('change_location'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: cities.length,
                  itemBuilder: (context, index) {
                    final city = cities[index];
                    final isSelected = _selectedLocation == city;
                    return ListTile(
                      title: Text(
                        city.isEmpty ? context.tr('all_morocco') : city,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                          color: isSelected ? AppColors.primary : theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                      onTap: () {
                        setState(() {
                          _selectedLocation = city;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();
    final propertyProvider = context.watch<PropertyProvider>();

    final allFeatured = propertyProvider.featuredProperties;
    final allRental = propertyProvider.rentalProperties;
    final allSale = propertyProvider.saleProperties;
    final allRecent = propertyProvider.recentProperties;
    final isLoading = propertyProvider.isLoading;

    // Filter by selected category and location
    List<Property> filterProperties(List<Property> list) {
      var filtered = list;
      if (_selectedCategory != 'All' && _selectedCategory != 'الكل' && _selectedCategory != 'Tous') {
        filtered = filtered.where((p) {
          final catName = p.categoryName?.toLowerCase() ?? p.type.toLowerCase();
          return catName == _selectedCategory.toLowerCase();
        }).toList();
      }
      if (_selectedLocation.isNotEmpty) {
        filtered = filtered.where((p) => p.location.toLowerCase().contains(_selectedLocation.toLowerCase())).toList();
      }
      return filtered;
    }

    final featuredProperties = filterProperties(allFeatured);
    final rentalProperties = filterProperties(allRental);
    final saleProperties = filterProperties(allSale);
    final recentProperties = filterProperties(allRecent);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.only(
                  top: 12, left: 24, right: 24, bottom: 8),
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
                            onTap: _showLocationPicker,
                            child: Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 16, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  _selectedLocation.isEmpty ? context.tr('all_morocco') : 'Morocco, $_selectedLocation',
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
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? DarkColors.backgroundSecondary
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: isDark ? null : Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
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
                              NotificationsScreen.show(context);
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? DarkColors.backgroundSecondary
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: isDark ? null : Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                              ),
                              child: Consumer<NotificationProvider>(
                                builder: (context, notifProvider, child) {
                                  return Badge(
                                    isLabelVisible: notifProvider.unreadCount > 0,
                                    label: Text(
                                      notifProvider.unreadCount > 9 ? '9+' : '${notifProvider.unreadCount}',
                                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    backgroundColor: AppColors.error,
                                    child: Icon(Icons.notifications_outlined,
                                        size: 24,
                                        color: theme.textTheme.bodyLarge?.color),
                                  );
                                },
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
                          height: 54,
                          decoration: BoxDecoration(
                            color: isDark
                                ? DarkColors.card
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: isDark
                                ? null
                                : Border.all(
                                    color: const Color(0xFFE2E8F0),
                                    width: 1.5,
                                  ),
                            boxShadow: isDark
                                ? [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [], // Removed shadow completely for a clean flat stroke look
                          ),
                          padding: const EdgeInsets.only(left: 16, right: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded,
                                  size: 22, color: AppColors.primary),
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
                                            ?.withValues(alpha: 0.6)),
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
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Icon(Icons.cancel,
                                        size: 20,
                                        color: theme.textTheme.bodyMedium?.color
                                            ?.withValues(alpha: 0.5)),
                                  ),
                                ),
                              Container(
                                height: 24,
                                width: 1,
                                color: isDark ? Colors.grey[800] : Colors.grey[300],
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                              ),
                              GestureDetector(
                                onTap: _showFilterModal,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 22),
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
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Categories
                    const SizedBox(height: 16),
                    _buildSectionHeader(
                        context.tr('categories'), context.tr('see_all')),
                    Consumer<CategoryProvider>(
                      builder: (context, catProvider, _) {
                        if (catProvider.isLoading && catProvider.categories.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        }
                        
                        final allCategories = [
                          {'name': 'All', 'slug': 'all', 'id': 0},
                          ...catProvider.categories
                        ];
                        
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: allCategories.map((cat) {
                              final catName = cat['name'] ?? '';
                              final catSlug = cat['slug'] ?? catName.toLowerCase();
                              
                              String translatedName = catName == 'All' 
                                  ? (context.tr('all') != 'all' ? context.tr('all') : 'All')
                                  : (context.tr('category.$catSlug') != 'category.$catSlug' 
                                      ? context.tr('category.$catSlug') 
                                      : catName);
                                      
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: CategoryPill(
                                  name: translatedName,
                                  isActive: _selectedCategory == catName,
                                  onPress: () => setState(
                                      () => _selectedCategory = catName),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
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
                      physics: const BouncingScrollPhysics(),
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
                        subtitle: context.tr('explore_popular'),
                        onExplore: () => context.go('/top-locations'),
                    ),
                    
                    if (_isTopLocationsLoading)
                      const SizedBox(
                        height: 180,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else 
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: _topLocations.asMap().entries.map((entry) {
                          final index = entry.key;
                          final locationData = entry.value;
                          final locationName = locationData['name'] as String;
                          final listingsCount = locationData['count'] as int;
                          
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(milliseconds: 400 + (index * 150)),
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
                              width: 125,
                              height: 150,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isDark
                                      ? [DarkColors.backgroundSecondary, DarkColors.card]
                                      : [AppColors.primary.withValues(alpha: 0.08), AppColors.primary.withValues(alpha: 0.02)],
                                ),
                                border: Border.all(
                                  color: isDark ? DarkColors.border : AppColors.primary.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () {
                                    context.go('/search', extra: {'city': locationName});
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: isDark ? DarkColors.card : Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.primary.withValues(alpha: 0.1),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.location_on,
                                            color: AppColors.primary,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          locationName,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: theme.textTheme.bodyLarge?.color,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '$listingsCount ${context.tr('listings_suffix') ?? 'listings'}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
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
                      physics: const BouncingScrollPhysics(),
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

                    // Best For Sale
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                        context.tr('best_for_sale') ?? 'Best for Sale', context.tr('see_all'),
                        subtitle: context.tr('properties_for_sale') ?? 'Properties available to buy'),
                    if (isLoading)
                       const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                    else if (saleProperties.isEmpty)
                       Padding(
                         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                         child: Center(child: Text(context.tr('no_sale_found') ?? 'No properties found for sale', style: TextStyle(color: theme.textTheme.bodyMedium?.color))),
                       )
                    else 
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: saleProperties.asMap().entries.map((entry) {
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
                                  heroTag: 'sale_property_image_${property.id}',
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Recent / All Properties
                    const SizedBox(height: 32),
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
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: RentalPropertyCard(
                                property: property,
                                heroTag: 'recent_property_image_${property.id}',
                              ),
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

  Widget _buildSectionHeader(String title, String action, {String? subtitle, VoidCallback? onExplore}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24).copyWith(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: theme.textTheme.bodyLarge?.color,
                    letterSpacing: -0.5,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: onExplore ?? () => context.go('/search'),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                action,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            number,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
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
      color: Colors.white.withValues(alpha: 0.2),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

