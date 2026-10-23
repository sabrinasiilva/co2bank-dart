import '../../nucleo/armazenamento_token.dart';
import '../../nucleo/cliente_api.dart';
import '../../nucleo/registro_erros.dart';

/// Notificação da central do sininho: alerta da IA, conquista, cupom
/// resgatado ou resumo da semana. Vem do GET /notifications.
class ItemNotificacao {
  final String id;
  final String tipo;
  final String titulo;
  final String corpo;
  final Map<String, dynamic> dados;
  final DateTime criadaEm;
  final bool lida;

  const ItemNotificacao({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.corpo,
    required this.dados,
    required this.criadaEm,
    required this.lida,
  });

  factory ItemNotificacao.fromJson(Map<String, dynamic> json) => ItemNotificacao(
        id: '${json['id']}',
        tipo: json['type'] as String? ?? '',
        titulo: json['title'] as String? ?? '',
        corpo: json['body'] as String? ?? '',
        dados: json['data'] is Map<String, dynamic>
            ? json['data'] as Map<String, dynamic>
            : const {},
        criadaEm: DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
            DateTime.now(),
        lida: json['read'] as bool? ?? false,
      );
}

class CentralNotificacoes {
  final List<ItemNotificacao> itens;
  final int naoLidas;

  const CentralNotificacoes({required this.itens, required this.naoLidas});

  static const vazia = CentralNotificacoes(itens: [], naoLidas: 0);
}

class ServicoNotificacoes {
  final ClienteApi _cliente;

  ServicoNotificacoes._(this._cliente);

  static Future<ServicoNotificacoes> autenticado() async {
    final cliente = ClienteApi();
    final token = await ArmazenamentoToken.obter();
    if (token != null) cliente.definirToken(token);
    return ServicoNotificacoes._(cliente);
  }

  /// Enquanto o backend não tiver a rota (404) ou sem rede, a central fica
  /// vazia, e o sininho mostra só o aviso de versão nova.
  Future<CentralNotificacoes> carregar() async {
    try {
      final resposta = await _cliente.get('/notifications?limit=50');
      if (!resposta.sucesso) return CentralNotificacoes.vazia;
      final itens = (resposta.corpo['items'] as List? ?? [])
          .map((e) => ItemNotificacao.fromJson(e as Map<String, dynamic>))
          .toList();
      return CentralNotificacoes(
        itens: itens,
        naoLidas: resposta.corpo['unread_count'] as int? ??
            itens.where((n) => !n.lida).length,
      );
    } catch (e, pilha) {
      registrarErro(e, pilha, contexto: 'ServicoNotificacoes.carregar');
      return CentralNotificacoes.vazia;
    }
  }

  Future<void> marcarTodasComoLidas() async {
    try {
      await _cliente.post('/notifications/read-all', {});
    } catch (e, pilha) {
      registrarErro(e, pilha, contexto: 'ServicoNotificacoes.marcarTodasComoLidas');
    }
  }
}
