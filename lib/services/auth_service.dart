import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final _supabase = Supabase.instance.client;

  static User? get currentUser => _supabase.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  static Future<AuthResult> sendOtp(String phone) async {
    try {
      await _supabase.auth.signInWithOtp(phone: phone);
      return AuthResult.success();
    } on AuthException catch (e) {
      return AuthResult.error(e.message);
    } catch (e) {
      return AuthResult.error('Something went wrong. Please try again.');
    }
  }

  static Future<AuthResult> verifyOtp(String phone, String token) async {
    try {
      final res = await _supabase.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );
      if (res.user != null) {
        return AuthResult.success();
      }
      return AuthResult.error('Verification failed. Please try again.');
    } on AuthException catch (e) {
      return AuthResult.error(e.message);
    } catch (e) {
      return AuthResult.error('Something went wrong. Please try again.');
    }
  }

  static Future<void> saveBusinessProfile({
    required String businessName,
    required String location,
    required String businessType,
  }) async {
    final user = currentUser;
    if (user != null) {
      try {
        await _supabase.from('profiles').upsert({
          'id': user.id,
          'phone': user.phone,
          'business_name': businessName,
          'location': location,
          'business_type': businessType,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        // silently fail — local cache still works
      }
    }
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
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      // continue even if signout fails
    }
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