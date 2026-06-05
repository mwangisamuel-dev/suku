import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/suku_theme.dart';
import '../models/models.dart';
import '../widgets/shared_widgets.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

enum ScanState { idle, scanning, result, manual }

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  ScanState _state = ScanState.idle;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late AnimationController _resultController;
  late Animation<Offset> _resultSlide;
  late Animation<double> _resultFade;

  // Simulated extracted data
  final _extracted = {
    'vendor': 'Naivas Supermarket',
    'amount': 3450.0,
    'date': 'Today, ${DateTime.now().day} Jun',
    'items': ['Unga 2kg x3', 'Sukari 1kg x2', 'Mafuta 2L'],
    'category': ExpenseCategory.stock,
  };

  String? _selectedManualCategory;
  final _amountController = TextEditingController();
  final _vendorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _resultController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _resultSlide = Tween<Offset>(
            begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _resultController, curve: Curves.easeOut));
    _resultFade = CurvedAnimation(parent: _resultController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _resultController.dispose();
    _amountController.dispose();
    _vendorController.dispose();
    super.dispose();
  }

  Future<void> _simulateScan() async {
    setState(() => _state = ScanState.scanning);
    await Future.delayed(const Duration(milliseconds: 2200));
    if (mounted) {
      setState(() => _state = ScanState.result);
      _resultController.forward();
      HapticFeedback.mediumImpact();
    }
  }

  void _saveTransaction() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              'Imeingizwa! Transaction saved ✓',
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: SukuColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
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

  Widget _buildCameraUI() {
    return Stack(
      children: [
        // Simulated camera background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A1E30), Color(0xFF102A43)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // Grid overlay
        CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _GridPainter(),
        ),

        SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                          border: Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    Text(
                      _state == ScanState.scanning ? 'Inasoma...' : 'Scan Receipt',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _state = ScanState.manual),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.15)),
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
                    ? _buildResultOverlay()
                    : _buildScanViewfinder(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScanViewfinder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _state == ScanState.scanning
              ? 'AI inasoma risiti yako...'
              : 'Weka risiti ndani ya fremu',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 14, color: Colors.white.withOpacity(0.7)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        // Viewfinder
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Transform.scale(
            scale: _state == ScanState.scanning ? _pulseAnim.value : 1.0,
            child: Container(
              width: 280,
              height: 380,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _state == ScanState.scanning
                      ? SukuColors.green
                      : Colors.white.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  // Corner accents
                  ..._buildCornerAccents(),
                  // Center content
                  Center(
                    child: _state == ScanState.scanning
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                color: SukuColors.green,
                                strokeWidth: 3,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Claude AI\nInasoma...',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: SukuColors.green),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_rounded,
                                  size: 48,
                                  color: Colors.white.withOpacity(0.25)),
                              const SizedBox(height: 12),
                              Text(
                                'Receipt here',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.3)),
                              ),
                            ],
                          ),
                  ),
                  // Scan line animation
                  if (_state == ScanState.scanning)
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (_, __) => Positioned(
                        top: 380 * ((_pulseController.value + 1) / 2),
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                SukuColors.green.withOpacity(0.8),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 48),
        // Action buttons
        if (_state == ScanState.idle)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CameraActionBtn(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                onTap: _simulateScan,
              ),
              const SizedBox(width: 24),
              // Main shutter
              GestureDetector(
                onTap: _simulateScan,
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
                  child: const Icon(Icons.document_scanner_rounded,
                      color: Colors.white, size: 30),
                ),
              ),
              const SizedBox(width: 24),
              _CameraActionBtn(
                icon: Icons.flash_auto_rounded,
                label: 'Flash',
                onTap: () {},
              ),
            ],
          ),
        if (_state == ScanState.scanning)
          Text(
            'Tafadhali subiri kidogo...',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: SukuColors.green.withOpacity(0.8),
                fontWeight: FontWeight.w500),
          ),
      ],
    );
  }

  List<Widget> _buildCornerAccents() {
    const c = SukuColors.green;
    const w = 24.0;
    const t = 3.0;
    return [
      Positioned(top: 0, left: 0,
          child: _Corner(color: c, width: w, thickness: t, top: true, left: true)),
      Positioned(top: 0, right: 0,
          child: _Corner(color: c, width: w, thickness: t, top: true, left: false)),
      Positioned(bottom: 0, left: 0,
          child: _Corner(color: c, width: w, thickness: t, top: false, left: true)),
      Positioned(bottom: 0, right: 0,
          child: _Corner(color: c, width: w, thickness: t, top: false, left: false)),
    ];
  }

  Widget _buildResultOverlay() {
    final cat = _extracted['category'] as ExpenseCategory;

    return SlideTransition(
      position: _resultSlide,
      child: FadeTransition(
        opacity: _resultFade,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Success header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: SukuColors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SukuColors.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: SukuColors.green, size: 18),
                    const SizedBox(width: 8),
                    Text('Risiti imesomwa! Receipt extracted',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: SukuColors.green)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Extracted data card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: SukuColors.surface,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Extracted Data',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: SukuColors.textSecondary)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: SukuColors.greenSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome_rounded,
                                  size: 12, color: SukuColors.green),
                              const SizedBox(width: 4),
                              Text('AI Powered',
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
                    _resultRow('Vendor', _extracted['vendor'] as String),
                    const SizedBox(height: 12),
                    _resultRow('Amount',
                        'Ksh ${(_extracted['amount'] as double).toStringAsFixed(0)}',
                        highlight: true),
                    const SizedBox(height: 12),
                    _resultRow('Date', _extracted['date'] as String),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Category',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13, color: SukuColors.textSecondary)),
                        CategoryBadge(category: cat),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: SukuColors.border),
                    const SizedBox(height: 12),
                    Text('Items Detected',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: SukuColors.textSecondary)),
                    const SizedBox(height: 8),
                    ...(_extracted['items'] as List<String>).map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.fiber_manual_record,
                                  size: 6, color: SukuColors.textHint),
                              const SizedBox(width: 8),
                              Text(item,
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      color: SukuColors.textPrimary)),
                            ],
                          ),
                        )),
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
                        setState(() => _state = ScanState.idle);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SukuColors.textSecondary,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                      onPressed: _saveTransaction,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Hifadhi — Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SukuColors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        textStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 15, fontWeight: FontWeight.w700),
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

  Widget _resultRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13, color: SukuColors.textSecondary)),
        Text(value,
            style: GoogleFonts.plusJakartaSans(
                fontSize: highlight ? 20 : 14,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                color: highlight ? SukuColors.textPrimary : SukuColors.textPrimary,
                letterSpacing: highlight ? -0.5 : 0)),
      ],
    );
  }

  Widget _buildManualEntry() {
    return Scaffold(
      backgroundColor: SukuColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => setState(() => _state = ScanState.idle),
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
            _buildField('Vendor / Shop Name', 'e.g. Naivas, Mama Ntilie',
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
                final active = _selectedManualCategory == cat.label;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedManualCategory = cat.label),
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
                            color:
                                active ? cat.color : SukuColors.textSecondary),
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
                onPressed: _saveTransaction,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Hifadhi — Save Transaction'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SukuColors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  textStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
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
              borderSide: const BorderSide(color: SukuColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: SukuColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: SukuColors.green, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _CameraActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CameraActionBtn(
      {required this.icon, required this.label, required this.onTap});

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
              border: Border.all(color: Colors.white.withOpacity(0.2)),
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

class _Corner extends StatelessWidget {
  final Color color;
  final double width;
  final double thickness;
  final bool top;
  final bool left;

  const _Corner({
    required this.color,
    required this.width,
    required this.thickness,
    required this.top,
    required this.left,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width,
      child: CustomPaint(
        painter: _CornerPainter(
            color: color, thickness: thickness, top: top, left: left),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final bool top;
  final bool left;

  _CornerPainter(
      {required this.color,
      required this.thickness,
      required this.top,
      required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final x = left ? 0.0 : size.width;
    final y = top ? 0.0 : size.height;
    final dx = left ? size.width : -size.width;
    final dy = top ? size.height : -size.height;

    path.moveTo(x + dx, y);
    path.lineTo(x, y);
    path.lineTo(x, y + dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
