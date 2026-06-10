import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class PinService {
  static const _storage = FlutterSecureStorage();
  static final _localAuth = LocalAuthentication();
  static const _pinKey = 'suku_pin';
  static const _pinSetKey = 'suku_pin_set';

  // ── Save PIN ──────────────────────────────────────────────────
  static Future<void> savePin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
    await _storage.write(key: _pinSetKey, value: 'true');
  }

  // ── Check if PIN is set ───────────────────────────────────────
  static Future<bool> isPinSet() async {
    final val = await _storage.read(key: _pinSetKey);
    return val == 'true';
  }

  // ── Verify PIN ────────────────────────────────────────────────
  static Future<bool> verifyPin(String pin) async {
    final saved = await _storage.read(key: _pinKey);
    return saved == pin;
  }

  // ── Clear PIN ─────────────────────────────────────────────────
  static Future<void> clearPin() async {
    await _storage.delete(key: _pinKey);
    await _storage.delete(key: _pinSetKey);
  }

  // ── Check if biometrics available ─────────────────────────────
  static Future<bool> isBiometricsAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return canCheck && isSupported && availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ── Authenticate with biometrics ──────────────────────────────
  static Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Use fingerprint to open Suku',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }
}
