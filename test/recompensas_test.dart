import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:co2bank_app/recompensas/oferta.dart';
import 'package:co2bank_app/recompensas/servico/servico_recompensas.dart';
import 'package:co2bank_app/recompensas/tela_conquistas.dart';

Oferta _oferta(String loja, {String descricao = '', String categoria = ''}) =>
    Oferta(
      loja: loja,
      descricao: descricao,
      categoria: categoria,
      custo: 10,
      url: '',
      iconeReserva: Icons.store,
      cor: Colors.green,
    );

Resgate _resgate(String loja, String codigo, String quando) => Resgate(
  id: codigo,
  nomeParceiro: loja,
  custo: 10,
  codigoCupom: codigo,
  resgatadoEm: DateTime.parse(quando),
);

void main() {
  group('cuponsDoMes', () {
    final agora = DateTime.utc(2026, 10, 23, 15);

    test('só conta os resgates do mês atual, um por loja', () {
      final cupons = cuponsDoMes([
        _resgate('Renner', 'CO2B-NOVO-AAAA', '2026-10-22T10:00:00Z'),
        _resgate('Renner', 'CO2B-VELH-BBBB', '2026-10-01T08:00:00Z'),
        _resgate('Natura', 'CO2B-SETE-CCCC', '2026-09-30T23:00:00Z'),
      ], agora: agora);

      expect(cupons, {'Renner': 'CO2B-NOVO-AAAA'});
    });

    test('usa o mês em UTC, como o backend', () {
      // 31/10 às 22h em São Paulo já é 1º de novembro em UTC.
      final cupons = cuponsDoMes([
        _resgate('Natura', 'CO2B-NOVE-DDDD', '2026-11-01T01:00:00Z'),
      ], agora: DateTime.utc(2026, 11, 1, 2));
      expect(cupons, {'Natura': 'CO2B-NOVE-DDDD'});
    });
  });

  group('LogicaRecompensas.formatar', () {
    test('separa milhares com ponto', () {
      expect(LogicaRecompensas.formatar(0), '0');
      expect(LogicaRecompensas.formatar(999), '999');
      expect(LogicaRecompensas.formatar(1000), '1.000');
      expect(LogicaRecompensas.formatar(1250), '1.250');
      expect(LogicaRecompensas.formatar(1234567), '1.234.567');
    });
  });

  group('LogicaRecompensas.filtrar', () {
    final ofertas = [
      _oferta('Loja Verde', descricao: '10% de desconto', categoria: 'Moda'),
      _oferta('Bike Já', descricao: '5% de desconto', categoria: 'Esporte'),
      _oferta(
        'Mercado Bom',
        descricao: '15% de desconto',
        categoria: 'Alimentação',
      ),
    ];

    test('busca vazia devolve tudo', () {
      expect(LogicaRecompensas.filtrar(ofertas, ''), ofertas);
      expect(LogicaRecompensas.filtrar(ofertas, '   '), ofertas);
    });

    test(
      'busca pelo nome, descrição ou categoria, sem diferenciar maiúsculas',
      () {
        expect(
          LogicaRecompensas.filtrar(ofertas, 'verde').single.loja,
          'Loja Verde',
        );
        expect(
          LogicaRecompensas.filtrar(ofertas, ' ESPORTE ').single.loja,
          'Bike Já',
        );
        expect(
          LogicaRecompensas.filtrar(ofertas, '15%').single.loja,
          'Mercado Bom',
        );
        expect(LogicaRecompensas.filtrar(ofertas, 'desconto'), hasLength(3));
        expect(LogicaRecompensas.filtrar(ofertas, 'nada disso'), isEmpty);
      },
    );
  });

  group('LogicaRecompensas.progresso', () {
    test('fica entre 0 e 1', () {
      expect(LogicaRecompensas.progresso(0, 100), 0.0);
      expect(LogicaRecompensas.progresso(25, 100), 0.25);
      expect(LogicaRecompensas.progresso(100, 100), 1.0);
      expect(LogicaRecompensas.progresso(150, 100), 1.0);
      expect(LogicaRecompensas.progresso(-5, 100), 0.0);
    });

    test('custo zero conta como completo', () {
      expect(LogicaRecompensas.progresso(10, 0), 1.0);
      expect(LogicaRecompensas.progresso(0, 0), 1.0);
    });
  });

  group('Oferta.doParceiro', () {
    test('monta a descrição pelo desconto', () {
      final oferta = Oferta.doParceiro({
        'name': 'Loja Verde',
        'category': 'Moda',
        'cost': 30,
        'discount_percent': 10,
        'url': 'https://www.lojaverde.com.br/promo',
      });
      expect(oferta.loja, 'Loja Verde');
      expect(oferta.descricao, '10% de desconto');
      expect(oferta.percentualDesconto, 10);
      expect(oferta.custo, 30);
      expect(oferta.categoria, 'Moda');
      expect(oferta.iconeReserva, Icons.checkroom);
      expect(oferta.temSite, isTrue);
      expect(
        oferta.urlLogo,
        'https://www.google.com/s2/favicons?domain=www.lojaverde.com.br&sz=128',
      );
    });

    test('categoria desconhecida e campos ausentes', () {
      final oferta = Oferta.doParceiro({'name': 'Parceiro'});
      expect(oferta.descricao, '0% de desconto');
      expect(oferta.custo, 0);
      expect(oferta.categoria, '');
      expect(oferta.iconeReserva, Icons.store);
      expect(oferta.temSite, isFalse);
      expect(oferta.urlLogo, isNull);
    });

    test('link de exemplo não conta como site', () {
      final oferta = Oferta.doParceiro({
        'name': 'Teste',
        'url': 'https://parceiro.example.com',
      });
      expect(oferta.temSite, isFalse);
      expect(oferta.urlLogo, isNull);
    });
  });

  group('iconeDaConquista', () {
    test('ícones conhecidos e padrão', () {
      expect(iconeDaConquista('eco'), Icons.eco);
      expect(iconeDaConquista('shield'), Icons.shield);
      expect(iconeDaConquista('foot_print'), Icons.directions_walk);
      expect(iconeDaConquista('desconhecido'), Icons.emoji_events);
    });
  });
}
