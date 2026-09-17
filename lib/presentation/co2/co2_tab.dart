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
  final int _month = DateTime.now().month;
  final int _year = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<MonthlySummary?> _load() async {
    final svc = await TransactionService.authenticated();
    return svc.monthlySummary(month: _month, year: _year);
  }

  @override
  Widget build(BuildContext context) {
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

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Relatório de CO2',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
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
                        ),
                        childCount: summary.topCategories.length,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
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

    Color statusColor;
    String statusLabel;
    if (pct < 50) {
      statusColor = AppColors.primary;
      statusLabel = 'No limite';
    } else if (pct < 80) {
      statusColor = AppColors.accent;
      statusLabel = 'Atenção';
    } else {
      statusColor = AppColors.accentWarm;
      statusLabel = 'Limite alto';
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
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${pct.toStringAsFixed(1)}% utilizado',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategorySummary category;
  final double maxCo2;

  const _CategoryRow({required this.category, required this.maxCo2});

  @override
  Widget build(BuildContext context) {
    final pct = maxCo2 > 0 ? category.co2Kg / maxCo2 : 0.0;

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
                  color: AppColors.textPrimary,
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
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
