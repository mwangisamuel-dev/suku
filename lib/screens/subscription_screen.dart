import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/language_service.dart';
import '../theme/suku_theme.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String _selectedPlan = 'Free';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedPlan = prefs.getString('subscription_plan') ?? 'Free';
    });
  }

  Future<void> _savePlan(String plan) async {
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subscription_plan', plan);
    if (!mounted) return;
    setState(() {
      _selectedPlan = plan;
      _saving = false;
    });

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(LanguageService.text('subscriptionTitle'),
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text(LanguageService.planSelectedMessage(plan),
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: SukuColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LanguageService.text('okButton'),
                style: GoogleFonts.plusJakartaSans(color: SukuColors.green, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPlanSelection(String plan) async {
    if (plan == 'Free') {
      await _savePlan(plan);
      return;
    }

    String selectedMethod = 'mpesa';
    final phoneController = TextEditingController();
    final cardNumberController = TextEditingController();
    final expiryController = TextEditingController();
    final cvcController = TextEditingController();
    final nameController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(LanguageService.text('subscriptionPaymentTitle'),
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(LanguageService.text('choosePaymentMethod'),
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: SukuColors.textSecondary)),
                    const SizedBox(height: 16),
                    RadioListTile<String>(
                      value: 'mpesa',
                      groupValue: selectedMethod,
                      title: Text(LanguageService.text('mpesaPaymentOption')),
                      onChanged: (value) => setState(() => selectedMethod = value ?? 'mpesa'),
                    ),
                    RadioListTile<String>(
                      value: 'airtel',
                      groupValue: selectedMethod,
                      title: Text(LanguageService.text('airtelPaymentOption')),
                      onChanged: (value) => setState(() => selectedMethod = value ?? 'airtel'),
                    ),
                    RadioListTile<String>(
                      value: 'mtn',
                      groupValue: selectedMethod,
                      title: Text(LanguageService.text('mtnPaymentOption')),
                      onChanged: (value) => setState(() => selectedMethod = value ?? 'mtn'),
                    ),
                    RadioListTile<String>(
                      value: 'card',
                      groupValue: selectedMethod,
                      title: Text(LanguageService.text('cardPaymentOption')),
                      onChanged: (value) => setState(() => selectedMethod = value ?? 'card'),
                    ),
                    const SizedBox(height: 12),
                    if (selectedMethod != 'card') ...[
                      TextField(
                        controller: phoneController,
                        decoration: InputDecoration(
                          labelText: LanguageService.text('enterPhoneNumber'),
                          hintText: LanguageService.text('phoneNumberHint'),
                          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ] else ...[
                      TextField(
                        controller: cardNumberController,
                        decoration: InputDecoration(
                          labelText: LanguageService.text('cardNumber'),
                          hintText: LanguageService.text('cardNumberHint'),
                          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: expiryController,
                              decoration: InputDecoration(
                                labelText: LanguageService.text('cardExpiry'),
                                hintText: LanguageService.text('cardExpiryHint'),
                                border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
                              ),
                              keyboardType: TextInputType.datetime,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: cvcController,
                              decoration: InputDecoration(
                                labelText: LanguageService.text('cardCvc'),
                                hintText: LanguageService.text('cardCvcHint'),
                                border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
                              ),
                              keyboardType: TextInputType.number,
                              obscureText: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: LanguageService.text('cardName'),
                          hintText: LanguageService.text('cardNameHint'),
                          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
                        ),
                        keyboardType: TextInputType.name,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(LanguageService.text('cancelButton'),
                      style: GoogleFonts.plusJakartaSans(color: SukuColors.textHint, fontWeight: FontWeight.w700)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: SukuColors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  onPressed: () {
                    if (selectedMethod != 'card') {
                      final phone = phoneController.text.trim();
                      if (phone.isEmpty || phone.length < 9) return;
                      Navigator.pop(context, {'method': selectedMethod, 'phone': phone});
                    } else {
                      final cardNumber = cardNumberController.text.trim();
                      final expiry = expiryController.text.trim();
                      final cvc = cvcController.text.trim();
                      final name = nameController.text.trim();
                      if (cardNumber.isEmpty || expiry.isEmpty || cvc.length < 3 || name.isEmpty) return;
                      Navigator.pop(context, {
                        'method': 'card',
                        'cardNumber': cardNumber,
                        'expiry': expiry,
                        'cvc': cvc,
                        'name': name,
                      });
                    }
                  },
                  child: Text(LanguageService.text('continueButton'),
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;
    if (result['method'] == 'card') {
      await _confirmCardPayment(
        plan,
        result['cardNumber']!,
        result['expiry']!,
        result['cvc']!,
        result['name']!,
      );
      return;
    }

    await _confirmMobileMoneyPayment(plan, result['method']!, result['phone']!);
  }

  Future<void> _confirmMobileMoneyPayment(String plan, String provider, String phone) async {
    final providerLabel = _providerLabel(provider);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(LanguageService.text('mobileMoneyPaymentTitle'),
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LanguageService.text('paymentRequestInstruction')
                    .replaceFirst('{phone}', phone)
                    .replaceFirst('{provider}', providerLabel),
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: SukuColors.textSecondary),
              ),
              const SizedBox(height: 14),
              Text(LanguageService.text('enterMobileMoneyPinOnPhone'),
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: SukuColors.textSecondary, height: 1.4)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(LanguageService.text('cancelButton'),
                  style: GoogleFonts.plusJakartaSans(color: SukuColors.textHint, fontWeight: FontWeight.w700)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: SukuColors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: () {
                Navigator.pop(context);
                _processPayment(plan, provider);
              },
              child: Text(LanguageService.text('confirmButton'),
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  String _providerLabel(String provider) {
    switch (provider) {
      case 'airtel':
        return LanguageService.text('airtelPaymentOption');
      case 'mtn':
        return LanguageService.text('mtnPaymentOption');
      default:
        return LanguageService.text('mpesaPaymentOption');
    }
  }

  Future<void> _confirmCardPayment(
    String plan,
    String cardNumber,
    String expiry,
    String cvc,
    String name,
  ) async {
    await showDialog(
      context: context,
      builder: (context) {
        final maskedNumber =
            cardNumber.length >= 4 ? '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}' : cardNumber;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(LanguageService.text('cardPaymentSummaryTitle'),
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${LanguageService.text('cardNumber')}: $maskedNumber',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: SukuColors.textSecondary)),
              const SizedBox(height: 8),
              Text('${LanguageService.text('cardExpiry')}: $expiry',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: SukuColors.textSecondary)),
              const SizedBox(height: 8),
              Text('${LanguageService.text('cardName')}: $name',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: SukuColors.textSecondary)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(LanguageService.text('cancelButton'),
                  style: GoogleFonts.plusJakartaSans(color: SukuColors.textHint, fontWeight: FontWeight.w700)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: SukuColors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: () {
                Navigator.pop(context);
                _processPayment(plan, 'card');
              },
              child: Text(LanguageService.text('confirmButton'),
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processPayment(String plan, String method) async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 700));
    await _savePlan(plan);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(LanguageService.text('paymentSuccess')),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.language,
      builder: (context, language, _) {
        return Scaffold(
          backgroundColor: SukuColors.background,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const BackButton(color: SukuColors.textPrimary),
                      const SizedBox(width: 8),
                      Text(LanguageService.text('subscriptionTitle'),
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: SukuColors.textPrimary,
                              letterSpacing: -0.5)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(LanguageService.text('subscriptionDescription'),
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: SukuColors.textSecondary, height: 1.5)),
                  const SizedBox(height: 24),
                  _PlanTile(
                    title: '${LanguageService.planName('Free')} — ${LanguageService.planPrice('Free')}',
                    subtitle: LanguageService.text('freePlanSubtitle'),
                    active: _selectedPlan == 'Free',
                    onTap: () => _confirmPlanSelection('Free'),
                  ),
                  const SizedBox(height: 12),
                  _PlanTile(
                    title: '${LanguageService.planName('Pro')} — ${LanguageService.planPrice('Pro')}',
                    subtitle: LanguageService.text('proPlanSubtitle'),
                    active: _selectedPlan == 'Pro',
                    onTap: () => _confirmPlanSelection('Pro'),
                  ),
                  const SizedBox(height: 12),
                  _PlanTile(
                    title: '${LanguageService.planName('Business')} — ${LanguageService.planPrice('Business')}',
                    subtitle: LanguageService.text('businessPlanSubtitle'),
                    active: _selectedPlan == 'Business',
                    onTap: () => _confirmPlanSelection('Business'),
                  ),
                  const SizedBox(height: 24),
                  Text('${LanguageService.text('currentPlan')}: ${LanguageService.planName(_selectedPlan)}',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, fontWeight: FontWeight.w600, color: SukuColors.textPrimary)),
                  const SizedBox(height: 8),
                  Text(
                    LanguageService.text('subscriptionSavedNotice'),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: SukuColors.textSecondary, height: 1.5),
                  ),
                  if (_saving) ...[
                    const SizedBox(height: 20),
                    const Center(child: CircularProgressIndicator(color: SukuColors.green)),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlanTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool active;
  final VoidCallback onTap;

  const _PlanTile({required this.title, required this.subtitle, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: active ? SukuColors.greenSurface : SukuColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? SukuColors.green : SukuColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 16, fontWeight: FontWeight.w700, color: SukuColors.textPrimary)),
                  const SizedBox(height: 6),
                  Text(subtitle,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: SukuColors.textSecondary, height: 1.4)),
                ],
              ),
            ),
            Icon(active ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: active ? SukuColors.green : SukuColors.textHint),
          ],
        ),
      ),
    );
  }
}
