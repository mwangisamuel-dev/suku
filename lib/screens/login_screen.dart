import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/suku_theme.dart';
import '../services/auth_service.dart';
import '../services/pin_service.dart';
import 'otp_screen.dart';
import 'home_screen.dart';
import 'pin_lock_screen.dart';
import 'pin_setup_screen.dart';
import 'business_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _countryCode = '+254';
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  final _countries = [
    {'code': '+254', 'flag': '🇰🇪', 'name': 'Kenya'},
    {'code': '+255', 'flag': '🇹🇿', 'name': 'Tanzania'},
    {'code': '+256', 'flag': '🇺🇬', 'name': 'Uganda'},
    {'code': '+250', 'flag': '🇷🇼', 'name': 'Rwanda'},
    {'code': '+233', 'flag': '🇬🇭', 'name': 'Ghana'},
    {'code': '+234', 'flag': '🇳🇬', 'name': 'Nigeria'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String get _fullPhone =>
      '$_countryCode${_phoneCtrl.text.replaceAll(RegExp(r'^0+'), '')}';

  Future<void> _sendPhoneOtp() async {
    if (_phoneCtrl.text.length < 9) return;
    setState(() { _loading = true; _error = null; });
    final result = await AuthService.sendOtp(_fullPhone);
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.success) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => OtpScreen(phone: _fullPhone)));
    } else {
      setState(() => _error = result.error);
    }
  }

  Future<void> _emailSignIn() async {
    if (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    final result = await AuthService.signInWithEmail(
        _emailCtrl.text.trim(), _passwordCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.success) {
      _navigateAfterLogin();
    } else {
      setState(() => _error = result.error);
    }
  }

  Future<void> _emailSignUp() async {
    if (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    final result = await AuthService.signUpWithEmail(
        _emailCtrl.text.trim(), _passwordCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.success) {
      _navigateAfterLogin();
    } else {
      setState(() => _error = result.error);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() { _loading = true; _error = null; });
    final result = await AuthService.signInWithGoogle();
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.success) {
      _navigateAfterLogin();
    } else {
      setState(() => _error = result.error);
    }
  }

  Future<void> _navigateAfterLogin() async {
    final profileComplete = await AuthService.isProfileComplete();
    final pinSet = await PinService.isPinSet();
    if (!mounted) return;
    if (!profileComplete) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const BusinessSetupScreen()),
          (_) => false);
    } else if (!pinSet) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const PinSetupScreen()),
          (_) => false);
    } else {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SukuColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Image.asset('assets/images/icon.png',
                  width: 52, height: 52),
              const SizedBox(height: 24),
              Text('Karibu Suku! 👋',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: SukuColors.textPrimary,
                      letterSpacing: -1)),
              const SizedBox(height: 6),
              Text('Your pocket accountant for biashara.',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      color: SukuColors.textSecondary)),
              const SizedBox(height: 32),

              // Tab bar
              Container(
                decoration: BoxDecoration(
                  color: SukuColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: SukuColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                          color: SukuColors.navy.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13, fontWeight: FontWeight.w500),
                  labelColor: SukuColors.textPrimary,
                  unselectedLabelColor: SukuColors.textSecondary,
                  tabs: const [
                    Tab(text: '📱 Phone'),
                    Tab(text: '✉️ Email'),
                    Tab(text: '🌐 Google'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Error
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SukuColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: SukuColors.error.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 16, color: SukuColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(_error!,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: SukuColors.error))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Tab content
              SizedBox(
                height: 320,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPhoneTab(),
                    _buildEmailTab(),
                    _buildGoogleTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Phone Number',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: SukuColors.textPrimary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: SukuColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SukuColors.border),
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
                            color: SukuColors.border, width: 1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _countries.firstWhere(
                            (c) => c['code'] == _countryCode)['flag']!,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 4),
                      Text(_countryCode,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 16, color: SukuColors.textHint),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 16, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: '712 345 678',
                    hintStyle: GoogleFonts.plusJakartaSans(
                        color: SukuColors.textHint),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 16),
                  ),
                  onChanged: (_) => setState(() => _error = null),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text('We\'ll send a 6-digit code to verify.',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12, color: SukuColors.textHint)),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _loading ? null : _sendPhoneOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: SukuColors.green,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : Text('Pata Code — Send OTP',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InputField(
          label: 'Email',
          hint: 'your@email.com',
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => setState(() => _error = null),
        ),
        const SizedBox(height: 14),
        _InputField(
          label: 'Password',
          hint: '••••••••',
          controller: _passwordCtrl,
          obscure: _obscurePassword,
          suffix: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              color: SukuColors.textHint,
              size: 20,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          onChanged: (_) => setState(() => _error = null),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: _loading ? null : _emailSignUp,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SukuColors.navy,
                    side: const BorderSide(color: SukuColors.navy),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Sign Up',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _emailSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SukuColors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text('Sign In',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGoogleTab() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SukuColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SukuColors.border),
          ),
          child: Column(
            children: [
              const Icon(Icons.account_circle_rounded,
                  size: 48, color: SukuColors.textHint),
              const SizedBox(height: 12),
              Text('Continue with Google',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Quick and secure sign in',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: SukuColors.textSecondary)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _googleSignIn,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2))
                      : const Icon(Icons.login_rounded),
                  label: Text('Sign in with Google',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SukuColors.navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
                          fontSize: 15, fontWeight: FontWeight.w500)),
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

class _InputField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final Function(String)? onChanged;

  const _InputField({
    required this.label,
    required this.hint,
    required this.controller,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: SukuColors.textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 15, color: SukuColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
                color: SukuColors.textHint),
            filled: true,
            fillColor: SukuColors.surface,
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: SukuColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: SukuColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: SukuColors.green, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}