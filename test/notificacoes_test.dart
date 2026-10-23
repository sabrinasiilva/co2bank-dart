import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:co2bank_app/notificacoes/servico/atualizacao_app.dart';
import 'package:co2bank_app/notificacoes/servico/servico_notificacoes.dart';
import 'package:co2bank_app/notificacoes/tela_notificacoes.dart';

Future<ServicoNotificacoes> _servico(http.Response resposta) => http.runWithClient(
      ServicoNotificacoes.autenticado,
      () => MockClient((_) async => resposta),
    );

http.Response _json(Object corpo, [int status = 200]) => http.Response(
      jsonEncode(corpo),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => initializeDateFormatting('pt_BR'));
  setUp(() => SharedPreferences.setMockInitialValues({'auth_token': 'token-salvo'}));

  group('VerificadorAtualizacao.comparar', () {
    const publicado = {
      'versao': '1.0.0',
      'build': 12,
      'apk': 'https://sabrinasiilva.github.io/co2bank-dart/co2bank.apk',
    };

    test('avisa quando o build publicado é maior que o instalado', () {
      final nova = VerificadorAtualizacao.comparar(buildInstalado: 10, publicado: publicado);
      expect(nova?.build, 12);
      expect(nova?.linkApk.toString(), endsWith('/co2bank.apk'));
    });

    test('não avisa quando já está na mesma versão ou numa mais nova', () {
      expect(VerificadorAtualizacao.comparar(buildInstalado: 12, publicado: publicado), isNull);
      expect(VerificadorAtualizacao.comparar(buildInstalado: 15, publicado: publicado), isNull);
    });

    test('ignora um versao.json sem link válido', () {
      expect(
        VerificadorAtualizacao.comparar(
          buildInstalado: 1,
          publicado: {'build': 30, 'apk': 'nao é link'},
        ),
        isNull,
      );
    });
  });

  group('quandoChegou', () {
    final agora = DateTime(2026, 10, 23, 15, 30);

    test('minutos, horas, ontem e data', () {
      expect(quandoChegou(agora.subtract(const Duration(seconds: 20)), agora: agora), 'agora');
      expect(quandoChegou(agora.subtract(const Duration(minutes: 5)), agora: agora), 'há 5 min');
      expect(quandoChegou(agora.subtract(const Duration(hours: 3)), agora: agora), 'há 3 h');
      expect(quandoChegou(DateTime(2026, 10, 22, 20), agora: agora), 'ontem');
      expect(quandoChegou(DateTime(2026, 10, 12, 9), agora: agora), '12 de out');
    });
  });

  group('ServicoNotificacoes.carregar', () {
    test('lê as notificações e a contagem de não lidas', () async {
      final servico = await _servico(_json({
        'items': [
          {
            'id': 'n1',
            'type': 'limit_alert',
            'title': 'Atenção ao seu limite de CO2',
            'body': 'Você já usou 90% do limite.',
            'created_at': '2026-10-23T12:00:00Z',
            'read': false,
          },
          {
            'id': 'n2',
            'type': 'redemption',
            'title': 'Cupom resgatado',
            'body': 'Seu cupom da Natura está em Meus cupons',
            'data': {'coupon_code': 'CO2B-AAAA'},
            'created_at': '2026-10-22T12:00:00Z',
            'read': true,
          },
        ],
        'unread_count': 1,
      }));

      final central = await servico.carregar();

      expect(central.naoLidas, 1);
      expect(central.itens.map((n) => n.tipo), ['limit_alert', 'redemption']);
      expect(central.itens[1].dados['coupon_code'], 'CO2B-AAAA');
      expect(central.itens[0].lida, isFalse);
    });

    test('rota que ainda não existe (404) deixa a central vazia', () async {
      final servico = await _servico(_json({'error': 'Not Found'}, 404));
      final central = await servico.carregar();
      expect(central.itens, isEmpty);
      expect(central.naoLidas, 0);
    });
  });
}
