import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/suku_theme.dart';
import '../services/pin_service.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'welcome_screen.dart';
import '../widgets/keypad.dart';

class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _pin = '';
  String? _error;
  int _attempts = 0;
  bool _biometricsAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final available = await PinService.isBiometricsAvailable();
    if (mounted) setState(() => _biometricsAvailable = available);
    if (available) _tryBiometrics();
  }

  Future<void> _tryBiometrics() async {
    final success = await PinService.authenticateWithBiometrics();
    if (success && mounted) _goToDashboard();
  }

  void _onKey(String digit) {
    if (_pin.length >= 4) return;
    setState(() {
      _error = null;
      _pin += digit;
    });
    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 100), _verifyPin);
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() {
      _error = null;
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _verifyPin() async {
    final correct = await PinService.verifyPin(_pin);
    if (correct) {
      HapticFeedback.lightImpact();
      _goToDashboard();
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _attempts++;
        _pin = '';
        _error =
            _attempts >= 5 ? 'Too many attempts. Please sign in again.' : 'Wrong PIN. ${5 - _attempts} attempts left.';
      });
      if (_attempts >= 5) {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        await AuthService.signOut();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (_) => false,
        );
      }
    }
  }

  void _goToDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SukuColors.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Image.asset('assets/images/icon.png', width: 60, height: 60),
              const SizedBox(height: 32),
              Text(
                'Welcome back 👋',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your PIN to continue',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _pin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? SukuColors.green : Colors.transparent,
                      border: Border.all(
                        color: filled ? SukuColors.green : Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              if (_error != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: SukuColors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_error!,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: SukuColors.error),
                      textAlign: TextAlign.center),
                ),
              ],
              const Spacer(),
              if (_biometricsAvailable) ...[
                GestureDetector(
                  onTap: _tryBiometrics,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: SukuColors.green.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: SukuColors.green.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.fingerprint_rounded, color: SukuColors.green, size: 36),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Use fingerprint',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: SukuColors.green, fontWeight: FontWeight.w500)),
                const SizedBox(height: 20),
              ],
              Keypad(onKey: _onKey, onDelete: _onDelete),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  await AuthService.signOut();
                  await PinService.clearPin();
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (_) => false,
                  );
                },
                child: Text(
                  'Sign in with different account',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: Colors.white.withOpacity(0.4), fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
