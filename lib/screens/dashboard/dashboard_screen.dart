import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../../main.dart';
import '../../services/auth_service.dart';
import '../../widgets/senti_card.dart';
import '../../widgets/pressable_3d_button.dart'; 
import '../debts/debts_screen.dart'; 
import '../savings/savings_screen.dart'; 
import '../profile/profile_screen.dart';
import 'expense_history_screen.dart'; 

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Pass the navigation callback to HomeTab
    final List<Widget> pages = [
      HomeTab(onSwitchTab: _onItemTapped),
      const DebtsScreen(), 
      const SavingsScreen(), 
      const ProfileScreen(),
    ];

    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color navBarColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    Color unselectedItemColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
      body: SafeArea(
        child: pages[_selectedIndex],
      ),
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const _AddExpenseModal(),
          );
        },
        backgroundColor: SentiColors.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBarColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Debts',
            ),
            BottomNavigationBarItem(
              icon: Icon(FontAwesomeIcons.piggyBank, size: 20),
              activeIcon: Icon(FontAwesomeIcons.piggyBank, size: 20),
              label: 'Savings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: SentiColors.primary,
          unselectedItemColor: unselectedItemColor,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          onTap: _onItemTapped,
          backgroundColor: navBarColor,
          elevation: 0,
          selectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

// --- HOME TAB CONTENT ---

class HomeTab extends StatelessWidget {
  final Function(int) onSwitchTab;

  const HomeTab({super.key, required this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final currency = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDark ? Colors.white : SentiColors.textMain;
    Color subTextColor = isDark ? Colors.grey.shade400 : SentiColors.textLight;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header with Streak ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
                      builder: (context, snapshot) {
                        String displayName = 'Hello!';
                        if (snapshot.hasData && snapshot.data != null) {
                          final data = snapshot.data!.data() as Map<String, dynamic>?;
                          final name = data?['firstName'] ?? 'User';
                          displayName = 'Hello, $name!';
                        }
                        // RESPONSIVE: FittedBox scales text down if name is too long
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            displayName,
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "How's your spending today?",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: subTextColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              // --- STREAK WIDGET ---
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
                builder: (context, snapshot) {
                  int streak = 0;
                  bool isLit = false;

                  if (snapshot.hasData && snapshot.data?.data() != null) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    streak = data['streak'] ?? 0;
                    
                    Timestamp? lastLog = data['lastLogDate'];
                    if (lastLog != null) {
                      DateTime date = lastLog.toDate();
                      DateTime now = DateTime.now();
                      if (date.year == now.year && date.month == now.month && date.day == now.day) {
                        isLit = true;
                      }
                    }
                  }

                  return GestureDetector(
                    onTap: () {
                      _showStreakDialog(context, isDark);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isLit 
                            ? (isDark ? Colors.orange.withOpacity(0.2) : Colors.orange.shade50) 
                            : (isDark ? Colors.grey.withOpacity(0.2) : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isLit ? Colors.orange.shade200 : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department, 
                            color: isLit ? Colors.orange : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "$streak",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: isLit ? Colors.orange : (isDark ? Colors.grey : Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // --- Spending Chart Card ---
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .collection('expenses')
                .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(DateTime.now().year, DateTime.now().month, 1))) 
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              Map<String, double> totals = {};
              double grandTotal = 0;

              if (snapshot.hasData) {
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  String cat = data['category'] ?? 'Other';
                  double amt = (data['amount'] ?? 0).toDouble();
                  
                  totals[cat] = (totals[cat] ?? 0) + amt;
                  grandTotal += amt;
                }
              }

              return SentiCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ExpenseHistoryScreen()),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "This Month's Spending",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    grandTotal > 0 ? SizedBox(
                      height: 200,
                      child: Row(
                        children: [
                          Expanded(flex: 1, child: _SpendingDonutChart(totals: totals)),
                          const SizedBox(width: 20),
                          Expanded(flex: 1, child: _ChartLegend(totals: totals, total: grandTotal, textColor: textColor)),
                        ],
                      ),
                    ) : Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Text("No spending yet this month", style: TextStyle(color: subTextColor)),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                    const SizedBox(height: 8),
                    _buildPersonalizedTip('spending', textColor),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // --- Debt Ledger Card ---
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .collection('debts')
                .where('settled', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              double owedToMe = 0;
              double iOwe = 0;

              if (snapshot.hasData) {
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final amount = (data['amount'] ?? 0).toDouble();
                  final type = data['type'];
                  if (type == 'owed') owedToMe += amount;
                  else if (type == 'owe') iOwe += amount;
                }
              }

              return SentiCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Debt Ledger", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 16),
                    
                    // RESPONSIVE: Row with FittedBox for amounts
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text("You are owed", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: textColor))),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(currency.format(owedToMe), style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: SentiColors.accent, fontSize: 18)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text("You owe", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: textColor))),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(currency.format(iOwe), style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: SentiColors.error, fontSize: 18)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildPersonalizedTip('debt', textColor),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () => onSwitchTab(1),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SentiColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          minimumSize: const Size(0, 36),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        child: const Text("View Details", style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // --- Top Priority Goal ---
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .collection('savings')
                .where('completed', isEqualTo: false) // Only show active goals
                .orderBy('createdAt', descending: true)
                .limit(1) 
                .snapshots(),
            builder: (context, snapshot) {
              // Empty State: Same Height as other cards
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SentiCard(
                  child: SizedBox(
                    width: double.infinity,
                    height: 220,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(FontAwesomeIcons.piggyBank, size: 48, color: SentiColors.primary.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          "No Goals Yet",
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Set a goal to start tracking!",
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => onSwitchTab(2),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SentiColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          child: const Text("Create Goal", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
              final title = data['title'] ?? "Goal";
              final current = (data['current'] ?? 0).toDouble();
              final target = (data['target'] ?? 1).toDouble();
              final percent = (current / target).clamp(0.0, 1.0);

              return SentiCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Top Priority Goal", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 16),
                    // RESPONSIVE: Title vs Amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            title, 
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: textColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text("${currency.format(current)} / ${currency.format(target)}", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearPercentIndicator(
                      lineHeight: 12.0,
                      percent: percent,
                      backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                      progressColor: SentiColors.primary,
                      barRadius: const Radius.circular(10),
                      padding: EdgeInsets.zero,
                      animation: true,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text("${(percent * 100).toStringAsFixed(0)}%", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                    const SizedBox(height: 12),
                    _buildPersonalizedTip('goal', textColor),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () => onSwitchTab(2),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SentiColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          minimumSize: const Size(0, 36),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        child: const Text("View All Goals", style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: 80), 
        ],
      ),
    );
  }

  // --- HELPER: Tip Generator Widget ---
  Widget _buildPersonalizedTip(String contextType, Color textColor) {
    final user = AuthService().currentUser;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        String tipText = "Keep tracking to stay in control.";
        if (snapshot.hasData && snapshot.data?.data() != null) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = data['financialStatus'] ?? '';
          final goal = data['primaryGoal'] ?? '';
          
          // Generate customized tip
          tipText = _generateRandomTip(contextType, status, goal);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lightbulb, size: 16, color: Colors.orangeAccent),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(fontSize: 10, color: textColor.withOpacity(0.7), fontStyle: FontStyle.italic),
                  children: [
                    TextSpan(text: "Senti's tips: ", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                    TextSpan(text: tipText),
                  ],
                ),
              ),
            ),
          ],
        );
      }
    );
  }

  // --- PERSONALIZED TIP LOGIC ---
  String _generateRandomTip(String contextType, String status, String goal) {
    final random = Random();
    List<String> tips = ["Consistency is key!"];

    // 1. Spending Tips
    if (contextType == 'spending') {
      // General tips
      tips = [
        "Small daily expenses (like coffee) add up fast. Check your 'Food' category!",
        "Review your spending weekly to catch leaks early.",
        "Wait 24 hours before making a big purchase to avoid impulse buying.",
        "Track every peso to see where your money really goes.",
      ];

      // Profile-specific
      if (status == 'Student') {
        tips.addAll([
          "Student discounts are real! Always check for perks with your ID.",
          "Textbooks are pricey. Look for second-hand or digital versions first.",
          "Meal prepping is your wallet's best friend. Skip the cafeteria!",
          "Use your student status to get software discounts."
        ]);
      } else if (status == 'Freelance/Self-Employed') {
        tips.addAll([
          "Inconsistent income? Try the '50/30/20' rule adjusted for your lowest month.",
          "Set aside tax money immediately when you get paid. Future you will be grateful.",
          "Create a 'lean' budget for slow months to avoid stress."
        ]);
      } else if (status == 'Full-time Employed') {
        tips.addAll([
          "Automate your savings on payday so you don't spend it first.",
          "Check if your employer offers benefits or reimbursements you aren't using.",
          "Avoid lifestyle inflation. Just because you earn more doesn't mean you must spend more."
        ]);
      }
    }

    // 2. Debt Tips
    if (contextType == 'debt') {
      tips = [
        "Lending to friends? Keep records here to avoid awkward conversations later.",
        "Paying off high-interest debt first usually saves you the most money.",
        "Consistency is key. Even small payments chip away at the total."
      ];

      if (goal == 'Becoming debt-free') {
        tips.addAll([
          "Since your goal is to be debt-free, try the 'Snowball Method' (pay smallest debts first).",
          "Any extra income (bonuses, gifts) should go straight to your debt.",
          "Review your subscriptions. Can you cut one to pay off debt faster?"
        ]);
      }
    }

    // 3. Goal Tips
    if (contextType == 'goal') {
      tips = [
        "You're closer to your goal than you were yesterday. Keep going!",
        "Review your goals monthly to make sure they still align with your life.",
        "Celebrate small milestones along the way!"
      ];

      if (goal == 'Saving for something special') {
        tips.add("Visualize the reward! It makes saving much easier.");
      } else if (goal == 'Investing for the future') {
        tips.add("Time in the market beats timing the market. Consistency is key.");
      } else if (goal == 'Building my peace of mind') {
        tips.add("An emergency fund is your safety net. Aim for 3-6 months of expenses.");
      } else if (goal == 'Finally getting organized') {
        tips.add("Organization brings clarity. You're doing great just by tracking!");
      }
    }
    
    return tips[random.nextInt(tips.length)];
  }

  void _showStreakDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.local_fire_department, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            Text("Daily Streak", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          ],
        ),
        content: Text(
          "Track your expenses every day to keep your streak alive! The fire will go out if you miss a day.",
          style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: isDark ? Colors.grey.shade400 : Colors.grey.shade800),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Got it",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: SentiColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- CHART WIDGETS ---
Color _getCategoryColor(String cat) {
  switch (cat) {
    case 'Food': return const Color(0xFF81C784);
    case 'Transport': return const Color(0xFF64B5F6);
    case 'Entertainment': return const Color(0xFFFFB74D);
    case 'Shopping': return const Color(0xFFE57373);
    case 'Other': return const Color(0xFFBA68C8);
    default: return Colors.primaries[cat.hashCode % Colors.primaries.length];
  }
}

class _ChartLegend extends StatelessWidget {
  final Map<String, double> totals;
  final double total;
  final Color textColor;

  const _ChartLegend({required this.totals, required this.total, required this.textColor});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final categories = totals.keys.toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Map categories to legend items
        ...categories.map((cat) => _legendItem(
          _getCategoryColor(cat), 
          cat, 
          currency.format(totals[cat])
        )),
        
        const Divider(height: 12),
        
        // Total Row with Overflow protection
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Total", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(currency.format(total), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _legendItem(Color color, String label, String amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: color, radius: 4),
              const SizedBox(width: 6),
              Text(label, style: GoogleFonts.inter(fontSize: 10, color: textColor.withOpacity(0.7))),
            ],
          ),
          // RESPONSIVE: FittedBox ensures large amounts don't break layout
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(amount, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: textColor)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpendingDonutChart extends StatelessWidget {
  final Map<String, double> totals;
  const _SpendingDonutChart({required this.totals});

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sectionsSpace: 0,
        centerSpaceRadius: 30,
        sections: totals.entries.map((entry) {
          return PieChartSectionData(
            color: _getCategoryColor(entry.key),
            value: entry.value,
            radius: 15,
            showTitle: false,
          );
        }).toList(),
      ),
    );
  }
}

// --- ADD EXPENSE MODAL ---
class _AddExpenseModal extends StatefulWidget {
  const _AddExpenseModal();
  @override
  State<_AddExpenseModal> createState() => _AddExpenseModalState();
}

class _AddExpenseModalState extends State<_AddExpenseModal> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _category = "Food";
  bool _isLoading = false;
  final List<String> _categories = ["Food", "Transport", "Entertainment", "Shopping", "Other"];

  Future<void> _saveExpense() async {
    if (_amountCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    final user = AuthService().currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('expenses').add({
        'amount': double.tryParse(_amountCtrl.text) ?? 0,
        'category': _category,
        'note': _noteCtrl.text,
        'date': FieldValue.serverTimestamp(),
      });

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = userDoc.data() ?? {};
      Timestamp? lastLog = data['lastLogDate'];
      int currentStreak = data['streak'] ?? 0;
      DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      DateTime? lastDate = lastLog?.toDate();
      if (lastDate != null) lastDate = DateTime(lastDate.year, lastDate.month, lastDate.day);

      if (lastDate == null || lastDate != today) {
         if (lastDate != null && lastDate == today.subtract(const Duration(days: 1))) {
             currentStreak += 1;
         } else {
             currentStreak = 1;
         }
         await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'streak': currentStreak,
            'lastLogDate': FieldValue.serverTimestamp(),
         });
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      print("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    Color text = isDark ? Colors.white : Colors.black;
    
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Add New Expense", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: SentiColors.primary)),
          const SizedBox(height: 24),
          Text("Amount", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: text)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: text),
              decoration: InputDecoration(
                hintText: "₱ 0.00",
                hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text("Category", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: text)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _category,
                isExpanded: true,
                dropdownColor: bg,
                style: TextStyle(color: text),
                items: _categories.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: GoogleFonts.inter()),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() => _category = newValue!);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text("Note (Optional)", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: text)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _noteCtrl,
              style: TextStyle(color: text),
              decoration: InputDecoration(
                hintText: "Add a note...",
                hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: Pressable3DButton(
              onTap: _isLoading ? null : _saveExpense,
              color: SentiColors.primary,
              height: 50,
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text("Add Expense", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}