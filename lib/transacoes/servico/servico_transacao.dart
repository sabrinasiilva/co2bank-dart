import '../../nucleo/cliente_api.dart';
import '../../nucleo/armazenamento_token.dart';

class ItemTransacao {
  final String id;
  final String nomeEstabelecimento;
  final String rotuloCategoria;
  final double valor;
  final double co2Kg;
  final DateTime ocorreuEm;
  final String origem;
  final String? idBanco;
  final String? codigoCategoria;
  final DateTime? registradaEm;

  const ItemTransacao({
    required this.id,
    required this.nomeEstabelecimento,
    required this.rotuloCategoria,
    required this.valor,
    required this.co2Kg,
    required this.ocorreuEm,
    this.origem = 'manual',
    this.idBanco,
    this.codigoCategoria,
    this.registradaEm,
  });

  bool get importadaOpenFinance => origem == 'open_finance';

  factory ItemTransacao.fromJson(Map<String, dynamic> json) => ItemTransacao(
        id: json['id'] as String,
        nomeEstabelecimento: json['merchant_name'] as String? ?? '',
        rotuloCategoria: json['category_label'] as String? ?? 'Outros',
        valor: (json['amount'] as num).toDouble(),
        co2Kg: (json['co2_kg'] as num).toDouble(),
        ocorreuEm: DateTime.parse(json['occurred_at'] as String),
        origem: json['source'] as String? ?? 'manual',
        idBanco: json['bank_id'] as String?,
        codigoCategoria: json['merchant_category_code'] as String?,
        registradaEm: DateTime.tryParse(json['created_at'] as String? ?? ''),
      );
}

class ResumoPorCategoria {
  final String categoria;
  final double co2Kg;

  const ResumoPorCategoria({required this.categoria, required this.co2Kg});

  factory ResumoPorCategoria.fromJson(Map<String, dynamic> json) =>
      ResumoPorCategoria(
        categoria: json['category'] as String,
        co2Kg: (json['co2_kg'] as num).toDouble(),
      );
}

class ResumoMensal {
  final int mes;
  final int ano;
  final double totalCo2Kg;
  final double limiteKg;
  final double percentualUsado;
  final double totalGastoReais;
  final int quantidadeTransacoes;
  final List<ResumoPorCategoria> principaisCategorias;

  const ResumoMensal({
    required this.mes,
    required this.ano,
    required this.totalCo2Kg,
    required this.limiteKg,
    required this.percentualUsado,
    required this.totalGastoReais,
    required this.quantidadeTransacoes,
    required this.principaisCategorias,
  });

  factory ResumoMensal.fromJson(Map<String, dynamic> json) => ResumoMensal(
        mes: json['month'] as int,
        ano: json['year'] as int,
        totalCo2Kg: (json['total_co2_kg'] as num).toDouble(),
        limiteKg: (json['limit_kg'] as num).toDouble(),
        percentualUsado: (json['percentage_used'] as num).toDouble(),
        totalGastoReais: (json['total_spent_brl'] as num).toDouble(),
        quantidadeTransacoes: json['transactions_count'] as int,
        principaisCategorias: (json['top_categories'] as List)
            .map((e) => ResumoPorCategoria.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class AlertaLimite {
  final bool ativo;
  final String? mensagem;

  const AlertaLimite({required this.ativo, this.mensagem});

  factory AlertaLimite.fromJson(Map<String, dynamic> json) => AlertaLimite(
        ativo: json['alert'] as bool,
        mensagem: json['message'] as String?,
      );
}

sealed class ResultadoResumoMensal {}

class ResumoCarregado extends ResultadoResumoMensal {
  final ResumoMensal resumo;
  ResumoCarregado(this.resumo);
}

class ResumoIndisponivel extends ResultadoResumoMensal {}

sealed class ResultadoAlertaLimite {}

class AlertaCarregado extends ResultadoAlertaLimite {
  final AlertaLimite alerta;
  AlertaCarregado(this.alerta);
}

class AlertaIndisponivel extends ResultadoAlertaLimite {}

sealed class ResultadoDetalheTransacao {}

class DetalheCarregado extends ResultadoDetalheTransacao {
  final ItemTransacao transacao;
  DetalheCarregado(this.transacao);
}

class DetalheIndisponivel extends ResultadoDetalheTransacao {}

class ServicoTransacao {
  final ClienteApi _cliente;

  ServicoTransacao._(this._cliente);

  static Future<ServicoTransacao> autenticado() async {
    final cliente = ClienteApi();
    final token = await ArmazenamentoToken.obter();
    if (token != null) cliente.definirToken(token);
    return ServicoTransacao._(cliente);
  }

  Future<List<ItemTransacao>> listarTransacoes({int? mes, int? ano}) async {
    var caminho = '/transactions';
    final params = <String>[];
    if (mes != null) params.add('month=$mes');
    if (ano != null) params.add('year=$ano');
    if (params.isNotEmpty) caminho += '?${params.join('&')}';

    try {
      final resposta = await _cliente.get(caminho);
      if (!resposta.sucesso) return [];
      return resposta.listaCorpo
          .map((e) => ItemTransacao.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<ResultadoDetalheTransacao> obterTransacao(String id) async {
    try {
      final resposta = await _cliente.get('/transactions/$id');
      if (resposta.sucesso) {
        return DetalheCarregado(ItemTransacao.fromJson(resposta.corpo));
      }
      return DetalheIndisponivel();
    } catch (_) {
      return DetalheIndisponivel();
    }
  }

  Future<ResultadoResumoMensal> resumoMensal(
      {required int mes, required int ano}) async {
    try {
      final resposta =
          await _cliente.get('/summary/monthly?month=$mes&year=$ano');
      if (resposta.sucesso) {
        return ResumoCarregado(ResumoMensal.fromJson(resposta.corpo));
      }
      return ResumoIndisponivel();
    } catch (_) {
      return ResumoIndisponivel();
    }
  }

  Future<ResultadoAlertaLimite> verificarLimite() async {
    try {
      final resposta = await _cliente.post('/check-limit', {});
      if (resposta.sucesso) {
        return AlertaCarregado(AlertaLimite.fromJson(resposta.corpo));
      }
      return AlertaIndisponivel();
    } catch (_) {
      return AlertaIndisponivel();
    }
  }

  Future<ItemTransacao?> criarTransacao({
    required String nomeEstabelecimento,
    required String codigoCategoria,
    required double valor,
    DateTime? ocorreuEm,
  }) async {
    try {
      final corpo = <String, dynamic>{
        'merchant_name': nomeEstabelecimento,
        'merchant_category_code': codigoCategoria,
        'amount': valor,
        if (ocorreuEm != null) 'occurred_at': ocorreuEm.toIso8601String(),
      };
      final resposta = await _cliente.post('/transactions', corpo);
      if (resposta.sucesso) return ItemTransacao.fromJson(resposta.corpo);
      return null;
    } catch (_) {
      return null;
    }
  }
}
