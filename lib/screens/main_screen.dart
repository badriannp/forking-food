import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forking/screens/home_screen.dart';
import 'package:forking/screens/add_recipe_screen.dart';
import 'package:forking/screens/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final GlobalKey _navigationBarKey = GlobalKey();

  final List<Widget> _screens = [
    const HomeScreen(),
    const AddRecipeScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Navigation Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  child: NavigationBar(
                    key: _navigationBarKey,
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _onItemTapped,
                    labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.add_circle_outline),
                        selectedIcon: Icon(Icons.add_circle),
                        label: 'Add',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.person_outline),
                        selectedIcon: Icon(Icons.person),
                        label: 'Profile',
                      ),
                      ],
                    ),
                ),
              ),
            // Content
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: 0,
                child: LayoutBuilder(
                  builder: (context, contentConstraints) {
                    // Obținem dimensiunea NavigationBar după ce a fost randat
                    final navBarBox = _navigationBarKey.currentContext?.findRenderObject() as RenderBox?;
                    final navBarHeight = navBarBox?.size.height ?? 0;
                    
                    // Adăugăm și padding-ul de bottom al ecranului
                    final bottomPadding = MediaQuery.of(context).padding.bottom;
                    final totalBottomPadding = navBarHeight + bottomPadding;

                    return Padding(
                      padding: EdgeInsets.only(bottom: totalBottomPadding),
                      child: _screens[_selectedIndex],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
} 