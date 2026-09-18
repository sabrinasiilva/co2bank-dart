import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../data/transaction_service.dart';

class Co2Tab extends StatefulWidget {
  const Co2Tab({super.key});

  @override
  State<Co2Tab> createState() => _Co2TabState();
}

class _Co2TabState extends State<Co2Tab> {
  late Future<MonthlySummary?> _data;
  late int _month;
  late int _year;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
    _data = _load();
  }

  Future<MonthlySummary?> _load() async {
    final svc = await TransactionService.authenticated();
    return svc.monthlySummary(month: _month, year: _year);
  }

  void _changeMonth(int delta) {
    final candidate = DateTime(_year, _month + delta);
    final now = DateTime.now();
    if (candidate.isAfter(DateTime(now.year, now.month))) return;
    setState(() {
      _month = candidate.month;
      _year = candidate.year;
      _data = _load();
    });
  }

  void _refresh() => setState(() => _data = _load());

  @override
  Widget build(BuildContext context) {
    final months = [
      '', 'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];

    final now = DateTime.now();
    final isCurrentMonth = _month == now.month && _year == now.year;

    return SafeArea(
      child: FutureBuilder<MonthlySummary?>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final summary = snapshot.data;

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            color: AppColors.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Text(
                          'Relatório de CO2',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        _MonthSelector(
                          label: '${months[_month]} $_year',
                          onPrev: () => _changeMonth(-1),
                          onNext: isCurrentMonth ? null : () => _changeMonth(1),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _SummaryCard(summary: summary),
                  ),
                ),
                if (summary != null && summary.topCategories.isNotEmpty) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'Por categoria',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _CategoryRow(
                          category: summary.topCategories[i],
                          maxCo2: summary.topCategories.first.co2Kg,
                          rank: i,
                        ),
                        childCount: summary.topCategories.length,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final String label;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  const _MonthSelector({
    required this.label,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 20),
            onPressed: onPrev,
            color: AppColors.textSecondary,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: onNext != null ? AppColors.textSecondary : AppColors.border,
            ),
            onPressed: onNext,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final MonthlySummary? summary;

  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final total = summary?.totalCo2Kg ?? 0.0;
    final limit = summary?.limitKg ?? 200.0;
    final pct = summary?.percentageUsed ?? 0.0;

    final Color statusColor;
    final String statusLabel;
    if (pct < 50) {
      statusColor = AppColors.primary;
      statusLabel = 'Ótimo';
    } else if (pct < 80) {
      statusColor = AppColors.accent;
      statusLabel = 'Atenção';
    } else if (pct < 100) {
      statusColor = AppColors.accentWarm;
      statusLabel = 'Limite alto';
    } else {
      statusColor = Colors.red.shade400;
      statusLabel = 'Ultrapassado';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(20),
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
                    '${total.toStringAsFixed(1)} kg CO2',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'de ${limit.toStringAsFixed(0)} kg de limite',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (pct > 100)
                Row(
                  children: [
                    Icon(Icons.warning_rounded, size: 13, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      'Limite ultrapassado!',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              else
                const SizedBox(),
              Text(
                '${pct.toStringAsFixed(1)}% utilizado',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategorySummary category;
  final double maxCo2;
  final int rank;

  const _CategoryRow({
    required this.category,
    required this.maxCo2,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final pct = maxCo2 > 0 ? category.co2Kg / maxCo2 : 0.0;

    final Color barColor;
    if (rank == 0) {
      barColor = AppColors.accentWarm;
    } else if (rank == 1) {
      barColor = AppColors.accent;
    } else {
      barColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category.category,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${category.co2Kg.toStringAsFixed(1)} kg',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}
