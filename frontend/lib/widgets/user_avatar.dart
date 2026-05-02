import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final double? fontSize;

  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 40,
    this.fontSize,
  });

  String get _initials {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    bool hasValidUrl = imageUrl != null && 
                       imageUrl!.startsWith('http') && 
                       !imageUrl!.contains('unsplash.com') && 
                       !imageUrl!.contains('pravatar.cc');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Theme.of(context).brightness == Brightness.dark ? null : Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: Theme.of(context).brightness == Brightness.dark ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ] : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: hasValidUrl
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildInitialsPlaceholder(),
                errorWidget: (context, url, error) => _buildInitialsPlaceholder(),
              )
            : _buildInitialsPlaceholder(),
      ),
    );
  }

  Widget _buildInitialsPlaceholder() {
    return Center(
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: fontSize ?? (size * 0.4),
        ),
      ),
    );
  }
}
