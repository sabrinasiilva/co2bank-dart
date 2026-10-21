import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:co2bank_app/transacoes/servico/servico_transacao.dart';

// O ServicoTransacao cria o próprio ClienteApi (que chama http.Client()), então
// o MockClient entra pelo http.runWithClient, sem mudar nada no app.

late List<http.Request> requisicoes;

Future<ServicoTransacao> _servico(
  Future<http.Response> Function(http.Request) responder,
) {
  requisicoes = [];
  return http.runWithClient(
    ServicoTransacao.autenticado,
    () => MockClient((req) {
      requisicoes.add(req);
      return responder(req);
    }),
  );
}

http.Response _json(Object corpo, [int status = 200]) => http.Response(
      jsonEncode(corpo),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Map<String, dynamic> _transacaoJson(String id) => {
      'id': id,
      'merchant_name': 'Mercado $id',
      'category_label': 'Supermercado',
      'amount': 100,
      'co2_kg': 5.2,
      'occurred_at': '2026-03-10T10:00:00',
    };

Map<String, dynamic> _resumoJson(int mes, int ano) => {
      'month': mes,
      'year': ano,
      'total_co2_kg': 100,
      'limit_kg': 200,
      'percentage_used': 50,
      'total_spent_brl': 1000,
      'transactions_count': 4,
      'top_categories': [],
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': 'token-salvo'});
  });

  group('autenticado', () {
    test('usa o token salvo', () async {
      final servico = await _servico((_) async => _json([]));
      await servico.listarTransacoes();
      expect(requisicoes.single.headers['Authorization'], 'Bearer token-salvo');
    });

    test('sem token salvo não manda Authorization', () async {
      SharedPreferences.setMockInitialValues({});
      final servico = await _servico((_) async => _json([]));
      await servico.listarTransacoes();
      expect(requisicoes.single.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('listarTransacoes', () {
    test('sem filtro chama /transactions e converte a lista', () async {
      final servico = await _servico(
          (_) async => _json([_transacaoJson('a'), _transacaoJson('b')]));

      final itens = await servico.listarTransacoes();

      expect(requisicoes.single.url.path, '/transactions');
      expect(requisicoes.single.url.query, isEmpty);
      expect(itens.map((i) => i.id), ['a', 'b']);
      expect(itens.first.nomeEstabelecimento, 'Mercado a');
    });

    test('filtra por mês e ano na query', () async {
      final servico = await _servico((_) async => _json([]));

      await servico.listarTransacoes(mes: 3, ano: 2026);
      await servico.listarTransacoes(ano: 2026);

      expect(requisicoes[0].url.query, 'month=3&year=2026');
      expect(requisicoes[1].url.query, 'year=2026');
    });

    test('erro do servidor avisa a falha (a tela mostra o erro, não um extrato vazio)',
        () async {
      final servico =
          await _servico((_) async => _json({'error': 'Token inválido'}, 401));
      expect(servico.listarTransacoes(),
          throwsA(isA<FalhaAoCarregarTransacoes>()));
    });

    test('resposta que não é lista devolve lista vazia', () async {
      final servico = await _servico((_) async => _json({'items': []}));
      expect(await servico.listarTransacoes(), isEmpty);
    });

    test('sem internet avisa a falha', () async {
      final servico =
          await _servico((_) async => throw http.ClientException('offline'));
      expect(servico.listarTransacoes(),
          throwsA(isA<FalhaAoCarregarTransacoes>()));
    });

    test('item malformado não derruba o app: avisa a falha', () async {
      final servico = await _servico(
          (_) async => _json([_transacaoJson('a'), {'id': 'b'}]));
      expect(servico.listarTransacoes(),
          throwsA(isA<FalhaAoCarregarTransacoes>()));
    });
  });

  group('obterTransacao', () {
    test('carrega o detalhe', () async {
      final servico = await _servico((_) async => _json(_transacaoJson('x')));
      final resultado = await servico.obterTransacao('x');
      expect(requisicoes.single.url.path, '/transactions/x');
      expect(resultado, isA<DetalheCarregado>());
      expect((resultado as DetalheCarregado).transacao.id, 'x');
    });

    test('404 fica indisponível', () async {
      final servico = await _servico((_) async => _json({}, 404));
      expect(await servico.obterTransacao('x'), isA<DetalheIndisponivel>());
    });
  });

  group('resumosDosUltimosMeses', () {
    test('pede os meses do mais antigo ao mais recente, virando o ano',
        () async {
      final servico = await _servico((req) async {
        final mes = int.parse(req.url.queryParameters['month']!);
        final ano = int.parse(req.url.queryParameters['year']!);
        return _json(_resumoJson(mes, ano));
      });

      final meses =
          await servico.resumosDosUltimosMeses(mes: 1, ano: 2026, quantidade: 3);

      expect(
        meses.map((m) => '${m.mes}/${m.ano}'),
        ['11/2025', '12/2025', '1/2026'],
      );
      expect(meses.every((m) => m.resumo != null), isTrue);
      expect(requisicoes.every((r) => r.url.path == '/summary/monthly'), isTrue);
    });

    test('mês que falha fica com resumo nulo', () async {
      final servico = await _servico((req) async {
        final mes = int.parse(req.url.queryParameters['month']!);
        if (mes == 2) return _json({'error': 'falhou'}, 500);
        return _json(_resumoJson(mes, 2026));
      });

      final meses =
          await servico.resumosDosUltimosMeses(mes: 3, ano: 2026, quantidade: 3);

      expect(meses.map((m) => m.mes), [1, 2, 3]);
      expect(meses[0].resumo, isNotNull);
      expect(meses[1].resumo, isNull);
      expect(meses[2].resumo, isNotNull);
    });

    test('quantidade padrão é 6', () async {
      final servico = await _servico((req) async => _json(_resumoJson(
            int.parse(req.url.queryParameters['month']!),
            int.parse(req.url.queryParameters['year']!),
          )));

      final meses = await servico.resumosDosUltimosMeses(mes: 6, ano: 2026);

      expect(meses.map((m) => m.mes), [1, 2, 3, 4, 5, 6]);
    });
  });

  group('verificarLimite', () {
    test('POST /check-limit e lê o alerta', () async {
      final servico = await _servico(
          (_) async => _json({'alert': true, 'message': 'Você usou 85%'}));

      final resultado = await servico.verificarLimite();

      expect(requisicoes.single.method, 'POST');
      expect(requisicoes.single.url.path, '/check-limit');
      expect((resultado as AlertaCarregado).alerta.mensagem, 'Você usou 85%');
    });

    test('erro fica indisponível', () async {
      final servico = await _servico((_) async => _json({}, 500));
      expect(await servico.verificarLimite(), isA<AlertaIndisponivel>());
    });
  });

  group('listarCategorias', () {
    test('converte as categorias do servidor', () async {
      final servico = await _servico((_) async => _json([
            {'mcc': '5541', 'label': 'Combustível', 'kg_per_100_brl': 21},
          ]));

      final resultado = await servico.listarCategorias();

      expect(requisicoes.single.url.path, '/transactions/categories');
      final categorias = (resultado as CategoriasCarregadas).categorias;
      expect(categorias.single.rotulo, 'Combustível');
    });

    test('lista vazia, erro ou rede usam a reserva local', () async {
      for (final responder in <Future<http.Response> Function(http.Request)>[
        (_) async => _json([]),
        (_) async => _json({}, 404),
        (_) async => throw http.ClientException('offline'),
      ]) {
        final servico = await _servico(responder);
        expect(await servico.listarCategorias(), isA<CategoriasDeReserva>());
      }
    });
  });

  group('estimarCompra', () {
    test('manda MCC e valor e lê a estimativa', () async {
      final servico = await _servico((_) async => _json({
            'category_label': 'Combustível',
            'co2_kg': 21,
            'month_total_co2_kg': 150,
            'limit_kg': 200,
            'percentage_before': 75,
            'percentage_after': 85.5,
          }));

      final resultado =
          await servico.estimarCompra(codigoCategoria: '5541', valor: 100);

      expect(requisicoes.single.url.path, '/transactions/estimate');
      expect(jsonDecode(requisicoes.single.body),
          {'merchant_category_code': '5541', 'amount': 100.0});
      expect((resultado as EstimativaCalculada).estimativa.co2Kg, 21);
    });

    test('404 avisa que o simulador ainda não existe no servidor', () async {
      final servico = await _servico((_) async => _json({}, 404));
      final resultado =
          await servico.estimarCompra(codigoCategoria: '5541', valor: 1);
      expect((resultado as EstimativaErro).mensagem,
          'O simulador ainda não está disponível no servidor.');
    });

    test('outro erro usa a mensagem do servidor ou uma padrão', () async {
      var servico = await _servico(
          (_) async => _json({'error': 'MCC desconhecido'}, 400));
      var resultado =
          await servico.estimarCompra(codigoCategoria: '0000', valor: 1);
      expect((resultado as EstimativaErro).mensagem, 'MCC desconhecido');

      servico = await _servico((_) async => _json({}, 500));
      resultado = await servico.estimarCompra(codigoCategoria: '0000', valor: 1);
      expect((resultado as EstimativaErro).mensagem,
          'Não foi possível simular agora.');
    });

    test('sem internet', () async {
      final servico =
          await _servico((_) async => throw http.ClientException('offline'));
      final resultado =
          await servico.estimarCompra(codigoCategoria: '5541', valor: 1);
      expect((resultado as EstimativaErro).mensagem,
          'Não foi possível conectar ao servidor.');
    });
  });

  group('criarTransacao', () {
    test('sem data não manda occurred_at', () async {
      final servico =
          await _servico((_) async => _json(_transacaoJson('nova'), 201));

      final resultado = await servico.criarTransacao(
        nomeEstabelecimento: 'Padaria',
        codigoCategoria: '5812',
        valor: 23.9,
      );

      expect(requisicoes.single.method, 'POST');
      expect(requisicoes.single.url.path, '/transactions');
      expect(jsonDecode(requisicoes.single.body), {
        'merchant_name': 'Padaria',
        'merchant_category_code': '5812',
        'amount': 23.9,
      });
      expect((resultado as TransacaoRegistrada).transacao.id, 'nova');
    });

    test('com data manda occurred_at em ISO 8601', () async {
      final servico =
          await _servico((_) async => _json(_transacaoJson('nova'), 201));

      await servico.criarTransacao(
        nomeEstabelecimento: 'Padaria',
        codigoCategoria: '5812',
        valor: 10,
        ocorreuEm: DateTime(2026, 3, 10, 8, 30),
      );

      expect(jsonDecode(requisicoes.single.body)['occurred_at'],
          '2026-03-10T08:30:00.000');
    });

    test('erro usa a mensagem do servidor ou uma padrão', () async {
      var servico =
          await _servico((_) async => _json({'error': 'Valor inválido'}, 400));
      var resultado = await servico.criarTransacao(
          nomeEstabelecimento: 'X', codigoCategoria: '5812', valor: 0);
      expect((resultado as RegistroErro).mensagem, 'Valor inválido');

      servico = await _servico((_) async => _json({}, 500));
      resultado = await servico.criarTransacao(
          nomeEstabelecimento: 'X', codigoCategoria: '5812', valor: 0);
      expect((resultado as RegistroErro).mensagem,
          'Não foi possível registrar a compra.');
    });
  });
}
