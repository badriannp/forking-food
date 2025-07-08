import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forking/screens/tabs/discover_screen.dart';
import 'package:forking/screens/tabs/home_screen.dart';
import 'package:forking/screens/tabs/profile_screen.dart';
import 'package:forking/utils/haptic_feedback.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const _storageKey = 'main_screen_selected_index';
  int _selectedIndex = 1;

  final List<Widget> _screens = const [
    DiscoverScreen(),
    HomeScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // restore saved index
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storedIndex = PageStorage.of(context)
              .readState(context, identifier: _storageKey) as int?;
      if (storedIndex != null) {
        setState(() => _selectedIndex = storedIndex);
      }
    });
  }

  void _onItemTapped(int index) {
    HapticUtils.triggerSelection();
    FocusManager.instance.primaryFocus?.unfocus();
    PageStorage.of(context).writeState(context, index, identifier: _storageKey);
    setState(() => _selectedIndex = index);
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
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        indicatorColor: Theme.of(context).colorScheme.primary,
        backgroundColor: Colors.transparent,
        elevation: 0,
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