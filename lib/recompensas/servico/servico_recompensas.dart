import '../../nucleo/armazenamento_token.dart';
import '../../nucleo/cliente_api.dart';
import '../../nucleo/registro_erros.dart';
import '../oferta.dart';

// Rotas usadas: conquistas (GET /rewards), saldo de CO₂Coins e parceiros
// (GET /rewards/tokens), resgate (POST /rewards/redeem) e cupons resgatados
// (GET /rewards/redemptions).

class ResumoCoins {
  final int ganhos; // ganhos no mês
  final int disponiveis; // saldo para gastar (ganhos menos resgates)
  final double kgEconomizados;
  final List<Oferta> ofertas;

  const ResumoCoins({
    required this.ganhos,
    required this.disponiveis,
    required this.kgEconomizados,
    required this.ofertas,
  });

  factory ResumoCoins.fromJson(Map<String, dynamic> json) {
    final ganhos = json['tokens_earned'] as int? ?? 0;
    return ResumoCoins(
      ganhos: ganhos,
      disponiveis: json['tokens_available'] as int? ?? ganhos,
      kgEconomizados: (json['kg_saved'] as num? ?? 0).toDouble(),
      ofertas: (json['partners'] as List? ?? [])
          .map((p) => Oferta.doParceiro(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Conquista {
  final String id;
  final String titulo;
  final String descricao;
  final String
  icone; // nome do ícone definido pelo backend (ex.: "eco", "shield")
  final bool conquistada;
  final DateTime? conquistadaEm;

  const Conquista({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.conquistada,
    this.conquistadaEm,
  });

  factory Conquista.fromJson(Map<String, dynamic> json) => Conquista(
    id: json['id'] as String? ?? '',
    titulo: json['title'] as String,
    descricao: json['description'] as String? ?? '',
    icone: json['icon'] as String? ?? '',
    conquistada: json['earned'] as bool? ?? false,
    conquistadaEm: DateTime.tryParse(json['earned_at'] as String? ?? ''),
  );
}

class ResumoConquistas {
  final int totalConquistadas;
  final int total;
  final List<Conquista> itens;

  const ResumoConquistas({
    required this.totalConquistadas,
    required this.total,
    required this.itens,
  });

  factory ResumoConquistas.fromJson(Map<String, dynamic> json) {
    final itens = (json['rewards'] as List? ?? [])
        .map((r) => Conquista.fromJson(r as Map<String, dynamic>))
        .toList();
    return ResumoConquistas(
      totalConquistadas:
          json['total_earned'] as int? ??
          itens.where((c) => c.conquistada).length,
      total: json['total'] as int? ?? itens.length,
      itens: itens,
    );
  }
}

class Resgate {
  final String id;
  final String nomeParceiro;
  final int custo;
  final int? percentualDesconto; // nulo quando o parceiro não existe mais
  final String? categoria;
  final String? url;
  final String? codigoCupom;
  final DateTime? resgatadoEm;

  const Resgate({
    required this.id,
    required this.nomeParceiro,
    required this.custo,
    this.percentualDesconto,
    this.categoria,
    this.url,
    this.codigoCupom,
    this.resgatadoEm,
  });

  factory Resgate.fromJson(Map<String, dynamic> json) => Resgate(
    id: '${json['id'] ?? ''}',
    nomeParceiro: json['partner_name'] as String? ?? '',
    custo: json['cost'] as int? ?? 0,
    percentualDesconto: json['discount_percent'] as int?,
    categoria: json['category'] as String?,
    url: json['url'] as String?,
    codigoCupom: json['coupon_code'] as String?,
    resgatadoEm: DateTime.tryParse(json['redeemed_at'] as String? ?? ''),
  );

  /// Mesma regra das ofertas: link de exemplo não conta como site.
  bool get temSite {
    final host = Uri.tryParse(url ?? '')?.host ?? '';
    return host.isNotEmpty && !host.endsWith('example.com');
  }
}

sealed class ResultadoListaResgates {}

class ResgatesCarregados extends ResultadoListaResgates {
  final List<Resgate> itens;
  ResgatesCarregados(this.itens);
}

class ResgatesIndisponiveis extends ResultadoListaResgates {
  /// true quando o servidor ainda não tem essa rota (404).
  final bool rotaAindaNaoPublicada;
  ResgatesIndisponiveis({this.rotaAindaNaoPublicada = false});
}

sealed class ResultadoConquistas {}

class ConquistasCarregadas extends ResultadoConquistas {
  final ResumoConquistas resumo;
  ConquistasCarregadas(this.resumo);
}

class ConquistasIndisponiveis extends ResultadoConquistas {}

sealed class ResultadoCoins {}

class CoinsCarregados extends ResultadoCoins {
  final ResumoCoins resumo;
  CoinsCarregados(this.resumo);
}

class CoinsIndisponiveis extends ResultadoCoins {}

sealed class ResultadoResgate {}

class ResgateConcluido extends ResultadoResgate {
  final int restantes;
  final String? codigoCupom;
  ResgateConcluido(this.restantes, {this.codigoCupom});
}

class ResgateFalhou extends ResultadoResgate {
  final String mensagem;
  ResgateFalhou(this.mensagem);
}

class ServicoRecompensas {
  final ClienteApi _cliente;

  ServicoRecompensas._(this._cliente);

  static Future<ServicoRecompensas> autenticado() async {
    final cliente = ClienteApi();
    final token = await ArmazenamentoToken.obter();
    if (token != null) cliente.definirToken(token);
    return ServicoRecompensas._(cliente);
  }

  Future<ResultadoListaResgates> carregarResgates() async {
    try {
      final resposta = await _cliente.get('/rewards/redemptions');
      if (resposta.codigoStatus == 404) {
        return ResgatesIndisponiveis(rotaAindaNaoPublicada: true);
      }
      if (!resposta.sucesso) return ResgatesIndisponiveis();
      final itens =
          resposta.listaCorpo
              .map((r) => Resgate.fromJson(r as Map<String, dynamic>))
              .toList()
            ..sort(
              (a, b) => (b.resgatadoEm ?? DateTime(0)).compareTo(
                a.resgatadoEm ?? DateTime(0),
              ),
            );
      return ResgatesCarregados(itens);
    } catch (e, pilha) {
      registrarErro(e, pilha, contexto: 'ServicoRecompensas.carregarResgates');
      return ResgatesIndisponiveis();
    }
  }

  Future<ResultadoConquistas> carregarConquistas() async {
    try {
      final resposta = await _cliente.get('/rewards');
      if (!resposta.sucesso) return ConquistasIndisponiveis();
      return ConquistasCarregadas(ResumoConquistas.fromJson(resposta.corpo));
    } catch (e, pilha) {
      registrarErro(
        e,
        pilha,
        contexto: 'ServicoRecompensas.carregarConquistas',
      );
      return ConquistasIndisponiveis();
    }
  }

  Future<ResultadoCoins> carregarCoins() async {
    try {
      final resposta = await _cliente.get('/rewards/tokens');
      if (!resposta.sucesso) return CoinsIndisponiveis();
      return CoinsCarregados(ResumoCoins.fromJson(resposta.corpo));
    } catch (e, pilha) {
      registrarErro(e, pilha, contexto: 'ServicoRecompensas.carregarCoins');
      return CoinsIndisponiveis();
    }
  }

  Future<ResultadoResgate> resgatar(Oferta oferta) async {
    try {
      final resposta = await _cliente.post('/rewards/redeem', {
        'partner_name': oferta.loja,
      });
      if (resposta.sucesso) {
        return ResgateConcluido(
          resposta.corpo['tokens_remaining'] as int? ?? 0,
          codigoCupom: resposta.corpo['coupon_code'] as String?,
        );
      }
      return ResgateFalhou(resposta.erro ?? 'Não foi possível resgatar agora.');
    } catch (e, pilha) {
      registrarErro(e, pilha, contexto: 'ServicoRecompensas.resgatar');
      return ResgateFalhou('Não foi possível conectar ao servidor.');
    }
  }
}
