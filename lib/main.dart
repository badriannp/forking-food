import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/welcome_screen.dart';
import 'screens/main_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/add_recipe_screen.dart';
import 'utils/constants.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
          return MaterialApp(
            title: 'Forking',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: const ColorScheme(
                brightness: Brightness.light,
                primary: AppColors.carrotYellow,
                onPrimary: AppColors.onPrimary,
                secondary: AppColors.darkGreen,
                onSecondary: AppColors.onSecondary,
                error: AppColors.error,
                onError: AppColors.onPrimary,
                surface: AppColors.surface,
                onSurface: AppColors.onSurface,
                tertiary: AppColors.accent,
                onTertiary: AppColors.onPrimary,
              ),
              scaffoldBackgroundColor: AppColors.surface,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.onSurface,
                elevation: 0,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.carrotYellow,
                  foregroundColor: AppColors.onPrimary,
                  minimumSize: const Size(double.infinity, 48),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.darkGreen,
                ),
              ),
              inputDecorationTheme: const InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.carrotYellow, width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              useMaterial3: true,
            ),
      routes: {
        '/add-recipe': (context) => const AddRecipeScreen(),
      },
      home: const AppEntryPoint(),
          );
        }
}

class AppEntryPoint extends StatelessWidget {
  const AppEntryPoint({super.key});

  Future<void> _initializeApp() async {
    // Initialize Firebase
    await Firebase.initializeApp();
    
    // Add a delay for splash screen visibility
    await Future.delayed(const Duration(milliseconds: 2000));
  }

  @override
  Widget build(BuildContext context) {
    return SplashScreen(
      initialization: _initializeApp,
      child: FutureBuilder(
        future: Future.value(), // Firebase already initialized
        builder: (context, snapshot) {
          // Check auth state
          final authService = AuthService();
          if (authService.isSignedIn) {
            return const MainScreen();
          } else {
            return const WelcomeScreen();
          }
        },
      ),
    );
  }
}