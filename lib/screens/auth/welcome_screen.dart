import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; 
import '../../main.dart';
import '../../widgets/pressable_3d_button.dart'; // Import the new widget
import 'login_screen.dart';
import 'onboarding_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: SentiColors.primary,
      body: Stack(
        children: [
          // --- LAYER 1 (Bottom): Senti Logo ---
          Positioned(
            top: screenHeight * 0.15, 
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Senti',
                style: GoogleFonts.inter(
                  fontSize: 72, 
                  fontWeight: FontWeight.w900, 
                  color: Colors.white,
                  letterSpacing: -1.0, 
                  height: 1.0,
                ),
              ),
            ),
          ),

          // --- LAYER 2 (Middle): Plant Image ---
          Positioned(
            top: screenHeight * 0.20, 
            left: -30,
            right: -30,
            child: Image.asset(
              'assets/images/plant.png',
              fit: BoxFit.contain,
              height: screenHeight * 0.50, 
            ),
          ),

          // --- LAYER 3 (Top): Subtitle ---
          Positioned(
            top: screenHeight * 0.25, 
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Your Friendly Guide to Financial Clarity.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.95), 
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 1),
                      blurRadius: 4.0,
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- LAYER 4: Bottom Content (Quote & Buttons) ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quote
                  Text(
                    '"The secret to getting ahead is\ngetting started."',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'CanvaSans',
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 32),

                  // Continue Button (Now using 3D Button)
                  Pressable3DButton(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                      );
                    },
                    color: Colors.white,
                    height: 56, // Slightly taller for the main welcome button
                    child: Text(
                      'Continue',
                      style: GoogleFonts.inter( 
                        fontSize: 20, 
                        fontWeight: FontWeight.w800, 
                        color: SentiColors.primary, // Green text
                        letterSpacing: 0, 
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),

                  // Sign In Button (Kept as Text for cleaner look, as per prototype)
                  TextButton(
                    onPressed: () {
                       Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Sign In',
                      style: GoogleFonts.inter( 
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 0, 
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}