import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:telephony/telephony.dart';
import '../models/models.dart';
import 'transaction_service.dart';

// Called when SMS arrives even when app is in background
@pragma('vm:entry-point')
void backgroundMessageHandler(SmsMessage message) async {
  final sms = message.body ?? '';
  if (_isMpesaSms(sms)) {
    final parsed = SmsService.parseMpesaSms(sms);
    if (parsed != null) {
      await TransactionService.addTransaction(
        title: parsed['vendor'] as String,
        vendor: parsed['vendor'] as String,
        amount: parsed['amount'] as double,
        type: parsed['type'] as TransactionType,
        category: parsed['category'] as ExpenseCategory?,
        isMpesa: true,
        notes: 'Auto-detected from SMS',
      );
    }
  }
}

bool _isMpesaSms(String sms) {
  final lower = sms.toLowerCase();
  return lower.contains('m-pesa') || lower.contains('mpesa') || (lower.contains('confirmed') && lower.contains('ksh'));
}

class SmsService {
  static final _telephony = Telephony.instance;
  static final _notifications = FlutterLocalNotificationsPlugin();
  static VoidCallback? onNewTransaction;

  // ── Initialize notifications ──────────────────────────────────
  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {},
    );

    // Create notification channel
    const channel = AndroidNotificationChannel(
      'suku_mpesa',
      'M-Pesa Transactions',
      description: 'Auto-detected M-Pesa transactions',
      importance: Importance.high,
    );
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ── Request SMS permission ────────────────────────────────────
  static Future<bool> requestSmsPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  static Future<bool> hasSmsPermission() async {
    return await Permission.sms.isGranted;
  }

  // ── Start listening to incoming SMS ──────────────────────────
  static Future<void> startListening({VoidCallback? onTransaction}) async {
    onNewTransaction = onTransaction;

    final granted = (await _telephony.requestPhoneAndSmsPermissions) ?? false;
    if (!granted) return;

    _telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) async {
        final sms = message.body ?? '';
        if (_isMpesaSms(sms)) {
          await _processMpesaSms(sms);
        }
      },
      onBackgroundMessage: backgroundMessageHandler,
    );
  }

  // ── Process M-Pesa SMS ────────────────────────────────────────
  static Future<void> _processMpesaSms(String sms) async {
    final parsed = parseMpesaSms(sms);
    if (parsed == null) return;

    // Save to Supabase
    final success = await TransactionService.addTransaction(
      title: parsed['vendor'] as String,
      vendor: parsed['vendor'] as String,
      amount: parsed['amount'] as double,
      type: parsed['type'] as TransactionType,
      category: parsed['category'] as ExpenseCategory?,
      isMpesa: true,
      notes: 'Auto-detected from SMS',
    );

    if (success) {
      // Show notification
      await _showNotification(
        title: parsed['type'] == TransactionType.income
            ? '💚 Money In — Ksh ${(parsed['amount'] as double).toStringAsFixed(0)}'
            : '🔴 Money Out — Ksh ${(parsed['amount'] as double).toStringAsFixed(0)}',
        body: '${parsed['vendor']} • Auto-saved to Suku',
      );

      // Refresh dashboard if app is open
      onNewTransaction?.call();
    }
  }

  // ── Show local notification ───────────────────────────────────
  static Future<void> _showNotification({required String title, required String body}) async {
    const androidDetails = AndroidNotificationDetails(
      'suku_mpesa',
      'M-Pesa Transactions',
      channelDescription: 'Auto-detected M-Pesa transactions',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF00A859),
    );
    const details = NotificationDetails(android: androidDetails);
    // Use a more stable ID based on timestamp hash
    final notificationId = title.hashCode.abs() % 100000;
    await _notifications.show(notificationId, title, body, details);
  }

  // ── Parse M-Pesa SMS into transaction data ────────────────────
  static Map<String, dynamic>? parseMpesaSms(String sms) {
    if (!_isMpesaSms(sms)) return null;

    // Amount — find first Ksh amount
    final amountRegex = RegExp(r'Ksh([\d,]+(?:\.\d{2})?)');
    final amountMatch = amountRegex.firstMatch(sms);
    if (amountMatch == null) return null;

    final amount = double.tryParse(amountMatch.group(1)!.replaceAll(',', '')) ?? 0;
    if (amount <= 0) return null;

    // Type
    final isIncome = sms.toLowerCase().contains('received') || sms.toLowerCase().contains('you have received');

    // Vendor
    String vendor = _extractVendor(sms, isIncome);

    // Category
    final cat = _detectCategory(sms);

    return {
      'amount': amount,
      'type': isIncome ? TransactionType.income : TransactionType.expense,
      'vendor': vendor,
      'category': isIncome ? null : cat,
    };
  }

  // ── Extract vendor name from SMS ──────────────────────────
  static String _extractVendor(String sms, bool isIncome) {
    try {
      if (isIncome) {
        final fromRegex = RegExp(r'from\s+([A-Z][A-Z\s]*?)\s+(?:\d|on)', caseSensitive: false);
        final match = fromRegex.firstMatch(sms);
        if (match != null) {
          final vendor = match.group(1)?.trim();
          if (vendor != null && vendor.isNotEmpty && vendor.length < 50) {
            return vendor;
          }
        }
      } else {
        final toRegex = RegExp(r'(?:sent to|paid to)\s+([A-Z][A-Z\s]*?)\s+(?:on|via|\d)', caseSensitive: false);
        final match = toRegex.firstMatch(sms);
        if (match != null) {
          final vendor = match.group(1)?.trim();
          if (vendor != null && vendor.isNotEmpty && vendor.length < 50) {
            return vendor;
          }
        }
      }
    } catch (_) {}
    return 'M-Pesa Transaction';
  }

  // ── Detect transaction category ────────────────────────────
  static ExpenseCategory _detectCategory(String sms) {
    final lower = sms.toLowerCase();

    const categoryKeywords = {
      ExpenseCategory.utilities: [
        'kplc',
        'kenya power',
        'safaricom',
        'water',
        'electricity',
        'internet',
        'airtime',
        'wifi',
        'power',
        'utility'
      ],
      ExpenseCategory.stock: [
        'naivas',
        'quickmart',
        'carrefour',
        'wholesale',
        'supermarket',
        'shop',
        'store',
        'duka',
        'market',
        'hardware',
        'provision'
      ],
      ExpenseCategory.rent: ['rent', 'kodi', 'lease', 'letting', 'landlord'],
      ExpenseCategory.salary: ['salary', 'wages', 'mshahara', 'payroll', 'staff'],
      ExpenseCategory.transport: [
        'petrol',
        'fuel',
        'matatu',
        'uber',
        'bolt',
        'taxi',
        'bus',
        'parking',
        'transport',
        'fare'
      ],
    };

    for (final entry in categoryKeywords.entries) {
      if (entry.value.any((keyword) => lower.contains(keyword))) {
        return entry.key;
      }
    }
    return ExpenseCategory.other;
  }

  // ── Read existing M-Pesa SMS from inbox ───────────────────────
  static Future<List<SmsMessage>> getRecentMpesaSms() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final timestamp = (thirtyDaysAgo.millisecondsSinceEpoch ~/ 1000).toString();

      final messages = await _telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: SmsFilter.where(SmsColumn.ADDRESS).equals('MPESA').and(SmsColumn.DATE).greaterThan(timestamp),
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );
      return messages ?? [];
    } catch (e) {
      return [];
    }
  }
}
