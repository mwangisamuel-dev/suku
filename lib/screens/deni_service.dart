import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/suku_theme.dart';
import '../services/deni_service.dart';

class DeniScreen extends StatefulWidget {
  const DeniScreen({super.key});

  @override
  State<DeniScreen> createState() => _DeniScreenState();
}

class _DeniScreenState extends State<DeniScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Deni> _all = [];
  bool _loading = true;
  final fmt = NumberFormat('#,##0', 'en_US');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await DeniService.getAll();
    if (!mounted) return;
    setState(() {
      _all = list;
      _loading = false;
    });
  }

  List<Deni> get _owesMe =>
      _all.where((d) => d.type == DeniType.owesMe).toList();
  List<Deni> get _iOwe =>
      _all.where((d) => d.type == DeniType.iOwe).toList();

  @override
  Widget build(BuildContext context) {
    final totalOwedToMe = DeniService.totalOwedToMe(_all);
    final totalIOwe = DeniService.totalIOwe(_all);
    final netPosition = totalOwedToMe - totalIOwe;

    return Scaffold(
      backgroundColor: SukuColors.background,
      body: Column(
        children: [
          // Header
          Container(
            color: SukuColors.navy,
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Deni 💸',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _showAddDeniDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: SukuColors.green,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.add_rounded,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text('Add',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Summary row
                Row(
                  children: [
                    _HeaderStat(
                      label: 'Owed to me',
                      value: 'Ksh ${fmt.format(totalOwedToMe)}',
                      color: SukuColors.green,
                    ),
                    const SizedBox(width: 12),
                    _HeaderStat(
                      label: 'I owe',
                      value: 'Ksh ${fmt.format(totalIOwe)}',
                      color: SukuColors.orange,
                    ),
                    const SizedBox(width: 12),
                    _HeaderStat(
                      label: 'Net position',
                      value:
                          '${netPosition >= 0 ? '+' : ''}Ksh ${fmt.format(netPosition)}',
                      color: netPosition >= 0
                          ? SukuColors.greenLight
                          : SukuColors.error,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Tabs
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: SukuColors.green,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: FontWeight.w700),
                    unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: FontWeight.w500),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withOpacity(0.5),
                    tabs: [
                      Tab(
                          text:
                              'Owed to me (${_owesMe.where((d) => d.status != DeniStatus.paid).length})'),
                      Tab(
                          text:
                              'I owe (${_iOwe.where((d) => d.status != DeniStatus.paid).length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: SukuColors.green))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(_owesMe, DeniType.owesMe),
                      _buildList(_iOwe, DeniType.iOwe),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Deni> list, DeniType type) {
    final active = list.where((d) => d.status != DeniStatus.paid).toList();
    final paid = list.where((d) => d.status == DeniStatus.paid).toList();

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: SukuColors.greenSurface,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  type == DeniType.owesMe
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: SukuColors.green,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                type == DeniType.owesMe
                    ? 'No one owes you yet'
                    : 'You don\'t owe anyone',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: SukuColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap Add to record a debt',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, color: SukuColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...active.map((d) => _DeniCard(
              deni: d,
              fmt: fmt,
              onRefresh: _load,
              onMarkPaid: () => _showMarkPaymentDialog(d),
              onRemind: () => _showReminderOptions(d),
              onDelete: () => _confirmDelete(d),
            )),
        if (paid.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('Settled',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: SukuColors.textSecondary)),
          ),
          ...paid.map((d) => _DeniCard(
                deni: d,
                fmt: fmt,
                onRefresh: _load,
                onMarkPaid: null,
                onRemind: null,
                onDelete: () => _confirmDelete(d),
              )),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  // ── Add Deni dialog ───────────────────────────────────────────
  void _showAddDeniDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DeniType selectedType = DeniType.owesMe;
    DateTime dueDate =
        DateTime.now().add(const Duration(days: 14));

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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                          color: SukuColors.border,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Record a Debt',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),

                  // Type selector
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setModal(
                              () => selectedType = DeniType.owesMe),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            decoration: BoxDecoration(
                              color: selectedType == DeniType.owesMe
                                  ? SukuColors.greenSurface
                                  : SukuColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selectedType == DeniType.owesMe
                                    ? SukuColors.green
                                    : SukuColors.border,
                                width: selectedType == DeniType.owesMe
                                    ? 1.5
                                    : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.arrow_downward_rounded,
                                    color:
                                        selectedType == DeniType.owesMe
                                            ? SukuColors.green
                                            : SukuColors.textHint,
                                    size: 20),
                                const SizedBox(height: 4),
                                Text('They owe me',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: selectedType ==
                                                DeniType.owesMe
                                            ? SukuColors.green
                                            : SukuColors.textSecondary)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setModal(
                              () => selectedType = DeniType.iOwe),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            decoration: BoxDecoration(
                              color: selectedType == DeniType.iOwe
                                  ? SukuColors.orange.withOpacity(0.1)
                                  : SukuColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selectedType == DeniType.iOwe
                                    ? SukuColors.orange
                                    : SukuColors.border,
                                width:
                                    selectedType == DeniType.iOwe ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.arrow_upward_rounded,
                                    color: selectedType == DeniType.iOwe
                                        ? SukuColors.orange
                                        : SukuColors.textHint,
                                    size: 20),
                                const SizedBox(height: 4),
                                Text('I owe them',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            selectedType == DeniType.iOwe
                                                ? SukuColors.orange
                                                : SukuColors.textSecondary)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _DialogField(
                      label: 'Name',
                      hint: 'e.g. John Kamau',
                      controller: nameCtrl),
                  const SizedBox(height: 12),
                  _DialogField(
                      label: 'Phone number',
                      hint: 'e.g. 0712345678',
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  _DialogField(
                      label: 'Amount (Ksh)',
                      hint: 'e.g. 5000',
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      prefix: 'Ksh '),
                  const SizedBox(height: 12),
                  _DialogField(
                      label: 'Notes (optional)',
                      hint: 'e.g. Loan for stock',
                      controller: notesCtrl),
                  const SizedBox(height: 12),

                  // Due date
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dueDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now()
                            .add(const Duration(days: 1825)),
                        builder: (_, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                                primary: SukuColors.green),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setModal(() => dueDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: SukuColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: SukuColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Due date',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: SukuColors.textSecondary)),
                          Text(
                              DateFormat('d MMM yyyy').format(dueDate),
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: SukuColors.textPrimary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameCtrl.text.isEmpty ||
                            amountCtrl.text.isEmpty) return;
                        final deni = Deni(
                          id: DateTime.now()
                              .millisecondsSinceEpoch
                              .toString(),
                          name: nameCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          originalAmount:
                              double.tryParse(amountCtrl.text) ?? 0,
                          paidAmount: 0,
                          type: selectedType,
                          status: DeniStatus.pending,
                          dueDate: dueDate,
                          notes: notesCtrl.text.trim().isEmpty
                              ? null
                              : notesCtrl.text.trim(),
                          createdAt: DateTime.now(),
                        );
                        Navigator.pop(context);
                        await DeniService.add(deni);
                        await _load();
                        HapticFeedback.mediumImpact();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SukuColors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Save',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Mark payment dialog ───────────────────────────────────────
  void _showMarkPaymentDialog(Deni deni) {
    final amountCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
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
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: SukuColors.border,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Text('Record Payment',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                  '${deni.name} — Remaining: Ksh ${fmt.format(deni.remainingAmount)}',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: SukuColors.textSecondary)),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: SukuColors.textPrimary),
                decoration: InputDecoration(
                  prefixText: 'Ksh ',
                  prefixStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 16, color: SukuColors.textSecondary),
                  hintText: '0',
                  filled: true,
                  fillColor: SukuColors.surfaceAlt,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: SukuColors.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: SukuColors.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: SukuColors.green, width: 1.5)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await DeniService.markFullyPaid(deni.id);
                        await _load();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SukuColors.green,
                        side: const BorderSide(
                            color: SukuColors.green),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Mark fully paid',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final amount =
                            double.tryParse(amountCtrl.text) ?? 0;
                        if (amount <= 0) return;
                        Navigator.pop(context);
                        await DeniService.markPayment(deni.id, amount);
                        await _load();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SukuColors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Record partial',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
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

  // ── Reminder options ──────────────────────────────────────────
  void _showReminderOptions(Deni deni) {
    final phone = deni.phone.replaceAll(RegExp(r'\D'), '');
    final intlPhone = phone.startsWith('0')
        ? '254${phone.substring(1)}'
        : phone;

    final isOwesMe = deni.type == DeniType.owesMe;
    final message = isOwesMe
        ? 'Habari ${deni.name}, nakukumbusha deni ya Ksh ${fmt.format(deni.remainingAmount)} ambayo ulinikopa. Tafadhali lipa haraka iwezekanavyo. Asante!'
        : 'Habari ${deni.name}, nakukumbusha kuhusu deni ya Ksh ${fmt.format(deni.remainingAmount)} ninayokukopa. Nitailipa hivi karibuni. Asante kwa uvumilivu!';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
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
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: SukuColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Send Reminder to ${deni.name}',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SukuColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(message,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: SukuColors.textSecondary,
                      height: 1.5)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  final encoded = Uri.encodeComponent(message);
                  final url =
                      'https://wa.me/$intlPhone?text=$encoded';
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri,
                        mode: LaunchMode.externalApplication);
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(
                        content: Text('WhatsApp not installed',
                            style: GoogleFonts.plusJakartaSans(
                                color: Colors.white)),
                        backgroundColor: SukuColors.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.all(16),
                      ));
                    }
                  }
                },
                icon: const Icon(Icons.message_rounded, size: 18),
                label: Text('Send via WhatsApp',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  final encoded = Uri.encodeComponent(message);
                  final url = 'sms:$phone?body=$encoded';
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
                icon: const Icon(Icons.sms_rounded, size: 18),
                label: Text('Send via SMS',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: SukuColors.navy,
                  side: const BorderSide(color: SukuColors.navy),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Delete ────────────────────────────────────────────────────
  Future<void> _confirmDelete(Deni deni) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Delete this debt?',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700)),
        content: Text(
            '${deni.name} — Ksh ${fmt.format(deni.originalAmount)} will be removed.',
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
            child: Text('Delete',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DeniService.delete(deni.id);
      await _load();
    }
  }
}

// ── Deni Card ─────────────────────────────────────────────────────────────────
class _DeniCard extends StatelessWidget {
  final Deni deni;
  final NumberFormat fmt;
  final VoidCallback onRefresh;
  final VoidCallback? onMarkPaid;
  final VoidCallback? onRemind;
  final VoidCallback onDelete;

  const _DeniCard({
    required this.deni,
    required this.fmt,
    required this.onRefresh,
    required this.onMarkPaid,
    required this.onRemind,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOwesMe = deni.type == DeniType.owesMe;
    final isPaid = deni.status == DeniStatus.paid;
    final color = isPaid
        ? SukuColors.textHint
        : isOwesMe
            ? SukuColors.green
            : SukuColors.orange;
    final progress = deni.originalAmount > 0
        ? deni.paidAmount / deni.originalAmount
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SukuColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPaid
              ? SukuColors.border
              : deni.isOverdue
                  ? SukuColors.error.withOpacity(0.3)
                  : SukuColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Center(
                  child: Text(
                    deni.name.isNotEmpty
                        ? deni.name[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: color),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(deni.name,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: SukuColors.textPrimary)),
                        const SizedBox(width: 8),
                        if (isPaid)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: SukuColors.green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Paid',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: SukuColors.green)),
                          )
                        else if (deni.isOverdue)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: SukuColors.error.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                                '${deni.daysOverdue}d overdue',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: SukuColors.error)),
                          ),
                      ],
                    ),
                    Text(
                      isPaid
                          ? 'Settled'
                          : 'Due ${DateFormat('d MMM yyyy').format(deni.dueDate)}',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: deni.isOverdue && !isPaid
                              ? SukuColors.error
                              : SukuColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Ksh ${fmt.format(deni.remainingAmount)}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isPaid ? SukuColors.textHint : color),
                  ),
                  if (deni.paidAmount > 0 && !isPaid)
                    Text(
                      'Paid: Ksh ${fmt.format(deni.paidAmount)}',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: SukuColors.textSecondary),
                    ),
                ],
              ),
            ],
          ),

          // Progress bar
          if (deni.paidAmount > 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],

          if (deni.notes != null) ...[
            const SizedBox(height: 8),
            Text(deni.notes!,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: SukuColors.textSecondary,
                    fontStyle: FontStyle.italic)),
          ],

          // Action buttons
          if (!isPaid) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (onRemind != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onRemind,
                      icon: const Icon(Icons.notifications_rounded,
                          size: 14),
                      label: Text('Remind',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SukuColors.navy,
                        side:
                            const BorderSide(color: SukuColors.border),
                        padding:
                            const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                if (onRemind != null) const SizedBox(width: 8),
                if (onMarkPaid != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onMarkPaid,
                      icon: const Icon(Icons.check_rounded, size: 14),
                      label: Text('Mark paid',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SukuColors.green,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: SukuColors.error.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: SukuColors.error, size: 16),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: onDelete,
                child: Text('Remove',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: SukuColors.textHint,
                        fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────
class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HeaderStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? prefix;

  const _DialogField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: SukuColors.textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 15, color: SukuColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix,
            hintStyle: GoogleFonts.plusJakartaSans(
                color: SukuColors.textHint),
            filled: true,
            fillColor: SukuColors.surfaceAlt,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: SukuColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: SukuColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: SukuColors.green, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}