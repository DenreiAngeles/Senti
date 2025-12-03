import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../services/auth_service.dart';
import '../../widgets/pressable_3d_button.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  // Toggle State: 'owed' (People owe me) vs 'owe' (I owe people)
  String _currentView = 'owed'; 
  final _user = AuthService().currentUser;
  final currency = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

  @override
  Widget build(BuildContext context) {
    // Dark Mode Check
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor = Theme.of(context).scaffoldBackgroundColor;
    Color headerColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    Color textColor = isDark ? Colors.white : SentiColors.textMain;
    
    // Toggle Colors
    Color trackColor = isDark ? Colors.grey.shade800 : const Color(0xFFF0F0F0);
    Color inactiveTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // --- Header & Toggle ---
          Container(
            padding: const EdgeInsets.all(24),
            color: headerColor,
            child: Column(
              children: [
                Text(
                  "Debt Ledger",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 24),
                
                // --- SLIDING TOGGLE SWITCH ---
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: trackColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.all(4), // Internal padding for the pill
                  child: Stack(
                    children: [
                      // 1. The Sliding Green Pill (Animated)
                      AnimatedAlign(
                        alignment: _currentView == 'owed' ? Alignment.centerLeft : Alignment.centerRight,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: FractionallySizedBox(
                          widthFactor: 0.5,
                          heightFactor: 1.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: SentiColors.primary,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // 2. The Text Labels (Clickable Layer)
                      Row(
                        children: [
                          _buildToggleOption("You are Owed", 'owed', inactiveTextColor),
                          _buildToggleOption("You Owe", 'owe', inactiveTextColor),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- Debt List ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_user?.uid)
                  .collection('debts')
                  .where('type', isEqualTo: _currentView)
                  .where('settled', isEqualTo: false)
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
                        Icon(Icons.check_circle_outline, size: 64, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          "All clear! No active debts.",
                          style: GoogleFonts.inter(color: isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final id = docs[index].id;
                    return _buildDebtCard(data, id, isDark);
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
                onTap: () => _showAddDebtModal(context, isDark),
                color: SentiColors.primary,
                height: 56,
                child: Text(
                  '+ Add New Debt',
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

  // --- Helper Widgets ---

  // Helper for the transparent text buttons on top of the slider
  Widget _buildToggleOption(String label, String value, Color inactiveColor) {
    bool isSelected = _currentView == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentView = value),
        behavior: HitTestBehavior.translucent, // Ensures taps are caught even on empty space
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isSelected ? Colors.white : inactiveColor,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  Widget _buildDebtCard(Map<String, dynamic> data, String id, bool isDark) {
    bool isOwed = _currentView == 'owed';
    Color amountColor = isOwed ? SentiColors.accent : SentiColors.error;
    
    // Exact colors from prototype
    const Color lightCardColor = Color(0xFFF7F6F1); // Beige
    const Color darkCardColor = Color(0xFF1E1E1E); 
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? darkCardColor : lightCardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black : const Color(0xFFEBEAE4), 
            blurRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: SentiColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                (data['person'] as String).isNotEmpty ? data['person'][0].toUpperCase() : "?",
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['person'] ?? "Unknown",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16, 
                    color: isDark ? Colors.white : SentiColors.textMain
                  ),
                ),
                Text(
                  data['note'] != null && (data['note'] as String).isNotEmpty 
                      ? data['note'] 
                      : "No details",
                  style: GoogleFonts.inter(
                    fontSize: 12, 
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, 
                    fontStyle: FontStyle.italic
                  ),
                ),
              ],
            ),
          ),

          // Amount & Action
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currency.format(data['amount'] ?? 0),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: amountColor,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 28,
                child: ElevatedButton(
                  onPressed: () => _settleDebt(id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SentiColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    "Settle",
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _settleDebt(String id) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_user?.uid)
        .collection('debts')
        .doc(id)
        .update({'settled': true});
  }

  void _showAddDebtModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) => _AddDebtModal(currentType: _currentView, isDark: isDark),
    );
  }
}

// --- Add Debt Modal Component ---

class _AddDebtModal extends StatefulWidget {
  final String currentType;
  final bool isDark;
  const _AddDebtModal({required this.currentType, required this.isDark});

  @override
  State<_AddDebtModal> createState() => _AddDebtModalState();
}

class _AddDebtModalState extends State<_AddDebtModal> {
  final _amountCtrl = TextEditingController();
  final _personCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveDebt() async {
    if (_amountCtrl.text.isEmpty || _personCtrl.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    final user = AuthService().currentUser;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('debts')
          .add({
        'amount': double.tryParse(_amountCtrl.text) ?? 0,
        'person': _personCtrl.text,
        'note': _noteCtrl.text,
        'type': widget.currentType,
        'settled': false,
        'date': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      print("Error adding debt: $e");
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
          Text(
            "Add New Debt",
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: text),
          ),
          const SizedBox(height: 24),
          
          _ModalInput(label: "Amount", controller: _amountCtrl, isNumber: true, hint: "₱ 0.00", isDark: widget.isDark),
          const SizedBox(height: 16),
          _ModalInput(label: widget.currentType == 'owed' ? "Debtor" : "Creditor", controller: _personCtrl, hint: widget.currentType == 'owed' ? "Name of Debtor" : "Name of Creditor", isDark: widget.isDark),
          const SizedBox(height: 16),
          _ModalInput(label: "Note (Optional)", controller: _noteCtrl, hint: "Add a note...", maxLines: 2, isDark: widget.isDark),
          
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            child: Pressable3DButton(
              onTap: _isLoading ? null : _saveDebt,
              color: SentiColors.primary,
              height: 50,
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : Text("Add Debt", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
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
  final int maxLines;
  final bool isDark;

  const _ModalInput({
    required this.label, 
    required this.controller, 
    this.hint = "", 
    this.isNumber = false,
    this.maxLines = 1,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    Color labelColor = isDark ? Colors.white : SentiColors.primary; 
    Color borderColor = isDark ? Colors.grey.shade700 : SentiColors.primary;
    Color hintColor = isDark ? Colors.grey.shade500 : Colors.grey.shade400;
    Color inputColor = isDark ? Colors.white : Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: labelColor)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            maxLines: maxLines,
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