import 'package:flutter/material.dart';
import '../theme/suku_theme.dart';

enum TransactionType { income, expense }

enum ExpenseCategory {
  stock,
  rent,
  salary,
  transport,
  utilities,
  other,
}

extension ExpenseCategoryExt on ExpenseCategory {
  String get label {
    switch (this) {
      case ExpenseCategory.stock: return 'Stock';
      case ExpenseCategory.rent: return 'Rent';
      case ExpenseCategory.salary: return 'Salary';
      case ExpenseCategory.transport: return 'Transport';
      case ExpenseCategory.utilities: return 'Utilities';
      case ExpenseCategory.other: return 'Other';
    }
  }

  String get swahili {
    switch (this) {
      case ExpenseCategory.stock: return 'Bidhaa';
      case ExpenseCategory.rent: return 'Kodi';
      case ExpenseCategory.salary: return 'Mshahara';
      case ExpenseCategory.transport: return 'Usafiri';
      case ExpenseCategory.utilities: return 'Huduma';
      case ExpenseCategory.other: return 'Nyingine';
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.stock: return SukuColors.catStock;
      case ExpenseCategory.rent: return SukuColors.catRent;
      case ExpenseCategory.salary: return SukuColors.catSalary;
      case ExpenseCategory.transport: return SukuColors.catTransport;
      case ExpenseCategory.utilities: return SukuColors.info;
      case ExpenseCategory.other: return SukuColors.catOther;
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.stock: return Icons.inventory_2_rounded;
      case ExpenseCategory.rent: return Icons.home_rounded;
      case ExpenseCategory.salary: return Icons.people_rounded;
      case ExpenseCategory.transport: return Icons.local_shipping_rounded;
      case ExpenseCategory.utilities: return Icons.bolt_rounded;
      case ExpenseCategory.other: return Icons.more_horiz_rounded;
    }
  }
}

class Transaction {
  final String id;
  final String title;
  final String? vendor;
  final double amount;
  final TransactionType type;
  final ExpenseCategory? category;
  final DateTime date;
  final String? receiptImagePath;
  final String? notes;
  final bool isMpesa;

  Transaction({
    required this.id,
    required this.title,
    this.vendor,
    required this.amount,
    required this.type,
    this.category,
    required this.date,
    this.receiptImagePath,
    this.notes,
    this.isMpesa = false,
  });
}

class MonthlySummary {
  final double totalIncome;
  final double totalExpenses;
  final Map<ExpenseCategory, double> byCategory;
  final List<Transaction> transactions;

  MonthlySummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.byCategory,
    required this.transactions,
  });

  double get netProfit => totalIncome - totalExpenses;
  double get profitMargin => totalIncome > 0 ? (netProfit / totalIncome) * 100 : 0;
}

// Sample data
class SampleData {
  static List<Transaction> get transactions => [
    Transaction(
      id: '1', title: 'Unga Wholesale', vendor: 'Mombasa Millers',
      amount: 4500, type: TransactionType.expense,
      category: ExpenseCategory.stock, date: DateTime.now().subtract(const Duration(hours: 2)),
      isMpesa: true,
    ),
    Transaction(
      id: '2', title: 'Sales - Morning', vendor: null,
      amount: 8200, type: TransactionType.income,
      category: null, date: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    Transaction(
      id: '3', title: 'Shop Rent', vendor: 'Nairobi Properties',
      amount: 12000, type: TransactionType.expense,
      category: ExpenseCategory.rent, date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Transaction(
      id: '4', title: 'Staff Wages', vendor: null,
      amount: 15000, type: TransactionType.expense,
      category: ExpenseCategory.salary, date: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Transaction(
      id: '5', title: 'Sales - Afternoon', vendor: null,
      amount: 6700, type: TransactionType.income,
      category: null, date: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Transaction(
      id: '6', title: 'Matatu Fare', vendor: null,
      amount: 350, type: TransactionType.expense,
      category: ExpenseCategory.transport, date: DateTime.now().subtract(const Duration(days: 3)),
      isMpesa: true,
    ),
    Transaction(
      id: '7', title: 'Kuku Supply', vendor: 'Farm Fresh Ltd',
      amount: 7800, type: TransactionType.expense,
      category: ExpenseCategory.stock, date: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Transaction(
      id: '8', title: 'KPLC Token', vendor: 'Kenya Power',
      amount: 1200, type: TransactionType.expense,
      category: ExpenseCategory.utilities, date: DateTime.now().subtract(const Duration(days: 4)),
      isMpesa: true,
    ),
    Transaction(
      id: '9', title: 'Weekend Sales', vendor: null,
      amount: 22400, type: TransactionType.income,
      category: null, date: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Transaction(
      id: '10', title: 'Packaging Materials', vendor: 'Eastleigh Supplies',
      amount: 2100, type: TransactionType.expense,
      category: ExpenseCategory.stock, date: DateTime.now().subtract(const Duration(days: 6)),
    ),
  ];

  static MonthlySummary get monthlySummary {
    final txns = transactions;
    double income = txns.where((t) => t.type == TransactionType.income)
        .fold(0, (s, t) => s + t.amount);
    double expenses = txns.where((t) => t.type == TransactionType.expense)
        .fold(0, (s, t) => s + t.amount);

    Map<ExpenseCategory, double> byCat = {};
    for (var t in txns.where((t) => t.type == TransactionType.expense && t.category != null)) {
      byCat[t.category!] = (byCat[t.category!] ?? 0) + t.amount;
    }

    return MonthlySummary(
      totalIncome: income,
      totalExpenses: expenses,
      byCategory: byCat,
      transactions: txns,
    );
  }

  // Weekly chart data [Mon–Sun]
  static List<double> get weeklyIncome => [8200, 6700, 0, 22400, 11000, 9800, 5600];
  static List<double> get weeklyExpenses => [4500, 15350, 12000, 7800, 2100, 1200, 350];
}
