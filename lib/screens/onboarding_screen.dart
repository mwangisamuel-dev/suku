import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/suku_theme.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingPage {
  final String emoji;
  final String title;
  final String subtitle;
  final String swahili;
  final Color accent;
  final List<Color> bgGradient;

  const _OnboardingPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.swahili,
    required this.accent,
    required this.bgGradient,
  });
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final _pages = const [
    _OnboardingPage(
      emoji: '📸',
      title: 'Snap. Done.\nBooks sorted.',
      subtitle:
          'Point your camera at any receipt and watch it vanish into your books instantly. No typing. No stress.',
      swahili: 'Piga picha ya risiti — Suku inafanya kazi.',
      accent: SukuColors.green,
      bgGradient: [Color(0xFFE8F8EF), Color(0xFFF5F7FA)],
    ),
    _OnboardingPage(
      emoji: '📊',
      title: 'Know your\nnumbers daily.',
      subtitle:
          'See your Money In vs Money Out at a glance. No debits. No credits. Just clear business sense.',
      swahili: 'Pesa inaingia. Pesa inatoka. Rahisi.',
      accent: SukuColors.navy,
      bgGradient: [Color(0xFFECF1F6), Color(0xFFF5F7FA)],
    ),
    _OnboardingPage(
      emoji: '🧾',
      title: 'Tax-ready in\none tap.',
      subtitle:
          'Generate a clean KRA-structured PDF report at the end of every month. Your accountant will love you.',
      swahili: 'Ripoti ya KRA tayari — bila msongo wa mawazo.',
      accent: SukuColors.orange,
      bgGradient: [Color(0xFFFFF0EB), Color(0xFFF5F7FA)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _animController.reset();
      _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut);
      _animController.forward();
    } else {
      _goToSignUp();
    }
  }

  void _goToSignUp() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(isLogin: false),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    return Scaffold(
      backgroundColor: SukuColors.background,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: page.bgGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset('assets/images/icon.png',
                        width: 36, height: 36),
                    GestureDetector(
                      onTap: _goToSignUp,
                      child: Text(
                        'Skip',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: SukuColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) {
                    setState(() => _currentPage = i);
                    _animController.reset();
                    _animController.forward();
                  },
                  itemCount: _pages.length,
                  itemBuilder: (_, i) =>
                      _buildPage(_pages[i]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (i) {
                        final active = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin:
                              const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active
                                ? page.accent
                                : page.accent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: page.accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage == _pages.length - 1
                                  ? 'Create Account'
                                  : 'Continue',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded,
                                size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: page.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                      color: page.accent.withOpacity(0.2), width: 1.5),
                ),
                child: Center(
                  child: Text(page.emoji,
                      style: const TextStyle(fontSize: 42)),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                page.title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: SukuColors.textPrimary,
                  height: 1.15,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                page.subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: SukuColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: page.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: page.accent.withOpacity(0.2)),
                ),
                child: Text(
                  '🇰🇪  ${page.swahili}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: page.accent,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}