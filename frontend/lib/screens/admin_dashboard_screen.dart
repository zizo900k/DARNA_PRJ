import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/admin_service.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../theme/auth_provider.dart';
import 'notifications_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _stats = {'pending': 0, 'published': 0, 'rejected': 0};
  List<Map<String, dynamic>> _properties = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _currentFilter = 'pending';
  int _currentPage = 1;
  int _lastPage = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final filters = ['pending', 'published', 'rejected'];
        _currentFilter = filters[_tabController.index];
        _currentPage = 1;
        _loadProperties();
      }
    });
    _loadData();
    
    Future.microtask(() {
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isLoggedIn && authProvider.user != null) {
        final userId = authProvider.user!['id'].toString();
        context.read<NotificationProvider>().fetchNotifications();
        context.read<NotificationProvider>().initWebSocket(userId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        AdminService.getStats(),
        AdminService.getProperties(status: _currentFilter, page: 1),
      ]);
      if (mounted) {
        setState(() {
          _stats = results[0];
          final propData = results[1];
          _properties = List<Map<String, dynamic>>.from(propData['data'] ?? []);
          _lastPage = propData['last_page'] ?? 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    try {
      final res = await AdminService.getProperties(
        status: _currentFilter,
        page: 1,
      );
      if (mounted) {
        setState(() {
          _properties = List<Map<String, dynamic>>.from(res['data'] ?? []);
          _currentPage = 1;
          _lastPage = res['last_page'] ?? 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveProperty(int id) async {
    try {
      await AdminService.approve(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Property approved'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showRejectDialog(int id) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? DarkColors.card : LightColors.card,
          title: Text('Reject Property',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: theme.textTheme.bodyLarge?.color)),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Reason for rejection...',
              filled: true,
              fillColor: isDark
                  ? DarkColors.backgroundSecondary
                  : LightColors.backgroundSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.pop(ctx, controller.text.trim());
                }
              },
              child: const Text('Reject',
                  style: TextStyle(
                      color: AppColors.error, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
    if (result != null && mounted) {
      try {
        await AdminService.reject(id, result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Property rejected'),
                backgroundColor: Colors.orange),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme, isDark),
            _buildStatsRow(theme, isDark),
            _buildTabs(theme, isDark),
            Expanded(child: _buildPropertyList(theme, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isDark
                    ? DarkColors.backgroundSecondary
                    : LightColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.arrow_back_ios_new,
                  size: 18, color: theme.textTheme.bodyLarge?.color),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Admin Dashboard',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: theme.textTheme.bodyLarge?.color,
                    )),
                const SizedBox(height: 2),
                Text('Review and manage submitted properties',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textTheme.bodyMedium?.color,
                    )),
              ],
            ),
          ),
          GestureDetector(
            onTap: _loadData,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.refresh, size: 20, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              NotificationsScreen.show(context);
            },
            child: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark
                    ? DarkColors.backgroundSecondary
                    : LightColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(14),
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
                        size: 20,
                        color: theme.textTheme.bodyLarge?.color),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _buildStatCard('Pending', _stats['pending'] ?? 0, Colors.orange,
              Icons.hourglass_empty, theme, isDark),
          const SizedBox(width: 10),
          _buildStatCard('Published', _stats['published'] ?? 0, Colors.green,
              Icons.check_circle_outline, theme, isDark),
          const SizedBox(width: 10),
          _buildStatCard('Rejected', _stats['rejected'] ?? 0, Colors.red,
              Icons.cancel_outlined, theme, isDark),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, dynamic count, Color color,
      IconData icon, ThemeData theme, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? DarkColors.card : LightColors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : const Color(0xFF0F172A).withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: theme.textTheme.bodyMedium?.color)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? DarkColors.backgroundSecondary
            : LightColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: theme.textTheme.bodyMedium?.color,
        labelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        dividerColor: Colors.transparent,
        splashBorderRadius: BorderRadius.circular(12),
        tabs: const [
          Tab(text: 'Pending'),
          Tab(text: 'Published'),
          Tab(text: 'Rejected'),
        ],
      ),
    );
  }

  Widget _buildPropertyList(ThemeData theme, bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_properties.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: theme.dividerColor),
            const SizedBox(height: 16),
            Text('No $_currentFilter properties',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyMedium?.color)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: _properties.length,
        itemBuilder: (ctx, i) => _buildPropertyCard(_properties[i], theme, isDark),
      ),
    );
  }

  Widget _buildPropertyCard(
      Map<String, dynamic> prop, ThemeData theme, bool isDark) {
    final status = prop['status'] as String? ?? 'pending';
    final photos = prop['photos'] as List? ?? [];
    String imageUrl = 'https://placehold.co/400x300/0D9488/FFFFFF/png?text=No+Image';
    if (photos.isNotEmpty) {
      final photo = photos.first;
      if (photo is Map) {
        imageUrl = (photo['full_url'] ?? photo['url'] ?? imageUrl) as String;
      }
    }
    final ownerName =
        (prop['user'] is Map ? prop['user']['name'] : null) as String? ??
            'Unknown';
    final category =
        (prop['category'] is Map ? prop['category']['name'] : null)
                as String? ??
            '';
    final createdAt = prop['created_at'] as String?;
    String dateStr = '';
    if (createdAt != null) {
      try {
        dateStr = DateFormat('MMM d, yyyy').format(DateTime.parse(createdAt));
      } catch (_) {}
    }
    final price = prop['price'] ?? prop['price_per_month'];
    final type = prop['type'] as String? ?? '';
    final id = prop['id'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.card : LightColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.18)
                : const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image + status badge
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: double.infinity,
                  height: 170,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 170,
                    color: isDark
                        ? DarkColors.backgroundSecondary
                        : LightColors.backgroundSecondary,
                    child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 170,
                    color: isDark
                        ? DarkColors.backgroundSecondary
                        : LightColors.backgroundSecondary,
                    child: const Icon(Icons.image_not_supported, size: 40),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: _buildStatusBadge(status),
              ),
              if (type.isNotEmpty)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(type.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
            ],
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prop['title'] as String? ?? 'Untitled',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: theme.textTheme.bodyLarge?.color),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 14, color: theme.textTheme.bodyMedium?.color),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(ownerName,
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodyMedium?.color),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (category.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(category,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (prop['location'] != null) ...[
                      Icon(Icons.location_on,
                          size: 13, color: theme.textTheme.bodyMedium?.color),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(prop['location'] as String,
                            style: TextStyle(
                                fontSize: 11,
                                color: theme.textTheme.bodyMedium?.color),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                    if (dateStr.isNotEmpty)
                      Text(dateStr,
                          style: TextStyle(
                              fontSize: 10,
                              color: theme.textTheme.bodySmall?.color)),
                  ],
                ),
                if (price != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'MAD ${_formatPrice(price)}${type == 'rent' ? ' /mo' : ''}',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary),
                  ),
                ],
                // Rejection reason
                if (status == 'rejected' &&
                    prop['rejection_reason'] != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            size: 14, color: Colors.red),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(prop['rejection_reason'] as String,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                ],
                // Action buttons
                if (status == 'pending') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.push('/property/$id'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? DarkColors.backgroundSecondary
                                  : LightColors.backgroundSecondary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text('View',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        theme.textTheme.bodyLarge?.color)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _approveProperty(id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                AppColors.primary,
                                Color(0xFF16A085)
                              ]),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: const Text('Approve',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showRejectDialog(id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color:
                                      AppColors.error.withValues(alpha: 0.3)),
                            ),
                            alignment: Alignment.center,
                            child: const Text('Reject',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.error)),
                          ),
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
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'published':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.toUpperCase(),
          style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    final num = double.tryParse(price.toString()) ?? 0;
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1)}M';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(0)}K';
    }
    return num.toStringAsFixed(0);
  }
}
