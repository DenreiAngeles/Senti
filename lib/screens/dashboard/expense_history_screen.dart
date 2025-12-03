import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../services/auth_service.dart';

class ExpenseHistoryScreen extends StatelessWidget {
  const ExpenseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final currency = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final timeFormat = DateFormat('MMM d • h:mm a'); 
    final monthFormat = DateFormat('MMMM yyyy'); 

    // --- DARK MODE COLORS ---
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor = Theme.of(context).scaffoldBackgroundColor;
    Color appBarColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    Color textColor = isDark ? Colors.white : SentiColors.textMain;
    Color subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    Color dividerColor = isDark ? Colors.grey.shade800 : const Color(0xFFF0F0F0);
    Color headerBg = isDark ? Colors.black54 : Colors.grey.shade50;

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
          "Expense History",
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
            .collection('expenses')
            .orderBy('date', descending: true)
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
                  Icon(Icons.receipt_long_outlined, size: 64, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    "No expenses recorded yet.",
                    style: GoogleFonts.inter(color: subTextColor),
                  ),
                ],
              ),
            );
          }

          // Grouping Logic
          final Map<String, List<QueryDocumentSnapshot>> groupedExpenses = {};
          final Map<String, double> monthlyTotals = {};

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final Timestamp? timestamp = data['date'];
            
            if (timestamp != null) {
              final date = timestamp.toDate();
              final monthKey = monthFormat.format(date);
              
              if (!groupedExpenses.containsKey(monthKey)) {
                groupedExpenses[monthKey] = [];
                monthlyTotals[monthKey] = 0;
              }
              
              groupedExpenses[monthKey]!.add(doc);
              monthlyTotals[monthKey] = monthlyTotals[monthKey]! + (data['amount'] ?? 0).toDouble();
            }
          }

          final monthKeys = groupedExpenses.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: monthKeys.length,
            itemBuilder: (context, sectionIndex) {
              final monthKey = monthKeys[sectionIndex];
              final expenses = groupedExpenses[monthKey]!;
              final total = monthlyTotals[monthKey]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Month Header ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    color: headerBg, 
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          monthKey,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                        Text(
                          "Total: ${currency.format(total)}",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: subTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- Expense Items ---
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    itemCount: expenses.length,
                    separatorBuilder: (_, __) => Divider(height: 32, color: dividerColor),
                    itemBuilder: (context, index) {
                      final data = expenses[index].data() as Map<String, dynamic>;
                      final amount = (data['amount'] ?? 0).toDouble();
                      final category = data['category'] ?? 'Other';
                      final note = data['note'] ?? '';
                      final Timestamp timestamp = data['date'];
                      
                      return Row(
                        children: [
                          // Category Icon
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _getCategoryColor(category).withOpacity(0.15), // Slightly more visible in dark mode
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getCategoryIcon(category),
                              color: _getCategoryColor(category),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: textColor,
                                  ),
                                ),
                                if (note.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      note,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: subTextColor,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  timeFormat.format(timestamp.toDate()),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Amount
                          Text(
                            "- ${currency.format(amount)}",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: SentiColors.error, 
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food': return const Color(0xFF81C784);
      case 'Transport': return const Color(0xFF64B5F6);
      case 'Entertainment': return const Color(0xFFFFB74D);
      case 'Shopping': return const Color(0xFFE57373);
      default: return const Color(0xFFBA68C8);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food': return Icons.restaurant;
      case 'Transport': return Icons.directions_bus;
      case 'Entertainment': return Icons.movie;
      case 'Shopping': return Icons.shopping_bag;
      default: return Icons.category;
    }
  }
}