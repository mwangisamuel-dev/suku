import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/suku_theme.dart';
import '../models/models.dart';
import '../services/transaction_service.dart';
import '../services/pdf_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _selectedMonth = DateTime.now();
  List<Transaction> _transactions = [];
  MonthlySummary _summary = MonthlySummary(
    totalIncome: 0,
    totalExpenses: 0,
    byCategory: {},
    transactions: [],
  );
  bool _loading = true;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final all = await TransactionService.getTransactions();
    final summary = TransactionService.getSummary(all);
    if (!mounted) return;
    setState(() {
      _transactions = all;
      _summary = summary;
      _loading = false;
    });
  }

  MonthlySummary get _monthSummary {
    final monthTxns =
        _transactions.where((t) => t.date.month == _selectedMonth.month && t.date.year == _selectedMonth.year).toList();

    double income = monthTxns.where((t) => t.type == TransactionType.income).fold(0, (s, t) => s + t.amount);
    double expenses = monthTxns.where((t) => t.type == TransactionType.expense).fold(0, (s, t) => s + t.amount);

    Map<ExpenseCategory, double> byCat = {};
    for (var t in monthTxns.where((t) => t.type == TransactionType.expense && t.category != null)) {
      byCat[t.category!] = (byCat[t.category!] ?? 0) + t.amount;
    }

    return MonthlySummary(
      totalIncome: income,
      totalExpenses: expenses,
      byCategory: byCat,
      transactions: monthTxns,
    );
  }

  Future<void> _generateAndShare() async {
    setState(() => _generating = true);
    try {
      final file = await PdfService.generateReport(
        transactions: _transactions,
        summary: _monthSummary,
        month: _selectedMonth,
      );
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Suku Report — ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to generate report: $e', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: SukuColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    }
    if (mounted) setState(() => _generating = false);
  }

  Future<void> _printReport() async {
    setState(() => _generating = true);
    try {
      final file = await PdfService.generateReport(
        transactions: _transactions,
        summary: _monthSummary,
        month: _selectedMonth,
      );
      await Printing.layoutPdf(onLayout: (_) async => file.readAsBytesSync());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to print: $e', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: SukuColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    }
    if (mounted) setState(() => _generating = false);
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_selectedMonth.year == now.year && _selectedMonth.month == now.month) return;
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ms = _monthSummary;
    final fmt = NumberFormat('#,##0', 'en_US');
    final isCurrentMonth = _selectedMonth.month == DateTime.now().month && _selectedMonth.year == DateTime.now().year;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ripoti',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 24, fontWeight: FontWeight.w800, color: SukuColors.textPrimary, letterSpacing: -0.5)),
                const SizedBox(height: 20),

                // Month selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: SukuColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: SukuColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _previousMonth,
                        icon: const Icon(Icons.chevron_left_rounded, color: SukuColors.textPrimary),
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(_selectedMonth),
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 16, fontWeight: FontWeight.w700, color: SukuColors.textPrimary),
                      ),
                      IconButton(
                        onPressed: isCurrentMonth ? null : _nextMonth,
                        icon: Icon(Icons.chevron_right_rounded,
                            color: isCurrentMonth ? SukuColors.border : SukuColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Summary cards
                if (_loading)
                  const Center(child: CircularProgressIndicator(color: SukuColors.green))
                else ...[
                  Row(
                    children: [
                      _SummaryCard(
                        label: 'Money In',
                        value: 'Ksh ${fmt.format(ms.totalIncome)}',
                        color: SukuColors.green,
                        icon: Icons.trending_up_rounded,
                      ),
                      const SizedBox(width: 12),
                      _SummaryCard(
                        label: 'Money Out',
                        value: 'Ksh ${fmt.format(ms.totalExpenses)}',
                        color: SukuColors.error,
                        icon: Icons.trending_down_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [SukuColors.navy, SukuColors.navyLight]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Net Profit',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white.withOpacity(0.6))),
                            const SizedBox(height: 4),
                            Text(
                              'Ksh ${fmt.format(ms.netProfit)}',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: (ms.netProfit >= 0 ? SukuColors.green : SukuColors.error).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            ms.totalIncome > 0 ? '${ms.profitMargin.toStringAsFixed(1)}% margin' : 'No data',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: ms.netProfit >= 0 ? SukuColors.greenLight : SukuColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Category breakdown
                  if (ms.byCategory.isNotEmpty) ...[
                    Text('Expense Breakdown',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 16, fontWeight: FontWeight.w700, color: SukuColors.textPrimary)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: SukuColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: SukuColors.border),
                      ),
                      child: Column(
                        children: (ms.byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).map((e) {
                          final pct = ms.totalExpenses > 0 ? e.value / ms.totalExpenses : 0.0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(children: [
                                      Icon(e.key.icon, size: 16, color: e.key.color),
                                      const SizedBox(width: 6),
                                      Text(e.key.label,
                                          style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: SukuColors.textPrimary)),
                                    ]),
                                    Text('Ksh ${fmt.format(e.value)}',
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13, fontWeight: FontWeight.w700, color: SukuColors.textPrimary)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    minHeight: 6,
                                    backgroundColor: e.key.color.withOpacity(0.12),
                                    valueColor: AlwaysStoppedAnimation(e.key.color),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // KRA estimate
                  Text('KRA Tax Estimate',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 16, fontWeight: FontWeight.w700, color: SukuColors.textPrimary)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: SukuColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: SukuColors.border),
                    ),
                    child: Column(
                      children: [
                        _KraRow(
                            label: 'Gross Income', value: 'Ksh ${fmt.format(ms.totalIncome)}', color: SukuColors.green),
                        _KraRow(
                            label: 'Total Expenses',
                            value: 'Ksh ${fmt.format(ms.totalExpenses)}',
                            color: SukuColors.error),
                        _KraRow(
                            label: 'Net Profit',
                            value: 'Ksh ${fmt.format(ms.netProfit)}',
                            color: ms.netProfit >= 0 ? SukuColors.green : SukuColors.error,
                            bold: true),
                        const Divider(height: 20, color: SukuColors.border),
                        _KraRow(
                            label: 'Estimated VAT (16%)',
                            value: 'Ksh ${fmt.format(ms.totalIncome * 0.16)}',
                            color: SukuColors.textSecondary),
                        _KraRow(
                            label: 'Estimated Income Tax (30%)',
                            value: 'Ksh ${fmt.format(ms.netProfit > 0 ? ms.netProfit * 0.30 : 0)}',
                            color: SukuColors.textSecondary),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: SukuColors.warning.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: SukuColors.warning.withOpacity(0.2)),
                          ),
                          child: Text(
                            '⚠️ Estimates only. Consult a certified accountant for official KRA filing.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: SukuColors.warning, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: _generating ? null : _printReport,
                            icon: const Icon(Icons.print_rounded, size: 18),
                            label: Text('Print', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: SukuColors.navy,
                              side: const BorderSide(color: SukuColors.navy),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _generating ? null : _generateAndShare,
                            icon: _generating
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.download_rounded, size: 18),
                            label: Text(_generating ? 'Generating...' : 'Download PDF',
                                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SukuColors.orange,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 100),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: SukuColors.textSecondary)),
            const SizedBox(height: 4),
            Text(value,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 15, fontWeight: FontWeight.w800, color: SukuColors.textPrimary, letterSpacing: -0.5)),
          ],
        ),
      ),
    );
  }
}

class _KraRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;

  const _KraRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: SukuColors.textSecondary, fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
          Text(value,
              style: GoogleFonts.plusJakartaSans(fontSize: bold ? 15 : 13, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
