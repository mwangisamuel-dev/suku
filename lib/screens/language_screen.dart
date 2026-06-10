import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/suku_theme.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _language = 'English';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _language = prefs.getString('app_language') ?? 'English';
      _loading = false;
    });
  }

  Future<void> _saveLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', language);
    if (!mounted) return;
    setState(() => _language = language);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$language selected', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
      backgroundColor: SukuColors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
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
                  Text('Language / Lugha',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: SukuColors.textPrimary,
                          letterSpacing: -0.5)),
                ],
              ),
              const SizedBox(height: 20),
              Text('Pick your preferred app language. This is stored locally for your device.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: SukuColors.textSecondary, height: 1.5)),
              const SizedBox(height: 24),
              if (_loading)
                const Center(child: CircularProgressIndicator(color: SukuColors.green))
              else ...[
                _LanguageItem(
                  label: 'English',
                  value: _language == 'English',
                  onTap: () => _saveLanguage('English'),
                ),
                const SizedBox(height: 12),
                _LanguageItem(
                  label: 'Kiswahili',
                  value: _language == 'Kiswahili',
                  onTap: () => _saveLanguage('Kiswahili'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageItem extends StatelessWidget {
  final String label;
  final bool value;
  final VoidCallback onTap;

  const _LanguageItem({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SukuColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: value ? SukuColors.green : SukuColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 15, fontWeight: FontWeight.w700, color: SukuColors.textPrimary)),
            ),
            if (value)
              const Icon(Icons.check_circle_rounded, color: SukuColors.green)
            else
              const Icon(Icons.circle_outlined, color: SukuColors.textHint),
          ],
        ),
      ),
    );
  }
}
