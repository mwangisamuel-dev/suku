import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final _supabase = Supabase.instance.client;

  static User? get currentUser => _supabase.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  // ── Phone OTP ─────────────────────────────────────────────────
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
      if (res.user != null) return AuthResult.success();
      return AuthResult.error('Verification failed. Please try again.');
    } on AuthException catch (e) {
      return AuthResult.error(e.message);
    } catch (e) {
      return AuthResult.error('Something went wrong. Please try again.');
    }
  }

  // ── Email ─────────────────────────────────────────────────────
  static Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      final res = await _supabase.auth.signInWithPassword(email: email, password: password);
      if (res.user != null) return AuthResult.success();
      return AuthResult.error('Sign in failed. Please try again.');
    } on AuthException catch (e) {
      return AuthResult.error(e.message);
    } catch (e) {
      return AuthResult.error('Something went wrong. Please try again.');
    }
  }

  static Future<AuthResult> signUpWithEmail(String email, String password) async {
    try {
      final res = await _supabase.auth.signUp(email: email, password: password);
      if (res.user != null) return AuthResult.success();
      return AuthResult.error('Sign up failed. Please try again.');
    } on AuthException catch (e) {
      return AuthResult.error(e.message);
    } catch (e) {
      return AuthResult.error('Something went wrong. Please try again.');
    }
  }

  // ── Google ────────────────────────────────────────────────────
  static Future<AuthResult> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(OAuthProvider.google);
      return AuthResult.success();
    } on AuthException catch (e) {
      return AuthResult.error(e.message);
    } catch (e) {
      return AuthResult.error('Google sign in failed. Please try again.');
    }
  }

  // ── Profile ───────────────────────────────────────────────────
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
        // silently fail
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('business_name', businessName);
    await prefs.setString('location', location);
    await prefs.setString('business_type', businessType);
    await prefs.setBool('profile_complete', true);
  }

  static Future<void> saveProfile({
    required String accountType,
    String? businessName,
    String? businessLocation,
    String? businessType,
    String? personalName,
    String? personalLocation,
    String? occupation,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('account_type', accountType);
    if (accountType == 'business') {
      if (businessName != null) await prefs.setString('business_name', businessName);
      if (businessLocation != null) await prefs.setString('location', businessLocation);
      if (businessType != null) await prefs.setString('business_type', businessType);
      await prefs.setBool('profile_complete', true);
      final user = currentUser;
      if (user != null) {
        try {
          await _supabase.from('profiles').upsert({
            'id': user.id,
            'phone': user.phone,
            'business_name': businessName,
            'location': businessLocation,
            'business_type': businessType,
            'created_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          // silently fail
        }
      }
    } else {
      if (personalName != null) await prefs.setString('personal_name', personalName);
      if (personalLocation != null) await prefs.setString('personal_location', personalLocation);
      if (occupation != null) await prefs.setString('occupation', occupation);
      await prefs.setBool('profile_complete', true);
    }
  }

  static Future<String> getAccountType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('account_type') ?? 'business';
  }

  static Future<String> getPersonalName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('personal_name') ?? '';
  }

  static Future<String> getPersonalLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('personal_location') ?? '';
  }

  static Future<String> getOccupation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('occupation') ?? '';
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
      // continue
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
  factory AuthResult.error(String message) => AuthResult._(success: false, error: message);
}
