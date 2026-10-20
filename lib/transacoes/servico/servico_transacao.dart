import '../../nucleo/cliente_api.dart';
import '../../nucleo/armazenamento_token.dart';
import '../../nucleo/notificacoes.dart';
import '../../nucleo/registro_erros.dart';

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

class ResumoDoMes {
  final int mes;
  final int ano;

  /// Nulo quando não deu para carregar aquele mês.
  final ResumoMensal? resumo;

  const ResumoDoMes({required this.mes, required this.ano, this.resumo});
}

class CategoriaCompra {
  final String codigo; // MCC usado no cálculo do backend
  final String rotulo;

  /// CO2 a cada R$ 100 nessa categoria. Nulo quando a lista veio da reserva local.
  final double? kgPor100;

  const CategoriaCompra({
    required this.codigo,
    required this.rotulo,
    this.kgPor100,
  });

  factory CategoriaCompra.fromJson(Map<String, dynamic> json) =>
      CategoriaCompra(
        codigo: json['mcc'] as String,
        rotulo: json['label'] as String,
        kgPor100: (json['kg_per_100_brl'] as num?)?.toDouble(),
      );
}

// Reserva para quando o GET /transactions/categories ainda não está no ar:
// MCCs que o backend já conhece, para dar para registrar compra mesmo assim.
const categoriasDeReserva = [
  CategoriaCompra(codigo: '5541', rotulo: 'Combustível'),
  CategoriaCompra(codigo: '8220', rotulo: 'Educação'),
  CategoriaCompra(codigo: '5732', rotulo: 'Eletrônicos'),
  CategoriaCompra(codigo: '5912', rotulo: 'Farmácia'),
  CategoriaCompra(codigo: '5699', rotulo: 'Moda'),
  CategoriaCompra(codigo: '5812', rotulo: 'Restaurante'),
  CategoriaCompra(codigo: '5815', rotulo: 'Streaming'),
  CategoriaCompra(codigo: '5411', rotulo: 'Supermercado'),
  CategoriaCompra(codigo: '4121', rotulo: 'Transporte'),
];

class EstimativaCompra {
  final String rotuloCategoria;
  final double co2Kg;
  final double totalMesKg;
  final double limiteKg;
  final double percentualAntes;
  final double percentualDepois;
  final bool passaDoLimite;

  const EstimativaCompra({
    required this.rotuloCategoria,
    required this.co2Kg,
    required this.totalMesKg,
    required this.limiteKg,
    required this.percentualAntes,
    required this.percentualDepois,
    required this.passaDoLimite,
  });

  factory EstimativaCompra.fromJson(Map<String, dynamic> json) {
    final depois = (json['percentage_after'] as num).toDouble();
    return EstimativaCompra(
      rotuloCategoria: json['category_label'] as String? ?? '',
      co2Kg: (json['co2_kg'] as num).toDouble(),
      totalMesKg: (json['month_total_co2_kg'] as num? ?? 0).toDouble(),
      limiteKg: (json['limit_kg'] as num).toDouble(),
      percentualAntes: (json['percentage_before'] as num).toDouble(),
      percentualDepois: depois,
      passaDoLimite: json['exceeds_limit'] as bool? ?? depois > 100,
    );
  }
}

sealed class ResultadoCategorias {}

class CategoriasCarregadas extends ResultadoCategorias {
  final List<CategoriaCompra> categorias;
  CategoriasCarregadas(this.categorias);
}

class CategoriasDeReserva extends ResultadoCategorias {}

sealed class ResultadoEstimativa {}

class EstimativaCalculada extends ResultadoEstimativa {
  final EstimativaCompra estimativa;
  EstimativaCalculada(this.estimativa);
}

class EstimativaErro extends ResultadoEstimativa {
  final String mensagem;
  EstimativaErro(this.mensagem);
}

sealed class ResultadoNovaTransacao {}

class TransacaoRegistrada extends ResultadoNovaTransacao {
  final ItemTransacao transacao;
  TransacaoRegistrada(this.transacao);
}

class RegistroErro extends ResultadoNovaTransacao {
  final String mensagem;
  RegistroErro(this.mensagem);
}

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
    } catch (e, pilha) {
      registrarErro(e, pilha, contexto: 'ServicoTransacao.listarTransacoes');
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
    } catch (e, pilha) {
      registrarErro(e, pilha, contexto: 'ServicoTransacao.obterTransacao');
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
    } catch (e, pilha) {
      registrarErro(e, pilha, contexto: 'ServicoTransacao.resumoMensal');
      return ResumoIndisponivel();
    }
  }

  /// Resumos dos [quantidade] meses que terminam em [mes]/[ano], do mais antigo
  /// para o mais recente. As chamadas são feitas em paralelo.
  Future<List<ResumoDoMes>> resumosDosUltimosMeses({
    required int mes,
    required int ano,
    int quantidade = 6,
  }) {
    final meses = [
      for (var i = quantidade - 1; i >= 0; i--) DateTime(ano, mes - i),
    ];
    return Future.wait(meses.map((data) async {
      final resultado = await resumoMensal(mes: data.month, ano: data.year);
      return ResumoDoMes(
        mes: data.month,
        ano: data.year,
        resumo: switch (resultado) {
          ResumoCarregado(:final resumo) => resumo,
          ResumoIndisponivel() => null,
        },
      );
    }));
  }

  /// Consulta o alerta do limite e, se ele estiver ativo, avisa no celular
  /// (no máximo uma vez por mês, e só se a pessoa ligou as notificações).
  Future<void> avisarSeLimiteAlto() async {
    final resultado = await verificarLimite();
    if (resultado case AlertaCarregado(:final alerta)
        when alerta.ativo && alerta.mensagem != null) {
      await Notificacoes.avisarLimite(alerta.mensagem!);
    }
  }

  Future<ResultadoAlertaLimite> verificarLimite() async {
    try {
      final resposta = await _cliente.post('/check-limit', {});
      if (resposta.sucesso) {
        return AlertaCarregado(AlertaLimite.fromJson(resposta.corpo));
      }
      return AlertaIndisponivel();
    } catch (e, pilha) {
      registrarErro(e, pilha, contexto: 'ServicoTransacao.verificarLimite');
      return AlertaIndisponivel();
    }
  }

  Future<ResultadoCategorias> listarCategorias() async {
    try {
      final resposta = await _cliente.get('/transactions/categories');
      if (!resposta.sucesso || resposta.listaCorpo.isEmpty) {
        return CategoriasDeReserva();
      }
      return CategoriasCarregadas(resposta.listaCorpo
          .map((e) => CategoriaCompra.fromJson(e as Map<String, dynamic>))
          .toList());
    } catch (e, pilha) {
      registrarErro(e, pilha, contexto: 'ServicoTransacao.listarCategorias');
      return CategoriasDeReserva();
    }
  }

  Future<ResultadoEstimativa> estimarCompra({
    required String codigoCategoria,
    required double valor,
  }) async {
    try {
      final resposta = await _cliente.post('/transactions/estimate', {
        'merchant_category_code': codigoCategoria,
        'amount': valor,
      });
      if (resposta.sucesso) {
        return EstimativaCalculada(EstimativaCompra.fromJson(resposta.corpo));
      }
      if (resposta.codigoStatus == 404) {
        return EstimativaErro('O simulador ainda não está disponível no servidor.');
      }
      return EstimativaErro(resposta.erro ?? 'Não foi possível simular agora.');
    } catch (e, pilha) {
      registrarErro(e, pilha, contexto: 'ServicoTransacao.estimarCompra');
      return EstimativaErro('Não foi possível conectar ao servidor.');
    }
  }

  Future<ResultadoNovaTransacao> criarTransacao({
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
      if (resposta.sucesso) {
        return TransacaoRegistrada(ItemTransacao.fromJson(resposta.corpo));
      }
      return RegistroErro(
          resposta.erro ?? 'Não foi possível registrar a compra.');
    } catch (e, pilha) {
      registrarErro(e, pilha, contexto: 'ServicoTransacao.criarTransacao');
      return RegistroErro('Não foi possível conectar ao servidor.');
    }
  }
}
