import 'package:flutter_test/flutter_test.dart';

import 'package:co2bank_app/nucleo/validadores.dart';

void main() {
  group('cpfValido', () {
    test('aceita CPFs válidos, com ou sem máscara', () {
      expect(Validadores.cpfValido('529.982.247-25'), isTrue);
      expect(Validadores.cpfValido('52998224725'), isTrue);
      expect(Validadores.cpfValido('111.444.777-35'), isTrue);
      // Primeiro dígito verificador dá resto 10 -> vira 0.
      expect(Validadores.cpfValido('123.456.789-09'), isTrue);
    });

    test('recusa dígito verificador errado', () {
      expect(Validadores.cpfValido('529.982.247-24'), isFalse);
      expect(Validadores.cpfValido('529.982.247-15'), isFalse);
      expect(Validadores.cpfValido('111.444.777-36'), isFalse);
    });

    test('recusa CPFs com todos os dígitos iguais', () {
      for (var d = 0; d <= 9; d++) {
        expect(Validadores.cpfValido('$d' * 11), isFalse, reason: '$d' * 11);
      }
    });

    test('recusa tamanho diferente de 11 dígitos', () {
      expect(Validadores.cpfValido(''), isFalse);
      expect(Validadores.cpfValido('529.982.247-2'), isFalse);
      expect(Validadores.cpfValido('529.982.247-250'), isFalse);
      expect(Validadores.cpfValido('abc'), isFalse);
    });
  });

  group('emailValido', () {
    test('aceita e-mails comuns', () {
      expect(Validadores.emailValido('sabrina@exemplo.com'), isTrue);
      expect(Validadores.emailValido('nome.sobrenome@empresa.io'), isTrue);
      expect(Validadores.emailValido('nome+tag@empresa.com'), isTrue);
      expect(Validadores.emailValido('nome_1-2@meu-dominio.org'), isTrue);
    });

    test('ignora espaços nas pontas', () {
      expect(Validadores.emailValido('  sabrina@exemplo.com  '), isTrue);
    });

    test('recusa e-mails malformados', () {
      expect(Validadores.emailValido(''), isFalse);
      expect(Validadores.emailValido('sem-arroba.com'), isFalse);
      expect(Validadores.emailValido('a@b'), isFalse);
      expect(Validadores.emailValido('a@b.c'), isFalse);
      expect(Validadores.emailValido('@exemplo.com'), isFalse);
      expect(Validadores.emailValido('nome com espaço@exemplo.com'), isFalse);
      expect(Validadores.emailValido('a@@exemplo.com'), isFalse);
    });

    test('aceita domínios com mais de um ponto (.com.br, subdomínios)', () {
      // Hoje o regex só aceita UM ponto depois do @, então e-mails como
      // "nome@uol.com.br" são recusados no cadastro.
      expect(Validadores.emailValido('sabrina@empresa.com.br'), isTrue);
      expect(Validadores.emailValido('nome@mail.empresa.com'), isTrue);
    }, skip: true); // BUG: e-mail .com.br é recusado
  });

  group('telefoneValido', () {
    test('aceita 10 (fixo) ou 11 (celular) dígitos', () {
      expect(Validadores.telefoneValido('1133334444'), isTrue);
      expect(Validadores.telefoneValido('11987654321'), isTrue);
      expect(Validadores.telefoneValido('(11) 98765-4321'), isTrue);
    });

    test('recusa menos de 10 ou mais de 11 dígitos', () {
      expect(Validadores.telefoneValido(''), isFalse);
      expect(Validadores.telefoneValido('987654321'), isFalse);
      expect(Validadores.telefoneValido('119876543210'), isFalse);
    });
  });

  group('forcaDaSenha', () {
    test('senha vazia ou sem nenhum critério vale 0', () {
      expect(Validadores.forcaDaSenha(''), 0);
      expect(Validadores.forcaDaSenha('abc'), 0);
    });

    test('cada critério soma cerca de um terço', () {
      expect(Validadores.forcaDaSenha('abcdefgh'), closeTo(0.33, 1e-9));
      expect(Validadores.forcaDaSenha('Abc'), closeTo(0.33, 1e-9));
      expect(Validadores.forcaDaSenha('abc1'), closeTo(0.34, 1e-9));
      expect(Validadores.forcaDaSenha('abc!'), closeTo(0.34, 1e-9));
    });

    test('combinação de critérios', () {
      expect(Validadores.forcaDaSenha('Abcdefgh'), closeTo(0.66, 1e-9));
      expect(Validadores.forcaDaSenha('abcdefg1'), closeTo(0.67, 1e-9));
      expect(Validadores.forcaDaSenha('Abc1'), closeTo(0.67, 1e-9));
    });

    test('senha com os três critérios vale 1', () {
      expect(Validadores.forcaDaSenha('Abcdefg1'), closeTo(1.0, 1e-9));
      expect(Validadores.forcaDaSenha('SenhaForte@'), closeTo(1.0, 1e-9));
    });

    test('só alguns símbolos contam como caractere especial', () {
      // A lista é [0-9!@#$%^&*]: ponto, hífen e sublinhado não entram.
      expect(Validadores.forcaDaSenha('abc.'), 0);
      expect(Validadores.forcaDaSenha('abc_'), 0);
    });
  });
}
