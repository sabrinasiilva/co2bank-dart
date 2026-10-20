import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:co2bank_app/autenticacao/servico/servico_autenticacao.dart';
import 'package:co2bank_app/nucleo/armazenamento_token.dart';
import 'package:co2bank_app/nucleo/cliente_api.dart';

late List<http.Request> requisicoes;

ServicoAutenticacao _servico(
  Future<http.Response> Function(http.Request) responder,
) {
  requisicoes = [];
  return ServicoAutenticacao(
    cliente: ClienteApi(
      cliente: MockClient((req) {
        requisicoes.add(req);
        return responder(req);
      }),
    ),
  );
}

http.Response _json(Object corpo, [int status = 200]) => http.Response(
      jsonEncode(corpo),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Future<ResultadoCadastro> _cadastrar(
  ServicoAutenticacao servico, {
  String? fotoBase64,
}) =>
    servico.cadastrar(
      nome: 'Sabrina',
      email: 'sabrina@exemplo.com',
      cpf: '52998224725',
      telefone: '11987654321',
      dataNascimento: '2000-01-31',
      senha: 'Senha@123',
      limiteCo2Kg: 150,
      fotoBase64: fotoBase64,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('entrar', () {
    test('sucesso devolve e salva o token', () async {
      final servico = _servico((_) async => _json({'token': 'jwt-1'}));

      final resultado =
          await servico.entrar(email: 'sabrina@exemplo.com', senha: '123');

      expect(requisicoes.single.url.path, '/auth/login');
      expect(jsonDecode(requisicoes.single.body),
          {'email': 'sabrina@exemplo.com', 'password': '123'});
      expect((resultado as LoginSucesso).token, 'jwt-1');
      expect(await ArmazenamentoToken.obter(), 'jwt-1');
    });

    test('401 é erro de credenciais e não salva token', () async {
      final servico =
          _servico((_) async => _json({'error': 'Senha incorreta'}, 401));

      final resultado = await servico.entrar(email: 'a@b.com', senha: 'x');

      expect(resultado, isA<LoginErroCredenciais>());
      expect(await ArmazenamentoToken.obter(), isNull);
    });

    test('sem internet é erro de rede', () async {
      final servico =
          _servico((_) async => throw http.ClientException('offline'));
      expect(await servico.entrar(email: 'a@b.com', senha: 'x'),
          isA<LoginErroRede>());
    });

    test('sucesso sem token na resposta vira erro de rede', () async {
      // O cast para String falha e cai no catch genérico.
      final servico = _servico((_) async => _json({}));
      expect(await servico.entrar(email: 'a@b.com', senha: 'x'),
          isA<LoginErroRede>());
    });
  });

  group('cadastrar', () {
    test('manda os campos e não inclui face_photo quando não há foto',
        () async {
      final servico = _servico((_) async => _json({'token': 'jwt-2'}, 201));

      final resultado = await _cadastrar(servico);

      expect(requisicoes.single.url.path, '/auth/register');
      expect(jsonDecode(requisicoes.single.body), {
        'name': 'Sabrina',
        'email': 'sabrina@exemplo.com',
        'cpf': '52998224725',
        'phone': '11987654321',
        'birth_date': '2000-01-31',
        'password': 'Senha@123',
        'co2_limit_kg': 150.0,
      });
      expect((resultado as CadastroSucesso).token, 'jwt-2');
      expect(await ArmazenamentoToken.obter(), 'jwt-2');
    });

    test('inclui face_photo quando há foto', () async {
      final servico = _servico((_) async => _json({'token': 'jwt-2'}, 201));

      await _cadastrar(servico, fotoBase64: 'aGVsbG8=');

      expect(jsonDecode(requisicoes.single.body)['face_photo'], 'aGVsbG8=');
    });

    test('erro usa a mensagem do servidor ou uma padrão', () async {
      var resultado = await _cadastrar(_servico(
          (_) async => _json({'error': 'E-mail já cadastrado'}, 409)));
      expect((resultado as CadastroErro).mensagem, 'E-mail já cadastrado');

      resultado = await _cadastrar(_servico((_) async => _json({}, 500)));
      expect((resultado as CadastroErro).mensagem, 'Erro ao criar conta');
    });

    test('sem internet', () async {
      final resultado = await _cadastrar(
          _servico((_) async => throw http.ClientException('offline')));
      expect(resultado, isA<CadastroErroRede>());
    });
  });

  group('recuperação de senha', () {
    test('solicitar código', () async {
      var servico = _servico((_) async => _json({}));
      expect(
        await servico.solicitarCodigoRecuperacao(email: 'a@b.com'),
        isA<CodigoEnviado>(),
      );
      expect(requisicoes.single.url.path, '/auth/forgot-password/request');

      servico = _servico((_) async => _json({'error': 'Não encontrado'}, 404));
      final erro = await servico.solicitarCodigoRecuperacao(email: 'a@b.com');
      expect((erro as ErroSolicitacaoCodigo).mensagem, 'Não encontrado');
    });

    test('redefinir senha', () async {
      var servico = _servico((_) async => _json({}));
      expect(
        await servico.redefinirSenha(tokenRedefinicao: 't', novaSenha: 'n'),
        isA<SenhaRedefinida>(),
      );
      expect(jsonDecode(requisicoes.single.body),
          {'reset_token': 't', 'new_password': 'n'});

      servico = _servico((_) async => _json({'error': 'expirado'}, 401));
      expect(
        await servico.redefinirSenha(tokenRedefinicao: 't', novaSenha: 'n'),
        isA<CodigoInvalidoOuExpirado>(),
      );

      servico = _servico((_) async => _json({'error': 'Senha fraca'}, 400));
      final erro =
          await servico.redefinirSenha(tokenRedefinicao: 't', novaSenha: 'n');
      expect((erro as ErroRedefinicao).mensagem, 'Senha fraca');
    });
  });
}
