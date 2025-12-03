import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../services/auth_service.dart';
import '../../widgets/senti_card.dart';

class GoalHistoryScreen extends StatelessWidget {
  const GoalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final currency = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final dateFormat = DateFormat('MMM d, yyyy');

    // --- DARK MODE COLORS ---
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor = Theme.of(context).scaffoldBackgroundColor;
    Color appBarColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    Color textColor = isDark ? Colors.white : SentiColors.textMain;
    Color subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Achievement History",
          style: GoogleFonts.inter(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .collection('savings')
            .where('completed', isEqualTo: true)
            .orderBy('completedDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events_outlined, size: 64, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    "No completed goals yet.\nKeep saving!",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: subTextColor),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              final target = (data['target'] ?? 0).toDouble();
              final date = (data['completedDate'] as Timestamp?)?.toDate();

              return SentiCard(
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.amber.withOpacity(0.2) : Colors.amber.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text("🏆", style: TextStyle(fontSize: 24)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['title'] ?? "Goal",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textColor, // Dynamic White/Black
                            ),
                          ),
                          Text(
                            "Achieved on ${date != null ? dateFormat.format(date) : 'Unknown'}",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: subTextColor, // Dynamic Grey
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      currency.format(target),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: SentiColors.accent, // Green usually looks fine in dark mode too
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}