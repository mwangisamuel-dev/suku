import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/suku_theme.dart';
import '../models/models.dart';
import '../widgets/shared_widgets.dart';
import '../services/transaction_service.dart';

class MpesaScreen extends StatefulWidget {
  const MpesaScreen({super.key});

  @override
  State<MpesaScreen> createState() => _MpesaScreenState();
}

class _MpesaScreenState extends State<MpesaScreen> {
  final _smsController = TextEditingController();
  Map<String, dynamic>? _parsed;
  bool _saved = false;
  bool _saving = false;

  final _examples = [
    'TGR76Y Confirmed. Ksh4,500 sent to NAIVAS SUPERMARKET on 3/6/26 at 9:14 AM. New M-PESA balance is Ksh12,340.00.',
    'ABC123 Confirmed. You have received Ksh8,200 from JOHN KAMAU 0712345678 on 3/6/26 at 2:30 PM.',
    'DEF456 Confirmed. Ksh1,200 paid to KPLC via M-PESA on 3/6/26. New balance Ksh11,140.',
  ];

  void _parseSms(String sms) {
    if (sms.trim().isEmpty) return;

    final amountRegex = RegExp(r'Ksh([\d,]+)');
    final firstMatch = amountRegex.firstMatch(sms);
    if (firstMatch == null) {
      setState(() =>
          _parsed = {'error': 'Could not find an amount in this SMS.'});
      return;
    }
    final amount =
        double.tryParse(firstMatch.group(1)!.replaceAll(',', '')) ??
            0;

    final isIncome = sms.toLowerCase().contains('received') ||
        sms.toLowerCase().contains('you have received');

    String vendor = 'M-Pesa Transaction';
    if (isIncome) {
      final fromRegex = RegExp(r'from ([A-Z\s]+) \d');
      final m = fromRegex.firstMatch(sms);
      if (m != null) vendor = m.group(1)!.trim();
    } else {
      final toRegex =
          RegExp(r'(?:sent to|paid to) ([A-Z\s]+) (?:on|via)');
      final m = toRegex.firstMatch(sms);
      if (m != null) vendor = m.group(1)!.trim();
    }

    ExpenseCategory cat = ExpenseCategory.other;
    final lower = sms.toLowerCase();
    if (lower.contains('kplc') ||
        lower.contains('kenya power') ||
        lower.contains('nairobi water')) {
      cat = ExpenseCategory.utilities;
    } else if (lower.contains('naivas') ||
        lower.contains('quickmart') ||
        lower.contains('carrefour') ||
        lower.contains('market') ||
        lower.contains('wholesale')) {
      cat = ExpenseCategory.stock;
    } else if (lower.contains('rent') ||
        lower.contains('kodi')) {
      cat = ExpenseCategory.rent;
    } else if (lower.contains('salary') ||
        lower.contains('mshahara') ||
        lower.contains('wages')) {
      cat = ExpenseCategory.salary;
    } else if (lower.contains('matatu') ||
        lower.contains('uber') ||
        lower.contains('bolt') ||
        lower.contains('petrol')) {
      cat = ExpenseCategory.transport;
    }

    setState(() {
      _saved = false;
      _parsed = {
        'amount': amount,
        'type':
            isIncome ? TransactionType.income : TransactionType.expense,
        'vendor': vendor,
        'category': isIncome ? null : cat,
        'isMpesa': true,
      };
    });
  }

  Future<void> _save() async {
    if (_parsed == null || _parsed!.containsKey('error')) return;
    setState(() => _saving = true);
    HapticFeedback.lightImpact();

    final success = await TransactionService.addTransaction(
      title: _parsed!['vendor'] as String,
      vendor: _parsed!['vendor'] as String,
      amount: _parsed!['amount'] as double,
      type: _parsed!['type'] as TransactionType,
      category: _parsed!['category'] as ExpenseCategory?,
      isMpesa: true,
    );

    if (!mounted) return;
    setState(() {
      _saving = false;
      _saved = success;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(
              success
                  ? Icons.check_circle_rounded
                  : Icons.error_outline_rounded,
              color: Colors.white,
              size: 18),
          const SizedBox(width: 8),
          Text(
              success
                  ? 'M-Pesa transaction saved!'
                  : 'Failed to save. Try again.',
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
      backgroundColor:
          success ? SukuColors.green : SukuColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));

    if (success) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) Navigator.pop(context, true);
      });
    }
  }

  @override
  void dispose() {
    _smsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SukuColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: SukuColors.greenSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.phone_android_rounded,
                  color: SukuColors.green, size: 18),
            ),
            const SizedBox(width: 10),
            Text('M-Pesa Import',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: SukuColors.greenSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: SukuColors.green.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: SukuColors.green, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Paste any M-Pesa SMS below. Suku will read it and save to your books.',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: SukuColors.greenDark,
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Paste M-Pesa SMS',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: SukuColors.textPrimary)),
            const SizedBox(height: 8),
            TextField(
              controller: _smsController,
              maxLines: 5,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: SukuColors.textPrimary),
              decoration: InputDecoration(
                hintText:
                    'e.g. TGR76Y Confirmed. Ksh4,500 sent to NAIVAS...',
                hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: SukuColors.textHint),
                filled: true,
                fillColor: SukuColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: SukuColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: SukuColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: SukuColors.green, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _parseSms(_smsController.text),
                      icon: const Icon(
                          Icons.auto_awesome_rounded,
                          size: 18),
                      label: const Text('Parse SMS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SukuColors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12)),
                        textStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _smsController.clear();
                        _parsed = null;
                        _saved = false;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SukuColors.textSecondary,
                      side: const BorderSide(
                          color: SukuColors.border),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12)),
                    ),
                    child: const Icon(Icons.clear_rounded),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Try an example',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: SukuColors.textPrimary)),
            const SizedBox(height: 10),
            ..._examples.map((ex) => GestureDetector(
                  onTap: () {
                    _smsController.text = ex;
                    _parseSms(ex);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: SukuColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: SukuColors.border),
                    ),
                    child: Text(ex,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: SukuColors.textSecondary,
                            height: 1.5),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                )),
            if (_parsed != null) ...[
              const SizedBox(height: 24),
              if (_parsed!.containsKey('error'))
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: SukuColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: SukuColors.error.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: SukuColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                            _parsed!['error'] as String,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: SukuColors.error)),
                      ),
                    ],
                  ),
                )
              else ...[
                SectionHeader(
                    title: 'Extracted Transaction'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: SukuColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border:
                        Border.all(color: SukuColors.border),
                  ),
                  child: Column(
                    children: [
                      _row(
                          'Type',
                          (_parsed!['type'] ==
                                  TransactionType.income)
                              ? 'Money In ↑'
                              : 'Money Out ↓',
                          _parsed!['type'] ==
                                  TransactionType.income
                              ? SukuColors.green
                              : SukuColors.error),
                      const Divider(
                          height: 20, color: SukuColors.border),
                      _row(
                          'Amount',
                          'Ksh ${(_parsed!['amount'] as double).toStringAsFixed(0)}',
                          SukuColors.textPrimary,
                          bold: true),
                      const Divider(
                          height: 20, color: SukuColors.border),
                      _row(
                          'Vendor / From',
                          _parsed!['vendor'] as String,
                          SukuColors.textPrimary),
                      if (_parsed!['category'] != null) ...[
                        const Divider(
                            height: 20,
                            color: SukuColors.border),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Category',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color:
                                        SukuColors.textSecondary)),
                            CategoryBadge(
                                category: _parsed!['category']
                                    as ExpenseCategory),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed:
                        (_saved || _saving) ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2))
                        : Icon(
                            _saved
                                ? Icons.check_circle_rounded
                                : Icons.save_rounded,
                            size: 20),
                    label: Text(
                        _saving
                            ? 'Saving...'
                            : _saved
                                ? 'Saved!'
                                : 'Hifadhi — Save Transaction',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _saved
                          ? SukuColors.greenDark
                          : SukuColors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14)),
                      textStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, Color valueColor,
      {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13, color: SukuColors.textSecondary)),
        Text(value,
            style: GoogleFonts.plusJakartaSans(
                fontSize: bold ? 18 : 14,
                fontWeight:
                    bold ? FontWeight.w800 : FontWeight.w600,
                color: valueColor,
                letterSpacing: bold ? -0.5 : 0)),
      ],
    );
  }
}