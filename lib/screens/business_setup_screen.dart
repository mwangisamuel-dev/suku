import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/suku_theme.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'pin_setup_screen.dart';

class BusinessSetupScreen extends StatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedType;
  bool _loading = false;
  int _step = 0;

  final _businessTypes = [
    {'icon': '🛒', 'label': 'Duka / Shop', 'value': 'shop'},
    {'icon': '🍳', 'label': 'Food / Restaurant', 'value': 'food'},
    {'icon': '✂️', 'label': 'Salon / Barber', 'value': 'salon'},
    {'icon': '🔧', 'label': 'Fundi / Repairs', 'value': 'repairs'},
    {'icon': '🚗', 'label': 'Transport / Boda', 'value': 'transport'},
    {'icon': '📦', 'label': 'Wholesale / Supply', 'value': 'wholesale'},
    {'icon': '💊', 'label': 'Pharmacy / Chemist', 'value': 'pharmacy'},
    {'icon': '📱', 'label': 'Tech / Electronics', 'value': 'tech'},
    {'icon': '🏗️', 'label': 'Construction', 'value': 'construction'},
    {'icon': '🌾', 'label': 'Farming / Agri', 'value': 'farming'},
    {'icon': '👔', 'label': 'Clothes / Mtumba', 'value': 'clothes'},
    {'icon': '💼', 'label': 'Other / Freelance', 'value': 'other'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  bool get _stepValid {
    if (_step == 0) return _nameController.text.trim().length >= 2;
    if (_step == 1) return _selectedType != null;
    if (_step == 2) return _locationController.text.trim().length >= 2;
    return false;
  }

  Future<void> _finish() async {
  setState(() => _loading = true);
  await AuthService.saveBusinessProfile(
    businessName: _nameController.text.trim(),
    location: _locationController.text.trim(),
    businessType: _selectedType ?? 'other',
  );
  if (!mounted) return;
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const PinSetupScreen()),
    (_) => false,
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SukuColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Progress bar
              Row(
                children: List.generate(3, (i) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= _step
                            ? SukuColors.green
                            : SukuColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                'Step ${_step + 1} of 3',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: SukuColors.textHint,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 28),

              // Step content
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildStep(),
                ),
              ),

              // Navigation buttons
              Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _step--),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: SukuColors.textSecondary,
                          side: const BorderSide(color: SukuColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('Back',
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _stepValid && !_loading
                          ? () {
                              if (_step < 2) {
                                setState(() => _step++);
                              } else {
                                _finish();
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SukuColors.green,
                        disabledBackgroundColor: SukuColors.border,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : Text(
                              _step == 2 ? 'Anza — Let\'s Go! 🚀' : 'Continue',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildNameStep();
      case 1:
        return _buildTypeStep();
      case 2:
        return _buildLocationStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildNameStep() {
    return Column(
      key: const ValueKey('name'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What\'s your\nbusiness called?',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: SukuColors.textPrimary,
                letterSpacing: -0.5,
                height: 1.2)),
        const SizedBox(height: 8),
        Text('This is how your reports and invoices will be labelled.',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: SukuColors.textSecondary,
                height: 1.6)),
        const SizedBox(height: 32),
        TextField(
          controller: _nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: SukuColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. Mama Mboga Shop, Kamau Hardware',
            hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 16, color: SukuColors.textHint),
            filled: true,
            fillColor: SukuColors.surface,
            prefixIcon: const Icon(Icons.store_rounded, color: SukuColors.green),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: SukuColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: SukuColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: SukuColors.green, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildTypeStep() {
    return Column(
      key: const ValueKey('type'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What kind of\nbusiness is it?',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: SukuColors.textPrimary,
                letterSpacing: -0.5,
                height: 1.2)),
        const SizedBox(height: 8),
        Text('This helps Suku suggest the right expense categories.',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: SukuColors.textSecondary,
                height: 1.6)),
        const SizedBox(height: 20),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            itemCount: _businessTypes.length,
            itemBuilder: (_, i) {
              final t = _businessTypes[i];
              final active = _selectedType == t['value'];
              return GestureDetector(
                onTap: () => setState(() => _selectedType = t['value']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: active
                        ? SukuColors.greenSurface
                        : SukuColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: active
                          ? SukuColors.green
                          : SukuColors.border,
                      width: active ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(t['icon']!,
                          style: const TextStyle(fontSize: 26)),
                      const SizedBox(height: 6),
                      Text(
                        t['label']!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: active
                              ? SukuColors.green
                              : SukuColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLocationStep() {
    return Column(
      key: const ValueKey('location'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Where is your\nbusiness located?',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: SukuColors.textPrimary,
                letterSpacing: -0.5,
                height: 1.2)),
        const SizedBox(height: 8),
        Text('This appears on your PDF reports.',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: SukuColors.textSecondary,
                height: 1.6)),
        const SizedBox(height: 32),
        TextField(
          controller: _locationController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: SukuColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. Gikomba, Westlands, Mombasa Rd',
            hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 15, color: SukuColors.textHint),
            filled: true,
            fillColor: SukuColors.surface,
            prefixIcon: const Icon(Icons.location_on_rounded,
                color: SukuColors.orange),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: SukuColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: SukuColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: SukuColors.green, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        // Summary card
        if (_nameController.text.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SukuColors.greenSurface,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: SukuColors.green.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: SukuColors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: SukuColors.green, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_nameController.text,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: SukuColors.textPrimary)),
                      Text(
                        _businessTypes.firstWhere(
                            (t) => t['value'] == _selectedType,
                            orElse: () => {'label': ''})['label'] ?? '',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: SukuColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
