import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:co2bank_app/nucleo/cliente_api.dart';

void main() {
  group('ClienteApi', () {
    late List<http.Request> requisicoes;

    ClienteApi cliente(http.Response Function(http.Request) responder) {
      requisicoes = [];
      return ClienteApi(
        cliente: MockClient((req) async {
          requisicoes.add(req);
          return responder(req);
        }),
      );
    }

    test('GET monta a URL a partir da base e manda JSON sem token', () async {
      final api = cliente((_) => http.Response('{"ok": true}', 200));

      final resposta = await api.get('/auth/me');

      final req = requisicoes.single;
      expect(req.method, 'GET');
      expect(req.url.toString(), '$urlBaseApi/auth/me');
      expect(req.headers['Content-Type'], startsWith('application/json'));
      expect(req.headers.containsKey('Authorization'), isFalse);
      expect(resposta.sucesso, isTrue);
      expect(resposta.corpo, {'ok': true});
    });

    test('depois de definirToken manda o Bearer', () async {
      final api = cliente((_) => http.Response('{}', 200))
        ..definirToken('abc123');

      await api.get('/transactions');

      expect(requisicoes.single.headers['Authorization'], 'Bearer abc123');
    });

    test('POST manda o corpo em JSON', () async {
      final api = cliente((_) => http.Response('{"id": "t1"}', 201));

      final resposta =
          await api.post('/transactions', {'amount': 12.5, 'name': 'Café'});

      final req = requisicoes.single;
      expect(req.method, 'POST');
      expect(jsonDecode(req.body), {'amount': 12.5, 'name': 'Café'});
      expect(resposta.codigoStatus, 201);
      expect(resposta.corpo['id'], 't1');
    });

    test('DELETE usa o método certo', () async {
      final api = cliente((_) => http.Response('{}', 204));

      final resposta = await api.delete('/open-finance/connections/itau');

      expect(requisicoes.single.method, 'DELETE');
      expect(requisicoes.single.url.path, '/open-finance/connections/itau');
      expect(resposta.sucesso, isTrue);
    });

    test('corpo que não é JSON vira erro "Resposta inválida do servidor"',
        () async {
      final api =
          cliente((_) => http.Response('<html>Bad Gateway</html>', 502));

      final resposta = await api.get('/summary/monthly');

      expect(resposta.sucesso, isFalse);
      expect(resposta.erro, 'Resposta inválida do servidor');
    });

    test('corpo vazio também vira erro, mesmo com status de sucesso', () async {
      final api = cliente((_) => http.Response('', 204));

      final resposta = await api.delete('/x');

      expect(resposta.sucesso, isTrue);
      expect(resposta.erro, 'Resposta inválida do servidor');
    });

    test('erro de rede é repassado como exceção', () async {
      final api = ClienteApi(
        cliente: MockClient((_) async => throw http.ClientException('offline')),
      );

      expect(api.get('/auth/me'), throwsA(isA<http.ClientException>()));
    });
  });

  group('RespostaApi', () {
    test('sucesso só para 2xx', () {
      expect(RespostaApi(199, {}).sucesso, isFalse);
      expect(RespostaApi(200, {}).sucesso, isTrue);
      expect(RespostaApi(299, {}).sucesso, isTrue);
      expect(RespostaApi(300, {}).sucesso, isFalse);
      expect(RespostaApi(404, {}).sucesso, isFalse);
    });

    test('corpo e listaCorpo não quebram com o tipo errado', () {
      final lista = RespostaApi(200, [1, 2]);
      expect(lista.listaCorpo, [1, 2]);
      expect(lista.corpo, isEmpty);
      expect(lista.erro, isNull);

      final mapa = RespostaApi(200, <String, dynamic>{'a': 1});
      expect(mapa.corpo, {'a': 1});
      expect(mapa.listaCorpo, isEmpty);

      final nulo = RespostaApi(200, null);
      expect(nulo.corpo, isEmpty);
      expect(nulo.listaCorpo, isEmpty);
    });

    test('erro lê o campo "error"', () {
      expect(
        RespostaApi(400, <String, dynamic>{'error': 'E-mail já cadastrado'}).erro,
        'E-mail já cadastrado',
      );
    });
  });
}
