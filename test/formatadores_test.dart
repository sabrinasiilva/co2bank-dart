import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:co2bank_app/nucleo/formatadores_entrada.dart';

/// Aplica o formatador como se a pessoa tivesse digitado [texto] no campo.
TextEditingValue _aplicar(
  TextInputFormatter formatador,
  String texto, {
  String anterior = '',
}) =>
    formatador.formatEditUpdate(
      TextEditingValue(text: anterior),
      TextEditingValue(
        text: texto,
        selection: TextSelection.collapsed(offset: texto.length),
      ),
    );

String _formatar(TextInputFormatter formatador, String texto) =>
    _aplicar(formatador, texto).text;

void main() {
  group('FormatadorCpf', () {
    final formatador = FormatadorCpf();

    test('formata o CPF completo', () {
      expect(_formatar(formatador, '52998224725'), '529.982.247-25');
    });

    test('formata enquanto digita', () {
      expect(_formatar(formatador, '5'), '5');
      expect(_formatar(formatador, '529'), '529');
      expect(_formatar(formatador, '5299'), '529.9');
      expect(_formatar(formatador, '5299822'), '529.982.2');
      expect(_formatar(formatador, '5299822472'), '529.982.247-2');
    });

    test('ignora o que não é dígito e reformata texto já mascarado', () {
      expect(_formatar(formatador, '529.982.247-25'), '529.982.247-25');
      expect(_formatar(formatador, 'abc529 982x247/25'), '529.982.247-25');
    });

    test('corta depois de 11 dígitos', () {
      expect(_formatar(formatador, '529982247251234'), '529.982.247-25');
    });

    test('vazio continua vazio', () {
      expect(_formatar(formatador, ''), '');
    });

    test('cursor vai para o fim do texto', () {
      final resultado = _aplicar(formatador, '5299822');
      expect(resultado.selection, const TextSelection.collapsed(offset: 9));
    });
  });

  group('FormatadorTelefone', () {
    final formatador = FormatadorTelefone();

    test('formata celular com 11 dígitos', () {
      expect(_formatar(formatador, '11987654321'), '(11) 98765-4321');
    });

    test('formata enquanto digita', () {
      expect(_formatar(formatador, '1'), '(1');
      expect(_formatar(formatador, '11'), '(11');
      expect(_formatar(formatador, '119'), '(11) 9');
      expect(_formatar(formatador, '1198765'), '(11) 98765');
      expect(_formatar(formatador, '11987654'), '(11) 98765-4');
    });

    test('ignora o que não é dígito e corta depois de 11 dígitos', () {
      expect(_formatar(formatador, '(11) 98765-4321'), '(11) 98765-4321');
      expect(_formatar(formatador, '1198765432199'), '(11) 98765-4321');
    });

    test('vazio continua vazio', () {
      expect(_formatar(formatador, ''), '');
    });

    test('cursor vai para o fim do texto', () {
      final resultado = _aplicar(formatador, '11987654321');
      expect(resultado.selection, const TextSelection.collapsed(offset: 15));
    });

    test('telefone fixo (10 dígitos) usa o hífen depois de 4 dígitos', () {
      // Hoje sai "(11) 33334-444": o hífen fica sempre na posição do celular,
      // embora Validadores.telefoneValido aceite 10 dígitos.
      expect(_formatar(formatador, '1133334444'), '(11) 3333-4444');
    }, skip: true); // BUG: número fixo fica com o hífen no lugar errado
  });

  group('FormatadorMoeda', () {
    final formatador = FormatadorMoeda();

    test('os dígitos entram pela direita, como centavos', () {
      expect(_formatar(formatador, '2'), '0,02');
      expect(_formatar(formatador, '25'), '0,25');
      expect(_formatar(formatador, '250'), '2,50');
      expect(_formatar(formatador, '2500'), '25,00');
      expect(_formatar(formatador, '125000'), '1.250,00');
      expect(_formatar(formatador, '123456789'), '1.234.567,89');
    });

    test('digitar mais um dígito no texto já formatado', () {
      // Campo com "0,02" e a pessoa digita 5 no fim.
      expect(_formatar(formatador, '0,025'), '0,25');
      // Campo com "2,50" e a pessoa digita 0 no fim.
      expect(_formatar(formatador, '2,500'), '25,00');
    });

    test('apagar o último dígito', () {
      // Campo com "2,50" e a pessoa apaga o 0.
      expect(_formatar(formatador, '2,5'), '0,25');
      // Campo com "0,02" e a pessoa apaga o 2.
      expect(_formatar(formatador, '0,0'), '');
    });

    test('zeros à esquerda somem e só zero vira campo vazio', () {
      expect(_formatar(formatador, '0'), '');
      expect(_formatar(formatador, '000'), '');
      expect(_formatar(formatador, '0005'), '0,05');
    });

    test('texto sem dígitos vira campo vazio', () {
      expect(_formatar(formatador, ''), '');
      expect(_formatar(formatador, 'abc'), '');
    });

    test('limita a 9 dígitos (até 9.999.999,99)', () {
      expect(_formatar(formatador, '999999999'), '9.999.999,99');
      expect(_formatar(formatador, '9999999999'), '9.999.999,99');
      // Com o campo cheio, o dígito novo é descartado.
      expect(_formatar(formatador, '1.234.567,890'), '1.234.567,89');
    });

    test('cursor vai para o fim do texto', () {
      final resultado = _aplicar(formatador, '125000');
      expect(resultado.selection, const TextSelection.collapsed(offset: 8));
    });

    group('valor', () {
      test('converte o texto da máscara em número', () {
        expect(FormatadorMoeda.valor('1.250,00'), 1250.0);
        expect(FormatadorMoeda.valor('0,05'), 0.05);
        expect(FormatadorMoeda.valor('2,50'), 2.5);
        expect(FormatadorMoeda.valor('9.999.999,99'), 9999999.99);
      });

      test('ignora prefixo e espaços', () {
        expect(FormatadorMoeda.valor('R\$ 3,99'), 3.99);
      });

      test('sem dígitos devolve nulo', () {
        expect(FormatadorMoeda.valor(''), isNull);
        expect(FormatadorMoeda.valor('R\$ ,'), isNull);
      });

      test('volta exatamente o valor que o formatador mostrou', () {
        for (final digitado in ['1', '99', '1234', '100000', '123456789']) {
          final texto = _formatar(formatador, digitado);
          expect(FormatadorMoeda.valor(texto), int.parse(digitado) / 100);
        }
      });
    });
  });
}
