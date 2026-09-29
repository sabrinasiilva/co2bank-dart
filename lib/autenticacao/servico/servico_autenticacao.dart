import '../../nucleo/cliente_api.dart';
import '../../nucleo/armazenamento_token.dart';

sealed class ResultadoLogin {}

class LoginSucesso extends ResultadoLogin {
  final String token;
  LoginSucesso(this.token);
}

class LoginErroCredenciais extends ResultadoLogin {}

class LoginErroRede extends ResultadoLogin {}

sealed class ResultadoCadastro {}

class CadastroSucesso extends ResultadoCadastro {
  final String token;
  CadastroSucesso(this.token);
}

class CadastroErro extends ResultadoCadastro {
  final String mensagem;
  CadastroErro(this.mensagem);
}

class CadastroErroRede extends ResultadoCadastro {}

sealed class ResultadoSolicitacaoCodigo {}

class CodigoEnviado extends ResultadoSolicitacaoCodigo {}

class ErroSolicitacaoCodigo extends ResultadoSolicitacaoCodigo {
  final String mensagem;
  ErroSolicitacaoCodigo(this.mensagem);
}

class ErroRedeSolicitacao extends ResultadoSolicitacaoCodigo {}

sealed class ResultadoRedefinicaoSenha {}

class SenhaRedefinida extends ResultadoRedefinicaoSenha {}

class CodigoInvalidoOuExpirado extends ResultadoRedefinicaoSenha {}

class ErroRedefinicao extends ResultadoRedefinicaoSenha {
  final String mensagem;
  ErroRedefinicao(this.mensagem);
}

class ErroRedeRedefinicao extends ResultadoRedefinicaoSenha {}

class ServicoAutenticacao {
  final ClienteApi _cliente;

  ServicoAutenticacao({ClienteApi? cliente})
      : _cliente = cliente ?? ClienteApi();

  Future<ResultadoCadastro> cadastrar({
    required String nome,
    required String email,
    required String cpf,
    required String telefone,
    required String dataNascimento,
    required String senha,
    required double limiteCo2Kg,
    String? fotoBase64,
  }) async {
    try {
      final corpo = {
        'name': nome,
        'email': email,
        'cpf': cpf,
        'phone': telefone,
        'birth_date': dataNascimento,
        'password': senha,
        'co2_limit_kg': limiteCo2Kg,
        if (fotoBase64 != null) 'face_photo': fotoBase64,
      };
      final resposta = await _cliente.post('/auth/register', corpo);
      if (resposta.sucesso) {
        final token = resposta.corpo['token'] as String;
        await ArmazenamentoToken.salvar(token);
        return CadastroSucesso(token);
      }
      return CadastroErro(resposta.erro ?? 'Erro ao criar conta');
    } catch (_) {
      return CadastroErroRede();
    }
  }

  Future<ResultadoLogin> entrar({
    required String email,
    required String senha,
  }) async {
    try {
      final resposta = await _cliente.post('/auth/login', {
        'email': email,
        'password': senha,
      });
      if (resposta.sucesso) {
        final token = resposta.corpo['token'] as String;
        await ArmazenamentoToken.salvar(token);
        return LoginSucesso(token);
      }
      return LoginErroCredenciais();
    } catch (_) {
      return LoginErroRede();
    }
  }

  Future<ResultadoSolicitacaoCodigo> solicitarCodigoRecuperacao({
    required String email,
  }) async {
    try {
      final resposta = await _cliente.post('/auth/forgot-password/request', {
        'email': email,
      });
      if (resposta.sucesso) return CodigoEnviado();
      return ErroSolicitacaoCodigo(resposta.erro ?? 'Erro ao enviar código');
    } catch (_) {
      return ErroRedeSolicitacao();
    }
  }

  Future<ResultadoRedefinicaoSenha> redefinirSenha({
    required String tokenRedefinicao,
    required String novaSenha,
  }) async {
    try {
      final resposta = await _cliente.post('/auth/reset-password', {
        'reset_token': tokenRedefinicao,
        'new_password': novaSenha,
      });
      if (resposta.sucesso) return SenhaRedefinida();
      if (resposta.codigoStatus == 401) return CodigoInvalidoOuExpirado();
      return ErroRedefinicao(resposta.erro ?? 'Erro ao redefinir senha');
    } catch (_) {
      return ErroRedeRedefinicao();
    }
  }
}
