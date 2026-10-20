import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:co2bank_app/presentation/rewards/achievements_screen.dart';
import 'package:co2bank_app/presentation/rewards/rewards_data.dart';

Offer _oferta(String loja, {String descricao = '', String categoria = ''}) =>
    Offer(
      store: loja,
      description: descricao,
      category: categoria,
      cost: 10,
      url: '',
      fallbackIcon: Icons.store,
      color: Colors.green,
    );

void main() {
  group('RewardsLogic.format', () {
    test('separa milhares com ponto', () {
      expect(RewardsLogic.format(0), '0');
      expect(RewardsLogic.format(999), '999');
      expect(RewardsLogic.format(1000), '1.000');
      expect(RewardsLogic.format(1250), '1.250');
      expect(RewardsLogic.format(1234567), '1.234.567');
    });
  });

  group('RewardsLogic.filter', () {
    final ofertas = [
      _oferta('Loja Verde', descricao: '10% de desconto', categoria: 'Moda'),
      _oferta('Bike Já', descricao: '5% de desconto', categoria: 'Esporte'),
      _oferta('Mercado Bom', descricao: '15% de desconto', categoria: 'Alimentação'),
    ];

    test('busca vazia devolve tudo', () {
      expect(RewardsLogic.filter(ofertas, ''), ofertas);
      expect(RewardsLogic.filter(ofertas, '   '), ofertas);
    });

    test('busca pelo nome, descrição ou categoria, sem diferenciar maiúsculas',
        () {
      expect(RewardsLogic.filter(ofertas, 'verde').single.store, 'Loja Verde');
      expect(RewardsLogic.filter(ofertas, ' ESPORTE ').single.store, 'Bike Já');
      expect(RewardsLogic.filter(ofertas, '15%').single.store, 'Mercado Bom');
      expect(RewardsLogic.filter(ofertas, 'desconto'), hasLength(3));
      expect(RewardsLogic.filter(ofertas, 'nada disso'), isEmpty);
    });
  });

  group('RewardsLogic.progress', () {
    test('fica entre 0 e 1', () {
      expect(RewardsLogic.progress(0, 100), 0.0);
      expect(RewardsLogic.progress(25, 100), 0.25);
      expect(RewardsLogic.progress(100, 100), 1.0);
      expect(RewardsLogic.progress(150, 100), 1.0);
      expect(RewardsLogic.progress(-5, 100), 0.0);
    });

    test('custo zero conta como completo', () {
      expect(RewardsLogic.progress(10, 0), 1.0);
      expect(RewardsLogic.progress(0, 0), 1.0);
    });
  });

  group('Offer.fromPartner', () {
    test('monta a descrição pelo desconto', () {
      final oferta = Offer.fromPartner({
        'name': 'Loja Verde',
        'category': 'Moda',
        'cost': 30,
        'discount_percent': 10,
        'url': 'https://www.lojaverde.com.br/promo',
      });
      expect(oferta.store, 'Loja Verde');
      expect(oferta.description, '10% de desconto');
      expect(oferta.discountPercent, 10);
      expect(oferta.cost, 30);
      expect(oferta.category, 'Moda');
      expect(oferta.fallbackIcon, Icons.checkroom);
      expect(oferta.hasWebsite, isTrue);
      expect(
        oferta.logoUrl,
        'https://www.google.com/s2/favicons?domain=www.lojaverde.com.br&sz=128',
      );
    });

    test('categoria desconhecida e campos ausentes', () {
      final oferta = Offer.fromPartner({'name': 'Parceiro'});
      expect(oferta.description, '0% de desconto');
      expect(oferta.cost, 0);
      expect(oferta.category, '');
      expect(oferta.fallbackIcon, Icons.store);
      expect(oferta.hasWebsite, isFalse);
      expect(oferta.logoUrl, isNull);
    });

    test('link de exemplo não conta como site', () {
      final oferta = Offer.fromPartner(
          {'name': 'Teste', 'url': 'https://parceiro.example.com'});
      expect(oferta.hasWebsite, isFalse);
      expect(oferta.logoUrl, isNull);
    });
  });

  group('achievementIcon', () {
    test('ícones conhecidos e padrão', () {
      expect(achievementIcon('eco'), Icons.eco);
      expect(achievementIcon('shield'), Icons.shield);
      expect(achievementIcon('foot_print'), Icons.directions_walk);
      expect(achievementIcon('desconhecido'), Icons.emoji_events);
    });
  });
}
