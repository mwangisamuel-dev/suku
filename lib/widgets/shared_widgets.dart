import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/suku_theme.dart';
import '../models/models.dart';

// ─── Amount Display ──────────────────────────────────────────────────────────
class SukuAmount extends StatelessWidget {
  final double amount;
  final double fontSize;
  final Color? color;
  final bool showSign;
  final TransactionType? type;

  const SukuAmount({
    super.key,
    required this.amount,
    this.fontSize = 28,
    this.color,
    this.showSign = false,
    this.type,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ??
        (type == TransactionType.income
            ? SukuColors.green
            : type == TransactionType.expense
                ? SukuColors.error
                : SukuColors.textPrimary);
    final formatted = NumberFormat('#,##0', 'en_US').format(amount);
    final sign = showSign ? (type == TransactionType.income ? '+' : '-') : '';

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '${sign}Ksh ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: fontSize * 0.5,
              fontWeight: FontWeight.w600,
              color: c.withOpacity(0.7),
            ),
          ),
          TextSpan(
            text: formatted,
            style: GoogleFonts.plusJakartaSans(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: c,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category Badge ───────────────────────────────────────────────────────────
class CategoryBadge extends StatelessWidget {
  final ExpenseCategory category;
  final bool compact;

  const CategoryBadge({super.key, required this.category, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: category.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, size: compact ? 12 : 14, color: category.color),
          const SizedBox(width: 4),
          Text(
            category.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: category.color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Transaction Tile ─────────────────────────────────────────────────────────
class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;

  const TransactionTile({super.key, required this.transaction, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final timeAgo = _timeAgo(transaction.date);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SukuColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SukuColors.border),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isIncome
                    ? SukuColors.greenSurface
                    : (transaction.category?.color ?? SukuColors.textHint).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(
                  isIncome ? Icons.trending_up_rounded : (transaction.category?.icon ?? Icons.receipt_rounded),
                  color: isIncome ? SukuColors.green : (transaction.category?.color ?? SukuColors.textHint),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Title + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          transaction.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: SukuColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (transaction.isMpesa)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: SukuColors.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'M-Pesa',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: SukuColors.green,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (transaction.category != null) ...[
                        CategoryBadge(category: transaction.category!, compact: true),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        timeAgo,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: SukuColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Amount
            Text(
              '${isIncome ? '+' : '-'} Ksh ${NumberFormat('#,##0').format(transaction.amount)}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isIncome ? SukuColors.green : SukuColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat('d MMM').format(date);
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style:
                GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: SukuColors.textPrimary)),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: SukuColors.green)),
          ),
      ],
    );
  }
}

// ─── Gradient Card ────────────────────────────────────────────────────────────
class GradientCard extends StatelessWidget {
  final Widget child;
  final List<Color> colors;
  final EdgeInsets? padding;
  final double borderRadius;

  const GradientCard({
    super.key,
    required this.child,
    required this.colors,
    this.padding,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: child,
    );
  }
}

// ─── Quick Action Button ──────────────────────────────────────────────────────
class QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Color? bgColor;

  const QuickActionBtn({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? SukuColors.green;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: bgColor ?? c.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.withOpacity(0.2)),
            ),
            child: Icon(icon, color: c, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, fontWeight: FontWeight.w600, color: SukuColors.textSecondary)),
        ],
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final String? change;

  const StatCard({
    super.key,
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    this.change,
  });

  @override
  Widget build(BuildContext context) {
    final hidden = amount < 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              if (change != null && !hidden)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(change!,
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, fontWeight: FontWeight.w500, color: SukuColors.textSecondary)),
          const SizedBox(height: 4),
          hidden
              ? Text('Ksh ••••',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 18, fontWeight: FontWeight.w800, color: SukuColors.textPrimary, letterSpacing: 2))
              : Text('Ksh ${NumberFormat('#,##0').format(amount)}',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 18, fontWeight: FontWeight.w800, color: SukuColors.textPrimary, letterSpacing: -0.5)),
        ],
      ),
    );
  }
}
