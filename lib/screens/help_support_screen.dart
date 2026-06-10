import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/suku_theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

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
                  Text('Help & Support',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: SukuColors.textPrimary,
                          letterSpacing: -0.5)),
                ],
              ),
              const SizedBox(height: 20),
              Text('Need help? Reach out to Suku support or view quick troubleshooting tips.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: SukuColors.textSecondary, height: 1.5)),
              const SizedBox(height: 24),
              const _InfoCard(
                title: 'Support email',
                content: 'support@sukuapp.co.ke',
                icon: Icons.email_rounded,
              ),
              const SizedBox(height: 12),
              const _InfoCard(
                title: 'Phone support',
                content: '+254 700 000 000',
                icon: Icons.phone_rounded,
              ),
              const SizedBox(height: 12),
              const _InfoCard(
                title: 'Quick tips',
                content:
                    'Update your business profile, enable M-Pesa import, and keep your notifications on for the smoothest experience.',
                icon: Icons.lightbulb_rounded,
              ),
              const Spacer(),
              Text('You can also email us anytime with your feedback or questions.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: SukuColors.textSecondary, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;

  const _InfoCard({required this.title, required this.content, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
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
  }
}
