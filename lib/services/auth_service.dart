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
      if (res.user != null) {
        await loadProfileFromDatabase();
        return AuthResult.success();
      }
      return AuthResult.error('Verification failed. Please try again.');
    } on AuthException catch (e) {
      return AuthResult.error(e.message);
    } catch (e) {
      return AuthResult.error('Something went wrong. Please try again.');
    }
  }

  static Future<bool> loadProfileFromDatabase() async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final response = await _supabase.from('profiles').select().eq('id', user.id).limit(1);

      if (response.isNotEmpty) {
        final row = Map<String, dynamic>.from(response.first as Map);
        final prefs = await SharedPreferences.getInstance();
        final accountType =
            (row['account_type'] as String?) ?? (row['business_name'] != null ? 'business' : 'personal');

        await prefs.setString('account_type', accountType);
        await prefs.setBool('profile_complete', true);

        if (accountType == 'business') {
          await prefs.setString('business_name', row['business_name']?.toString() ?? 'My Business');
          await prefs.setString('location', row['location']?.toString() ?? 'Nairobi, Kenya');
          await prefs.setString('business_type', row['business_type']?.toString() ?? 'other');
        } else {
          await prefs.setString('personal_name', row['personal_name']?.toString() ?? 'My Account');
          await prefs.setString('personal_location', row['personal_location']?.toString() ?? 'Nairobi, Kenya');
          await prefs.setString('occupation', row['occupation']?.toString() ?? 'other');
        }

        return true;
      }
    } catch (e) {
      // ignore database sync failures and keep current local state
    }
    return false;
  }

  // ── Email ─────────────────────────────────────────────────────
  static Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      final res = await _supabase.auth.signInWithPassword(email: email, password: password);
      if (res.user != null) {
        await loadProfileFromDatabase();
        return AuthResult.success();
      }
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
      final res = await _supabase.auth.signInWithOAuth(OAuthProvider.google);
      if (res.user != null) {
        await loadProfileFromDatabase();
        return AuthResult.success();
      }
      return AuthResult.error('Google sign in failed. Please try again.');
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
          'account_type': 'business',
          'business_name': businessName,
          'location': location,
          'business_type': businessType,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
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
            'account_type': 'business',
            'business_name': businessName,
            'location': businessLocation,
            'business_type': businessType,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
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
      final user = currentUser;
      if (user != null) {
        try {
          await _supabase.from('profiles').upsert({
            'id': user.id,
            'phone': user.phone,
            'account_type': 'personal',
            'personal_name': personalName,
            'personal_location': personalLocation,
            'occupation': occupation,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          // silently fail
        }
      }
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
