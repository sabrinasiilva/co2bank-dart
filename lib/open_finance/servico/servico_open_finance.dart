import '../../nucleo/cliente_api.dart';
import '../../nucleo/armazenamento_token.dart';

class ConexaoBanco {
  final String idBanco;
  final DateTime conectadoEm;
  final DateTime? ultimaSincronizacao;

  const ConexaoBanco({
    required this.idBanco,
    required this.conectadoEm,
    this.ultimaSincronizacao,
  });

  factory ConexaoBanco.fromJson(Map<String, dynamic> json) {
    final ultima = json['last_sync_at'] as String?;
    return ConexaoBanco(
      idBanco: json['bank_id'] as String,
      conectadoEm: DateTime.parse(json['connected_at'] as String),
      ultimaSincronizacao: ultima == null ? null : DateTime.parse(ultima),
    );
  }
}

sealed class ResultadoConexoes {}

class ConexoesCarregadas extends ResultadoConexoes {
  final List<ConexaoBanco> conexoes;
  ConexoesCarregadas(this.conexoes);
}

class ConexoesIndisponiveis extends ResultadoConexoes {}

sealed class ResultadoOperacaoOpenFinance {}

class OperacaoConcluida extends ResultadoOperacaoOpenFinance {}

class OperacaoErro extends ResultadoOperacaoOpenFinance {
  final String mensagem;
  OperacaoErro(this.mensagem);
}

sealed class ResultadoSincronizacao {}

class SincronizacaoConcluida extends ResultadoSincronizacao {
  final int novas;
  final int ignoradas;
  SincronizacaoConcluida({required this.novas, required this.ignoradas});
}

class SincronizacaoErro extends ResultadoSincronizacao {
  final String mensagem;
  SincronizacaoErro(this.mensagem);
}

class ServicoOpenFinance {
  final ClienteApi _cliente;

  ServicoOpenFinance._(this._cliente);

  static Future<ServicoOpenFinance> autenticado() async {
    final cliente = ClienteApi();
    final token = await ArmazenamentoToken.obter();
    if (token != null) cliente.definirToken(token);
    return ServicoOpenFinance._(cliente);
  }

  Future<ResultadoConexoes> listarConexoes() async {
    try {
      final resposta = await _cliente.get('/open-finance/connections');
      if (!resposta.sucesso) return ConexoesIndisponiveis();
      return ConexoesCarregadas(
        resposta.listaCorpo
            .map((e) => ConexaoBanco.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (_) {
      return ConexoesIndisponiveis();
    }
  }

  Future<ResultadoOperacaoOpenFinance> conectar(
    Iterable<String> idsBancos,
  ) async {
    try {
      final resposta = await _cliente.post('/open-finance/connections', {
        'bank_ids': idsBancos.toList(),
      });
      if (resposta.sucesso) return OperacaoConcluida();
      return OperacaoErro(resposta.erro ?? 'Não foi possível conectar o banco');
    } catch (_) {
      return OperacaoErro('Não foi possível conectar ao servidor');
    }
  }

  Future<ResultadoOperacaoOpenFinance> desconectar(String idBanco) async {
    try {
      final resposta = await _cliente.delete(
        '/open-finance/connections/$idBanco',
      );
      if (resposta.sucesso) return OperacaoConcluida();
      return OperacaoErro(
        resposta.erro ?? 'Não foi possível desconectar o banco',
      );
    } catch (_) {
      return OperacaoErro('Não foi possível conectar ao servidor');
    }
  }

  Future<ResultadoSincronizacao> sincronizar() async {
    try {
      final resposta = await _cliente.post('/open-finance/sync', {});
      if (resposta.sucesso) {
        return SincronizacaoConcluida(
          novas: resposta.corpo['synced'] as int? ?? 0,
          ignoradas: resposta.corpo['skipped'] as int? ?? 0,
        );
      }
      return SincronizacaoErro(
        resposta.erro ?? 'Não foi possível sincronizar agora',
      );
    } catch (_) {
      return SincronizacaoErro('Não foi possível conectar ao servidor');
    }
  }
}
