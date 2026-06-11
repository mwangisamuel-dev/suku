import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/suku_theme.dart';
import '../services/auth_service.dart';
import '../services/pin_service.dart';
import 'welcome_screen.dart';
import 'pin_lock_screen.dart';
import 'pin_setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _taglineController;
  late AnimationController _bgController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _taglineOpacity;
  late Animation<double> _bgExpand;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _bgController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _bgExpand = CurvedAnimation(parent: _bgController, curve: Curves.easeOut);
    _logoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _logoScale =
        Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _logoController, curve: Curves.elasticOut));
    _logoOpacity = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _logoController, curve: const Interval(0, 0.4)));
    _textController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _textOpacity =
        Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));
    _taglineController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _taglineOpacity = Tween<double>(begin: 0, end: 1).animate(_taglineController);
    _runAnimations();
  }

  Future<void> _runAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _bgController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _taglineController.forward();
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    Widget nextScreen;
    if (AuthService.isLoggedIn) {
      await AuthService.loadProfileFromDatabase();
      final pinSet = await PinService.isPinSet();
      nextScreen = pinSet ? const PinLockScreen() : const PinSetupScreen();
    } else {
      nextScreen = const WelcomeScreen();
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => nextScreen,
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _taglineController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: SukuColors.navy,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgExpand,
            builder: (_, __) => Center(
              child: Container(
                width: size.width * 2 * _bgExpand.value,
                height: size.width * 2 * _bgExpand.value,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    SukuColors.navyLight,
                    SukuColors.navy,
                  ]),
                ),
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -80,
            child: AnimatedBuilder(
              animation: _bgExpand,
              builder: (_, __) => Opacity(
                opacity: _bgExpand.value * 0.4,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [SukuColors.green.withOpacity(0.6), Colors.transparent]),
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (_, __) => Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Image.asset('assets/images/icon.png', width: 110, height: 110),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AnimatedBuilder(
                  animation: _textController,
                  builder: (_, __) => FadeTransition(
                    opacity: _textOpacity,
                    child: SlideTransition(
                      position: _textSlide,
                      child: Text(
                        'SUKU',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 6,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedBuilder(
                  animation: _taglineController,
                  builder: (_, __) => Opacity(
                    opacity: _taglineOpacity.value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        border: Border.all(color: SukuColors.green.withOpacity(0.4)),
                        borderRadius: BorderRadius.circular(20),
                        color: SukuColors.green.withOpacity(0.1),
                      ),
                      child: Text(
                        'Your pocket accountant.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: SukuColors.green,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _taglineController,
              builder: (_, __) => Opacity(
                opacity: _taglineOpacity.value,
                child: Text(
                  'Biashara safi. Hesabu bila stress.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.35),
                    letterSpacing: 0.5,
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
