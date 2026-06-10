import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/suku_theme.dart';

class MpesaSettingsScreen extends StatefulWidget {
  const MpesaSettingsScreen({super.key});

  @override
  State<MpesaSettingsScreen> createState() => _MpesaSettingsScreenState();
}

class _MpesaSettingsScreenState extends State<MpesaSettingsScreen> {
  bool _autoImport = false;
  bool _notifyOnImport = true;
  bool _showMpesaQuickAction = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoImport = prefs.getBool('mpesa_auto_import') ?? false;
      _notifyOnImport = prefs.getBool('mpesa_notify_import') ?? true;
      _showMpesaQuickAction = prefs.getBool('mpesa_show_quick_action') ?? true;
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
                  Text('M-Pesa Settings',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: SukuColors.textPrimary,
                          letterSpacing: -0.5)),
                ],
              ),
              const SizedBox(height: 20),
              Text('Control how Suku imports and notifies you about M-Pesa activity.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: SukuColors.textSecondary, height: 1.5)),
              const SizedBox(height: 24),
              if (_loading)
                const Center(child: CircularProgressIndicator(color: SukuColors.green))
              else ...[
                _SettingSwitch(
                  label: 'Auto import M-Pesa SMS',
                  subtitle: 'Detect and save MPESA transactions automatically.',
                  value: _autoImport,
                  onChanged: (value) {
                    setState(() => _autoImport = value);
                    _update('mpesa_auto_import', value);
                  },
                ),
                const SizedBox(height: 12),
                _SettingSwitch(
                  label: 'Notify on M-Pesa import',
                  subtitle: 'Receive a notification when a new M-Pesa transaction is added.',
                  value: _notifyOnImport,
                  onChanged: (value) {
                    setState(() => _notifyOnImport = value);
                    _update('mpesa_notify_import', value);
                  },
                ),
                const SizedBox(height: 12),
                _SettingSwitch(
                  label: 'Show M-Pesa quick action',
                  subtitle: 'Display the M-Pesa shortcut on the home dashboard.',
                  value: _showMpesaQuickAction,
                  onChanged: (value) {
                    setState(() => _showMpesaQuickAction = value);
                    _update('mpesa_show_quick_action', value);
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

class _SettingSwitch extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingSwitch({required this.label, required this.subtitle, required this.value, required this.onChanged});

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
                Text(subtitle,
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
