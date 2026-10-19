import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../nucleo/cores_app.dart';
import 'reward_service.dart';
import 'rewards_style.dart';

// CONQUISTAS: badges que a pessoa ganha usando o app (GET /rewards).

/// DESIGN: ícone de cada conquista, a partir do nome que vem do backend.
/// Para uma conquista nova com outro ícone, inclua um item aqui.
IconData achievementIcon(String name) => switch (name) {
  'foot_print' => Icons.directions_walk,
  'eco' => Icons.eco,
  'shield' => Icons.shield,
  'category' => Icons.category,
  'calendar' => Icons.calendar_month,
  _ => Icons.emoji_events,
};

/// ESTRUTURA E ESTADO: lista de conquistas com o resumo no topo.
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  AchievementsSummary? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final service = await RewardService.authenticated();
    final result = await service.loadAchievements();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result case AchievementsLoaded(:final summary)) _summary = summary;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Conquistas',
          style: RewardsStyle.font(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: RewardsStyle.action,
        foregroundColor: Colors.white,
      ),
      body: _body(),
    );
  }

  Widget _body() {
    final summary = _summary;
    if (summary == null) {
      if (_loading) {
        return const Center(
          child: CircularProgressIndicator(color: RewardsStyle.green),
        );
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: CoresApp.gray),
              const SizedBox(height: 16),
              Text(
                'Não foi possível carregar suas conquistas',
                textAlign: TextAlign.center,
                style: RewardsStyle.font(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: RewardsStyle.action,
                ),
                onPressed: _load,
                child: Text(
                  'Tentar novamente',
                  style: RewardsStyle.font(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Conquistadas primeiro, na ordem em que vieram do backend.
    final items = [
      ...summary.items.where((a) => a.earned),
      ...summary.items.where((a) => !a.earned),
    ];

    return RefreshIndicator(
      color: RewardsStyle.green,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AchievementsSummaryCard(
            earned: summary.totalEarned,
            total: summary.total,
          ),
          const SizedBox(height: 24),
          Text('Suas conquistas', style: RewardsStyle.sectionTitle),
          const SizedBox(height: 12),
          for (final a in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AchievementCard(achievement: a),
            ),
        ],
      ),
    );
  }
}

/// ESTRUTURA: cartão do topo com "X de Y conquistadas" e a barra de progresso.
class AchievementsSummaryCard extends StatelessWidget {
  final int earned;
  final int total;

  const AchievementsSummaryCard({
    super.key,
    required this.earned,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? (earned / total).clamp(0.0, 1.0) : 0.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: RewardsStyle.balanceGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: RewardsStyle.green, size: 18),
              const SizedBox(width: 6),
              Text('Suas conquistas', style: _light),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$earned de $total conquistadas',
            style: RewardsStyle.font(
              color: RewardsStyle.green,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 700),
              builder: (_, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: RewardsStyle.green.withAlpha(40),
                color: RewardsStyle.green,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            earned >= total
                ? 'Você conquistou todas!'
                : 'Faltam ${total - earned} para completar',
            style: _light,
          ),
        ],
      ),
    );
  }
}

final _light = RewardsStyle.font(color: RewardsStyle.green);

/// DESIGN: card de uma conquista. Verde quando já foi ganha, cinza quando ainda não.
class AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const AchievementCard({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    final earned = achievement.earned;
    final earnedAt = achievement.earnedAt;
    final color = earned ? RewardsStyle.green : CoresApp.gray;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: earned
            ? RewardsStyle.greenLight.withAlpha(40)
            : CoresApp.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: earned
              ? RewardsStyle.greenLight.withAlpha(120)
              : CoresApp.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: earned ? RewardsStyle.greenLight : CoresApp.border,
              shape: BoxShape.circle,
            ),
            child: Icon(
              earned ? achievementIcon(achievement.icon) : Icons.lock_outline,
              color: earned ? CoresApp.dark : CoresApp.gray,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement.title, style: RewardsStyle.storeName),
                const SizedBox(height: 2),
                Text(achievement.description, style: RewardsStyle.caption),
                const SizedBox(height: 6),
                Text(
                  earned
                      ? earnedAt == null
                            ? 'Conquistada'
                            : 'Conquistada em ${DateFormat('dd/MM/yyyy', 'pt_BR').format(earnedAt.toLocal())}'
                      : 'Ainda não conquistada',
                  style: RewardsStyle.font(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ESTRUTURA: atalho na tela de Recompensas que abre as conquistas.
class AchievementsShortcut extends StatelessWidget {
  final int? earned;
  final int? total;
  final VoidCallback onTap;

  const AchievementsShortcut({
    super.key,
    required this.earned,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final count = earned != null && total != null
        ? '$earned de $total conquistadas'
        : 'Veja as conquistas que você já ganhou';
    return Container(
      decoration: RewardsStyle.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: RewardsStyle.gold.withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.emoji_events, color: RewardsStyle.warning),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Conquistas', style: RewardsStyle.storeName),
                      Text(count, style: RewardsStyle.caption),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: CoresApp.gray),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
