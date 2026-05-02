import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/language_provider.dart';
import '../theme/auth_provider.dart';
import '../services/profile_service.dart';
import '../services/api_service.dart';
import '../widgets/user_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with WidgetsBindingObserver {
  Map<String, dynamic> _stats = {
    'listings': 0,
    'reviews': 0,
  };

  List<Map<String, dynamic>> _listings = [];
  bool _isLoading = true;
  Timer? _pollTimer;
  bool _isListingsGrid = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
    _startPolling();
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
      final statsRes = await ProfileService.getStats();
      final listingsRes = await ProfileService.getListings();
      if (mounted) {
        setState(() {
          _stats = statsRes;
          _listings = List<Map<String, dynamic>>.from(listingsRes);
        });
      }
    } catch (e) {
      // Ignore background errors
    }
  }

  Future<void> _loadProfileData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final statsRes = await ProfileService.getStats();
      final listingsRes = await ProfileService.getListings();
      if (mounted) {
        setState(() {
          _stats = statsRes;
          _listings = List<Map<String, dynamic>>.from(listingsRes);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteListing(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('delete_property') ?? 'Delete Property'),
        content: Text(context.tr('delete_property_confirm') ?? 'Are you sure you want to permanently delete this property?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.tr('cancel') ?? 'Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(context.tr('delete') ?? 'Delete', style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    
    if (confirm != true) return;

    try {
      await ApiService.delete('/properties/$id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('success') ?? 'Deleted successfully')));
        _loadProfileData(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${context.tr('error_prefix') ?? 'Error: '}$e')));
      }
    }
  }

  Future<void> _toggleVisibility(int id, String currentStatus) async {
    try {
      final res = await ApiService.put('/properties/$id/toggle-visibility');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('status_updated'))));
        _loadProfileData(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${context.tr('error_prefix') ?? 'Error: '}$e')));
      }
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature (${context.tr('coming_soon')})'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'published':
      case 'available':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'hidden':
        return Colors.grey;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

/*
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
                              child: Image.network(
                                transaction['image'] as String,
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
*/
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
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isListingsGrid = !_isListingsGrid;
                      });
                    },
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
                      child: Icon(_isListingsGrid ? Icons.view_list : Icons.grid_view,
                          size: 20, color: theme.textTheme.bodyLarge?.color),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () async {
                      await context.push('/addListing');
                      _loadProfileData();
                    },
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
          if (_listings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text(context.tr('no_listings_found'))),
            )
          else
            _isListingsGrid
                ? Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: _listings.map((listing) => SizedBox(
                      width: (MediaQuery.of(context).size.width - 48 - 16) / 2,
                      child: _buildListingCard(listing, theme, isGrid: true),
                    )).toList(),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _listings.map((listing) {
                        return _buildListingCard(listing, theme, isGrid: false, isLast: listing == _listings.last);
                      }).toList(),
                    ),
                  ),
        ],
      ),
    );
  }

  Widget _buildListingCard(Map<String, dynamic> listing, ThemeData theme, {bool isGrid = false, bool isLast = false}) {
    return Container(
      width: isGrid ? null : 200,
      padding: EdgeInsets.only(
        right: isGrid ? 0 : (isLast ? 0 : 16),
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
                  child: Image.network(
                    (() {
                      if (listing['photos'] is List && (listing['photos'] as List).isNotEmpty) {
                        final photo = (listing['photos'] as List).first;
                        if (photo is Map) return photo['full_url'] as String? ?? photo['url'] as String? ?? 'https://placehold.co/800x600/20B2AA/FFFFFF/png?text=Darna+Image';
                      }
                      return (listing['full_url'] as String?) ?? (listing['image'] as String?) ?? 'https://placehold.co/800x600/20B2AA/FFFFFF/png?text=Darna+Image';
                    })(),
                    width: double.infinity,
                    height: isGrid ? 100 : 140,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: isGrid ? 100 : 140,
                      width: double.infinity,
                      color: Colors.grey.withValues(alpha: 0.2),
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: GestureDetector(
                    onTap: () async {
                      await context.push(
                        '/updateListing/${listing['id']}',
                        extra: listing,
                      );
                      _loadProfileData();
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.edit,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(listing['status'] as String?),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      context.tr('status_${listing['status'] ?? 'pending'}').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1ABC9C),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                              text: 'MAD ${listing['price_per_month'] ?? listing['price'] ?? 'N/A'} '),
                          TextSpan(
                            text: listing['type'] == 'rent' ? '/mo' : '',
                            style: const TextStyle(fontSize: 9),
                          ),
                        ],
                      ),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (listing['title'] ?? context.tr('no_title')) as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          size: 10, color: Color(0xFFFFC107)),
                      const SizedBox(width: 4),
                      Text(
                        (listing['rating'] ?? 0).toString(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.location_on,
                          size: 10,
                          color: theme.textTheme.bodyMedium?.color),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          (listing['location'] ?? context.tr('unknown_location')) as String,
                          style: TextStyle(
                            fontSize: 9,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (listing['status'] == 'rejected' && listing['rejection_reason'] != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, color: Colors.red, size: 12),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              listing['rejection_reason'] as String,
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.red,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _toggleVisibility(listing['id'], listing['status']),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 26),
                        side: BorderSide(color: listing['status'] == 'hidden' ? Colors.green : Colors.orange),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: Text(
                        listing['status'] == 'hidden' ? (context.tr('enable') ?? 'Enable') : (context.tr('disable') ?? 'Disable'),
                        style: TextStyle(fontSize: 9, color: listing['status'] == 'hidden' ? Colors.green : Colors.orange),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _deleteListing(listing['id']),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 26),
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: Text(
                        context.tr('delete') ?? 'Delete',
                        style: const TextStyle(fontSize: 9, color: Colors.red),
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

/*
  Widget _buildSold(ThemeData theme) {
    if (_sold.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: _sold.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: (item['image'] ?? item['images']?.first ?? '') as String,
                  width: 60, height: 60, fit: BoxFit.cover,
                ),
              ),
              title: Text((item['title'] ?? '') as String, style: TextStyle(fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color)),
              subtitle: Text('${item['price'] ?? 0} ${context.tr('mad')}', textDirection: TextDirection.ltr, style: TextStyle(color: AppColors.primary)),
            ),
          )).toList(),
        ),
      );
    }
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
*/

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
                              UserAvatar(
                                name: (user?['full_name'] ?? user?['name'] ?? context.tr('user')).toString(),
                                imageUrl: (user?['full_avatar_url'] ?? user?['avatar'])?.toString(),
                                size: 100,
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
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            (user?['full_name'] as String?) ?? (user?['name'] as String?) ?? context.tr('user'),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            (user?['email'] as String?) ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Stats
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (user?['role'] != 'admin')
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 24),
                        child: Row(
                          children: [
                            Expanded(child: _buildStatCard((stats['total_listings'] ?? stats['listings'] ?? 0).toString(),
                                context.tr('listings_count'), theme, isDark)),
                            // Removed sold

                            const SizedBox(width: 12),
                            Expanded(child: _buildStatCard((stats['total_reviews'] ?? stats['reviews'] ?? 0).toString(),
                                context.tr('reviews_count'), theme, isDark)),
                          ],
                        ),
                      ),

                    // Tabs removed
                    const SizedBox(height: 24),

                    // Content
                    if (_isLoading)
                      const SizedBox()
                    else 
                      Column(
                        children: [
                          if (user?['role'] == 'admin')
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.admin_panel_settings, color: Colors.redAccent),
                                ),
                                title: Text(
                                  context.tr('admin_dashboard') ?? 'Admin Dashboard',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                                trailing: Icon(Icons.chevron_right, color: theme.dividerColor),
                                onTap: () => context.push('/admin/shell'),
                              ),
                              ),
                          if (user?['role'] != 'admin') ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.calendar_today, color: AppColors.primary),
                                ),
                                title: Text(
                                  context.tr('my_requests') ?? 'My Requests',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                                trailing: Icon(Icons.chevron_right, color: theme.dividerColor),
                                onTap: () => context.push('/requests'),
                              ),
                            ),
                            _buildListings(theme, isDark),
                          ],
                        ],
                      ),

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
                                context.tr('logout_confirm'),
                                style: TextStyle(
                                    color: theme.textTheme.bodyMedium?.color),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    context.tr('cancel'),
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
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.3)),
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
          color: isDark ? DarkColors.card : LightColors.card,
          borderRadius: BorderRadius.circular(20),
          border: isDark ? null : Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          boxShadow: isDark ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : [],
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

/*
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
                      color: Colors.black.withValues(alpha: 0.08),
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
*/
}

