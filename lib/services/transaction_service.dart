import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'storage_service.dart';

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
    String? receiptImagePath,
  }) async {
    try {
      String? storedPath = receiptImagePath;
      if (receiptImagePath != null) {
        final moved = await StorageService.moveReceiptToAppDir(receiptImagePath!);
        if (moved != null) storedPath = moved;
      }

      await _supabase.from('transactions').insert({
        'user_id': _userId,
        'title': title,
        'vendor': vendor,
        'amount': amount,
        'type': type.name,
        'category': category?.name,
        'is_mpesa': isMpesa,
        'notes': notes,
        'receipt_image_path': storedPath,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Load all transactions for current user ────────────────────
  static Future<List<Transaction>> getTransactions() async {
    try {
      final res = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', _userId as Object)
          .order('created_at', ascending: false);

      return (res as List).map((row) => _fromRow(row)).toList();
    } catch (e) {
      return [];
    }
  }

  // ── Delete a transaction ──────────────────────────────────────
  static Future<bool> deleteTransaction(String id) async {
    try {
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
      type: row['type'] == 'income' ? TransactionType.income : TransactionType.expense,
      category: row['category'] != null
          ? ExpenseCategory.values.firstWhere((e) => e.name == row['category'], orElse: () => ExpenseCategory.other)
          : null,
      isMpesa: row['is_mpesa'] ?? false,
      notes: row['notes'],
      receiptImagePath: row['receipt_image_path'],
      date: DateTime.parse(row['created_at']),
    );
  }

  // ── Calculate summary from transactions ───────────────────────
  static MonthlySummary getSummary(List<Transaction> transactions) {
    final now = DateTime.now();
    final monthTxns = transactions.where((t) => t.date.month == now.month && t.date.year == now.year).toList();

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
}
