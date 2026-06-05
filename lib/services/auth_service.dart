import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // ── Demo mode — no Supabase needed ──────────────────────────
  // Any phone number works, OTP is always 123456

  static bool get isLoggedIn {
    // We use a simple flag stored in memory for demo
    return _loggedIn;
  }

  static bool _loggedIn = false;

  static Future<AuthResult> sendOtp(String phone) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    return AuthResult.success();
  }

  static Future<AuthResult> verifyOtp(String phone, String token) async {
    await Future.delayed(const Duration(seconds: 1));
    if (token == '123456') {
      _loggedIn = true;
      return AuthResult.success();
    }
    return AuthResult.error('Wrong code. Use 123456 for demo.');
  }

  static Future<void> saveBusinessProfile({
    required String businessName,
    required String location,
    required String businessType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('business_name', businessName);
    await prefs.setString('location', location);
    await prefs.setString('business_type', businessType);
    await prefs.setBool('profile_complete', true);
  }

  static Future<bool> isProfileComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('profile_complete') ?? false;
  }

  static Future<String> getBusinessName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('business_name') ?? 'My Business';
  }

  static Future<void> signOut() async {
    _loggedIn = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

class AuthResult {
  final bool success;
  final String? error;

  AuthResult._({required this.success, this.error});

  factory AuthResult.success() => AuthResult._(success: true);
  factory AuthResult.error(String message) =>
      AuthResult._(success: false, error: message);
}