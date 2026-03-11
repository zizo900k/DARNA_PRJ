import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../data/properties_data.dart';
import '../widgets/category_pill.dart';
import '../widgets/rental_property_card.dart';
import '../widgets/filter_modal.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortOption = 'Default';

  final List<String> _sortOptions = [
    'Default',
    'Price: Low to High',
    'Price: High to Low',
    'Rating'
  ];

  void _showFilterModal() {
    FilterModal.show(
      context,
      onApply: (filters) {
        print('Filters applied: $filters');
      },
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? DarkColors.border : LightColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Sort By',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 16),
              ..._sortOptions.map((option) {
                final isSelected = _sortOption == option;
                return GestureDetector(
                  onTap: () {
                    setState(() => _sortOption = option);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.12)
                          : (isDark
                              ? DarkColors.backgroundSecondary
                              : LightColors.backgroundSecondary),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          option,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? AppColors.primary
                                : theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle,
                              color: AppColors.primary, size: 20),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
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

    final filteredProperties = PropertiesData.properties.where((property) {
      final matchesSearch = property.title
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          property.location.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' ||
          property.type == _selectedCategory.toLowerCase();
      // Added basic category matching workaround representing Expo data consistency
      final hasSelectedCat = _selectedCategory == 'All' ||
          property.title
              .toLowerCase()
              .contains(_selectedCategory.toLowerCase());
      return matchesSearch && (matchesCategory || hasSelectedCat);
    }).toList()
      ..sort((a, b) {
        switch (_sortOption) {
          case 'Price: Low to High':
            return (a.pricePerMonth ?? a.price ?? 0)
                .compareTo(b.pricePerMonth ?? b.price ?? 0);
          case 'Price: High to Low':
            return (b.pricePerMonth ?? b.price ?? 0)
                .compareTo(a.pricePerMonth ?? a.price ?? 0);
          case 'Rating':
            return b.rating.compareTo(a.rating);
          default:
            return 0;
        }
      });

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
              color: theme.cardColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discover',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: theme.textTheme.bodyLarge?.color,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Find your perfect property',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: theme.textTheme.bodyMedium?.color,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.25)),
                      color: AppColors.primary.withOpacity(0.15),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: const Text(
                      '10', // Hardcoded for demo/matching properties.length
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Section
            Container(
              color: theme.cardColor,
              padding: const EdgeInsets.symmetric(horizontal: 24)
                  .copyWith(bottom: 16),
              child: Row(
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
                            color:
                                isDark ? DarkColors.border : LightColors.border,
                            width: 1.5),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(Icons.search,
                              size: 20, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              onChanged: (val) =>
                                  setState(() => _searchQuery = val),
                              style: TextStyle(
                                fontSize: 15,
                                color: theme.textTheme.bodyLarge?.color,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search properties...',
                                hintStyle: TextStyle(
                                    color: theme.textTheme.bodyMedium?.color
                                        ?.withOpacity(0.6)),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () => setState(() => _searchQuery = ''),
                              child: Icon(Icons.cancel,
                                  size: 20,
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withOpacity(0.5)),
                            )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _showFilterModal,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(Icons.tune,
                          color: AppColors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Categories
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 20, bottom: 16, left: 24),
                          child: Text(
                            'Categories',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: theme.textTheme.bodyLarge?.color,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: PropertiesData.categories.map((category) {
                              return CategoryPill(
                                name: category.name,
                                isActive: _selectedCategory == category.name,
                                onPress: () => setState(
                                    () => _selectedCategory = category.name),
                              );
                            }).toList(),
                          ),
                        ),

                        // Results Header
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.15),
                                  border: Border.all(
                                      color:
                                          AppColors.primary.withOpacity(0.25)),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.home,
                                        size: 16, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${filteredProperties.length} ${filteredProperties.length == 1 ? 'Property' : 'Properties'}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: _showSortBottomSheet,
                                child: Row(
                                  children: [
                                    Icon(Icons.swap_vert,
                                        size: 16,
                                        color:
                                            theme.textTheme.bodyMedium?.color),
                                    const SizedBox(width: 6),
                                    Text(
                                      _sortOption == 'Default'
                                          ? 'Sort'
                                          : _sortOption,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _sortOption == 'Default'
                                            ? theme.textTheme.bodyMedium?.color
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Results Grid
                  filteredProperties.isNotEmpty
                      ? SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio:
                                  0.65, // Adjust based on RentalPropertyCard content details
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 0,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return TweenAnimationBuilder<double>(
                                  key: ValueKey(filteredProperties[index].id),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: Duration(
                                      milliseconds:
                                          400 + (index.clamp(0, 10) * 100)),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) {
                                    return Transform.translate(
                                      offset: Offset(0, 30 * (1 - value)),
                                      child: Opacity(
                                        opacity: value,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: RentalPropertyCard(
                                    property: filteredProperties[index],
                                  ),
                                );
                              },
                              childCount: filteredProperties.length,
                            ),
                          ),
                        )
                      : SliverFillRemaining(
                          hasScrollBody: false,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutBack,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: 0.8 + (0.2 * value),
                                child: Opacity(
                                  opacity: value,
                                  child: child,
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 60, horizontal: 32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.primary.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: AppColors.primary
                                              .withOpacity(0.20),
                                          width: 2),
                                    ),
                                    child: const Icon(Icons.search_off,
                                        size: 48, color: AppColors.primary),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'No Properties Found',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: theme.textTheme.bodyLarge?.color,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'We couldn\'t find any properties matching\nyour search criteria.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: theme.textTheme.bodyMedium?.color,
                                      height: 1.4,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _searchQuery = '';
                                        _selectedCategory = 'All';
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            AppColors.primary,
                                            AppColors.primaryDark
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 32, vertical: 16),
                                      child: const Text(
                                        'Reset Filters',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.white,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
