import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/suku_theme.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _goToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  void _goToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => const LoginScreen(isLogin: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: SukuColors.navy,
      body: Stack(
        children: [
          // Background decorations
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  SukuColors.green.withOpacity(0.25),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  SukuColors.navyLight,
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      // Logo
                      Image.asset('assets/images/icon.png',
                          width: 64, height: 64),
                      const SizedBox(height: 40),

                      // Headline
                      Text(
                        'Hesabu\nbila stress.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                          letterSpacing: -1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Smart bookkeeping for your biashara.\nSnap receipts. Track M-Pesa. Stay tax-ready.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.6),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Trust badges
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _Badge(label: '🔒 Secure'),
                          _Badge(label: '📱 M-Pesa ready'),
                          _Badge(label: '🧾 KRA reports'),
                          _Badge(label: '🇰🇪 Built for Kenya'),
                        ],
                      ),

                      const Spacer(),

                      // Illustration area
                      Center(
                        child: Container(
                          width: size.width * 0.7,
                          height: 180,
                          decoration: BoxDecoration(
                            color: SukuColors.navyLight,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  _MiniCard(
                                      label: 'Money In',
                                      value: 'Ksh 37,300',
                                      color: SukuColors.green),
                                  const SizedBox(width: 12),
                                  _MiniCard(
                                      label: 'Money Out',
                                      value: 'Ksh 14,650',
                                      color: SukuColors.orange),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color:
                                      SukuColors.green.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '✓ Net Profit: Ksh 22,650',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: SukuColors.greenLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // CTA Buttons
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _goToSignUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SukuColors.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            'Get Started — It\'s Free',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: _goToLogin,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.3)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            'I already have an account',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color)),
        ],
      ),
    );
  }
}