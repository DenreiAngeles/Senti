import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../main.dart';
import '../../services/auth_service.dart';
import '../../widgets/pressable_3d_button.dart';
import '../../widgets/senti_card.dart';
import 'goal_history_screen.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  final _user = AuthService().currentUser;
  final currency = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

  @override
  Widget build(BuildContext context) {
    // --- DARK MODE LOGIC ---
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color headerColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    Color textColor = isDark ? Colors.white : SentiColors.textMain;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // --- Header ---
          Container(
            padding: const EdgeInsets.all(24),
            color: headerColor,
            width: double.infinity,
            child: Column(
              children: [
                Text(
                  "Savings Goals",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                
                // --- GOALS ACHIEVED PILL (Clickable) ---
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(_user?.uid)
                      .collection('savings')
                      .where('completed', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    int count = 0;
                    if (snapshot.hasData) count = snapshot.data!.docs.length;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const GoalHistoryScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.amber.withOpacity(0.2) : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? Colors.amber.shade700 : Colors.amber.shade200
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("🏆", style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(
                              "$count Goals Achieved",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.amber.shade400 : Colors.amber.shade800,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios, 
                              size: 12, 
                              color: isDark ? Colors.amber.shade400 : Colors.amber.shade800
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // --- Goals List (Active Only) ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_user?.uid)
                  .collection('savings')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Filter out completed goals on the client side
                final docs = snapshot.data?.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['completed'] != true;
                }).toList() ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.savings_outlined, size: 64, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          "No active savings goals.\nStart saving for something special!",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(color: isDark ? Colors.grey.shade400 : Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final id = docs[index].id;
                    return _buildGoalCard(data, id, isDark);
                  },
                );
              },
            ),
          ),

          // --- Add Button ---
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: Pressable3DButton(
                onTap: () => _showAddGoalModal(context, isDark),
                color: SentiColors.primary,
                height: 56,
                child: Text(
                  '+ Add New Goal',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Components ---

  Widget _buildGoalCard(Map<String, dynamic> data, String id, bool isDark) {
    double current = (data['current'] ?? 0).toDouble();
    double target = (data['target'] ?? 1).toDouble();
    double percent = (current / target).clamp(0.0, 1.0);
    
    // Dynamic text color for dark mode
    Color textColor = isDark ? Colors.white : SentiColors.textMain;

    return SentiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  data['title'] ?? "Goal",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${currency.format(current)} / ${currency.format(target)}",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),

          LinearPercentIndicator(
            lineHeight: 14.0,
            percent: percent,
            backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            progressColor: SentiColors.primary,
            barRadius: const Radius.circular(10),
            padding: EdgeInsets.zero,
            animation: true,
            animationDuration: 1000,
          ),
          
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${(percent * 100).toStringAsFixed(0)}%",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: SentiColors.primary,
                ),
              ),
              
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: () => _showAddFundsModal(context, id, current, target, data['title'], isDark),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SentiColors.primary,
                    foregroundColor: Colors.white, // FORCE WHITE TEXT
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    "Add Funds",
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Modals ---

  void _showAddGoalModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddGoalModal(isDark: isDark),
    );
  }

  void _showAddFundsModal(BuildContext context, String docId, double current, double target, String title, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddFundsModal(
        docId: docId, 
        currentAmount: current, 
        targetAmount: target,
        goalTitle: title,
        isDark: isDark,
        onGoalCompleted: () {
          _showCelebrationDialog(context, title, isDark);
        }
      ),
    );
  }

  void _showCelebrationDialog(BuildContext context, String goalTitle, bool isDark) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: _CelebrationWidget(goalTitle: goalTitle, isDark: isDark),
        );
      },
    );
  }
}

// --- Animated Celebration Widget ---
class _CelebrationWidget extends StatefulWidget {
  final String goalTitle;
  final bool isDark;
  const _CelebrationWidget({required this.goalTitle, required this.isDark});

  @override
  State<_CelebrationWidget> createState() => _CelebrationWidgetState();
}

class _CelebrationWidgetState extends State<_CelebrationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color bg = widget.isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("🎉", style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            Text(
              "Goal Achieved!",
              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: SentiColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              "You did it! '${widget.goalTitle}' is complete.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: widget.isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: Pressable3DButton(
                onTap: () => Navigator.pop(context),
                color: SentiColors.primary,
                height: 48,
                child: Text("Awesome!", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Add Goal Modal ---

class _AddGoalModal extends StatefulWidget {
  final bool isDark;
  const _AddGoalModal({required this.isDark});

  @override
  State<_AddGoalModal> createState() => _AddGoalModalState();
}

class _AddGoalModalState extends State<_AddGoalModal> {
  final _titleCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _initialCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveGoal() async {
    if (_titleCtrl.text.isEmpty || _targetCtrl.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    final user = AuthService().currentUser;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('savings')
          .add({
        'title': _titleCtrl.text,
        'target': double.tryParse(_targetCtrl.text) ?? 0,
        'current': double.tryParse(_initialCtrl.text) ?? 0,
        'completed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      print("Error adding goal: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color bg = widget.isDark ? const Color(0xFF1E1E1E) : Colors.white;
    Color text = widget.isDark ? Colors.white : SentiColors.primary;

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
          Text("Add New Savings Goal", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: text)),
          const SizedBox(height: 24),
          _ModalInput(label: "Goal Title", controller: _titleCtrl, hint: "e.g. New Laptop", isDark: widget.isDark),
          const SizedBox(height: 16),
          _ModalInput(label: "Fund Needed", controller: _targetCtrl, isNumber: true, hint: "₱ 0.00", isDark: widget.isDark),
          const SizedBox(height: 16),
          _ModalInput(label: "Initial Fund (Optional)", controller: _initialCtrl, isNumber: true, hint: "₱ 0.00", isDark: widget.isDark),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: Pressable3DButton(
              onTap: _isLoading ? null : _saveGoal,
              color: SentiColors.primary,
              height: 50,
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text("Add Goal", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}

// --- Add Funds Modal ---

class _AddFundsModal extends StatefulWidget {
  final String docId;
  final double currentAmount;
  final double targetAmount;
  final String goalTitle;
  final bool isDark;
  final VoidCallback onGoalCompleted;

  const _AddFundsModal({
    required this.docId, 
    required this.currentAmount,
    required this.targetAmount,
    required this.goalTitle,
    required this.isDark,
    required this.onGoalCompleted,
  });

  @override
  State<_AddFundsModal> createState() => _AddFundsModalState();
}

class _AddFundsModalState extends State<_AddFundsModal> {
  final _amountCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _addFunds() async {
    if (_amountCtrl.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    final user = AuthService().currentUser;
    double amountToAdd = double.tryParse(_amountCtrl.text) ?? 0;
    double newTotal = widget.currentAmount + amountToAdd;
    
    bool isCompleted = newTotal >= widget.targetAmount;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('savings')
          .doc(widget.docId)
          .update({
        'current': newTotal,
        'completed': isCompleted,
        'completedDate': isCompleted ? FieldValue.serverTimestamp() : null,
      });
      
      if (mounted) {
        Navigator.pop(context); 
        if (isCompleted) {
          widget.onGoalCompleted(); 
        }
      }
    } catch (e) {
      print("Error adding funds: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color bg = widget.isDark ? const Color(0xFF1E1E1E) : Colors.white;
    Color text = widget.isDark ? Colors.white : SentiColors.primary;

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
          Text("Add Funds to '${widget.goalTitle}'", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: text)),
          const SizedBox(height: 24),
          _ModalInput(label: "Amount to Add", controller: _amountCtrl, isNumber: true, hint: "₱ 0.00", isDark: widget.isDark),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: Pressable3DButton(
              onTap: _isLoading ? null : _addFunds,
              color: SentiColors.primary,
              height: 50,
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text("Add Funds", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}

class _ModalInput extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isNumber;
  final bool isDark;

  const _ModalInput({
    required this.label, 
    required this.controller, 
    this.hint = "", 
    this.isNumber = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    Color labelColor = isDark ? Colors.white : Colors.black;
    Color borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    Color hintColor = isDark ? Colors.grey.shade500 : Colors.grey.shade400;
    Color inputColor = isDark ? Colors.white : Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: labelColor)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: GoogleFonts.inter(color: inputColor),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: hintColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}