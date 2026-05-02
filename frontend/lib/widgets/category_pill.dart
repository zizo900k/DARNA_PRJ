import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CategoryPill extends StatelessWidget {
  final String? name;
  final String? category;
  final bool isActive;
  final VoidCallback? onPress;

  const CategoryPill({
    super.key,
    this.name,
    this.category,
    this.isActive = false,
    this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = name ?? category ?? '';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final inactiveBgColor = isDark ? DarkColors.backgroundSecondary : Colors.white;
    final borderColor = isDark ? DarkColors.border : const Color(0xFFE2E8F0);
    final textSecondaryColor = isDark ? DarkColors.textSecondary : LightColors.textSecondary;

    return Container(
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isActive ? null : inactiveBgColor,
        gradient: isActive
            ? const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(14),
        border: isActive
            ? null
            : isDark
                ? Border.all(color: borderColor, width: 1)
                : Border.all(color: borderColor, width: 1.5), // Crisp stroke for light mode
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              displayName,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                letterSpacing: -0.2,
                color: isActive ? AppColors.white : textSecondaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

