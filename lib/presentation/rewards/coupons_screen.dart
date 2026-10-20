import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../nucleo/cores_app.dart';
import '../../nucleo/registro_erros.dart';
import 'reward_service.dart';
import 'rewards_offers.dart';
import 'rewards_style.dart';

// CUPONS: descontos já resgatados, com o código para usar na loja (GET /rewards/redemptions).

/// ESTRUTURA E ESTADO: lista dos cupons resgatados.
/// [highlightCode] destaca o cupom que acabou de ser resgatado.
class CouponsScreen extends StatefulWidget {
  final String? highlightCode;

  const CouponsScreen({super.key, this.highlightCode});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  RedemptionsResult? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = await RewardService.authenticated();
    final result = await service.loadRedemptions();
    if (mounted) setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.background,
      appBar: AppBar(
        title: Text(
          'Meus cupons',
          style: RewardsStyle.font(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: RewardsStyle.action,
        foregroundColor: Colors.white,
      ),
      body: switch (_result) {
        null => const Center(
          child: CircularProgressIndicator(color: RewardsStyle.green),
        ),
        RedemptionsUnavailable(:final notDeployedYet) => _Message(
          icon: Icons.cloud_off,
          title: notDeployedYet
              ? 'Os cupons vão aparecer aqui em breve'
              : 'Não foi possível carregar seus cupons',
          text: notDeployedYet
              ? 'Seus resgates estão guardados. Eles aparecem nesta tela assim que o servidor for atualizado.'
              : 'Confira sua conexão e tente de novo.',
          onRetry: _load,
        ),
        RedemptionsLoaded(:final items) when items.isEmpty => const _Message(
          icon: Icons.local_offer_outlined,
          title: 'Você ainda não resgatou nenhum cupom',
          text:
              'Fique abaixo do limite de CO₂ do mês para ganhar CO₂Coins e troque por desconto nos parceiros.',
        ),
        RedemptionsLoaded(:final items) => RefreshIndicator(
          color: RewardsStyle.green,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final r in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CouponCard(
                    redemption: r,
                    highlighted:
                        r.couponCode != null &&
                        r.couponCode == widget.highlightCode,
                  ),
                ),
            ],
          ),
        ),
      },
    );
  }
}

/// DESIGN: card de um cupom, com o código, copiar e abrir a loja.
class CouponCard extends StatelessWidget {
  final Redemption redemption;
  final bool highlighted;

  const CouponCard({
    super.key,
    required this.redemption,
    this.highlighted = false,
  });

  Future<void> _copy(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (context.mounted) showRewardsSnack(context, 'Código copiado');
  }

  Future<void> _openStore(BuildContext context) async {
    var ok = false;
    try {
      ok = await launchUrl(Uri.parse(redemption.url!));
    } catch (e, pilha) {
      registrarErro(e, pilha, contexto: 'CouponCard._openStore');
    }
    if (!ok && context.mounted) {
      showRewardsSnack(
        context,
        'Não foi possível abrir ${redemption.partnerName}.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = redemption.couponCode;
    final redeemedAt = redemption.redeemedAt;
    final discount = redemption.discountPercent;

    return Container(
      decoration: RewardsStyle.cardDecoration.copyWith(
        border: Border.all(
          color: highlighted ? RewardsStyle.greenLight : CoresApp.border,
          width: highlighted ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(redemption.partnerName, style: RewardsStyle.storeName),
                    Text(
                      [
                        if (redeemedAt != null)
                          'Resgatado em ${DateFormat('dd/MM/yyyy', 'pt_BR').format(redeemedAt.toLocal())}',
                        '${redemption.cost} CO₂Coins',
                      ].join(' · '),
                      style: RewardsStyle.caption,
                    ),
                  ],
                ),
              ),
              if (discount != null) DiscountBadge(percent: discount),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
            decoration: BoxDecoration(
              color: CoresApp.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CoresApp.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    code ?? 'Código disponível em breve',
                    style: RewardsStyle.font(
                      fontSize: code == null ? 13 : 17,
                      fontWeight: code == null
                          ? FontWeight.normal
                          : FontWeight.bold,
                      color: code == null
                          ? CoresApp.textSecondary
                          : CoresApp.textPrimary,
                    ).copyWith(letterSpacing: code == null ? 0 : 1.5),
                  ),
                ),
                if (code != null)
                  IconButton(
                    tooltip: 'Copiar código',
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    color: RewardsStyle.green,
                    onPressed: () => _copy(context, code),
                  ),
              ],
            ),
          ),
          if (redemption.hasWebsite) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: RewardsStyle.green,
                ),
                onPressed: () => _openStore(context),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(
                  'Abrir loja',
                  style: RewardsStyle.font(
                    fontWeight: FontWeight.w600,
                    color: RewardsStyle.green,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ESTRUTURA: mensagem de lista vazia ou de erro.
class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final VoidCallback? onRetry;

  const _Message({
    required this.icon,
    required this.title,
    required this.text,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: CoresApp.gray),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: RewardsStyle.font(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              text,
              textAlign: TextAlign.center,
              style: RewardsStyle.caption,
            ),
            if (onRetry != null) ...[
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
          ],
        ),
      ),
    );
  }
}

/// ESTRUTURA: atalho na tela de Recompensas que abre os cupons.
class CouponsShortcut extends StatelessWidget {
  final int? count;
  final VoidCallback onTap;

  const CouponsShortcut({super.key, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final count = this.count;
    final subtitle = switch (count) {
      null => 'Veja os descontos que você já resgatou',
      0 => 'Nenhum cupom resgatado ainda',
      1 => '1 cupom resgatado',
      _ => '$count cupons resgatados',
    };
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
                    color: RewardsStyle.greenLight.withAlpha(60),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_offer_outlined,
                    color: RewardsStyle.green,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Meus cupons', style: RewardsStyle.storeName),
                      Text(subtitle, style: RewardsStyle.caption),
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
