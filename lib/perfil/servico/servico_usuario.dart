import '../../nucleo/cliente_api.dart';
import '../../nucleo/armazenamento_token.dart';

class PerfilUsuario {
  final String id;
  final String nome;
  final String email;
  final String cpf;
  final String telefone;
  final double limiteCo2Kg;

  const PerfilUsuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.cpf,
    required this.telefone,
    required this.limiteCo2Kg,
  });

  factory PerfilUsuario.fromJson(Map<String, dynamic> json) => PerfilUsuario(
        id: json['id'] as String,
        nome: json['name'] as String,
        email: json['email'] as String,
        cpf: json['cpf'] as String,
        telefone: json['phone'] as String? ?? '',
        limiteCo2Kg: (json['co2_limit_kg'] as num).toDouble(),
      );
}

sealed class ResultadoPerfil {}

class PerfilCarregado extends ResultadoPerfil {
  final PerfilUsuario perfil;
  PerfilCarregado(this.perfil);
}

class PerfilIndisponivel extends ResultadoPerfil {}

class ServicoUsuario {
  final ClienteApi _cliente;

  ServicoUsuario._(this._cliente);

  static Future<ServicoUsuario> autenticado() async {
    final cliente = ClienteApi();
    final token = await ArmazenamentoToken.obter();
    if (token != null) cliente.definirToken(token);
    return ServicoUsuario._(cliente);
  }

  Future<ResultadoPerfil> obterPerfil() async {
    try {
      final resposta = await _cliente.get('/auth/me');
      if (resposta.sucesso) {
        return PerfilCarregado(PerfilUsuario.fromJson(resposta.corpo));
      }
      return PerfilIndisponivel();
    } catch (_) {
      return PerfilIndisponivel();
    }
  }
}
