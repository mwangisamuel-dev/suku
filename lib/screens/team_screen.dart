import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/suku_theme.dart';
import '../services/team_service.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  List<TeamMember> _members = [];
  bool _loading = true;
  bool _inviting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final members = await TeamService.getTeamMembers();
    if (!mounted) return;
    setState(() {
      _members = members;
      _loading = false;
    });
  }

  Future<void> _revoke(TeamMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Revoke access?',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700)),
        content: Text(
            '${member.email} will lose access to your business data immediately.',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14, color: SukuColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.plusJakartaSans(
                    color: SukuColors.textSecondary,
                    fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: SukuColors.error,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: Text('Revoke',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await TeamService.revokeAccess(member.id);
      if (success) {
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Access revoked',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            backgroundColor: SukuColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ));
        }
      }
    }
  }

  void _showInviteDialog() {
    final emailCtrl = TextEditingController();
    TeamRole selectedRole = TeamRole.cashier;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: SukuColors.surface,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: SukuColors.border,
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 20),
                Text('Invite Team Member',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                    'They\'ll get access once they sign up with this email.',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: SukuColors.textSecondary)),
                const SizedBox(height: 20),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 15, color: SukuColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Email address',
                    hintText: 'accountant@example.com',
                    labelStyle: GoogleFonts.plusJakartaSans(
                        color: SukuColors.textSecondary),
                    filled: true,
                    fillColor: SukuColors.surfaceAlt,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: SukuColors.border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: SukuColors.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: SukuColors.green, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Role',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: SukuColors.textPrimary)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _RoleCard(
                        title: 'Cashier',
                        desc: 'Can add transactions only',
                        icon: Icons.point_of_sale_rounded,
                        active: selectedRole == TeamRole.cashier,
                        onTap: () => setModal(
                            () => selectedRole = TeamRole.cashier),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _RoleCard(
                        title: 'Accountant',
                        desc: 'Can view & export reports',
                        icon: Icons.calculate_rounded,
                        active: selectedRole == TeamRole.accountant,
                        onTap: () => setModal(
                            () => selectedRole = TeamRole.accountant),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _inviting
                        ? null
                        : () async {
                            if (emailCtrl.text.trim().isEmpty) return;
                            setModal(() => _inviting = true);
                            final success =
                                await TeamService.inviteMember(
                              email: emailCtrl.text,
                              role: selectedRole,
                            );
                            if (!mounted) return;
                            Navigator.pop(context);
                            await _load();
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                              content: Text(
                                  success
                                      ? 'Invite sent!'
                                      : 'Failed to invite. Try again.',
                                  style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                              backgroundColor: success
                                  ? SukuColors.green
                                  : SukuColors.error,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12)),
                              margin: const EdgeInsets.all(16),
                            ));
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SukuColors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Send Invite',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SukuColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Team',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 18, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(color: SukuColors.green))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: SukuColors.greenSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: SukuColors.green.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: SukuColors.green, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Invite an accountant to view reports, or a cashier to log sales. They use their own Suku login.',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: SukuColors.greenDark,
                                height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _showInviteDialog,
                      icon: const Icon(Icons.person_add_rounded,
                          size: 18),
                      label: Text('Invite Team Member',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SukuColors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Your Team (${_members.length})',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: SukuColors.textPrimary)),
                  const SizedBox(height: 12),
                  if (_members.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: SukuColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: SukuColors.border),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.group_off_rounded,
                              size: 40, color: SukuColors.textHint),
                          const SizedBox(height: 12),
                          Text('No team members yet',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: SukuColors.textPrimary)),
                          const SizedBox(height: 4),
                          Text(
                              'Invite your accountant or cashier to collaborate.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: SukuColors.textSecondary)),
                        ],
                      ),
                    )
                  else
                    ..._members.map((member) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: SukuColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: SukuColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: (member.role ==
                                              TeamRole.accountant
                                          ? SukuColors.navy
                                          : SukuColors.orange)
                                      .withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  member.role == TeamRole.accountant
                                      ? Icons.calculate_rounded
                                      : Icons.point_of_sale_rounded,
                                  color: member.role ==
                                          TeamRole.accountant
                                      ? SukuColors.navy
                                      : SukuColors.orange,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(member.email,
                                        style:
                                            GoogleFonts.plusJakartaSans(
                                                fontSize: 14,
                                                fontWeight:
                                                    FontWeight.w600,
                                                color: SukuColors
                                                    .textPrimary),
                                        overflow:
                                            TextOverflow.ellipsis),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets
                                              .symmetric(
                                              horizontal: 6,
                                              vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _statusColor(
                                                    member.status)
                                                .withOpacity(0.12),
                                            borderRadius:
                                                BorderRadius
                                                    .circular(6),
                                          ),
                                          child: Text(
                                              member.status
                                                  .toUpperCase(),
                                              style: GoogleFonts
                                                  .plusJakartaSans(
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight
                                                              .w700,
                                                      color:
                                                          _statusColor(
                                                              member
                                                                  .status))),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                            member.role ==
                                                    TeamRole.accountant
                                                ? 'Accountant'
                                                : 'Cashier',
                                            style: GoogleFonts
                                                .plusJakartaSans(
                                                    fontSize: 11,
                                                    color: SukuColors
                                                        .textSecondary)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (member.status != 'revoked')
                                IconButton(
                                  icon: const Icon(
                                      Icons.person_remove_rounded,
                                      color: SukuColors.error,
                                      size: 20),
                                  onPressed: () => _revoke(member),
                                ),
                            ],
                          ),
                        )),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return SukuColors.green;
      case 'revoked':
        return SukuColors.error;
      default:
        return SukuColors.warning;
    }
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String desc;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.desc,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active
              ? SukuColors.greenSurface
              : SukuColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? SukuColors.green : SukuColors.border,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                size: 20,
                color: active
                    ? SukuColors.green
                    : SukuColors.textSecondary),
            const SizedBox(height: 8),
            Text(title,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: active
                        ? SukuColors.green
                        : SukuColors.textPrimary)),
            const SizedBox(height: 2),
            Text(desc,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: SukuColors.textSecondary,
                    height: 1.3)),
          ],
        ),
      ),
    );
  }
}