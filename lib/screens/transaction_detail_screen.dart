import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/suku_theme.dart';
import '../models/models.dart';
import '../services/pdf_service.dart';
import '../services/transaction_service.dart';
import '../services/language_service.dart';
import '../widgets/shared_widgets.dart';

class TransactionDetailScreen extends StatefulWidget {
  final Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  bool _deleting = false;
  bool _sharing = false;

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete transaction?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text('This cannot be undone.',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: SukuColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.plusJakartaSans(color: SukuColors.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: SukuColors.error,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Delete', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _deleting = true);
    HapticFeedback.mediumImpact();

    final success = await TransactionService.deleteTransaction(widget.transaction.id);

    if (!mounted) return;
    setState(() => _deleting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Transaction deleted',
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: SukuColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to delete. Try again.', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: SukuColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  Future<void> _shareInvoice() async {
    setState(() => _sharing = true);
    try {
      final file = await PdfService.generateInvoice(transaction: widget.transaction);
      await Share.shareXFiles([XFile(file.path)], subject: 'Suku Invoice - ${widget.transaction.title}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(LanguageService.text('invoiceGenerateSuccess'),
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: SukuColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(LanguageService.text('invoiceShareError'), style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: SukuColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final isIncome = t.type == TransactionType.income;
    final color = isIncome ? SukuColors.green : SukuColors.error;

    return Scaffold(
      backgroundColor: SukuColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: SukuColors.navy,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (_deleting)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                  onPressed: _delete,
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [SukuColors.navy, SukuColors.navyLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -40,
                      right: -40,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(0.12),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 56, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isIncome ? Icons.trending_up_rounded : (t.category?.icon ?? Icons.receipt_rounded),
                                  color: color,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                isIncome ? 'Money In' : 'Money Out',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13, fontWeight: FontWeight.w600, color: color),
                              ),
                              if (t.isMpesa) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: SukuColors.green.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('M-Pesa',
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10, fontWeight: FontWeight.w700, color: SukuColors.greenLight)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${isIncome ? '+' : '-'} Ksh ${NumberFormat('#,##0').format(t.amount)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t.title,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 15, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: SukuColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: SukuColors.border),
                    ),
                    child: Column(
                      children: [
                        _detailRow(
                          icon: Icons.store_rounded,
                          label: 'Vendor',
                          value: t.vendor ?? 'N/A',
                        ),
                        const Divider(height: 24, color: SukuColors.border),
                        _detailRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'Date & Time',
                          value: DateFormat('EEEE, d MMMM yyyy · HH:mm').format(t.date),
                        ),
                        if (t.category != null) ...[
                          const Divider(height: 24, color: SukuColors.border),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: SukuColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.label_rounded, size: 18, color: SukuColors.textSecondary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Category',
                                        style:
                                            GoogleFonts.plusJakartaSans(fontSize: 12, color: SukuColors.textSecondary)),
                                    const SizedBox(height: 4),
                                    CategoryBadge(category: t.category!),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (t.notes != null) ...[
                          const Divider(height: 24, color: SukuColors.border),
                          _detailRow(
                            icon: Icons.notes_rounded,
                            label: 'Notes',
                            value: t.notes!,
                          ),
                        ],
                        const Divider(height: 24, color: SukuColors.border),
                        _detailRow(
                          icon: Icons.tag_rounded,
                          label: 'Transaction ID',
                          value: '#${t.id.substring(0, 8).toUpperCase()}',
                        ),
                        const Divider(height: 24, color: SukuColors.border),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: SukuColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.receipt_long_rounded, size: 18, color: SukuColors.textSecondary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                t.receiptImagePath != null
                                    ? LanguageService.text('receiptAttached')
                                    : LanguageService.text('receiptNotAttached'),
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: SukuColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _sharing ? null : _shareInvoice,
                          icon: _sharing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: SukuColors.navy),
                                )
                              : const Icon(Icons.share_rounded, color: SukuColors.navy),
                          label: Text(
                            LanguageService.text('shareInvoice'),
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: SukuColors.navy),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: SukuColors.navy,
                            side: const BorderSide(color: SukuColors.navy),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _sharing ? null : _shareInvoice,
                          icon: _sharing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.download_rounded),
                          label: Text(
                            LanguageService.text('downloadInvoice'),
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SukuColors.orange,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Delete button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _deleting ? null : _delete,
                      icon: _deleting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: SukuColors.error))
                          : const Icon(Icons.delete_outline_rounded, color: SukuColors.error),
                      label: Text(_deleting ? 'Deleting...' : 'Delete Transaction',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: SukuColors.error)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SukuColors.error,
                        side: const BorderSide(color: SukuColors.error),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: SukuColors.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: SukuColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: SukuColors.textSecondary)),
              const SizedBox(height: 3),
              Text(value,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, fontWeight: FontWeight.w600, color: SukuColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}
