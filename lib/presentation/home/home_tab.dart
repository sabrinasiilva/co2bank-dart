import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../data/transaction_service.dart';
import '../../data/user_service.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late Future<_HomeData> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<_HomeData> _load() async {
    final now = DateTime.now();
    final userSvc = await UserService.authenticated();
    final txSvc = await TransactionService.authenticated();

    final user = await userSvc.getMe();
    final summary = await txSvc.monthlySummary(month: now.month, year: now.year);
    final recent = await txSvc.listTransactions(month: now.month, year: now.year);

    return _HomeData(
      user: user,
      summary: summary,
      recent: recent.take(4).toList(),
    );
  }

  void _refresh() => setState(() => _data = _load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HomeData>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final data = snapshot.data!;
        final summary = data.summary;
        final pct = (summary?.percentageUsed ?? 0) / 100;
        final arcColor = pct < 0.5
            ? AppColors.primary
            : pct < 0.8
                ? AppColors.accent
                : AppColors.accentWarm;

        final months = [
          '', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
          'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
        ];
        final now = DateTime.now();
        final monthLabel = '${months[now.month]} ${now.year}';

        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          color: AppColors.primary,
          child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _HeroCard(
                    userName: data.user?.name.split(' ').first ?? '',
                    monthLabel: monthLabel,
                    pct: pct,
                    arcColor: arcColor,
                    totalCo2: summary?.totalCo2Kg ?? 0,
                    limitKg: summary?.limitKg ?? 200,
                    percentageUsed: summary?.percentageUsed ?? 0,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _StatsRow(summary: summary),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Últimas movimentações',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                if (data.recent.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _EmptyTransactions(),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _TransactionTile(tx: data.recent[i]),
                        childCount: data.recent.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
      },
    );
  }
}

class _HomeData {
  final UserProfile? user;
  final MonthlySummary? summary;
  final List<TransactionItem> recent;

  _HomeData({required this.user, required this.summary, required this.recent});
}

class _HeroCard extends StatelessWidget {
  final String userName;
  final String monthLabel;
  final double pct;
  final Color arcColor;
  final double totalCo2;
  final double limitKg;
  final double percentageUsed;

  const _HeroCard({
    required this.userName,
    required this.monthLabel,
    required this.pct,
    required this.arcColor,
    required this.totalCo2,
    required this.limitKg,
    required this.percentageUsed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        left: 28,
        right: 28,
        bottom: 36,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName.isEmpty ? 'Olá' : 'Olá, $userName',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    monthLabel,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
              Builder(
                builder: (ctx) => GestureDetector(
                  onTap: () => Scaffold.of(ctx).openDrawer(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.menu_rounded, size: 22, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(180, 180),
                  painter: _ArcPainter(progress: pct.clamp(0.0, 1.0), color: arcColor),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${percentageUsed.toStringAsFixed(1)}%',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: arcColor,
                      ),
                    ),
                    Text(
                      'do limite',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${totalCo2.toStringAsFixed(1)} kg CO2 usados',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'de ${limitKg.toStringAsFixed(0)} kg de limite mensal',
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _ArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * progress,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress || old.color != color;
}

class _StatsRow extends StatelessWidget {
  final MonthlySummary? summary;

  const _StatsRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Gastos no mês',
            value: fmt.format(summary?.totalSpentBrl ?? 0),
            icon: Icons.payments_rounded,
            iconColor: AppColors.accentWarm,
            bgColor: const Color(0xFFFFF8EC),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Movimentações',
            value: '${summary?.transactionsCount ?? 0}',
            icon: Icons.swap_horiz_rounded,
            iconColor: AppColors.primary,
            bgColor: const Color(0xFFF0FAE8),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionItem tx;

  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_rounded, size: 20, color: AppColors.gray),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.merchantName.isEmpty ? tx.categoryLabel : tx.merchantName,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  tx.categoryLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fmt.format(tx.amount),
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${tx.co2Kg.toStringAsFixed(1)} kg CO2',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: AppColors.gray,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.receipt_long_rounded, size: 40, color: AppColors.border),
          const SizedBox(height: 12),
          Text(
            'Nenhuma movimentação este mês',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
