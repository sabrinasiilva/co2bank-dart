import '../../nucleo/cliente_api.dart';
import '../../nucleo/armazenamento_token.dart';
import '../../nucleo/registro_erros.dart';

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

// Classes de resultado para a edição de perfil 
sealed class ResultadoAtualizacaoPerfil {}

class PerfilAtualizado extends ResultadoAtualizacaoPerfil {}

class ErroMensagemPerfil extends ResultadoAtualizacaoPerfil {
  final String mensagem;
  ErroMensagemPerfil(this.mensagem);
}

class ErroRedePerfil extends ResultadoAtualizacaoPerfil {}

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
    } catch (e, pilha) {
      registrarErro(e, pilha, contexto: 'ServicoUsuario.obterPerfil');
      return PerfilIndisponivel();
    }
  }
  // Método para atualizar o perfil via PATCH
  Future<ResultadoAtualizacaoPerfil> atualizarPerfil({
    String? nome,
    String? telefone,
    int? limite,
  }) async {
    try {
      final corpo = <String, dynamic>{};
      if (nome != null) corpo['name'] = nome;
      if (telefone != null) corpo['phone'] = telefone;
      if (limite != null) corpo['co2_limit_kg'] = limite;

      final resposta = await _cliente.patch('/auth/me', corpo);

      if (resposta.sucesso) {
        return PerfilAtualizado();
      } else if (resposta.codigoStatus == 400) {
        final mensagem = resposta.erro ?? 'Dados inválidos';
        return ErroMensagemPerfil(mensagem);
      } else {
        return ErroRedePerfil();
      }
    } catch (e, pilha) {
      registrarErro(e, pilha, contexto: 'ServicoUsuario.atualizarPerfil');
      return ErroRedePerfil();
    }
  }
}