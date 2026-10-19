import 'package:flutter/material.dart';
import '../../nucleo/cores_app.dart';
import 'achievements_screen.dart';
import 'coupons_screen.dart';
import 'reward_service.dart';
import 'rewards_data.dart';
import 'rewards_header.dart';
import 'rewards_offers.dart';
import 'rewards_style.dart';

/// ESTRUTURA E ESTADO: saldo e parceiros vindos do backend, busca e resgate.
class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final _search = TextEditingController();
  RewardService? _service;
  TokensSummary? _summary;
  AchievementsSummary? _achievements;
  int? _couponsCount;
  bool _loading = true;
  bool _failed = false;
  bool _redeeming = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    _service ??= await RewardService.authenticated();
    final (result, achievements, redemptions) = await (
      _service!.loadTokens(),
      _service!.loadAchievements(),
      _service!.loadRedemptions(),
    ).wait;
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (achievements case AchievementsLoaded(:final summary)) {
        _achievements = summary;
      }
      if (redemptions case RedemptionsLoaded(:final items)) {
        _couponsCount = items.length;
      }
      switch (result) {
        case TokensLoaded(:final summary):
          _summary = summary;
        case TokensUnavailable():
          _failed = true;
      }
    });
  }

  Future<void> _openCoupons({String? highlightCode}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CouponsScreen(highlightCode: highlightCode),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _openAchievements() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AchievementsScreen()),
    );
    if (mounted) await _load();
  }

  Future<void> _open(Offer offer) async {
    final ok = await RewardsLogic.openStore(offer);
    if (!ok && mounted) {
      showRewardsSnack(context, 'Não foi possível abrir ${offer.store}.');
    }
  }

  Future<void> _redeem(Offer offer) async {
    if (_redeeming) return;
    final confirmed = await confirmRedeem(context, offer);
    if (!confirmed || !mounted) return;

    setState(() => _redeeming = true);
    final result = await _service!.redeem(offer);
    if (!mounted) return;
    setState(() => _redeeming = false);

    switch (result) {
      case RedeemSuccess(:final couponCode):
        showRewardsSnack(
          context,
          couponCode == null
              ? 'Cupom da ${offer.store} resgatado!'
              : 'Cupom da ${offer.store} resgatado: $couponCode',
          action: SnackBarAction(
            label: 'Ver cupom',
            onPressed: () => _openCoupons(highlightCode: couponCode),
          ),
        );
        await _load();
      case RedeemFailed(:final message):
        showRewardsSnack(context, message);
        await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Shopping Verde',
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
      return _LoadError(onRetry: _load);
    }

    // Enquanto um resgate está em andamento, o saldo vai a zero na tela para
    // nenhum outro botão de "Resgatar" ficar ativo ao mesmo tempo.
    final balance = _redeeming ? 0 : summary.available;
    final offers = RewardsLogic.filter(summary.offers, _query);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: RefreshIndicator(
        color: RewardsStyle.green,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            BalanceCard(
              balance: summary.available,
              earned: summary.earned,
              kgSaved: summary.kgSaved,
            ),
            if (_failed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Não deu para atualizar o saldo agora. Puxe para baixo para tentar de novo.',
                  style: RewardsStyle.font(color: RewardsStyle.warning),
                ),
              ),
            const SizedBox(height: 12),
            AchievementsShortcut(
              earned: _achievements?.totalEarned,
              total: _achievements?.total,
              onTap: _openAchievements,
            ),
            const SizedBox(height: 12),
            CouponsShortcut(count: _couponsCount, onTap: _openCoupons),
            const SizedBox(height: 20),
            SearchBox(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 24),
            Text('Descontos em Parceiros', style: RewardsStyle.sectionTitle),
            const SizedBox(height: 12),
            if (offers.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    'Nenhum parceiro encontrado',
                    style: RewardsStyle.caption,
                  ),
                ),
              ),
            for (final o in offers)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OfferCard(
                  offer: o,
                  balance: balance,
                  onOpen: () => _open(o),
                  onRedeem: () => _redeem(o),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// ESTRUTURA: aviso quando não dá para carregar o saldo e os parceiros.
class _LoadError extends StatelessWidget {
  final VoidCallback onRetry;

  const _LoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: CoresApp.gray),
            const SizedBox(height: 16),
            Text(
              'Não foi possível carregar suas recompensas',
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
              onPressed: onRetry,
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
}
