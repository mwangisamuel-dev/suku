import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../theme/suku_theme.dart';
import '../models/models.dart';
import '../widgets/shared_widgets.dart';
import '../services/transaction_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

enum ScanState { idle, scanning, result, manual }

class _ScanScreenState extends State<ScanScreen>
    with TickerProviderStateMixin {
  ScanState _state = ScanState.idle;
  File? _imageFile;
  late AnimationController _resultController;
  late Animation<Offset> _resultSlide;
  late Animation<double> _resultFade;

  // Extracted data
  String _vendor = '';
  double _amount = 0;
  String _date = '';
  ExpenseCategory _category = ExpenseCategory.other;
  List<String> _rawLines = [];

  final _amountController = TextEditingController();
  final _vendorController = TextEditingController();
  String? _selectedCategory;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _resultController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _resultSlide =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _resultController, curve: Curves.easeOut));
    _resultFade = CurvedAnimation(
        parent: _resultController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _resultController.dispose();
    _amountController.dispose();
    _vendorController.dispose();
    super.dispose();
  }

  // ── Pick image and scan ───────────────────────────────────────
  Future<void> _scan(ImageSource source) async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    setState(() {
      _state = ScanState.scanning;
      _imageFile = File(picked.path);
    });

    try {
      final inputImage = InputImage.fromFile(_imageFile!);
      final recognizer = TextRecognizer();
      final result = await recognizer.processImage(inputImage);
      await recognizer.close();

      _extractData(result.text);

      setState(() => _state = ScanState.result);
      _resultController.forward();
      HapticFeedback.mediumImpact();
    } catch (e) {
      setState(() => _state = ScanState.manual);
    }
  }

  // ── Extract amount, vendor, date from raw text ────────────────
  void _extractData(String text) {
    final lines =
        text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    _rawLines = lines;

    // Amount — find largest number that looks like a price
    double bestAmount = 0;
    final amountRegex = RegExp(
        r'(?:ksh|kshs|ksh\.|total|amount|jumla|bei)[\s:]*([0-9,]+(?:\.[0-9]{1,2})?)',
        caseSensitive: false);
    final allNumbers =
        RegExp(r'\b([0-9,]{3,}(?:\.[0-9]{1,2})?)\b');

    // First try labeled amounts
    for (final match in amountRegex.allMatches(text)) {
      final val =
          double.tryParse(match.group(1)!.replaceAll(',', ''));
      if (val != null && val > bestAmount) bestAmount = val;
    }

    // If nothing found try largest number
    if (bestAmount == 0) {
      for (final match in allNumbers.allMatches(text)) {
        final val =
            double.tryParse(match.group(1)!.replaceAll(',', ''));
        if (val != null && val > bestAmount && val < 10000000) {
          bestAmount = val;
        }
      }
    }
    _amount = bestAmount;
    _amountController.text =
        bestAmount > 0 ? bestAmount.toStringAsFixed(0) : '';

    // Vendor — first meaningful line (usually business name)
    _vendor = '';
    for (final line in lines.take(5)) {
      if (line.length > 3 &&
          !RegExp(r'^[0-9\s\-\/\*\.]+$').hasMatch(line) &&
          !line.toLowerCase().contains('receipt') &&
          !line.toLowerCase().contains('invoice')) {
        _vendor = line;
        break;
      }
    }
    _vendorController.text = _vendor;

    // Date
    final dateRegex = RegExp(
        r'\b(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})\b');
    final dateMatch = dateRegex.firstMatch(text);
    _date = dateMatch != null
        ? dateMatch.group(1)!
        : _formatDate(DateTime.now());

    // Category guess from keywords
    final lower = text.toLowerCase();
    if (lower.contains('supermarket') ||
        lower.contains('wholesale') ||
        lower.contains('naivas') ||
        lower.contains('quickmart') ||
        lower.contains('hardware')) {
      _category = ExpenseCategory.stock;
    } else if (lower.contains('rent') ||
        lower.contains('kodi') ||
        lower.contains('lease')) {
      _category = ExpenseCategory.rent;
    } else if (lower.contains('salary') ||
        lower.contains('wages') ||
        lower.contains('mshahara')) {
      _category = ExpenseCategory.salary;
    } else if (lower.contains('matatu') ||
        lower.contains('petrol') ||
        lower.contains('fuel') ||
        lower.contains('uber') ||
        lower.contains('parking')) {
      _category = ExpenseCategory.transport;
    } else if (lower.contains('kplc') ||
        lower.contains('water') ||
        lower.contains('safaricom') ||
        lower.contains('electricity')) {
      _category = ExpenseCategory.utilities;
    } else {
      _category = ExpenseCategory.other;
    }
    _selectedCategory = _category.name;
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';

  Future<void> _saveTransaction() async {
    final amount =
        double.tryParse(_amountController.text) ?? _amount;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please enter a valid amount',
            style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: SukuColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }

    setState(() => _saving = true);
    HapticFeedback.lightImpact();

    final cat = ExpenseCategory.values.firstWhere(
        (e) => e.name == _selectedCategory,
        orElse: () => ExpenseCategory.other);

    final success = await TransactionService.addTransaction(
      title: _vendorController.text.isNotEmpty
          ? _vendorController.text
          : 'Receipt scan',
      vendor: _vendorController.text,
      amount: amount,
      type: TransactionType.expense,
      category: cat,
      notes: 'Scanned receipt — $_date',
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Imeingizwa! Transaction saved ✓',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ],
        ),
        backgroundColor: SukuColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SukuColors.navy,
      body: _state == ScanState.manual
          ? _buildManualEntry()
          : _buildCameraUI(),
    );
  }

  // ── Camera UI ─────────────────────────────────────────────────
  Widget _buildCameraUI() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A1E30), Color(0xFF102A43)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _GridPainter()),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    Text(
                      _state == ScanState.scanning
                          ? 'Inasoma...'
                          : _state == ScanState.result
                              ? 'Imesomwa! ✓'
                              : 'Scan Receipt',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _state = ScanState.manual),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('Manual',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _state == ScanState.result
                    ? _buildResultSheet()
                    : _buildViewfinder(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildViewfinder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _state == ScanState.scanning
              ? 'Inasoma maandishi...'
              : 'Chagua picha ya risiti',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        // Viewfinder box
        Container(
          width: 280,
          height: 360,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _state == ScanState.scanning
                  ? SukuColors.green
                  : Colors.white.withOpacity(0.4),
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              _buildCorner(top: true, left: true),
              _buildCorner(top: true, left: false),
              _buildCorner(top: false, left: true),
              _buildCorner(top: false, left: false),
              Center(
                child: _state == ScanState.scanning
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                              color: SukuColors.green,
                              strokeWidth: 3),
                          const SizedBox(height: 16),
                          Text('ML Kit\nInasoma...',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: SukuColors.green)),
                        ],
                      )
                    : _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.file(_imageFile!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity),
                          )
                        : Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_rounded,
                                  size: 48,
                                  color:
                                      Colors.white.withOpacity(0.25)),
                              const SizedBox(height: 12),
                              Text('Receipt here',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      color: Colors.white
                                          .withOpacity(0.3))),
                            ],
                          ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        if (_state == ScanState.idle) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CameraBtn(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                onTap: () => _scan(ImageSource.gallery),
              ),
              const SizedBox(width: 32),
              // Shutter button
              GestureDetector(
                onTap: () => _scan(ImageSource.camera),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [SukuColors.orange, Color(0xFFFF8C5A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: SukuColors.orange.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 8)),
                    ],
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: Colors.white, size: 30),
                ),
              ),
              const SizedBox(width: 32),
              _CameraBtn(
                icon: Icons.edit_rounded,
                label: 'Manual',
                onTap: () =>
                    setState(() => _state = ScanState.manual),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildResultSheet() {
    return SlideTransition(
      position: _resultSlide,
      child: FadeTransition(
        opacity: _resultFade,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Success banner
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: SukuColors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: SukuColors.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: SukuColors.green, size: 18),
                    const SizedBox(width: 8),
                    Text('Receipt scanned! Review and confirm.',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: SukuColors.green)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Editable extracted data
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: SukuColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Extracted Data',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: SukuColors.textSecondary)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: SukuColors.greenSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome_rounded,
                                  size: 12, color: SukuColors.green),
                              const SizedBox(width: 4),
                              Text('ML Kit OCR',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: SukuColors.green)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Amount — editable
                    Text('Amount (Ksh)',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: SukuColors.textSecondary,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: SukuColors.textPrimary,
                          letterSpacing: -0.5),
                      decoration: InputDecoration(
                        prefixText: 'Ksh ',
                        prefixStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: SukuColors.textSecondary),
                        filled: true,
                        fillColor: SukuColors.surfaceAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: SukuColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: SukuColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: SukuColors.green, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Vendor — editable
                    Text('Vendor / Shop',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: SukuColors.textSecondary,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _vendorController,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          color: SukuColors.textPrimary),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: SukuColors.surfaceAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: SukuColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: SukuColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: SukuColors.green, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Date
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Date',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: SukuColors.textSecondary,
                                fontWeight: FontWeight.w500)),
                        Text(_date,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: SukuColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Category
                    Text('Category',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: SukuColors.textSecondary,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ExpenseCategory.values.map((cat) {
                        final active =
                            _selectedCategory == cat.name;
                        return GestureDetector(
                          onTap: () => setState(
                              () => _selectedCategory = cat.name),
                          child: AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: active
                                  ? cat.color.withOpacity(0.14)
                                  : SukuColors.surfaceAlt,
                              borderRadius:
                                  BorderRadius.circular(10),
                              border: Border.all(
                                color: active
                                    ? cat.color.withOpacity(0.5)
                                    : SukuColors.border,
                                width: active ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(cat.icon,
                                    size: 14,
                                    color: active
                                        ? cat.color
                                        : SukuColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(cat.label,
                                    style:
                                        GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight:
                                                FontWeight.w600,
                                            color: active
                                                ? cat.color
                                                : SukuColors
                                                    .textSecondary)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _resultController.reset();
                        setState(() {
                          _state = ScanState.idle;
                          _imageFile = null;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(
                            color: Colors.white24),
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Rescan',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              color: Colors.white70)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _saveTransaction,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2))
                          : const Icon(Icons.check_rounded),
                      label: Text(
                          _saving ? 'Saving...' : 'Hifadhi — Save',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SukuColors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Manual entry ──────────────────────────────────────────────
  Widget _buildManualEntry() {
    return Scaffold(
      backgroundColor: SukuColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_state == ScanState.manual) {
              setState(() => _state = ScanState.idle);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text('Add Manually',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 18, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildField('Amount (Ksh)', 'e.g. 2500',
                controller: _amountController,
                keyboardType: TextInputType.number,
                prefix: const Icon(Icons.attach_money_rounded,
                    color: SukuColors.green, size: 20)),
            const SizedBox(height: 16),
            _buildField('Vendor / Shop Name',
                'e.g. Naivas, Mama Ntilie',
                controller: _vendorController),
            const SizedBox(height: 20),
            Text('Category',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: SukuColors.textPrimary)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: ExpenseCategory.values.map((cat) {
                final active = _selectedCategory == cat.name;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedCategory = cat.name),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: active
                          ? cat.color.withOpacity(0.15)
                          : SukuColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: active
                              ? cat.color.withOpacity(0.4)
                              : SukuColors.border,
                          width: active ? 1.5 : 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat.icon,
                            size: 16,
                            color: active
                                ? cat.color
                                : SukuColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(cat.label,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? cat.color
                                    : SukuColors.textSecondary)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _saveTransaction,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Icon(Icons.save_rounded),
                label: Text('Hifadhi — Save Transaction',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SukuColors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, String hint,
      {TextEditingController? controller,
      TextInputType? keyboardType,
      Widget? prefix}) {
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
          keyboardType: keyboardType,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 15, color: SukuColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefix,
            hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14, color: SukuColors.textHint),
            filled: true,
            fillColor: SukuColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: SukuColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: SukuColors.border),
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

  Widget _buildCorner(
      {required bool top, required bool left}) {
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: left ? 0 : null,
      right: left ? null : 0,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: top
                ? const BorderSide(
                    color: SukuColors.green, width: 3)
                : BorderSide.none,
            bottom: top
                ? BorderSide.none
                : const BorderSide(
                    color: SukuColors.green, width: 3),
            left: left
                ? const BorderSide(
                    color: SukuColors.green, width: 3)
                : BorderSide.none,
            right: left
                ? BorderSide.none
                : const BorderSide(
                    color: SukuColors.green, width: 3),
          ),
        ),
      ),
    );
  }
}

class _CameraBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CameraBtn(
      {required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withOpacity(0.2)),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 0.5;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}