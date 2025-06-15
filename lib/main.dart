import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';
import 'utils/constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: const AuthScreen(),
            theme: ThemeData(
              colorScheme: ColorScheme(
                brightness: Brightness.light,
                primary: AppColors.carrotYellow,
                onPrimary: AppColors.onPrimary,
                secondary: AppColors.darkGreen,
                onSecondary: AppColors.onSecondary,
                error: AppColors.error,
                onError: AppColors.onPrimary,
                surface: AppColors.background,
                onSurface: AppColors.onSurface,
                tertiary: AppColors.accent,
                onTertiary: AppColors.onPrimary,
              ),
              scaffoldBackgroundColor: AppColors.background,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.black87,
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
              inputDecorationTheme: InputDecorationTheme(
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.carrotYellow, width: 2),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                ),
              ),
              useMaterial3: true,
            ),
          );
        }
        // Loader cât timp Firebase se inițializează
        return const MaterialApp(
          home: Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }
}