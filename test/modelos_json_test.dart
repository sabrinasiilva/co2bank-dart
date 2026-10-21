import 'package:flutter_test/flutter_test.dart';

import 'package:co2bank_app/open_finance/servico/servico_open_finance.dart';
import 'package:co2bank_app/perfil/servico/servico_usuario.dart';
import 'package:co2bank_app/recompensas/servico/servico_recompensas.dart';
import 'package:co2bank_app/transacoes/servico/servico_transacao.dart';

void main() {
  group('ItemTransacao.fromJson', () {
    test('lê todos os campos', () {
      final item = ItemTransacao.fromJson({
        'id': 't1',
        'merchant_name': 'Posto Shell',
        'category_label': 'Combustível',
        'amount': 150,
        'co2_kg': 32.5,
        'occurred_at': '2026-03-10T14:30:00',
        'source': 'open_finance',
        'bank_id': 'nubank',
        'merchant_category_code': '5541',
        'created_at': '2026-03-10T15:00:00',
      });

      expect(item.id, 't1');
      expect(item.nomeEstabelecimento, 'Posto Shell');
      expect(item.rotuloCategoria, 'Combustível');
      expect(item.valor, 150.0);
      expect(item.co2Kg, 32.5);
      expect(item.ocorreuEm, DateTime(2026, 3, 10, 14, 30));
      expect(item.origem, 'open_finance');
      expect(item.importadaOpenFinance, isTrue);
      expect(item.idBanco, 'nubank');
      expect(item.codigoCategoria, '5541');
      expect(item.registradaEm, DateTime(2026, 3, 10, 15));
    });

    test('usa valores padrão para campos opcionais', () {
      final item = ItemTransacao.fromJson({
        'id': 't2',
        'amount': 10.5,
        'co2_kg': 1,
        'occurred_at': '2026-03-10',
      });

      expect(item.nomeEstabelecimento, '');
      expect(item.rotuloCategoria, 'Outros');
      expect(item.origem, 'manual');
      expect(item.importadaOpenFinance, isFalse);
      expect(item.idBanco, isNull);
      expect(item.codigoCategoria, isNull);
      expect(item.registradaEm, isNull);
    });

    test('created_at inválido vira nulo em vez de quebrar', () {
      final item = ItemTransacao.fromJson({
        'id': 't3',
        'amount': 1,
        'co2_kg': 1,
        'occurred_at': '2026-03-10',
        'created_at': 'ontem',
      });
      expect(item.registradaEm, isNull);
    });
  });

  group('ResumoMensal.fromJson', () {
    test('lê o resumo e as categorias principais', () {
      final resumo = ResumoMensal.fromJson({
        'month': 3,
        'year': 2026,
        'total_co2_kg': 120,
        'limit_kg': 200,
        'percentage_used': 60.0,
        'total_spent_brl': 1500.5,
        'transactions_count': 12,
        'top_categories': [
          {'category': 'Combustível', 'co2_kg': 80},
          {'category': 'Restaurante', 'co2_kg': 25.5},
        ],
      });

      expect(resumo.mes, 3);
      expect(resumo.ano, 2026);
      expect(resumo.totalCo2Kg, 120.0);
      expect(resumo.limiteKg, 200.0);
      expect(resumo.percentualUsado, 60.0);
      expect(resumo.totalGastoReais, 1500.5);
      expect(resumo.quantidadeTransacoes, 12);
      expect(resumo.principaisCategorias, hasLength(2));
      expect(resumo.principaisCategorias.first.categoria, 'Combustível');
      expect(resumo.principaisCategorias.first.co2Kg, 80.0);
      expect(resumo.principaisCategorias.last.co2Kg, 25.5);
    });
  });

  group('AlertaLimite.fromJson', () {
    test('com e sem mensagem', () {
      final ativo = AlertaLimite.fromJson({'alert': true, 'message': '85%'});
      expect(ativo.ativo, isTrue);
      expect(ativo.mensagem, '85%');

      final inativo = AlertaLimite.fromJson({'alert': false});
      expect(inativo.ativo, isFalse);
      expect(inativo.mensagem, isNull);
    });
  });

  group('CategoriaCompra.fromJson', () {
    test('lê o MCC, o rótulo e o fator de CO2', () {
      final categoria = CategoriaCompra.fromJson({
        'mcc': '5541',
        'label': 'Combustível',
        'kg_per_100_brl': 21,
      });
      expect(categoria.codigo, '5541');
      expect(categoria.rotulo, 'Combustível');
      expect(categoria.kgPor100, 21.0);
    });

    test('fator ausente fica nulo', () {
      final categoria =
          CategoriaCompra.fromJson({'mcc': '5411', 'label': 'Supermercado'});
      expect(categoria.kgPor100, isNull);
    });

    test('reserva local tem MCCs únicos e sem fator', () {
      final codigos = categoriasDeReserva.map((c) => c.codigo).toList();
      expect(codigos.toSet(), hasLength(codigos.length));
      expect(categoriasDeReserva.every((c) => c.kgPor100 == null), isTrue);
    });
  });

  group('EstimativaCompra.fromJson', () {
    Map<String, dynamic> base() => {
          'category_label': 'Combustível',
          'co2_kg': 21,
          'month_total_co2_kg': 150,
          'limit_kg': 200,
          'percentage_before': 75,
          'percentage_after': 85.5,
        };

    test('lê todos os campos', () {
      final estimativa = EstimativaCompra.fromJson(
          {...base(), 'exceeds_limit': false});
      expect(estimativa.rotuloCategoria, 'Combustível');
      expect(estimativa.co2Kg, 21.0);
      expect(estimativa.totalMesKg, 150.0);
      expect(estimativa.limiteKg, 200.0);
      expect(estimativa.percentualAntes, 75.0);
      expect(estimativa.percentualDepois, 85.5);
      expect(estimativa.passaDoLimite, isFalse);
    });

    test('sem exceeds_limit, calcula pelo percentual depois', () {
      expect(EstimativaCompra.fromJson(base()).passaDoLimite, isFalse);
      expect(
        EstimativaCompra.fromJson({...base(), 'percentage_after': 100})
            .passaDoLimite,
        isFalse,
      );
      expect(
        EstimativaCompra.fromJson({...base(), 'percentage_after': 100.1})
            .passaDoLimite,
        isTrue,
      );
    });

    test('exceeds_limit do servidor tem prioridade', () {
      expect(
        EstimativaCompra.fromJson({...base(), 'exceeds_limit': true})
            .passaDoLimite,
        isTrue,
      );
    });

    test('campos opcionais ausentes', () {
      final json = base()
        ..remove('category_label')
        ..remove('month_total_co2_kg');
      final estimativa = EstimativaCompra.fromJson(json);
      expect(estimativa.rotuloCategoria, '');
      expect(estimativa.totalMesKg, 0);
    });
  });

  group('PerfilUsuario.fromJson', () {
    test('lê o perfil, com telefone opcional', () {
      final perfil = PerfilUsuario.fromJson({
        'id': 'u1',
        'name': 'Sabrina',
        'email': 'sabrina@exemplo.com',
        'cpf': '52998224725',
        'co2_limit_kg': 150,
      });
      expect(perfil.id, 'u1');
      expect(perfil.nome, 'Sabrina');
      expect(perfil.email, 'sabrina@exemplo.com');
      expect(perfil.cpf, '52998224725');
      expect(perfil.telefone, '');
      expect(perfil.limiteCo2Kg, 150.0);
    });
  });

  group('ConexaoBanco.fromJson', () {
    test('com e sem última sincronização', () {
      final conectada = ConexaoBanco.fromJson({
        'bank_id': 'itau',
        'connected_at': '2026-01-05T10:00:00',
        'last_sync_at': '2026-02-01T08:00:00',
      });
      expect(conectada.idBanco, 'itau');
      expect(conectada.conectadoEm, DateTime(2026, 1, 5, 10));
      expect(conectada.ultimaSincronizacao, DateTime(2026, 2, 1, 8));

      final nunca = ConexaoBanco.fromJson({
        'bank_id': 'inter',
        'connected_at': '2026-01-05T10:00:00',
        'last_sync_at': null,
      });
      expect(nunca.ultimaSincronizacao, isNull);
    });
  });

  group('Recompensas', () {
    test('ResumoCoins: saldo disponível cai para os ganhos quando ausente',
        () {
      final resumo = ResumoCoins.fromJson({
        'tokens_earned': 40,
        'kg_saved': 12.5,
        'partners': [
          {'name': 'Loja Verde', 'category': 'Moda', 'cost': 30, 'discount_percent': 10},
        ],
      });
      expect(resumo.ganhos, 40);
      expect(resumo.disponiveis, 40);
      expect(resumo.kgEconomizados, 12.5);
      expect(resumo.ofertas.single.loja, 'Loja Verde');

      final comSaldo =
          ResumoCoins.fromJson({'tokens_earned': 40, 'tokens_available': 10});
      expect(comSaldo.disponiveis, 10);
    });

    test('ResumoCoins: json vazio vira tudo zero', () {
      final resumo = ResumoCoins.fromJson({});
      expect(resumo.ganhos, 0);
      expect(resumo.disponiveis, 0);
      expect(resumo.kgEconomizados, 0);
      expect(resumo.ofertas, isEmpty);
    });

    test('ResumoConquistas: conta as conquistas quando o total não vem', () {
      final resumo = ResumoConquistas.fromJson({
        'rewards': [
          {'id': 'a', 'title': 'Primeira compra', 'earned': true, 'earned_at': '2026-01-02T00:00:00'},
          {'id': 'b', 'title': 'Um mês no limite'},
          {'id': 'c', 'title': 'Três meses', 'earned': true},
        ],
      });
      expect(resumo.total, 3);
      expect(resumo.totalConquistadas, 2);
      expect(resumo.itens.first.conquistadaEm, DateTime(2026, 1, 2));
      expect(resumo.itens[1].conquistada, isFalse);
      expect(resumo.itens[1].descricao, '');

      final doServidor = ResumoConquistas.fromJson(
          {'rewards': [], 'total': 10, 'total_earned': 4});
      expect(doServidor.total, 10);
      expect(doServidor.totalConquistadas, 4);
    });

    test('Resgate: id numérico vira texto e campos opcionais ficam nulos',
        () {
      final cupom = Resgate.fromJson({
        'id': 7,
        'partner_name': 'Loja Verde',
        'cost': 30,
        'coupon_code': 'VERDE10',
        'redeemed_at': '2026-03-01T12:00:00',
      });
      expect(cupom.id, '7');
      expect(cupom.nomeParceiro, 'Loja Verde');
      expect(cupom.custo, 30);
      expect(cupom.codigoCupom, 'VERDE10');
      expect(cupom.resgatadoEm, DateTime(2026, 3, 1, 12));
      expect(cupom.percentualDesconto, isNull);
      expect(cupom.temSite, isFalse);
    });

    test('Resgate.temSite ignora links de exemplo', () {
      Resgate comUrl(String? url) =>
          Resgate.fromJson({'id': '1', 'url': url});
      expect(comUrl('https://www.lojaverde.com.br').temSite, isTrue);
      expect(comUrl('https://loja.example.com').temSite, isFalse);
      expect(comUrl('https://example.com').temSite, isFalse);
      expect(comUrl('').temSite, isFalse);
      expect(comUrl(null).temSite, isFalse);
    });
  });
}
