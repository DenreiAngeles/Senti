import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main.dart';
import '../../services/auth_service.dart';
import '../../core/theme_notifier.dart'; // Import theme manager
import '../../widgets/pressable_3d_button.dart';
import '../../widgets/senti_card.dart';
import '../auth/welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  
  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    // Check current theme mode
    bool isDark = themeNotifier.value == ThemeMode.dark;
    Color textColor = isDark ? Colors.white : SentiColors.textMain;
    Color subTextColor = isDark ? Colors.grey.shade400 : SentiColors.textLight;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // --- Header: User Info ---
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
                builder: (context, snapshot) {
                  String name = "User";
                  String email = user?.email ?? "No Email";
                  int streak = 0;

                  if (snapshot.hasData && snapshot.data != null) {
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    if (data != null) {
                      name = "${data['firstName']} ${data['lastName']}";
                      streak = data['streak'] ?? 0;
                    }
                  }

                  return Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: SentiColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).cardColor, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.person, size: 60, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        email,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: subTextColor,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // --- Gamification Stats ---
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              "🔥 $streak", 
                              "Days Streak", 
                              Colors.orange,
                              textColor
                            )
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user?.uid)
                                  .collection('savings')
                                  .snapshots(),
                              builder: (context, goalSnapshot) {
                                int achievedCount = 0;
                                if (goalSnapshot.hasData) {
                                  for (var doc in goalSnapshot.data!.docs) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    double target = (data['target'] ?? 1).toDouble();
                                    double current = (data['current'] ?? 0).toDouble();
                                    if (current >= target && target > 0) achievedCount++;
                                  }
                                }
                                return _buildStatCard(
                                  "🏆 $achievedCount", 
                                  "Goals Achieved", 
                                  Colors.amber,
                                  textColor
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 40),

              // --- Settings (Dark Mode Toggle) ---
              SentiCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.dark_mode, color: isDark ? Colors.white : SentiColors.primary),
                        const SizedBox(width: 12),
                        Text(
                          "Dark Mode",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: isDark,
                      activeColor: SentiColors.primary,
                      onChanged: (val) {
                        themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // --- About Button ---
              Pressable3DButton(
                onTap: () => _showAboutDialog(context),
                color: SentiColors.primary,
                height: 56,
                child: Text(
                  "About Senti",
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),

              const SizedBox(height: 16),

              // --- Log Out Button ---
              Pressable3DButton(
                onTap: () async {
                  await AuthService().signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                      (route) => false,
                    );
                  }
                },
                color: const Color(0xFFEF4444),
                height: 56,
                child: Text(
                  "Log Out",
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color accentColor, Color textColor) {
    return SentiCard(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10, 
              fontWeight: FontWeight.bold, 
              color: accentColor, 
              letterSpacing: 0.5
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    // Determine colors for dialog based on theme
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    Color text = isDark ? Colors.white : Colors.black;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: SentiColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite, color: SentiColors.primary, size: 40),
                ),
                const SizedBox(height: 20),
                Text(
                  "Made with ❤️",
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: text),
                ),
                const SizedBox(height: 12),
                Text(
                  "Senti is a passion project created by a Computer Science student as part of a University course.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 14, color: text.withOpacity(0.8), height: 1.5),
                ),
                const SizedBox(height: 12),
                Text(
                  "This app was built for CS-312: Mobile Computing.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 12, color: text.withOpacity(0.5), fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: Pressable3DButton(
                    onTap: () => Navigator.pop(context),
                    color: SentiColors.primary,
                    height: 48,
                    child: Text("Close", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}