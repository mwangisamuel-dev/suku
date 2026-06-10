import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../theme/suku_theme.dart';

class BusinessInfoScreen extends StatefulWidget {
  const BusinessInfoScreen({super.key});

  @override
  State<BusinessInfoScreen> createState() => _BusinessInfoScreenState();
}

class _BusinessInfoScreenState extends State<BusinessInfoScreen> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedType;
  bool _loading = true;
  bool _saving = false;

  final _businessTypes = [
    {'label': 'Duka / Shop', 'value': 'shop'},
    {'label': 'Food / Restaurant', 'value': 'food'},
    {'label': 'Salon / Barber', 'value': 'salon'},
    {'label': 'Fundi / Repairs', 'value': 'repairs'},
    {'label': 'Transport / Boda', 'value': 'transport'},
    {'label': 'Other / Freelance', 'value': 'other'},
  ];

  @override
  void initState() {
    super.initState();
    _loadBusinessInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadBusinessInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('business_name') ?? '';
      _locationController.text = prefs.getString('location') ?? '';
      _selectedType = prefs.getString('business_type') ?? 'other';
      _loading = false;
    });
  }

  bool get _canSave {
    return _nameController.text.trim().length >= 2 &&
        _locationController.text.trim().length >= 2 &&
        _selectedType != null;
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    await AuthService.saveBusinessProfile(
      businessName: _nameController.text.trim(),
      location: _locationController.text.trim(),
      businessType: _selectedType ?? 'other',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Business info saved', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
      backgroundColor: SukuColors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SukuColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: SukuColors.green))
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const BackButton(color: SukuColors.textPrimary),
                          const SizedBox(width: 8),
                          Text('Business Info',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: SukuColors.textPrimary,
                                  letterSpacing: -0.5)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text('Update your business name, location and category for reports and receipts.',
                          style:
                              GoogleFonts.plusJakartaSans(fontSize: 14, color: SukuColors.textSecondary, height: 1.5)),
                      const SizedBox(height: 24),
                      _buildField(label: 'Business Name', controller: _nameController, hint: 'e.g. Mama Kuku Shop'),
                      const SizedBox(height: 14),
                      _buildField(label: 'Location', controller: _locationController, hint: 'e.g. Nairobi, Kenya'),
                      const SizedBox(height: 18),
                      Text('Business Type',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 14, fontWeight: FontWeight.w700, color: SukuColors.textPrimary)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _businessTypes.map((type) {
                          final value = type['value']!;
                          final selected = _selectedType == value;
                          return ChoiceChip(
                            label: Text(type['label']!,
                                style: GoogleFonts.plusJakartaSans(
                                    color: selected ? Colors.white : SukuColors.textPrimary)),
                            selected: selected,
                            onSelected: (_) => setState(() => _selectedType = value),
                            selectedColor: SukuColors.green,
                            backgroundColor: SukuColors.surface,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _canSave && !_saving ? _save : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SukuColors.green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _saving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text('Save business info',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildField({required String label, required TextEditingController controller, required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: SukuColors.textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: SukuColors.textHint),
            filled: true,
            fillColor: SukuColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: SukuColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: SukuColors.border),
            ),
          ),
        ),
      ],
    );
  }
}
