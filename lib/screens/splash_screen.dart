import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart';
import 'auth/welcome_screen.dart'; // Correct path to WelcomeScreen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize Animation Controller
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Fade In
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // Slide Up slightly (from offset 0.5 to 0)
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5), 
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Start Animation
    _controller.forward();

    // Navigate to Welcome Screen after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const WelcomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              // Smooth fade transition to Welcome Screen
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SentiColors.primary, // Deep Green
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Text(
              'Senti',
              style: GoogleFonts.inter(
                fontSize: 64, // Large, bold text
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -2.0,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}