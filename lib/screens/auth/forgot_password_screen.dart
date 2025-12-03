import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart';
import '../../widgets/pressable_3d_button.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleReset() async {
    if (_emailController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      await _authService.sendPasswordResetEmail(_emailController.text.trim());
      
      if (mounted) {
        // Show Success Dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Icon(Icons.mark_email_read, color: SentiColors.primary, size: 48),
            content: Text(
              "Check your email! We've sent a password reset link to ${_emailController.text}.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade800),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close Dialog
                  Navigator.pop(context); // Go back to Login
                },
                child: Text("Got it", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: SentiColors.primary)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: SentiColors.error)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SentiColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                "Reset Password",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Enter your email address and we'll send you a link to reset your password.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 32),
              
              // Reusing your custom text field style
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.inter(color: SentiColors.textMain),
                  decoration: InputDecoration(
                    hintText: "Email",
                    hintStyle: GoogleFonts.inter(color: Colors.grey.shade500),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              if (_isLoading)
                const Center(child: CircularProgressIndicator(color: Colors.white))
              else
                Pressable3DButton(
                  onTap: _handleReset,
                  color: Colors.white,
                  height: 48,
                  child: Text(
                    "Send Reset Link",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: SentiColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}