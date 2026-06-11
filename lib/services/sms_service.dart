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
  return lower.contains('m-pesa') ||
      lower.contains('mpesa') ||
      lower.contains('fuliza') ||
      lower.contains('airtime') ||
      lower.contains('bundle') ||
      ((lower.contains('confirmed') || lower.contains('transaction')) && lower.contains('ksh'));
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
    final amountRegex = RegExp(r'Ksh\s*([\d,]+(?:\.\d{2})?)', caseSensitive: false);
    final amountMatch = amountRegex.firstMatch(sms);
    if (amountMatch == null) return null;

    final amount = double.tryParse(amountMatch.group(1)!.replaceAll(',', '')) ?? 0;
    if (amount <= 0) return null;

    final lower = sms.toLowerCase();
    final isIncome = lower.contains('received') ||
        lower.contains('you have received') ||
        lower.contains('money in') ||
        lower.contains('deposit');

    String vendor = 'M-Pesa Transaction';
    if (lower.contains('fuliza')) {
      vendor = 'Fuliza';
    } else if (lower.contains('airtime')) {
      vendor = 'Airtime';
    } else if (lower.contains('bundle') || lower.contains('data bundle')) {
      vendor = 'Data Bundle';
    }

    if (isIncome) {
      final fromRegex =
          RegExp(r'from\s+([A-Z][A-Z0-9&\-\s\.]+?)(?:\s+\d{2}|\s+on\b|\s+via\b|\.|$)', caseSensitive: false);
      final match = fromRegex.firstMatch(sms);
      if (match != null) {
        vendor = match.group(1)!.trim();
      }
    } else {
      final toRegex = RegExp(
          r'(?:sent to|paid to|paid for|bought|purchased|withdrawn from|withdrawn|withdrawal from|to)\s+([A-Z][A-Z0-9&\-\s\.]+?)(?:\s+on\b|\s+via\b|\.|$)',
          caseSensitive: false);
      final match = toRegex.firstMatch(sms);
      if (match != null) {
        vendor = match.group(1)!.trim();
      }
    }

    ExpenseCategory cat = ExpenseCategory.other;
    if (lower.contains('kplc') ||
        lower.contains('kenya power') ||
        lower.contains('nairobi water') ||
        lower.contains('water bill') ||
        lower.contains('electricity') ||
        lower.contains('utilities')) {
      cat = ExpenseCategory.utilities;
    } else if (lower.contains('naivas') ||
        lower.contains('quickmart') ||
        lower.contains('carrefour') ||
        lower.contains('wholesale') ||
        lower.contains('supermarket') ||
        lower.contains('shop') ||
        lower.contains('store')) {
      cat = ExpenseCategory.stock;
    } else if (lower.contains('rent') || lower.contains('kodi') || lower.contains('house')) {
      cat = ExpenseCategory.rent;
    } else if (lower.contains('salary') || lower.contains('wages') || lower.contains('mshahara')) {
      cat = ExpenseCategory.salary;
    } else if (lower.contains('petrol') ||
        lower.contains('fuel') ||
        lower.contains('matatu') ||
        lower.contains('uber') ||
        lower.contains('bolt') ||
        lower.contains('transport')) {
      cat = ExpenseCategory.transport;
    }

    return {
      'amount': amount,
      'type': isIncome ? TransactionType.income : TransactionType.expense,
      'vendor': vendor,
      'category': isIncome ? null : cat,
    };
  }

  // ── Read existing M-Pesa SMS from inbox ───────────────────────
  static Future<List<SmsMessage>> getRecentMpesaSms() async {
    try {
      final messages = await _telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: SmsFilter.where(SmsColumn.ADDRESS).equals('MPESA'),
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );
      return messages.where((sms) => _isMpesaSms(sms.body ?? '')).toList();
    } catch (e) {
      return [];
    }
  }
}
