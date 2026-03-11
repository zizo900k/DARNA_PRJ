import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/language_provider.dart';
import '../theme/auth_provider.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    Key? key,
  }) : super(key: key ?? const ValueKey<String>('ScaffoldWithNavBar'));

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            destinations: [
              NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  label: context.tr('nav_home')),
              NavigationDestination(
                  icon: const Icon(Icons.search_outlined),
                  label: context.tr('nav_search')),
              NavigationDestination(
                  icon: const Icon(Icons.favorite_outline),
                  label: context.tr('nav_favorites')),
              NavigationDestination(
                  icon: const Icon(Icons.person_outline),
                  label: context.tr('nav_profile')),
            ],
            onDestinationSelected: (int index) {
              if (index == 2 && !authProvider.isLoggedIn) {
                // Favorites requires auth
                context.go('/signin');
                return;
              }
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
          ),
        );
      },
    );
  }
}
