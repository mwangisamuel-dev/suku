import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/suku_theme.dart';
import '../services/auth_service.dart';
import 'otp_screen.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  bool _loading = false;
  String? _error;
  String _countryCode = '+254';
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final _countries = [
    {'code': '+254', 'flag': '🇰🇪', 'name': 'Kenya'},
    {'code': '+255', 'flag': '🇹🇿', 'name': 'Tanzania'},
    {'code': '+256', 'flag': '🇺🇬', 'name': 'Uganda'},
    {'code': '+251', 'flag': '🇪🇹', 'name': 'Ethiopia'},
    {'code': '+250', 'flag': '🇷🇼', 'name': 'Rwanda'},
    {'code': '+233', 'flag': '🇬🇭', 'name': 'Ghana'},
    {'code': '+234', 'flag': '🇳🇬', 'name': 'Nigeria'},
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _animController.dispose();
    super.dispose();
  }

  String get _fullPhone =>
      '$_countryCode${_phoneController.text.replaceAll(RegExp(r'^0+'), '')}';

  bool get _isValid => _phoneController.text.length >= 9;

  Future<void> _sendOtp() async {
    if (!_isValid) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await AuthService.sendOtp(_fullPhone);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(phone: _fullPhone),
        ),
      );
    } else {
      setState(() => _error = result.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SukuColors.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Image.asset('assets/images/icon.png',
                      width: 52, height: 52),
                  const SizedBox(height: 32),
                  Text(
                    'Karibu Suku! 👋',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: SukuColors.textPrimary,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your phone number to get started.\nNo passwords. Just a quick code.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      color: SukuColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Phone Number',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: SukuColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: SukuColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _error != null
                            ? SukuColors.error
                            : SukuColors.border,
                        width: _error != null ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _showCountryPicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(
                                    color: SukuColors.border, width: 1),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _countries.firstWhere((c) =>
                                      c['code'] == _countryCode)['flag']!,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _countryCode,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: SukuColors.textPrimary,
                                  ),
                                ),
                                const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 16,
                                    color: SukuColors.textHint),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: SukuColors.textPrimary,
                              letterSpacing: 1,
                            ),
                            decoration: InputDecoration(
                              hintText: '712 345 678',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                color: SukuColors.textHint,
                                letterSpacing: 1,
                              ),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 16),
                            ),
                            onChanged: (_) =>
                                setState(() => _error = null),
                            onSubmitted: (_) => _sendOtp(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 14, color: SukuColors.error),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _error!,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: SukuColors.error),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'We\'ll send a 6-digit code to verify your number.',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: SukuColors.textHint,
                        height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (_isValid && !_loading) ? _sendOtp : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SukuColors.green,
                        disabledBackgroundColor: SukuColors.border,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              'Pata Code — Send OTP',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _TrustBadge(
                          icon: Icons.lock_rounded, label: 'Secure'),
                      const SizedBox(width: 20),
                      _TrustBadge(
                          icon: Icons.verified_rounded,
                          label: 'No spam'),
                      const SizedBox(width: 20),
                      _TrustBadge(
                          icon: Icons.flash_on_rounded,
                          label: 'Instant'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: SukuColors.surface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: SukuColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Text('Select Country',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ..._countries.map((c) => ListTile(
                  leading: Text(c['flag']!,
                      style: const TextStyle(fontSize: 24)),
                  title: Text(c['name']!,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                  trailing: Text(c['code']!,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: SukuColors.textSecondary)),
                  selected: _countryCode == c['code'],
                  selectedTileColor: SukuColors.greenSurface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    setState(() => _countryCode = c['code']!);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: SukuColors.green),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: SukuColors.textSecondary,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}