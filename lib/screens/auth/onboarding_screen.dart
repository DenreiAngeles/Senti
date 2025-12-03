import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import '../../main.dart';
import '../../widgets/pressable_3d_button.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../dashboard/dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  
  int _currentPage = 0;
  bool _isLoading = false;
  String _loadingMessage = "Sign Up"; 
  
  // State for selections
  String? _selectedStatus;
  String? _selectedGoal;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _firstNameController.addListener(_updateState);
    _lastNameController.addListener(_updateState);
    _emailController.addListener(_updateState);
    _passwordController.addListener(_updateState);
  }

  void _updateState() {
    setState(() {});
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isCurrentStepValid {
    switch (_currentPage) {
      case 0: return _selectedStatus != null;
      case 1: return _selectedGoal != null;
      case 2:
        return _firstNameController.text.trim().isNotEmpty &&
               _lastNameController.text.trim().isNotEmpty &&
               _emailController.text.trim().isNotEmpty &&
               _passwordController.text.trim().isNotEmpty;
      default: return false;
    }
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = "Signing in...";
    });

    try {
      final userCredential = await _authService.signInWithGoogle();
      final user = userCredential?.user;

      if (user != null) {
        String firstName = "";
        String lastName = "";
        if (user.displayName != null) {
          final parts = user.displayName!.split(" ");
          firstName = parts.first;
          if (parts.length > 1) lastName = parts.sublist(1).join(" ");
        }

        await _firestoreService.createUserProfile(
          uid: user.uid,
          firstName: firstName.isNotEmpty ? firstName : "User",
          lastName: lastName,
          email: user.email ?? "",
          status: _selectedStatus ?? "Other",
          goal: _selectedGoal ?? "General Savings",
        ).catchError((e) => print("Profile Save Error: $e"));

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
            (route) => false,
          );
        }
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

  Future<void> _handleSignUp() async {
    FocusScope.of(context).unfocus(); 
    setState(() {
      _isLoading = true;
      _loadingMessage = "Creating Account...";
    });

    try {
      User? user;
      try {
        user = await _authService.signUp(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          user = await _authService.signIn(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
        } else {
          rethrow;
        }
      }
      
      if (user != null) {
        _firestoreService.createUserProfile(
          uid: user.uid,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          status: _selectedStatus ?? "Other",
          goal: _selectedGoal ?? "General Savings",
        ).catchError((e) {
          print("Background Profile Save Error: $e");
        });

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString().split(']').last.trim()}"),
            backgroundColor: SentiColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = "Sign Up";
        });
      }
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _handleSignUp();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = (_currentPage + 1) / 3;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black54),
                    onPressed: _prevPage,
                  ),
                  Expanded(
                    child: Container(
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: SentiColors.primary,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), 
                ],
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), 
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                children: [
                  _SelectionStep(
                    title: "Everyone's financial story is unique.\nWhat does yours look like right now?",
                    options: const [
                      {'icon': FontAwesomeIcons.briefcase, 'label': 'Full-time Employed'},
                      {'icon': FontAwesomeIcons.chartLine, 'label': 'Freelance/Self-Employed'},
                      {'icon': FontAwesomeIcons.graduationCap, 'label': 'Student'},
                      {'icon': FontAwesomeIcons.moneyBillWave, 'label': 'Other'},
                    ],
                    selectedOption: _selectedStatus,
                    onSelect: (val) => setState(() => _selectedStatus = val),
                  ),

                  _SelectionStep(
                    title: "Great things are ahead! What's the\nnext big milestone you'd like to celebrate?",
                    options: const [
                      {'icon': FontAwesomeIcons.gift, 'label': 'Saving for something special'},
                      {'icon': FontAwesomeIcons.shieldHalved, 'label': 'Building my peace of mind'},
                      {'icon': FontAwesomeIcons.linkSlash, 'label': 'Becoming debt-free'}, 
                      {'icon': FontAwesomeIcons.lightbulb, 'label': 'Finally getting organized'},
                      {'icon': FontAwesomeIcons.plantWilt, 'label': 'Investing for the future'},
                    ],
                    selectedOption: _selectedGoal,
                    onSelect: (val) => setState(() => _selectedGoal = val),
                  ),

                  _SignUpFormStep(
                    firstName: _firstNameController,
                    lastName: _lastNameController,
                    email: _emailController,
                    password: _passwordController,
                    isButtonEnabled: _isCurrentStepValid && !_isLoading,
                    onSignUp: _handleSignUp,
                    onGoogleSignUp: _handleGoogleSignUp,
                    loadingMessage: _isLoading ? _loadingMessage : null, 
                  ),
                ],
              ),
            ),

            if (_currentPage < 2)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: Pressable3DButton(
                    onTap: _isCurrentStepValid ? _nextPage : null,
                    color: _isCurrentStepValid ? SentiColors.primary : Colors.grey.shade300,
                    height: 56, 
                    child: Text(
                      'Continue',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _isCurrentStepValid ? Colors.white : Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SelectionStep extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> options;
  final String? selectedOption;
  final Function(String) onSelect;

  const _SelectionStep({
    required this.title,
    required this.options,
    required this.selectedOption,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: SentiColors.textMain,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 40),
          ...options.map((opt) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () => onSelect(opt['label']),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                decoration: BoxDecoration(
                  color: selectedOption == opt['label'] 
                      ? SentiColors.primary.withOpacity(0.05) 
                      : Colors.white,
                  border: Border.all(
                    color: selectedOption == opt['label'] 
                        ? SentiColors.primary 
                        : Colors.grey.shade300,
                    width: selectedOption == opt['label'] ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      opt['icon'], 
                      color: SentiColors.primary, 
                      size: 24
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        opt['label'],
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: SentiColors.textMain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}

class _SignUpFormStep extends StatelessWidget {
  final TextEditingController firstName;
  final TextEditingController lastName;
  final TextEditingController email;
  final TextEditingController password;
  final bool isButtonEnabled;
  final String? loadingMessage; 
  final VoidCallback onSignUp;
  final VoidCallback onGoogleSignUp;

  const _SignUpFormStep({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.isButtonEnabled,
    required this.onSignUp,
    required this.onGoogleSignUp,
    this.loadingMessage,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "You're all set! Let's make it official.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: SentiColors.textMain,
                  ),
                ),
                const SizedBox(height: 30),
                
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
                        onTap: onGoogleSignUp,
                        color: Colors.white, 
                        height: 40,
                        child: Image.asset('assets/images/google.png', height: 18),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1.5)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1.5)),
                  ],
                ),

                const SizedBox(height: 24),

                _SimpleInput(controller: email, label: "Email"),
                const SizedBox(height: 16),
                _SimpleInput(controller: password, label: "Password", isPassword: true),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(child: _SimpleInput(controller: firstName, label: "First Name")),
                    const SizedBox(width: 6), 
                    Expanded(child: _SimpleInput(controller: lastName, label: "Last Name")),
                  ],
                ),
                
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity, 
                  child: Pressable3DButton(
                    onTap: isButtonEnabled ? onSignUp : null,
                    color: isButtonEnabled ? SentiColors.primary : Colors.grey.shade300, 
                    height: 40,
                    child: loadingMessage != null 
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                            const SizedBox(width: 12),
                            Text(loadingMessage!, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        )
                      : Text(
                          'Sign Up',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isButtonEnabled ? Colors.white : Colors.grey.shade500,
                          ),
                        ),
                  ),
                ),
                
                const SizedBox(height: 40), 
              ],
            ),
          ),
        );
      }
    );
  }
}

class _SimpleInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isPassword;

  const _SimpleInput({required this.controller, required this.label, this.isPassword = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: GoogleFonts.inter(
          color: const Color(0xFF1F2937), 
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        cursorColor: SentiColors.primary,
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
        ),
      ),
    );
  }
}