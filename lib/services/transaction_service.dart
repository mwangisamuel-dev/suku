import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'team_service.dart';

class TransactionService {
  static final _supabase = Supabase.instance.client;

  static String? get _userId => _supabase.auth.currentUser?.id;

  // ── Save a transaction ────────────────────────────────────────
  static Future<bool> addTransaction({
    required String title,
    String? vendor,
    required double amount,
    required TransactionType type,
    ExpenseCategory? category,
    bool isMpesa = false,
    String? notes,
  }) async {
    try {
      final canAdd = await TeamService.canAddTransactions();
      if (!canAdd) return false;

      final effectiveUserId = await TeamService.getEffectiveUserId();

      await _supabase.from('transactions').insert({
        'user_id': effectiveUserId,
        'title': title,
        'vendor': vendor,
        'amount': amount,
        'type': type.name,
        'category': category?.name,
        'is_mpesa': isMpesa,
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Load all transactions for current business context ─────────
  static Future<List<Transaction>> getTransactions() async {
    try {
      final effectiveUserId = await TeamService.getEffectiveUserId();
      if (effectiveUserId.isEmpty) return [];

      final res = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', effectiveUserId)
          .order('created_at', ascending: false);

      return (res as List).map((row) => _fromRow(row)).toList();
    } catch (e) {
      return [];
    }
  }

  // ── Delete a transaction ──────────────────────────────────────
  static Future<bool> deleteTransaction(String id) async {
    try {
      final canDelete = await TeamService.canDeleteTransactions();
      if (!canDelete) return false;

      await _supabase.from('transactions').delete().eq('id', id);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Map Supabase row to Transaction model ─────────────────────
  static Transaction _fromRow(Map<String, dynamic> row) {
    return Transaction(
      id: row['id'],
      title: row['title'],
      vendor: row['vendor'],
      amount: (row['amount'] as num).toDouble(),
      type: row['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      category: row['category'] != null
          ? ExpenseCategory.values.firstWhere(
              (e) => e.name == row['category'],
              orElse: () => ExpenseCategory.other)
          : null,
      isMpesa: row['is_mpesa'] ?? false,
      notes: row['notes'],
      date: DateTime.parse(row['created_at']),
    );
  }

  // ── Calculate summary from transactions ───────────────────────
  static MonthlySummary getSummary(List<Transaction> transactions) {
    final now = DateTime.now();
    final monthTxns = transactions
        .where((t) =>
            t.date.month == now.month && t.date.year == now.year)
        .toList();

    double income = monthTxns
        .where((t) => t.type == TransactionType.income)
        .fold(0, (s, t) => s + t.amount);

    double expenses = monthTxns
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (s, t) => s + t.amount);

    Map<ExpenseCategory, double> byCat = {};
    for (var t in monthTxns.where((t) =>
        t.type == TransactionType.expense && t.category != null)) {
      byCat[t.category!] = (byCat[t.category!] ?? 0) + t.amount;
    }

    return MonthlySummary(
      totalIncome: income,
      totalExpenses: expenses,
      byCategory: byCat,
      transactions: monthTxns,
    );
  }
}