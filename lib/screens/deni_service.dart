import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum DeniType { owesMe, iOwe }

enum DeniStatus { pending, partial, paid }

class Deni {
  final String id;
  final String name;
  final String phone;
  final double originalAmount;
  final double paidAmount;
  final DeniType type;
  final DeniStatus status;
  final DateTime dueDate;
  final String? notes;
  final DateTime createdAt;

  Deni({
    required this.id,
    required this.name,
    required this.phone,
    required this.originalAmount,
    required this.paidAmount,
    required this.type,
    required this.status,
    required this.dueDate,
    this.notes,
    required this.createdAt,
  });

  double get remainingAmount => originalAmount - paidAmount;
  bool get isOverdue =>
      status != DeniStatus.paid && dueDate.isBefore(DateTime.now());
  int get daysOverdue => DateTime.now().difference(dueDate).inDays;

  Deni copyWith({double? paidAmount, DeniStatus? status}) => Deni(
        id: id,
        name: name,
        phone: phone,
        originalAmount: originalAmount,
        paidAmount: paidAmount ?? this.paidAmount,
        type: type,
        status: status ?? this.status,
        dueDate: dueDate,
        notes: notes,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'originalAmount': originalAmount,
        'paidAmount': paidAmount,
        'type': type.name,
        'status': status.name,
        'dueDate': dueDate.toIso8601String(),
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Deni.fromJson(Map<String, dynamic> json) => Deni(
        id: json['id'],
        name: json['name'],
        phone: json['phone'],
        originalAmount: (json['originalAmount'] as num).toDouble(),
        paidAmount: (json['paidAmount'] as num).toDouble(),
        type: json['type'] == 'owesMe' ? DeniType.owesMe : DeniType.iOwe,
        status: DeniStatus.values.firstWhere(
            (e) => e.name == json['status'],
            orElse: () => DeniStatus.pending),
        dueDate: DateTime.parse(json['dueDate']),
        notes: json['notes'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class DeniService {
  static const _key = 'deni_records';

  static Future<List<Deni>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = List<Map<String, dynamic>>.from(
        jsonDecode(raw).map((e) => Map<String, dynamic>.from(e)));
    return list.map((e) => Deni.fromJson(e)).toList();
  }

  static Future<void> _saveAll(List<Deni> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  static Future<void> add(Deni deni) async {
    final list = await getAll();
    list.insert(0, deni);
    await _saveAll(list);
  }

  static Future<void> delete(String id) async {
    final list = await getAll();
    list.removeWhere((d) => d.id == id);
    await _saveAll(list);
  }

  static Future<void> markPayment(String id, double amount) async {
    final list = await getAll();
    final idx = list.indexWhere((d) => d.id == id);
    if (idx < 0) return;
    final d = list[idx];
    final newPaid = (d.paidAmount + amount).clamp(0, d.originalAmount);
    final newStatus = newPaid >= d.originalAmount
        ? DeniStatus.paid
        : newPaid > 0
            ? DeniStatus.partial
            : DeniStatus.pending;
    list[idx] = d.copyWith(paidAmount: newPaid, status: newStatus);
    await _saveAll(list);
  }

  static Future<void> markFullyPaid(String id) async {
    final list = await getAll();
    final idx = list.indexWhere((d) => d.id == id);
    if (idx < 0) return;
    final d = list[idx];
    list[idx] =
        d.copyWith(paidAmount: d.originalAmount, status: DeniStatus.paid);
    await _saveAll(list);
  }

  // ── Summary ───────────────────────────────────────────────────
  static double totalOwedToMe(List<Deni> list) => list
      .where((d) =>
          d.type == DeniType.owesMe && d.status != DeniStatus.paid)
      .fold(0, (s, d) => s + d.remainingAmount);

  static double totalIOwe(List<Deni> list) => list
      .where(
          (d) => d.type == DeniType.iOwe && d.status != DeniStatus.paid)
      .fold(0, (s, d) => s + d.remainingAmount);
}