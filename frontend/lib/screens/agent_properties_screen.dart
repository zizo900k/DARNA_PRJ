import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../theme/language_provider.dart';
import '../services/api_service.dart';

class AgentPropertiesScreen extends StatefulWidget {
  final int agentId;
  final String agentName;
  final String? agentAvatar;

  const AgentPropertiesScreen({
    super.key,
    required this.agentId,
    required this.agentName,
    this.agentAvatar,
  });

  @override
  State<AgentPropertiesScreen> createState() => _AgentPropertiesScreenState();
}

class _AgentPropertiesScreenState extends State<AgentPropertiesScreen> {
  bool _isLoading = true;
  List<dynamic> _properties = [];
  Map<String, dynamic>? _agent;

  @override
  void initState() {
    super.initState();
    _fetchAgentProperties();
  }

  Future<void> _fetchAgentProperties() async {
    try {
      final response = await ApiService.get('/agents/${widget.agentId}');
      if (mounted) {
        setState(() {
          _agent = response['agent'];
          _properties = response['properties'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching agent properties: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getPropertyImage(dynamic property) {
    if (property == null) return '';
    if (property['photos'] is List && (property['photos'] as List).isNotEmpty) {
      final photo = (property['photos'] as List).first;
      if (photo is Map) return photo['full_url'] ?? photo['url'] ?? '';
    }
    return '';
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
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.arrow_back, size: 20, color: theme.textTheme.bodyLarge?.color),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.agentName,
                      style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Agent Info Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    backgroundImage: widget.agentAvatar != null
                        ? NetworkImage(widget.agentAvatar!)
                        : null,
                    child: widget.agentAvatar == null
                        ? const Icon(Icons.person, color: Colors.white, size: 28)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.agentName,
                          style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_properties.length} ${context.tr('properties') ?? 'Properties'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Properties List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _properties.isEmpty
                      ? Center(
                          child: Text(
                            context.tr('no_properties_found'),
                            style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _properties.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final prop = _properties[index];
                            final imageUrl = _getPropertyImage(prop);
                            final price = prop['price'] ?? prop['price_per_month'] ?? 0;
                            final type = prop['type']?.toString() ?? '';

                            return GestureDetector(
                              onTap: () {
                                context.push('/property/${prop['id']}', extra: {
                                  'property': Map<String, dynamic>.from(prop),
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark ? DarkColors.card : LightColors.card,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 12, offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Image
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                      child: imageUrl.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: imageUrl,
                                              height: 180, width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorWidget: (_, __, ___) => Container(
                                                height: 180, color: Colors.grey.withValues(alpha: 0.2),
                                                child: const Icon(Icons.image_not_supported, size: 40),
                                              ),
                                            )
                                          : Container(
                                              height: 180, width: double.infinity,
                                              color: isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary,
                                              child: Icon(Icons.home_outlined, size: 40, color: theme.dividerColor),
                                            ),
                                    ),
                                    // Info
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  prop['title'] ?? context.tr('property'),
                                                  style: TextStyle(
                                                    fontSize: 16, fontWeight: FontWeight.bold,
                                                    color: theme.textTheme.bodyLarge?.color,
                                                  ),
                                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  type == 'rent' ? 'Rent' : 'Sale',
                                                  style: const TextStyle(
                                                    fontSize: 11, fontWeight: FontWeight.bold,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(Icons.location_on_outlined, size: 14, color: theme.textTheme.bodyMedium?.color),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  prop['location'] ?? '',
                                                  style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color),
                                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '$price MAD${type == 'rent' ? '/mo' : ''}',
                                                style: const TextStyle(
                                                  fontSize: 16, fontWeight: FontWeight.w800,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  _miniStat(Icons.bed_outlined, '${prop['bedrooms'] ?? 0}', theme),
                                                  const SizedBox(width: 12),
                                                  _miniStat(Icons.bathtub_outlined, '${prop['bathrooms'] ?? 0}', theme),
                                                  const SizedBox(width: 12),
                                                  _miniStat(Icons.crop_square, '${prop['area'] ?? 0}m²', theme),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String value, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.textTheme.bodyMedium?.color),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
      ],
    );
  }
}
