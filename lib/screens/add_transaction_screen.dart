import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/suku_theme.dart';
import '../models/models.dart';
import '../services/transaction_service.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionType? initialType;
  const AddTransactionScreen({super.key, this.initialType});

  @override
  State<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  late TransactionType _type;
  ExpenseCategory? _category;
  final _amountCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _loading = false;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? TransactionType.expense;
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _amountCtrl.text.isNotEmpty &&
      _titleCtrl.text.isNotEmpty &&
      (_type == TransactionType.income || _category != null);

  Future<void> _save() async {
    if (!_isValid) return;
    setState(() => _loading = true);
    HapticFeedback.mediumImpact();

    final success = await TransactionService.addTransaction(
      title: _titleCtrl.text.trim(),
      amount: double.tryParse(_amountCtrl.text) ?? 0,
      type: _type,
      category: _category,
      notes: _notesCtrl.text.trim().isEmpty
          ? null
          : _notesCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Transaction saved!',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ],
          ),
          backgroundColor: SukuColors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save. Please try again.',
              style: GoogleFonts.plusJakartaSans(
                  color: Colors.white)),
          backgroundColor: SukuColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = _type == TransactionType.income;

    return Scaffold(
      backgroundColor: SukuColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Add Transaction',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: _isValid && !_loading ? _save : null,
            child: Text('Save',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _isValid
                        ? SukuColors.green
                        : SukuColors.textHint)),
          ),
        ],
      ),
      body: SlideTransition(
        position: _slideAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: SukuColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: SukuColors.border),
                ),
                child: Row(
                  children: [
                    _TypeTab(
                      label: '↑ Money In',
                      active: isIncome,
                      activeColor: SukuColors.green,
                      onTap: () => setState(() {
                        _type = TransactionType.income;
                        _category = null;
                      }),
                    ),
                    _TypeTab(
                      label: '↓ Money Out',
                      active: !isIncome,
                      activeColor: SukuColors.error,
                      onTap: () => setState(
                          () => _type = TransactionType.expense),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Amount
              Center(
                child: Column(
                  children: [
                    Text('Amount (Ksh)',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: SukuColors.textSecondary,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    IntrinsicWidth(
                      child: TextField(
                        controller: _amountCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: isIncome
                              ? SukuColors.green
                              : SukuColors.error,
                          letterSpacing: -1,
                        ),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            color: SukuColors.border,
                            letterSpacing: -1,
                          ),
                          border: InputBorder.none,
                          prefixText: 'Ksh ',
                          prefixStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: (isIncome
                                    ? SukuColors.green
                                    : SukuColors.error)
                                .withOpacity(0.6),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              const Divider(color: SukuColors.border),
              const SizedBox(height: 20),

              // Title
              _Field(
                label: isIncome
                    ? 'Source / Description'
                    : 'What did you pay for?',
                hint: isIncome
                    ? 'e.g. Morning sales, Customer payment'
                    : 'e.g. Unga wholesale, Staff wages',
                controller: _titleCtrl,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Category
              if (!isIncome) ...[
                Text('Category',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: SukuColors.textPrimary)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ExpenseCategory.values.map((cat) {
                    final active = _category == cat;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _category = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: active
                              ? cat.color.withOpacity(0.14)
                              : SukuColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: active
                                ? cat.color.withOpacity(0.5)
                                : SukuColors.border,
                            width: active ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(cat.icon,
                                size: 16,
                                color: active
                                    ? cat.color
                                    : SukuColors.textSecondary),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(cat.label,
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: active
                                            ? cat.color
                                            : SukuColors.textPrimary)),
                                Text(cat.swahili,
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        color: active
                                            ? cat.color.withOpacity(0.7)
                                            : SukuColors.textHint)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Notes
              _Field(
                label: 'Notes (optional)',
                hint: 'Any extra details...',
                controller: _notesCtrl,
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      _isValid && !_loading ? _save : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isValid
                        ? (isIncome
                            ? SukuColors.green
                            : SukuColors.navy)
                        : SukuColors.border,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    textStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : Text(_isValid
                          ? 'Hifadhi — Save Transaction'
                          : 'Fill all fields to save'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _TypeTab(
      {required this.label,
      required this.active,
      required this.activeColor,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active
                ? activeColor.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: active ? activeColor : SukuColors.textHint),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final int maxLines;
  final Function(String)? onChanged;

  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: SukuColors.textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          onChanged: onChanged,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 15, color: SukuColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14, color: SukuColors.textHint),
            filled: true,
            fillColor: SukuColors.surface,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: SukuColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: SukuColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: SukuColors.green, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}