import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/language_provider.dart';
import '../theme/auth_provider.dart';
import '../providers/chat_provider.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    Key? key,
  }) : super(key: key ?? const ValueKey<String>('ScaffoldWithNavBar'));

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ChatProvider>(
      builder: (context, authProvider, chatProvider, _) {
        final unread = chatProvider.unreadCount;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (authProvider.isLoggedIn && authProvider.user != null) {
            chatProvider.initRealTime(authProvider.user!['id']);
          } else {
            chatProvider.stopRealTime();
          }
        });

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
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  child: const Icon(Icons.chat_bubble_outline),
                ),
                label: context.tr('nav_messages'),
              ),
              NavigationDestination(
                  icon: const Icon(Icons.person_outline),
                  label: context.tr('nav_profile')),
            ],
            onDestinationSelected: (int index) {
              // Favorites (2), Messages (3), Profile (4) require auth
              if ((index == 2 || index == 3 || index == 4) && !authProvider.isLoggedIn) {
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
