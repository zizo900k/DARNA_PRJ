import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/welcome_screen.dart';
import '../screens/sign_in_screen.dart';
import '../screens/sign_up_screen.dart';
import '../screens/home_screen.dart';
import '../screens/search_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/property_detail_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/add_listing_screen.dart';
import '../screens/update_listing_screen.dart';
import '../screens/home_guest_screen.dart';
import '../data/properties_data.dart';

import 'scaffold_with_nav_bar.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorHomeKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellHome');
final GlobalKey<NavigatorState> _shellNavigatorSearchKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellSearch');
final GlobalKey<NavigatorState> _shellNavigatorFavoritesKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellFavorites');
final GlobalKey<NavigatorState> _shellNavigatorProfileKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellProfile');

class AppRouter {
  static Map<String, dynamic> _propertyToMap(Property p) {
    return {
      'id': p.id,
      'title': p.title,
      'description': p.description,
      'type': p.type,
      'status': p.status,
      'price': p.price,
      'pricePerMonth': p.pricePerMonth,
      'location': p.location,
      'bedrooms': p.bedrooms,
      'bathrooms': p.bathrooms,
      'area': p.area,
      'rating': p.rating,
      'reviews': 0,
      'images': [p.image],
      'featured': p.featured,
      'address': p.location,
      'distance': '—',
      'duration': '—',
      'agent': {
        'name': 'Darna Agent',
        'avatar': 'https://i.pravatar.cc/150?img=12',
        'role': 'Property Agent',
      },
      'facilities': <Map<String, dynamic>>[],
      'cost': {
        'rent': p.pricePerMonth ?? p.price ?? 0,
        'description': 'Monthly cost estimate',
      },
      'nearbyProperties': <Map<String, dynamic>>[],
      'userReviews': <Map<String, dynamic>>[],
    };
  }

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/welcome',
    routes: <RouteBase>[
      GoRoute(
        path: '/welcome',
        builder: (BuildContext context, GoRouterState state) {
          return const WelcomeScreen();
        },
      ),
      GoRoute(
        path: '/signin',
        builder: (BuildContext context, GoRouterState state) {
          return const SignInScreen();
        },
      ),
      GoRoute(
        path: '/signup',
        builder: (BuildContext context, GoRouterState state) {
          return const SignUpScreen();
        },
      ),
      GoRoute(
        path: '/home_guest',
        builder: (BuildContext context, GoRouterState state) {
          return const HomeGuestScreen();
        },
      ),
      // Stateful shell route for bottom tabs
      StatefulShellRoute.indexedStack(
        builder: (BuildContext context, GoRouterState state,
            StatefulNavigationShell navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          // Home
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHomeKey,
            routes: <RouteBase>[
              GoRoute(
                path: '/home',
                builder: (BuildContext context, GoRouterState state) {
                  return const HomeScreen(); // Actually HomeAuthScreen equivalent
                },
              ),
            ],
          ),
          // Search
          StatefulShellBranch(
            navigatorKey: _shellNavigatorSearchKey,
            routes: <RouteBase>[
              GoRoute(
                path: '/search',
                builder: (BuildContext context, GoRouterState state) {
                  return const SearchScreen();
                },
              ),
            ],
          ),
          // Favorites
          StatefulShellBranch(
            navigatorKey: _shellNavigatorFavoritesKey,
            routes: <RouteBase>[
              GoRoute(
                path: '/favorites',
                builder: (BuildContext context, GoRouterState state) {
                  return const FavoritesScreen();
                },
              ),
            ],
          ),
          // Profile
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProfileKey,
            routes: <RouteBase>[
              GoRoute(
                path: '/profile',
                builder: (BuildContext context, GoRouterState state) {
                  return const ProfileScreen();
                },
              ),
            ],
          ),
        ],
      ),
      // Independent sub-routes (no bottom nav)
      GoRoute(
        path: '/property/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (BuildContext context, GoRouterState state) {
          final propertyId =
              int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          final property = PropertiesData.properties
                  .where((p) => p.id == propertyId)
                  .isNotEmpty
              ? _propertyToMap(PropertiesData.properties
                  .firstWhere((p) => p.id == propertyId))
              : null;
          return CustomTransitionPage(
            key: state.pageKey,
            child: PropertyDetailScreen(property: property),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      GoRoute(
        path: '/editProfile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) {
          return const EditProfileScreen();
        },
      ),
      GoRoute(
        path: '/addListing',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) {
          return const AddListingScreen();
        },
      ),
      GoRoute(
        path: '/updateListing/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) {
          // Listing ID is available via state.pathParameters['id']
          return const UpdateListingScreen();
        },
      ),
    ],
  );
}
