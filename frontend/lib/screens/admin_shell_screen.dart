import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/language_provider.dart';
import 'admin_dashboard_screen.dart';
import 'profile_screen.dart';

class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({Key? key}) : super(key: key);

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    AdminDashboardScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            label: context.tr('admin_dashboard_tab') ?? 'Dashboard',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            label: context.tr('nav_profile') ?? 'Profile',
          ),
        ],
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
