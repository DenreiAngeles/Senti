import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:async';
import '../../main.dart';
import '../../widgets/pressable_3d_button.dart';
import '../../services/auth_service.dart'; 
import '../dashboard/dashboard_screen.dart'; 
import 'onboarding_screen.dart';
import 'forgot_password_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  
  bool _obscurePassword = true;
  bool _isLoading = false; 

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateState);
    _passwordController.addListener(_updateState);
  }

  void _updateState() {
    setState(() {});
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isInputValid => 
      _emailController.text.trim().isNotEmpty && 
      _passwordController.text.trim().isNotEmpty;

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential != null && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: SentiColors.error)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus(); 
    setState(() => _isLoading = true);
    
    try {
      final user = await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException("Connection timed out. Please check your internet.");
      });

      if (user != null && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.contains("TimeoutException")) {
          msg = "Connection timed out. Check your network.";
        } else if (msg.contains("user-not-found") || msg.contains("wrong-password")) {
          msg = "Invalid email or password.";
        } else {
          msg = msg.replaceAll("Exception: ", ""); 
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: SentiColors.error,
            behavior: SnackBarBehavior.floating,
          ),
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
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(flex: 2),
                    
                    Text(
                      'Sign In',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 24, 
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Pressable3DButton(
                            onTap: () {
                               // UPDATED: Show "Coming Soon" toast
                               ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Coming Soon!"),
                                  duration: Duration(seconds: 1),
                                )
                              );
                            },
                            color: Colors.white,
                            height: 40,
                            child: const Icon(FontAwesomeIcons.apple, color: Colors.black, size: 20),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Pressable3DButton(
                            onTap: _isLoading ? null : _handleGoogleLogin,
                            color: Colors.white,
                            height: 40,
                            child: Image.asset(
                              'assets/images/google.png', 
                              height: 20,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white.withOpacity(0.5), thickness: 1.5)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.white.withOpacity(0.5), thickness: 1.5)),
                      ],
                    ),

                    const SizedBox(height: 12),

                    _SentiTextField(
                      label: 'Email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _SentiTextField(
                      label: 'Password',
                      controller: _passwordController,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      onToggleVisibility: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    if (_isLoading)
                      const Center(child: CircularProgressIndicator(color: Colors.white))
                    else
                      Pressable3DButton(
                        onTap: _isInputValid ? _handleLogin : null,
                        color: _isInputValid ? Colors.white : Colors.grey.shade400,
                        height: 40,
                        child: Text(
                          'Sign In',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _isInputValid ? SentiColors.primary : Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Forgot password?',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    
                    const Spacer(flex: 3),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'No account yet? ',
                          style: TextStyle(color: Colors.white.withOpacity(0.8)),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                            );
                          },
                          child: const Text(
                            'Sign up',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SentiTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;
  final TextInputType keyboardType;

  const _SentiTextField({
    required this.label,
    required this.controller,
    this.isPassword = false,
    this.obscureText = false,
    this.onToggleVisibility,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(
          color: const Color(0xFF1F2937), 
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        cursorColor: const Color(0xFF1E5631), 
        decoration: InputDecoration(
          hintText: label,
          hintStyle: GoogleFonts.inter(
            color: Colors.grey.shade500,
            fontSize: 14, 
          ),
          filled: false, 
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          isDense: true,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onPressed: onToggleVisibility,
                  padding: EdgeInsets.zero, 
                  constraints: const BoxConstraints(),
                )
              : null,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
        ),
      ),
    );
  }
}