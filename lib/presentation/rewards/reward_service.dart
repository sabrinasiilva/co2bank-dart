import '../../nucleo/armazenamento_token.dart';
import '../../nucleo/cliente_api.dart';
import '../../nucleo/registro_erros.dart';
import 'rewards_data.dart';

// API: conquistas (GET /rewards), saldo de CO₂Coins e parceiros (GET /rewards/tokens),
// resgate (POST /rewards/redeem) e cupons resgatados (GET /rewards/redemptions).

class TokensSummary {
  final int earned; // ganhos no mês
  final int available; // saldo para gastar (ganhos menos resgates)
  final double kgSaved;
  final List<Offer> offers;

  const TokensSummary({
    required this.earned,
    required this.available,
    required this.kgSaved,
    required this.offers,
  });

  factory TokensSummary.fromJson(Map<String, dynamic> json) {
    final earned = json['tokens_earned'] as int? ?? 0;
    return TokensSummary(
      earned: earned,
      available: json['tokens_available'] as int? ?? earned,
      kgSaved: (json['kg_saved'] as num? ?? 0).toDouble(),
      offers: (json['partners'] as List? ?? [])
          .map((p) => Offer.fromPartner(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String
  icon; // nome do ícone definido pelo backend (ex.: "eco", "shield")
  final bool earned;
  final DateTime? earnedAt;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.earned,
    this.earnedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    id: json['id'] as String? ?? '',
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    icon: json['icon'] as String? ?? '',
    earned: json['earned'] as bool? ?? false,
    earnedAt: DateTime.tryParse(json['earned_at'] as String? ?? ''),
  );
}

class AchievementsSummary {
  final int totalEarned;
  final int total;
  final List<Achievement> items;

  const AchievementsSummary({
    required this.totalEarned,
    required this.total,
    required this.items,
  });

  factory AchievementsSummary.fromJson(Map<String, dynamic> json) {
    final items = (json['rewards'] as List? ?? [])
        .map((r) => Achievement.fromJson(r as Map<String, dynamic>))
        .toList();
    return AchievementsSummary(
      totalEarned:
          json['total_earned'] as int? ?? items.where((a) => a.earned).length,
      total: json['total'] as int? ?? items.length,
      items: items,
    );
  }
}

class Redemption {
  final String id;
  final String partnerName;
  final int cost;
  final int? discountPercent; // nulo quando o parceiro não existe mais
  final String? category;
  final String? url;
  final String? couponCode;
  final DateTime? redeemedAt;

  const Redemption({
    required this.id,
    required this.partnerName,
    required this.cost,
    this.discountPercent,
    this.category,
    this.url,
    this.couponCode,
    this.redeemedAt,
  });

  factory Redemption.fromJson(Map<String, dynamic> json) => Redemption(
    id: '${json['id'] ?? ''}',
    partnerName: json['partner_name'] as String? ?? '',
    cost: json['cost'] as int? ?? 0,
    discountPercent: json['discount_percent'] as int?,
    category: json['category'] as String?,
    url: json['url'] as String?,
    couponCode: json['coupon_code'] as String?,
    redeemedAt: DateTime.tryParse(json['redeemed_at'] as String? ?? ''),
  );

  /// Mesma regra das ofertas: link de exemplo não conta como site.
  bool get hasWebsite {
    final host = Uri.tryParse(url ?? '')?.host ?? '';
    return host.isNotEmpty && !host.endsWith('example.com');
  }
}

sealed class RedemptionsResult {}

class RedemptionsLoaded extends RedemptionsResult {
  final List<Redemption> items;
  RedemptionsLoaded(this.items);
}

class RedemptionsUnavailable extends RedemptionsResult {
  /// true quando o servidor ainda não tem essa rota (404).
  final bool notDeployedYet;
  RedemptionsUnavailable({this.notDeployedYet = false});
}

sealed class AchievementsResult {}

class AchievementsLoaded extends AchievementsResult {
  final AchievementsSummary summary;
  AchievementsLoaded(this.summary);
}

class AchievementsUnavailable extends AchievementsResult {}

sealed class TokensResult {}

class TokensLoaded extends TokensResult {
  final TokensSummary summary;
  TokensLoaded(this.summary);
}

class TokensUnavailable extends TokensResult {}

sealed class RedeemResult {}

class RedeemSuccess extends RedeemResult {
  final int remaining;
  final String? couponCode;
  RedeemSuccess(this.remaining, {this.couponCode});
}

class RedeemFailed extends RedeemResult {
  final String message;
  RedeemFailed(this.message);
}

class RewardService {
  final ClienteApi _client;

  RewardService._(this._client);

  static Future<RewardService> authenticated() async {
    final client = ClienteApi();
    final token = await ArmazenamentoToken.obter();
    if (token != null) client.definirToken(token);
    return RewardService._(client);
  }

  Future<RedemptionsResult> loadRedemptions() async {
    try {
      final response = await _client.get('/rewards/redemptions');
      if (response.codigoStatus == 404) {
        return RedemptionsUnavailable(notDeployedYet: true);
      }
      if (!response.sucesso) return RedemptionsUnavailable();
      final items =
          response.listaCorpo
              .map((r) => Redemption.fromJson(r as Map<String, dynamic>))
              .toList()
            ..sort(
              (a, b) => (b.redeemedAt ?? DateTime(0)).compareTo(
                a.redeemedAt ?? DateTime(0),
              ),
            );
      return RedemptionsLoaded(items);
    } catch (e, pilha) {
      registrarErro(e, pilha, contexto: 'RewardService.loadRedemptions');
      return RedemptionsUnavailable();
    }
  }

  Future<AchievementsResult> loadAchievements() async {
    try {
      final response = await _client.get('/rewards');
      if (!response.sucesso) return AchievementsUnavailable();
      return AchievementsLoaded(AchievementsSummary.fromJson(response.corpo));
    } catch (e, pilha) {
      registrarErro(e, pilha, contexto: 'RewardService.loadAchievements');
      return AchievementsUnavailable();
    }
  }

  Future<TokensResult> loadTokens() async {
    try {
      final response = await _client.get('/rewards/tokens');
      if (!response.sucesso) return TokensUnavailable();
      return TokensLoaded(TokensSummary.fromJson(response.corpo));
    } catch (e, pilha) {
      registrarErro(e, pilha, contexto: 'RewardService.loadTokens');
      return TokensUnavailable();
    }
  }

  Future<RedeemResult> redeem(Offer offer) async {
    try {
      final response = await _client.post('/rewards/redeem', {
        'partner_name': offer.store,
      });
      if (response.sucesso) {
        return RedeemSuccess(
          response.corpo['tokens_remaining'] as int? ?? 0,
          couponCode: response.corpo['coupon_code'] as String?,
        );
      }
      return RedeemFailed(response.erro ?? 'Não foi possível resgatar agora.');
    } catch (e, pilha) {
      registrarErro(e, pilha, contexto: 'RewardService.redeem');
      return RedeemFailed('Não foi possível conectar ao servidor.');
    }
  }
}
