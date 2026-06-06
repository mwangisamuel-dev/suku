import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/suku_theme.dart';
import '../services/pin_service.dart';
import 'home_screen.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _confirming = false;
  String? _error;

  void _onKey(String digit) {
    setState(() {
      _error = null;
      if (!_confirming) {
        if (_pin.length < 4) {
          _pin += digit;
          if (_pin.length == 4) {
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) setState(() => _confirming = true);
            });
          }
        }
      } else {
        if (_confirmPin.length < 4) {
          _confirmPin += digit;
          if (_confirmPin.length == 4) {
            _validatePins();
          }
        }
      }
    });
  }

  void _onDelete() {
    setState(() {
      _error = null;
      if (!_confirming) {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      }
    });
  }

  Future<void> _validatePins() async {
    if (_pin == _confirmPin) {
      HapticFeedback.lightImpact();
      await PinService.savePin(_pin);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _error = 'PINs do not match. Try again.';
        _confirmPin = '';
        _pin = '';
        _confirming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPin = _confirming ? _confirmPin : _pin;

    return Scaffold(
      backgroundColor: SukuColors.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Image.asset('assets/images/icon.png', width: 60, height: 60),
              const SizedBox(height: 32),
              Text(
                _confirming ? 'Confirm your PIN' : 'Create a PIN',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _confirming
                    ? 'Enter your PIN again to confirm'
                    : 'This PIN protects your Suku account',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < currentPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? SukuColors.green
                          : Colors.white.withOpacity(0.2),
                      border: Border.all(
                        color: filled
                            ? SukuColors.green
                            : Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),

              // Error
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: SukuColors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _error!,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: SukuColors.error),
                  ),
                ),
              ],

              const Spacer(),

              // Keypad
              _Keypad(onKey: _onKey, onDelete: _onDelete),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}