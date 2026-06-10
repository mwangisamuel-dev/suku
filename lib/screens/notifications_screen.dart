import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/suku_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _transactionAlerts = true;
  bool _weeklySummary = false;
  bool _smsAlerts = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _transactionAlerts = prefs.getBool('notify_transactions') ?? true;
      _weeklySummary = prefs.getBool('notify_weekly_summary') ?? false;
      _smsAlerts = prefs.getBool('notify_sms_alerts') ?? true;
      _loading = false;
    });
  }

  Future<void> _update(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SukuColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const BackButton(color: SukuColors.textPrimary),
                  const SizedBox(width: 8),
                  Text('Notifications',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: SukuColors.textPrimary,
                          letterSpacing: -0.5)),
                ],
              ),
              const SizedBox(height: 20),
              Text('Choose how Suku keeps you informed about your business activity.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: SukuColors.textSecondary, height: 1.5)),
              const SizedBox(height: 24),
              if (_loading)
                const Center(child: CircularProgressIndicator(color: SukuColors.green))
              else ...[
                _NotificationSwitch(
                  label: 'Transaction alerts',
                  description: 'Receive a notification when a transaction is added or updated.',
                  value: _transactionAlerts,
                  onChanged: (value) {
                    setState(() => _transactionAlerts = value);
                    _update('notify_transactions', value);
                  },
                ),
                const SizedBox(height: 12),
                _NotificationSwitch(
                  label: 'Weekly summary',
                  description: 'Receive a weekly bookkeeping summary by notification.',
                  value: _weeklySummary,
                  onChanged: (value) {
                    setState(() => _weeklySummary = value);
                    _update('notify_weekly_summary', value);
                  },
                ),
                const SizedBox(height: 12),
                _NotificationSwitch(
                  label: 'M-Pesa SMS alerts',
                  description: 'Get notified when M-Pesa import activity is processed.',
                  value: _smsAlerts,
                  onChanged: (value) {
                    setState(() => _smsAlerts = value);
                    _update('notify_sms_alerts', value);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationSwitch extends StatelessWidget {
  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationSwitch(
      {required this.label, required this.description, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SukuColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SukuColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 15, fontWeight: FontWeight.w700, color: SukuColors.textPrimary)),
                const SizedBox(height: 6),
                Text(description,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: SukuColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeThumbColor: SukuColors.green),
        ],
      ),
    );
  }
}
