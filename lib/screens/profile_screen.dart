import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/language_provider.dart';
import '../theme/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _activeTab = 'Transaction';

  final _stats = {
    'listings': 30,
    'sold': 12,
    'reviews': 28,
  };

  final _transactions = [
    {
      'id': 1,
      'title': 'Wings Tower',
      'image':
          'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=400',
      'status': 'Rent',
      'date': 'November 21, 2021',
    },
    {
      'id': 2,
      'title': 'Bridgeland Modern House',
      'image':
          'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=400',
      'status': 'Rent',
      'date': 'December 17, 2021',
    },
  ];

  final _listings = [
    {
      'id': 1,
      'title': 'Apartment for sent',
      'image':
          'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=400',
      'price': 1500,
      'priceType': 'month',
      'rating': 4.9,
      'location': 'Laayoune, Morocco',
      'category': 'Apartment',
    },
    {
      'id': 2,
      'title': 'House For Sent',
      'image':
          'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=400',
      'price': 2100,
      'priceType': 'month',
      'rating': 4.8,
      'location': 'Laayoune, Morocco',
      'category': 'House',
    },
  ];

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature (${context.tr('coming_soon')})'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildTransactions(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_transactions.length} ${context.tr('transactions_count')}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? DarkColors.backgroundSecondary
                      : LightColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.grid_view,
                    size: 20, color: theme.textTheme.bodyLarge?.color),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _transactions.map((transaction) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: transaction == _transactions.first ? 8 : 0,
                    left: transaction == _transactions.last ? 8 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () => _showComingSoon('Transaction Details'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(
                                imageUrl: transaction['image'] as String,
                                width: double.infinity,
                                height: 160,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF1ABC9C),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.favorite_border,
                                    size: 18, color: Colors.white),
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1ABC9C),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  transaction['status'] as String,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transaction['title'] as String,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF4CAF50),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      transaction['date'] as String,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            theme.textTheme.bodyMedium?.color,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildListings(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_listings.length} ${context.tr('listings_count')}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark
                          ? DarkColors.backgroundSecondary
                          : LightColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.grid_view,
                        size: 20, color: theme.textTheme.bodyLarge?.color),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => context.push('/addListing'),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF16A085)]),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      alignment: Alignment.center,
                      child:
                          const Icon(Icons.add, size: 24, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _listings.map((listing) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: listing == _listings.first ? 8 : 0,
                    left: listing == _listings.last ? 8 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () => context.push('/property/${listing['id']}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(
                                imageUrl: listing['image'] as String,
                                width: double.infinity,
                                height: 140,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 12,
                              left: 12,
                              child: GestureDetector(
                                onTap: () {
                                  context
                                      .push('/updateListing/${listing['id']}');
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF1ABC9C),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.edit,
                                      size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: GestureDetector(
                                onTap: () =>
                                    _showComingSoon('Add to Favorites'),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF1ABC9C),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.favorite_border,
                                      size: 18, color: Colors.white),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1ABC9C),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                          text: 'MAD ${listing['price']} '),
                                      TextSpan(
                                        text: '/${listing['priceType']}',
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ],
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                listing['title'] as String,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      size: 12, color: Color(0xFFFFC107)),
                                  const SizedBox(width: 4),
                                  Text(
                                    listing['rating'].toString(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.location_on,
                                      size: 12,
                                      color: theme.textTheme.bodyMedium?.color),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      listing['location'] as String,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color:
                                            theme.textTheme.bodyMedium?.color,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSold(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: theme.dividerColor),
          const SizedBox(height: 16),
          Text(
            context.tr('no_sold_properties'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('no_sold_subtitle'),
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final stats = _stats;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('profile'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/editProfile'),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? DarkColors.backgroundSecondary
                            : LightColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.settings_outlined,
                          size: 24, color: theme.textTheme.bodyLarge?.color),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  children: [
                    // Profile Info
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: CachedNetworkImage(
                                  imageUrl: user['avatar'] as String,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => context.push('/editProfile'),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primary,
                                          Color(0xFF16A085)
                                        ],
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.edit,
                                        size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            user['name'] as String,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            user['email'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Stats
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 24),
                      child: Row(
                        children: [
                          _buildStatCard(stats['listings'].toString(),
                              context.tr('listings_count'), theme, isDark),
                          const SizedBox(width: 12),
                          _buildStatCard(stats['sold'].toString(),
                              context.tr('sold_count'), theme, isDark),
                          const SizedBox(width: 12),
                          _buildStatCard(stats['reviews'].toString(),
                              context.tr('reviews_count'), theme, isDark),
                        ],
                      ),
                    ),

                    // Tabs
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? DarkColors.backgroundSecondary
                            : LightColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          _buildTabItem('Transaction', theme, isDark),
                          _buildTabItem('Listings', theme, isDark),
                          _buildTabItem('Sold', theme, isDark),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Content
                    if (_activeTab == 'Transaction')
                      _buildTransactions(theme, isDark),
                    if (_activeTab == 'Listings') _buildListings(theme, isDark),
                    if (_activeTab == 'Sold') _buildSold(theme),

                    // Logout Button
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 32),
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              title: Text(
                                context.tr('logout'),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                              content: Text(
                                'Are you sure you want to logout?',
                                style: TextStyle(
                                    color: theme.textTheme.bodyMedium?.color),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                        color:
                                            theme.textTheme.bodyMedium?.color),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    context.read<AuthProvider>().logout();
                                    context.go('/welcome');
                                  },
                                  child: const Text(
                                    'Logout',
                                    style: TextStyle(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppColors.error.withOpacity(0.3)),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout,
                                  color: AppColors.error, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                context.tr('logout'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.error,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String number, String label, ThemeData theme, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDark
              ? DarkColors.backgroundSecondary
              : LightColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark ? DarkColors.border : LightColors.border),
        ),
        child: Column(
          children: [
            Text(
              number,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String label, ThemeData theme, bool isDark) {
    final isActive = _activeTab == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? theme.cardColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label == 'Transaction'
                ? context.tr('transactions_count').toUpperCase()
                : label == 'Listings'
                    ? context.tr('listings_count').toUpperCase()
                    : context.tr('sold_count').toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive
                  ? theme.textTheme.bodyLarge?.color
                  : theme.textTheme.bodyMedium?.color,
            ),
          ),
        ),
      ),
    );
  }
}
