import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/suku_theme.dart';
import '../models/models.dart';
import '../widgets/shared_widgets.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../services/transaction_service.dart';
import 'scan_screen.dart';
import 'add_transaction_screen.dart';
import 'business_info_screen.dart';
import 'language_screen.dart';
import 'mpesa_screen.dart';
import 'mpesa_settings_screen.dart';
import 'notifications_screen.dart';
import 'help_support_screen.dart';
import 'subscription_screen.dart';
import 'transaction_detail_screen.dart';
import 'phone_screen.dart';
import '../services/sms_service.dart';
import 'reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _navIndex = 0;
  late AnimationController _cardController;
  late Animation<double> _cardAnim;
  bool _balanceVisible = true;
  String _businessName = 'Biashara yako';
  List<Transaction> _transactions = [];
  MonthlySummary _summary = MonthlySummary(
    totalIncome: 0,
    totalExpenses: 0,
    byCategory: {},
    transactions: [],
  );
  bool _loadingData = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _cardController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _cardAnim = CurvedAnimation(parent: _cardController, curve: Curves.easeOutBack);
    _cardController.forward();
    _loadData();
    _startSmsListener();
  }

  Future _startSmsListener() async {
    await SmsService.startListening(
      onTransaction: () {
        // Refresh dashboard when new M-Pesa comes in
        _loadData();
      },
    );
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final transactions = await TransactionService.getTransactions();
    final summary = TransactionService.getSummary(transactions);
    if (!mounted) return;
    setState(() {
      _businessName = prefs.getString('business_name') ?? 'Biashara yako';
      _transactions = transactions;
      _summary = summary;
      _loadingData = false;
    });
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SukuColors.background,
      body: _loadingData
          ? const Center(child: CircularProgressIndicator(color: SukuColors.green))
          : IndexedStack(
              index: _navIndex,
              children: [
                _DashboardTab(
                  summary: _summary,
                  transactions: _transactions,
                  cardAnim: _cardAnim,
                  balanceVisible: _balanceVisible,
                  onToggleBalance: () => setState(() => _balanceVisible = !_balanceVisible),
                  businessName: _businessName,
                  onRefresh: _loadData,
                ),
                _TransactionsTab(
                  transactions: _transactions,
                  onRefresh: _loadData,
                  hideAmount: !_balanceVisible,
                ),
                const SizedBox(),
                const ReportsScreen(),
                _SettingsTab(),
              ],
            ),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildFAB() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
        if (result == true) _loadData();
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [SukuColors.orange, Color(0xFFFF8C5A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: SukuColors.orange.withOpacity(0.45), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildNavBar() {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.receipt_long_rounded, 'label': 'Transactions'},
      {'icon': Icons.add, 'label': ''},
      {'icon': Icons.bar_chart_rounded, 'label': 'Reports'},
      {'icon': Icons.person_rounded, 'label': 'Profile'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: SukuColors.surface,
        boxShadow: [
          BoxShadow(
            color: SukuColors.navy.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          )
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BottomAppBar(
          elevation: 0,
          color: SukuColors.surface,
          notchMargin: 8,
          shape: const CircularNotchedRectangle(),
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (i) {
                if (i == 2) return const SizedBox(width: 64);
                final active = _navIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _navIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? SukuColors.green.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          items[i]['icon'] as IconData,
                          color: active ? SukuColors.green : SukuColors.textHint,
                          size: 24,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          items[i]['label'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                            color: active ? SukuColors.green : SukuColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Dashboard Tab ─────────────────────────────────────────────────────────────
class _DashboardTab extends StatelessWidget {
  final MonthlySummary summary;
  final List<Transaction> transactions;
  final Animation<double> cardAnim;
  final bool balanceVisible;
  final VoidCallback onToggleBalance;
  final String businessName;
  final VoidCallback onRefresh;

  const _DashboardTab({
    required this.summary,
    required this.transactions,
    required this.cardAnim,
    required this.balanceVisible,
    required this.onToggleBalance,
    required this.businessName,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Habari za asubuhi'
        : now.hour < 17
            ? 'Habari za mchana'
            : 'Habari za jioni';

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting 👋',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13, color: SukuColors.textSecondary, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          businessName,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: SukuColors.textPrimary,
                              letterSpacing: -0.5),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _IconBtn(icon: Icons.search_rounded, onTap: () {}),
                        const SizedBox(width: 8),
                        Stack(
                          children: [
                            _IconBtn(icon: Icons.notifications_none_rounded, onTap: () {}),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: SukuColors.orange),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ScaleTransition(
                  scale: cardAnim,
                  child: _BalanceCard(
                    summary: summary,
                    visible: balanceVisible,
                    onToggle: onToggleBalance,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    QuickActionBtn(
                      icon: Icons.add_rounded,
                      label: 'Add',
                      onTap: () async {
                        final result = await Navigator.push(
                            context, MaterialPageRoute(builder: (_) => const AddTransactionScreen()));
                        if (result == true) onRefresh();
                      },
                      color: SukuColors.green,
                    ),
                    QuickActionBtn(
                      icon: Icons.document_scanner_rounded,
                      label: 'Scan',
                      onTap: () async {
                        final result =
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
                        if (result == true) onRefresh();
                      },
                      color: SukuColors.orange,
                    ),
                    QuickActionBtn(
                      icon: Icons.sms_rounded,
                      label: 'M-Pesa',
                      onTap: () async {
                        final result =
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => const MpesaScreen()));
                        if (result == true) onRefresh();
                      },
                      color: SukuColors.green,
                    ),
                    QuickActionBtn(
                      icon: Icons.picture_as_pdf_rounded,
                      label: 'Report',
                      onTap: () {},
                      color: SukuColors.navy,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Money In',
                        amount: balanceVisible ? summary.totalIncome : -1,
                        color: SukuColors.green,
                        icon: Icons.trending_up_rounded,
                        change: null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Money Out',
                        amount: balanceVisible ? summary.totalExpenses : -1,
                        color: SukuColors.error,
                        icon: Icons.trending_down_rounded,
                        change: null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (transactions.isNotEmpty) ...[
                  _WeeklyChart(transactions: transactions),
                  const SizedBox(height: 24),
                  if (summary.byCategory.isNotEmpty) ...[
                    SectionHeader(title: 'Matumizi ya Mwezi', action: 'See all', onAction: () {}),
                    const SizedBox(height: 14),
                    _CategoryBreakdown(summary: summary, balanceVisible: balanceVisible),
                    const SizedBox(height: 24),
                  ],
                ],
                SectionHeader(title: 'Miamala ya Hivi Karibuni', action: 'View all', onAction: () {}),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          sliver: transactions.isEmpty
              ? SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: SukuColors.greenSurface,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(Icons.receipt_long_rounded, size: 40, color: SukuColors.green),
                          ),
                          const SizedBox(height: 16),
                          Text('Hakuna miamala bado',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16, fontWeight: FontWeight.w700, color: SukuColors.textPrimary)),
                          const SizedBox(height: 6),
                          Text('Tap + to add your first transaction',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: SukuColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _DashboardTransactionTile(
                      transaction: transactions[i],
                      visible: balanceVisible,
                      onTap: () async {
                        final result = await Navigator.push(context,
                            MaterialPageRoute(builder: (_) => TransactionDetailScreen(transaction: transactions[i])));
                        if (result == true) onRefresh();
                      },
                    ),
                    childCount: transactions.length > 5 ? 5 : transactions.length,
                  ),
                ),
        ),
      ],
    );
  }
}

class _DashboardTransactionTile extends StatelessWidget {
  final Transaction transaction;
  final bool visible;
  final VoidCallback? onTap;

  const _DashboardTransactionTile({required this.transaction, required this.visible, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final timeAgo = _timeAgo(transaction.date);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SukuColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SukuColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isIncome
                    ? SukuColors.greenSurface
                    : (transaction.category?.color ?? SukuColors.textHint).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(
                  isIncome ? Icons.trending_up_rounded : (transaction.category?.icon ?? Icons.receipt_rounded),
                  color: isIncome ? SukuColors.green : (transaction.category?.color ?? SukuColors.textHint),
                  size: 22,
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
                      Expanded(
                        child: Text(
                          transaction.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: SukuColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (transaction.isMpesa)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: SukuColors.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'M-Pesa',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: SukuColors.green,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (transaction.category != null) ...[
                        CategoryBadge(category: transaction.category!, compact: true),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        timeAgo,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: SukuColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              visible ? '${isIncome ? '+' : '-'} Ksh ${NumberFormat('#,##0').format(transaction.amount)}' : '••••',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isIncome ? SukuColors.green : SukuColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat('d MMM').format(date);
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: SukuColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SukuColors.border),
        ),
        child: Icon(icon, size: 20, color: SukuColors.textPrimary),
      ),
    );
  }
}

// ─── Balance Card ──────────────────────────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  final MonthlySummary summary;
  final bool visible;
  final VoidCallback onToggle;

  const _BalanceCard({required this.summary, required this.visible, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [SukuColors.navy, SukuColors.navyLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: SukuColors.navy.withOpacity(0.35),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SukuColors.green.withOpacity(0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: SukuColors.green),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('MMMM yyyy').format(DateTime.now()),
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13, color: Colors.white.withOpacity(0.65), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: onToggle,
                    child: Icon(
                      visible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      color: Colors.white.withOpacity(0.5),
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Net Profit',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: visible
                    ? Text(
                        'Ksh ${NumberFormat('#,##0').format(summary.netProfit)}',
                        key: const ValueKey('visible'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -1.5,
                        ),
                      )
                    : Text(
                        'Ksh ••••••',
                        key: const ValueKey('hidden'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: SukuColors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  summary.totalIncome > 0
                      ? '${summary.profitMargin.toStringAsFixed(1)}% margin  •  Biashara safi ✓'
                      : 'Anza kurekodi miamala yako',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, color: SukuColors.greenLight, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _MiniStat(
                      label: 'Money In',
                      value: visible ? 'Ksh ${NumberFormat('#,##0').format(summary.totalIncome)}' : '••••',
                      color: SukuColors.greenLight),
                  Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      width: 1,
                      height: 32,
                      color: Colors.white.withOpacity(0.15)),
                  _MiniStat(
                      label: 'Money Out',
                      value: visible ? 'Ksh ${NumberFormat('#,##0').format(summary.totalExpenses)}' : '••••',
                      color: SukuColors.orangeLight),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 11, color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

// ─── Weekly Chart ──────────────────────────────────────────────────────────────
class _WeeklyChart extends StatefulWidget {
  final List<Transaction> transactions;

  const _WeeklyChart({required this.transactions});

  @override
  State<_WeeklyChart> createState() => _WeeklyChartState();
}

class _WeeklyChartState extends State<_WeeklyChart> {
  bool _showIncome = true;

  List<double> _getWeeklyData(TransactionType type) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final data = List<double>.filled(7, 0);
    for (var t in widget.transactions) {
      if (t.type == type && t.date.isAfter(weekStart.subtract(const Duration(days: 1)))) {
        final dayIndex = t.date.weekday - 1;
        if (dayIndex >= 0 && dayIndex < 7) {
          data[dayIndex] += t.amount;
        }
      }
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final data = _showIncome ? _getWeeklyData(TransactionType.income) : _getWeeklyData(TransactionType.expense);
    final color = _showIncome ? SukuColors.green : SukuColors.error;
    final maxY = data.reduce((a, b) => a > b ? a : b);
    final double chartMax = maxY > 0 ? maxY * 1.2 : 1000.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SukuColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SukuColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Wiki Hii',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 15, fontWeight: FontWeight.w700, color: SukuColors.textPrimary)),
              Container(
                decoration: BoxDecoration(
                  color: SukuColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _ChartToggleBtn(
                        label: 'In',
                        active: _showIncome,
                        color: SukuColors.green,
                        onTap: () => setState(() => _showIncome = true)),
                    _ChartToggleBtn(
                        label: 'Out',
                        active: !_showIncome,
                        color: SukuColors.error,
                        onTap: () => setState(() => _showIncome = false)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                maxY: chartMax,
                minY: 0,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => SukuColors.navy,
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      'Ksh ${NumberFormat('#,##0').format(rod.toY)}',
                      GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(days[v.toInt()],
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12, color: SukuColors.textHint, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) {
                  final hasData = data[i] > 0;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: data[i],
                        width: 22,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        gradient: LinearGradient(
                          colors: hasData
                              ? [color, color.withOpacity(0.7)]
                              : [color.withOpacity(0.15), color.withOpacity(0.05)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ],
                  );
                }),
              ),
              swapAnimationDuration: const Duration(milliseconds: 400),
              swapAnimationCurve: Curves.easeInOut,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartToggleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _ChartToggleBtn({required this.label, required this.active, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13, fontWeight: FontWeight.w700, color: active ? color : SukuColors.textHint)),
      ),
    );
  }
}

// ─── Category Breakdown ────────────────────────────────────────────────────────
class _CategoryBreakdown extends StatelessWidget {
  final MonthlySummary summary;
  final bool balanceVisible;

  const _CategoryBreakdown({required this.summary, required this.balanceVisible});

  @override
  Widget build(BuildContext context) {
    final sorted = summary.byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = summary.totalExpenses;

    return Column(
      children: sorted.map((e) {
        final pct = total > 0 ? e.value / total : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: e.key.color),
                      ),
                      const SizedBox(width: 8),
                      Text(e.key.label,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13, fontWeight: FontWeight.w600, color: SukuColors.textPrimary)),
                    ],
                  ),
                  Row(
                    children: [
                      Text(balanceVisible ? 'Ksh ${NumberFormat('#,##0').format(e.value)}' : 'Ksh ••••',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13, fontWeight: FontWeight.w700, color: SukuColors.textPrimary)),
                      const SizedBox(width: 8),
                      Text('${(pct * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: SukuColors.textHint)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: e.key.color.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation(e.key.color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Transactions Tab ──────────────────────────────────────────────────────────
class _TransactionsTab extends StatefulWidget {
  final List<Transaction> transactions;
  final VoidCallback onRefresh;
  final bool hideAmount;

  const _TransactionsTab({required this.transactions, required this.onRefresh, required this.hideAmount});

  @override
  State<_TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<_TransactionsTab> {
  TransactionType? _filter;

  List<Transaction> get filtered =>
      _filter == null ? widget.transactions : widget.transactions.where((t) => t.type == _filter).toList();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Miamala Yote',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 24, fontWeight: FontWeight.w800, color: SukuColors.textPrimary, letterSpacing: -0.5)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _FilterChip(label: 'Yote', active: _filter == null, onTap: () => setState(() => _filter = null)),
                    const SizedBox(width: 8),
                    _FilterChip(
                        label: '↑ Money In',
                        active: _filter == TransactionType.income,
                        color: SukuColors.green,
                        onTap: () => setState(() => _filter = TransactionType.income)),
                    const SizedBox(width: 8),
                    _FilterChip(
                        label: '↓ Money Out',
                        active: _filter == TransactionType.expense,
                        color: SukuColors.error,
                        onTap: () => setState(() => _filter = TransactionType.expense)),
                  ],
                ),
              ],
            ),
          ),
        ),
        filtered.isEmpty
            ? SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: SukuColors.greenSurface,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(Icons.receipt_long_rounded, size: 40, color: SukuColors.green),
                        ),
                        const SizedBox(height: 16),
                        Text('Hakuna miamala bado',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 16, fontWeight: FontWeight.w700, color: SukuColors.textPrimary)),
                        const SizedBox(height: 6),
                        Text('Tap + to add your first transaction',
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: SukuColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => TransactionTile(
                      transaction: filtered[i],
                      hideAmount: widget.hideAmount,
                      onTap: () async {
                        final result = await Navigator.push(context,
                            MaterialPageRoute(builder: (_) => TransactionDetailScreen(transaction: filtered[i])));
                        if (result == true) widget.onRefresh();
                      },
                    ),
                    childCount: filtered.length,
                  ),
                ),
              ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.active, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? SukuColors.navy;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? c.withOpacity(0.12) : SukuColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? c.withOpacity(0.3) : SukuColors.border),
        ),
        child: Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13, fontWeight: FontWeight.w600, color: active ? c : SukuColors.textSecondary)),
      ),
    );
  }
}

// ─── Settings Tab ─────────────────────────────────────────────────────────────
class _SettingsTab extends StatefulWidget {
  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  String _businessName = '';
  String _location = '';
  String _accountType = 'business';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _accountType = prefs.getString('account_type') ?? 'business';
      if (_accountType == 'personal') {
        _businessName = prefs.getString('personal_name') ?? 'My Account';
        _location = prefs.getString('personal_location') ?? 'Nairobi, Kenya';
      } else {
        _businessName = prefs.getString('business_name') ?? 'My Business';
        _location = prefs.getString('location') ?? 'Nairobi, Kenya';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(LanguageService.text('accountTitle'),
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 24, fontWeight: FontWeight.w800, color: SukuColors.textPrimary, letterSpacing: -0.5)),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [SukuColors.greenSurface, SukuColors.surface]),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: SukuColors.green.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [SukuColors.green, SukuColors.greenDark]),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.store_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _businessName,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16, fontWeight: FontWeight.w700, color: SukuColors.textPrimary),
                            ),
                            if (_location.isNotEmpty)
                              Text(
                                _location,
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: SukuColors.textSecondary),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: SukuColors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                            _accountType == 'personal'
                                ? LanguageService.text('businessBadgePersonal')
                                : LanguageService.text('businessBadgeBusiness'),
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12, fontWeight: FontWeight.w700, color: SukuColors.green)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _SettingsRow(
                    label: LanguageService.text('settingsSubscription'),
                    icon: Icons.star_rounded,
                    color: SukuColors.orange,
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
                    }),
                _SettingsRow(
                    label: LanguageService.text('settingsMpesa'),
                    icon: Icons.phone_android_rounded,
                    color: SukuColors.green,
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const MpesaSettingsScreen()));
                    }),
                _SettingsRow(
                    label: LanguageService.text('settingsBusinessInfo'),
                    icon: Icons.store_rounded,
                    color: SukuColors.navy,
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessInfoScreen()));
                      _load();
                    }),
                _SettingsRow(
                    label: LanguageService.text('settingsNotifications'),
                    icon: Icons.notifications_rounded,
                    color: SukuColors.info,
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                    }),
                _SettingsRow(
                    label: LanguageService.text('settingsLanguage'),
                    icon: Icons.language_rounded,
                    color: SukuColors.catStock,
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageScreen()));
                    }),
                _SettingsRow(
                    label: LanguageService.text('settingsHelpSupport'),
                    icon: Icons.help_rounded,
                    color: SukuColors.catRent,
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
                    }),
                _SettingsRow(
                  label: 'Sign Out',
                  icon: Icons.logout_rounded,
                  color: SukuColors.error,
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Text('Sign out?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                        content: Text('You will need to verify your phone number again.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: SukuColors.textSecondary)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Cancel',
                                style: GoogleFonts.plusJakartaSans(
                                    color: SukuColors.textSecondary, fontWeight: FontWeight.w600)),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: SukuColors.error,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            child: Text('Sign Out',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await AuthService.signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                            context, MaterialPageRoute(builder: (_) => const PhoneScreen()), (_) => false);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SettingsRow({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label,
            style:
                GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: SukuColors.textPrimary)),
        trailing: const Icon(Icons.chevron_right_rounded, color: SukuColors.textHint, size: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: SukuColors.border),
        ),
        tileColor: SukuColors.surface,
        onTap: onTap,
      ),
    );
  }
}
