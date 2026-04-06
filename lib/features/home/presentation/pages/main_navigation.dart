import 'package:flutter/material.dart';
import 'package:qr_check_app/features/home/presentation/pages/dashboard_page.dart';
import 'package:qr_check_app/features/profile/presentation/pages/profile_page.dart';
import 'package:qr_check_app/features/qr/presentation/widgets/scan_action_modal.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const SizedBox(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    if (index == 1) {
      _showScanActionModal();
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _showScanActionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const ScanActionModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex == 1 ? 0 : _currentIndex > 1 ? _currentIndex - 1 : _currentIndex,
        children: [
          _pages[0],
          _pages[2],
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onItemTapped,
        height: 70,
        elevation: 0,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFFFE5D9),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Color(0xFF2C3E50)),
            selectedIcon: Icon(Icons.home, color: Color(0xFFFF7300)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFFF7300),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                color: Colors.white,
                size: 28,
              ),
            ),
            label: '',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline, color: Color(0xFF2C3E50)),
            selectedIcon: Icon(Icons.person, color: Color(0xFFFF7300)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
