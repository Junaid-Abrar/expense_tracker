import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainNavigationWrapper extends StatefulWidget {
  final Widget child;

  const MainNavigationWrapper({super.key, required this.child});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _selectedIndex = 0;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Home',
      route: '/home',
    ),
    NavigationItem(
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics,
      label: 'Analytics',
      route: '/analytics',
    ),
    NavigationItem(
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
      label: 'Budget',
      route: '/budget',
    ),
    NavigationItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
      route: '/settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
            context.go(_navigationItems[index].route);
          },
          type: BottomNavigationBarType.fixed,
          items: _navigationItems
              .map((item) => BottomNavigationBarItem(
            icon: Icon(item.icon),
            activeIcon: Icon(item.selectedIcon),
            label: item.label,
          ))
              .toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/expenses/add'),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
  });
}