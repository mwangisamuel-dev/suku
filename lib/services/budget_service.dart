import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/models.dart';

class BudgetService {
  static const _overallKey = 'budget_overall';
  static const _categoryKey = 'budget_categories';
  static const _goalsKey = 'budget_goals';

  // ── Overall monthly budget ────────────────────────────────────
  static Future<void> saveOverallBudget(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_overallKey, amount);
  }

  static Future<double> getOverallBudget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_overallKey) ?? 0;
  }

  // ── Per category budgets ──────────────────────────────────────
  static Future<void> saveCategoryBudget(
      ExpenseCategory category, double amount) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_categoryKey);
    final map = raw != null
        ? Map<String, double>.from(
            jsonDecode(raw).map((k, v) => MapEntry(k, v.toDouble())))
        : <String, double>{};
    map[category.name] = amount;
    await prefs.setString(_categoryKey, jsonEncode(map));
  }

  static Future<Map<ExpenseCategory, double>>
      getCategoryBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_categoryKey);
    if (raw == null) return {};
    final map = Map<String, dynamic>.from(jsonDecode(raw));
    final result = <ExpenseCategory, double>{};
    for (final entry in map.entries) {
      try {
        final cat = ExpenseCategory.values
            .firstWhere((e) => e.name == entry.key);
        result[cat] = (entry.value as num).toDouble();
      } catch (_) {}
    }
    return result;
  }

  // ── Goals ─────────────────────────────────────────────────────
  static Future<void> saveGoals(List<BudgetGoal> goals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _goalsKey, jsonEncode(goals.map((g) => g.toJson()).toList()));
  }

  static Future<List<BudgetGoal>> getGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_goalsKey);
    if (raw == null) return [];
    final list = List<Map<String, dynamic>>.from(
        jsonDecode(raw).map((e) => Map<String, dynamic>.from(e)));
    return list.map((e) => BudgetGoal.fromJson(e)).toList();
  }

  static Future<void> addGoal(BudgetGoal goal) async {
    final goals = await getGoals();
    goals.add(goal);
    await saveGoals(goals);
  }

  static Future<void> deleteGoal(String id) async {
    final goals = await getGoals();
    goals.removeWhere((g) => g.id == id);
    await saveGoals(goals);
  }

  static Future<void> updateGoalProgress(
      String id, double current) async {
    final goals = await getGoals();
    final idx = goals.indexWhere((g) => g.id == id);
    if (idx >= 0) {
      goals[idx] = goals[idx].copyWith(currentAmount: current);
      await saveGoals(goals);
    }
  }

  // ── Budget health check ───────────────────────────────────────
  static BudgetStatus getStatus(double spent, double budget) {
    if (budget <= 0) return BudgetStatus.none;
    final pct = spent / budget;
    if (pct >= 1.0) return BudgetStatus.exceeded;
    if (pct >= 0.8) return BudgetStatus.warning;
    return BudgetStatus.good;
  }
}

enum BudgetStatus { none, good, warning, exceeded }

class BudgetGoal {
  final String id;
  final String title;
  final String emoji;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;

  BudgetGoal({
    required this.id,
    required this.title,
    required this.emoji,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
  });

  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0, 1) : 0;
  bool get isComplete => currentAmount >= targetAmount;
  int get daysLeft => deadline.difference(DateTime.now()).inDays;

  BudgetGoal copyWith({double? currentAmount}) => BudgetGoal(
        id: id,
        title: title,
        emoji: emoji,
        targetAmount: targetAmount,
        currentAmount: currentAmount ?? this.currentAmount,
        deadline: deadline,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'emoji': emoji,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'deadline': deadline.toIso8601String(),
      };

  factory BudgetGoal.fromJson(Map<String, dynamic> json) => BudgetGoal(
        id: json['id'],
        title: json['title'],
        emoji: json['emoji'],
        targetAmount: (json['targetAmount'] as num).toDouble(),
        currentAmount: (json['currentAmount'] as num).toDouble(),
        deadline: DateTime.parse(json['deadline']),
      );
}