import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:senti/screens/splash_screen.dart';
import 'firebase_options.dart';
import 'core/theme_notifier.dart'; // Import the notifier

class SentiColors {
  static const Color primary = Color(0xFF1E5631); // Deep Green
  static const Color accent = Color(0xFF4F9F63);  
  static const Color background = Color(0xFFF9FAFB); 
  static const Color textMain = Color(0xFF1F2937);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color error = Color(0xFFEF4444);
  
  // Dark Mode Specifics
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SentiApp());
}

class SentiApp extends StatelessWidget {
  const SentiApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to theme changes
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'Senti Finance',
          debugShowCheckedModeBanner: false,
          
          // --- MODE SETTINGS ---
          themeMode: currentMode,
          
          // --- LIGHT THEME (Your existing theme) ---
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: SentiColors.background,
            colorScheme: ColorScheme.fromSeed(
              seedColor: SentiColors.primary,
              primary: SentiColors.primary,
              secondary: SentiColors.accent,
              surface: Colors.white,
              error: SentiColors.error,
              brightness: Brightness.light,
            ),
            textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).apply(
              bodyColor: SentiColors.textMain,
              displayColor: SentiColors.textMain,
            ),
            // ... (Your existing button/input styles remain here if you want explicit overrides, 
            // but relying on ColorScheme is cleaner for switching) ...
          ),

          // --- DARK THEME ---
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: SentiColors.darkBackground,
            colorScheme: ColorScheme.fromSeed(
              seedColor: SentiColors.primary,
              primary: SentiColors.accent, // Use lighter green in dark mode for visibility
              secondary: SentiColors.primary,
              surface: SentiColors.darkSurface,
              error: SentiColors.error,
              brightness: Brightness.dark,
            ),
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
            // Ensure inputs look good in dark mode
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: SentiColors.darkSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade800),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade800),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: SentiColors.accent, width: 2),
              ),
            ),
          ),
          
          home: const SplashScreen(),
        );
      },
    );
  }
}