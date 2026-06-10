import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/language_service.dart';
import '../theme/suku_theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.language,
      builder: (context, language, _) {
        final supportEmail = LanguageService.text('supportEmail');
        final phoneSupport = LanguageService.text('phoneSupport');

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
                      Text(LanguageService.text('helpSupportTitle'),
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: SukuColors.textPrimary,
                              letterSpacing: -0.5)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(LanguageService.text('helpSupportInfo'),
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: SukuColors.textSecondary, height: 1.5)),
                  const SizedBox(height: 24),
                  _InfoCard(
                    title: LanguageService.text('emailLabel'),
                    content: supportEmail,
                    icon: Icons.email_rounded,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: supportEmail));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(LanguageService.text('copySuccess')),
                        duration: const Duration(seconds: 2),
                      ));
                    },
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    title: LanguageService.text('phoneLabel'),
                    content: phoneSupport,
                    icon: Icons.phone_rounded,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: phoneSupport));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(LanguageService.text('copySuccess')),
                        duration: const Duration(seconds: 2),
                      ));
                    },
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    title: LanguageService.text('helpTipsLabel'),
                    content: LanguageService.text('helpTips'),
                    icon: Icons.lightbulb_rounded,
                  ),
                  const Spacer(),
                  Text(LanguageService.text('helpSupportFooter'),
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: SukuColors.textSecondary, height: 1.5)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final VoidCallback? onTap;

  const _InfoCard({required this.title, required this.content, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SukuColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SukuColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
                BoxDecoration(color: SukuColors.green.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: SukuColors.green, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 15, fontWeight: FontWeight.w700, color: SukuColors.textPrimary)),
                const SizedBox(height: 6),
                Text(content,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: SukuColors.textSecondary, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}
