import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forking/screens/tabs/discover_screen.dart';
import 'package:forking/screens/tabs/home_screen.dart';
import 'package:forking/screens/tabs/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Folosim PageStorage pentru a păstra indexul selectat
  static const String _storageKey = 'main_screen_selected_index';
  
  // Inițializăm cu valoarea salvată sau 1 (Home tab) dacă nu există
  int get _selectedIndex => PageStorage.of(context).readState(context, identifier: _storageKey) ?? 1;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DiscoverScreen(),
      const HomeScreen(),
      const ProfileScreen(),
    ];
  }

  void _updateSelectedIndex(int index) {
    // Salvăm indexul în PageStorage
    PageStorage.of(context).writeState(context, index, identifier: _storageKey);
    setState(() {});
  }

  void _onItemTapped(int index) {
    FocusScope.of(context).unfocus();
    _updateSelectedIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        indicatorColor: Theme.of(context).colorScheme.primary,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
} 