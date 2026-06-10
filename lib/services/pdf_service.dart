import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class PdfService {
  // ── Generate and return PDF file ──────────────────────────────
  static Future<File> generateReport({
    required List<Transaction> transactions,
    required MonthlySummary summary,
    required DateTime month,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final businessName =
        prefs.getString('business_name') ?? 'My Business';
    final location = prefs.getString('location') ?? 'Kenya';
    final businessType =
        prefs.getString('business_type') ?? 'Business';

    final pdf = pw.Document();
    final monthLabel = DateFormat('MMMM yyyy').format(month);
    final font = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();
    final fmt = NumberFormat('#,##0', 'en_US');

    // Filter to this month
    final monthTxns = transactions.where((t) =>
        t.date.month == month.month &&
        t.date.year == month.year).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(
            businessName, location, monthLabel, fontBold, font),
        footer: (context) => _buildFooter(context, font),
        build: (context) => [
          pw.SizedBox(height: 20),

          // Summary boxes
          _buildSummaryRow(summary, fmt, fontBold, font),
          pw.SizedBox(height: 24),

          // Category breakdown
          if (summary.byCategory.isNotEmpty) ...[
            _sectionTitle('Expense Breakdown', fontBold),
            pw.SizedBox(height: 10),
            _buildCategoryTable(summary, fmt, fontBold, font),
            pw.SizedBox(height: 24),
          ],

          // Transactions table
          _sectionTitle(
              'All Transactions — $monthLabel', fontBold),
          pw.SizedBox(height: 10),
          _buildTransactionsTable(
              monthTxns, fmt, fontBold, font),
          pw.SizedBox(height: 24),

          // KRA summary
          _sectionTitle('KRA Tax Summary', fontBold),
          pw.SizedBox(height: 10),
          _buildKraSummary(summary, fmt, fontBold, font),
        ],
      ),
    );

    // Save to temp file
    final dir = await getTemporaryDirectory();
    final filename =
        'Suku_Report_${DateFormat('MMM_yyyy').format(month)}.pdf';
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // ── Header ────────────────────────────────────────────────────
  static pw.Widget _buildHeader(
    String businessName,
    String location,
    String month,
    pw.Font bold,
    pw.Font regular,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            bottom: pw.BorderSide(
                color: PdfColor.fromInt(0xFF00A859), width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('SUKU',
                  style: pw.TextStyle(
                      font: bold,
                      fontSize: 22,
                      color: PdfColor.fromInt(0xFF102A43),
                      letterSpacing: 3)),
              pw.Text('Your Pocket Accountant',
                  style: pw.TextStyle(
                      font: regular,
                      fontSize: 10,
                      color: PdfColor.fromInt(0xFF5A7184))),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(businessName,
                  style: pw.TextStyle(
                      font: bold,
                      fontSize: 14,
                      color: PdfColor.fromInt(0xFF0F1923))),
              pw.Text(location,
                  style: pw.TextStyle(
                      font: regular,
                      fontSize: 10,
                      color: PdfColor.fromInt(0xFF5A7184))),
              pw.Text('Financial Report — $month',
                  style: pw.TextStyle(
                      font: regular,
                      fontSize: 10,
                      color: PdfColor.fromInt(0xFF5A7184))),
            ],
          ),
        ],
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────
  static pw.Widget _buildFooter(
      pw.Context context, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            top: pw.BorderSide(
                color: PdfColor.fromInt(0xFFE2E8F0))),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
              'Generated by Suku on ${DateFormat('d MMM yyyy').format(DateTime.now())}',
              style: pw.TextStyle(
                  font: font,
                  fontSize: 8,
                  color: PdfColor.fromInt(0xFF9BAAB8))),
          pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(
                  font: font,
                  fontSize: 8,
                  color: PdfColor.fromInt(0xFF9BAAB8))),
        ],
      ),
    );
  }

  // ── Summary row ───────────────────────────────────────────────
  static pw.Widget _buildSummaryRow(
    MonthlySummary summary,
    NumberFormat fmt,
    pw.Font bold,
    pw.Font regular,
  ) {
    return pw.Row(
      children: [
        _summaryBox('Total Income', 'Ksh ${fmt.format(summary.totalIncome)}',
            PdfColor.fromInt(0xFF00A859), bold, regular),
        pw.SizedBox(width: 12),
        _summaryBox('Total Expenses',
            'Ksh ${fmt.format(summary.totalExpenses)}',
            PdfColor.fromInt(0xFFEF4444), bold, regular),
        pw.SizedBox(width: 12),
        _summaryBox(
            'Net Profit',
            'Ksh ${fmt.format(summary.netProfit)}',
            summary.netProfit >= 0
                ? PdfColor.fromInt(0xFF00A859)
                : PdfColor.fromInt(0xFFEF4444),
            bold,
            regular),
      ],
    );
  }

  static pw.Widget _summaryBox(String label, String value,
      PdfColor color, pw.Font bold, pw.Font regular) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromInt(0xFFF5F7FA),
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(
              color: PdfColor.fromInt(0xFFE2E8F0)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style: pw.TextStyle(
                    font: regular,
                    fontSize: 9,
                    color: PdfColor.fromInt(0xFF5A7184))),
            pw.SizedBox(height: 4),
            pw.Text(value,
                style: pw.TextStyle(
                    font: bold, fontSize: 14, color: color)),
          ],
        ),
      ),
    );
  }

  // ── Section title ─────────────────────────────────────────────
  static pw.Widget _sectionTitle(String title, pw.Font bold) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            bottom: pw.BorderSide(
                color: PdfColor.fromInt(0xFFE2E8F0))),
      ),
      child: pw.Text(title,
          style: pw.TextStyle(
              font: bold,
              fontSize: 13,
              color: PdfColor.fromInt(0xFF102A43))),
    );
  }

  // ── Category table ────────────────────────────────────────────
  static pw.Widget _buildCategoryTable(
    MonthlySummary summary,
    NumberFormat fmt,
    pw.Font bold,
    pw.Font regular,
  ) {
    final sorted = summary.byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF0F4F8)),
          children: [
            _tableHeader('Category', bold),
            _tableHeader('Amount', bold),
            _tableHeader('%', bold),
          ],
        ),
        ...sorted.map((e) {
          final pct = summary.totalExpenses > 0
              ? (e.value / summary.totalExpenses * 100)
                  .toStringAsFixed(1)
              : '0';
          return pw.TableRow(
            decoration: const pw.BoxDecoration(
                border: pw.Border(
                    bottom: pw.BorderSide(
                        color: PdfColor.fromInt(0xFFE2E8F0),
                        width: 0.5))),
            children: [
              _tableCell(e.key.label, regular),
              _tableCell('Ksh ${fmt.format(e.value)}', regular),
              _tableCell('$pct%', regular),
            ],
          );
        }),
      ],
    );
  }

  // ── Transactions table ────────────────────────────────────────
  static pw.Widget _buildTransactionsTable(
    List<Transaction> transactions,
    NumberFormat fmt,
    pw.Font bold,
    pw.Font regular,
  ) {
    if (transactions.isEmpty) {
      return pw.Text('No transactions this month.',
          style: pw.TextStyle(
              font: regular,
              fontSize: 11,
              color: PdfColor.fromInt(0xFF5A7184)));
    }

    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF0F4F8)),
          children: [
            _tableHeader('Date', bold),
            _tableHeader('Description', bold),
            _tableHeader('Category', bold),
            _tableHeader('Type', bold),
            _tableHeader('Amount', bold),
          ],
        ),
        ...transactions.map((t) {
          final isIncome = t.type == TransactionType.income;
          return pw.TableRow(
            decoration: const pw.BoxDecoration(
                border: pw.Border(
                    bottom: pw.BorderSide(
                        color: PdfColor.fromInt(0xFFE2E8F0),
                        width: 0.5))),
            children: [
              _tableCell(
                  DateFormat('d/M/yy').format(t.date), regular),
              _tableCell(t.title, regular),
              _tableCell(t.category?.label ?? '—', regular),
              _tableCellColored(
                  isIncome ? 'Income' : 'Expense',
                  isIncome
                      ? PdfColor.fromInt(0xFF00A859)
                      : PdfColor.fromInt(0xFFEF4444),
                  regular),
              _tableCellColored(
                  '${isIncome ? '+' : '-'} Ksh ${fmt.format(t.amount)}',
                  isIncome
                      ? PdfColor.fromInt(0xFF00A859)
                      : PdfColor.fromInt(0xFFEF4444),
                  bold),
            ],
          );
        }),
      ],
    );
  }

  // ── KRA Summary ───────────────────────────────────────────────
  static pw.Widget _buildKraSummary(
    MonthlySummary summary,
    NumberFormat fmt,
    pw.Font bold,
    pw.Font regular,
  ) {
    final vat = summary.totalIncome * 0.16;
    final taxableIncome =
        summary.netProfit > 0 ? summary.netProfit : 0.0;
    final estimatedTax = taxableIncome * 0.30;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF0F4F8),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
            color: PdfColor.fromInt(0xFFE2E8F0)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
              'This is an estimated tax summary for reference only. Consult a certified accountant for official KRA filing.',
              style: pw.TextStyle(
                  font: regular,
                  fontSize: 8,
                  color: PdfColor.fromInt(0xFF9BAAB8),
                  fontStyle: pw.FontStyle.italic)),
          pw.SizedBox(height: 12),
          _kraRow('Gross Income', 'Ksh ${fmt.format(summary.totalIncome)}', bold, regular),
          _kraRow('Total Expenses', 'Ksh ${fmt.format(summary.totalExpenses)}', bold, regular),
          _kraRow('Net Profit', 'Ksh ${fmt.format(summary.netProfit)}', bold, regular),
          pw.Divider(color: PdfColor.fromInt(0xFFE2E8F0)),
          _kraRow('Estimated VAT (16%)', 'Ksh ${fmt.format(vat)}', bold, regular),
          _kraRow('Estimated Income Tax (30%)', 'Ksh ${fmt.format(estimatedTax)}', bold, regular),
        ],
      ),
    );
  }

  static pw.Widget _kraRow(
      String label, String value, pw.Font bold, pw.Font regular) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  font: regular,
                  fontSize: 10,
                  color: PdfColor.fromInt(0xFF5A7184))),
          pw.Text(value,
              style: pw.TextStyle(
                  font: bold,
                  fontSize: 10,
                  color: PdfColor.fromInt(0xFF0F1923))),
        ],
      ),
    );
  }

  // ── Table helpers ─────────────────────────────────────────────
  static pw.Widget _tableHeader(String text, pw.Font bold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
          horizontal: 8, vertical: 8),
      child: pw.Text(text,
          style: pw.TextStyle(
              font: bold,
              fontSize: 9,
              color: PdfColor.fromInt(0xFF102A43))),
    );
  }

  static pw.Widget _tableCell(String text, pw.Font regular) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
          horizontal: 8, vertical: 7),
      child: pw.Text(text,
          style: pw.TextStyle(
              font: regular,
              fontSize: 9,
              color: PdfColor.fromInt(0xFF0F1923))),
    );
  }

  static pw.Widget _tableCellColored(
      String text, PdfColor color, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
          horizontal: 8, vertical: 7),
      child: pw.Text(text,
          style:
              pw.TextStyle(font: font, fontSize: 9, color: color)),
    );
  }
}