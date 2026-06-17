import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TeamRole { owner, accountant, cashier }

class TeamMember {
  final String id;
  final String email;
  final TeamRole role;
  final String status;
  final DateTime createdAt;

  TeamMember({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    required this.createdAt,
  });

  factory TeamMember.fromRow(Map<String, dynamic> row) {
    return TeamMember(
      id: row['id'],
      email: row['invited_email'],
      role: row['role'] == 'accountant'
          ? TeamRole.accountant
          : TeamRole.cashier,
      status: row['status'],
      createdAt: DateTime.parse(row['created_at']),
    );
  }
}

class TeamService {
  static final _supabase = Supabase.instance.client;

  // ── Invite a team member ──────────────────────────────────────
  static Future<bool> inviteMember({
    required String email,
    required TeamRole role,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      await _supabase.from('team_members').insert({
        'business_owner_id': user.id,
        'invited_email': email.trim().toLowerCase(),
        'role': role == TeamRole.accountant ? 'accountant' : 'cashier',
        'status': 'pending',
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Get all team members for current owner ─────────────────────
  static Future<List<TeamMember>> getTeamMembers() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final res = await _supabase
          .from('team_members')
          .select()
          .eq('business_owner_id', user.id)
          .order('created_at', ascending: false);
      return (res as List)
          .map((row) => TeamMember.fromRow(row))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ── Revoke access ────────────────────────────────────────────
  static Future<bool> revokeAccess(String memberId) async {
    try {
      await _supabase
          .from('team_members')
          .update({'status': 'revoked'})
          .eq('id', memberId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Activate invite — call this when invited user logs in ──────
  // Links their auth.uid() to the pending invite if their email matches
  static Future<void> activatePendingInvites() async {
    final user = _supabase.auth.currentUser;
    if (user == null || user.email == null) return;

    try {
      await _supabase
          .from('team_members')
          .update({
            'invited_user_id': user.id,
            'status': 'active',
          })
          .eq('invited_email', user.email!.toLowerCase())
          .eq('status', 'pending');
    } catch (e) {
      // silently fail
    }
  }

  // ── Check if current user is a team member (not an owner) ──────
  // Returns the business owner's user id and role if so
  static Future<Map<String, dynamic>?> getActiveBusinessContext() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final res = await _supabase
          .from('team_members')
          .select()
          .eq('invited_user_id', user.id)
          .eq('status', 'active')
          .maybeSingle();

      if (res == null) return null;

      return {
        'owner_id': res['business_owner_id'],
        'role': res['role'] == 'accountant'
            ? TeamRole.accountant
            : TeamRole.cashier,
      };
    } catch (e) {
      return null;
    }
  }

  // ── Get the effective user id to query transactions for ────────
  // If logged in as team member, returns owner's id. Otherwise own id.
  static Future<String> getEffectiveUserId() async {
    final context = await getActiveBusinessContext();
    if (context != null) return context['owner_id'] as String;
    return _supabase.auth.currentUser?.id ?? '';
  }

  // ── Get current role ─────────────────────────────────────────
  static Future<TeamRole> getCurrentRole() async {
    final context = await getActiveBusinessContext();
    if (context != null) return context['role'] as TeamRole;
    return TeamRole.owner;
  }

  static Future<bool> canAddTransactions() async {
    final role = await getCurrentRole();
    return role == TeamRole.owner || role == TeamRole.cashier;
  }

  static Future<bool> canDeleteTransactions() async {
    final role = await getCurrentRole();
    return role == TeamRole.owner;
  }

  static Future<bool> canViewReports() async {
    final role = await getCurrentRole();
    return role == TeamRole.owner || role == TeamRole.accountant;
  }
}