import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:co2bank_app/open_finance/bancos_open_finance.dart';
import 'package:co2bank_app/transacoes/icone_categoria.dart';

void main() {
  group('bancoPorId', () {
    test('encontra os bancos pelo id do backend', () {
      expect(bancoPorId('nubank')?.nome, 'Nubank');
      expect(bancoPorId('itau')?.nome, 'Itaú');
      expect(bancoPorId('c6')?.nome, 'C6 Bank');
    });

    test('id desconhecido ou nulo devolve nulo', () {
      expect(bancoPorId('banco_x'), isNull);
      expect(bancoPorId(null), isNull);
      expect(bancoPorId('Nubank'), isNull);
    });

    test('ids da lista são únicos', () {
      final ids = bancosOpenFinance.map((b) => b.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });
  });

  group('iconePorCategoria', () {
    test('categorias conhecidas', () {
      expect(iconePorCategoria('Combustível'), Icons.local_gas_station_rounded);
      expect(iconePorCategoria('Supermercado'), Icons.shopping_cart_rounded);
      expect(iconePorCategoria('Passagem aérea'), Icons.flight_rounded);
    });

    test('categoria desconhecida usa o recibo', () {
      expect(iconePorCategoria('Outros'), Icons.receipt_rounded);
      expect(iconePorCategoria(''), Icons.receipt_rounded);
      expect(iconePorCategoria('combustível'), Icons.receipt_rounded);
    });
  });
}
