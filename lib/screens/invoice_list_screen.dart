import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';
import '../services/language_service.dart';
import '../services/pdf_service.dart';
import '../services/transaction_service.dart';
import '../theme/suku_theme.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  bool _loading = true;
  bool _sharing = false;
  List<Transaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final transactions = await TransactionService.getTransactions();
    if (!mounted) return;
    setState(() {
      _transactions = transactions;
      _loading = false;
    });
  }

  Future<void> _shareInvoice(Transaction transaction) async {
    setState(() => _sharing = true);
    try {
      final file = await PdfService.generateInvoice(transaction: transaction);
      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)], subject: 'Suku Invoice - ${transaction.title}');
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

  Future<void> _downloadInvoice(Transaction transaction) async {
    setState(() => _sharing = true);
    try {
      final file = await PdfService.generateInvoice(transaction: transaction);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${LanguageService.text('invoiceSavedTo')} ${file.path}',
            style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: SukuColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(LanguageService.text('invoiceSaveError'), style: GoogleFonts.plusJakartaSans(color: Colors.white)),
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
    return Scaffold(
      backgroundColor: SukuColors.background,
      appBar: AppBar(
        title: Text(LanguageService.text('invoiceListTitle'),
            style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: SukuColors.textPrimary),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: SukuColors.green))
          : _transactions.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(LanguageService.text('invoiceEmpty'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(fontSize: 16, color: SukuColors.textSecondary)),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _transactions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final transaction = _transactions[index];
                    final isIncome = transaction.type == TransactionType.income;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: SukuColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: SukuColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: isIncome ? SukuColors.greenSurface : SukuColors.error.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  isIncome ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                  color: isIncome ? SukuColors.green : SukuColors.error,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(transaction.title,
                                        style: GoogleFonts.plusJakartaSans(
                                            fontSize: 15, fontWeight: FontWeight.w700, color: SukuColors.textPrimary)),
                                    const SizedBox(height: 4),
                                    Text(DateFormat('d MMM yyyy').format(transaction.date),
                                        style:
                                            GoogleFonts.plusJakartaSans(fontSize: 12, color: SukuColors.textSecondary)),
                                    if (transaction.category != null)
                                      Text(transaction.category!.label,
                                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: SukuColors.textHint)),
                                  ],
                                ),
                              ),
                              Text(
                                '${isIncome ? '+' : '-'} Ksh ${NumberFormat('#,##0').format(transaction.amount)}',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isIncome ? SukuColors.green : SukuColors.error),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _sharing ? null : () => _shareInvoice(transaction),
                                  icon: _sharing
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(color: SukuColors.navy, strokeWidth: 2),
                                        )
                                      : const Icon(Icons.share_rounded, size: 18),
                                  label: Text(LanguageService.text('invoiceShareButton'),
                                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: SukuColors.navy,
                                    side: const BorderSide(color: SukuColors.navy),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _sharing ? null : () => _downloadInvoice(transaction),
                                  icon: _sharing
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Icon(Icons.download_rounded, size: 18),
                                  label: Text(LanguageService.text('invoiceDownloadButton'),
                                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
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
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
