import 'package:flutter/services.dart';

class FormatadorCpf extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 11; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(digits[i]);
    }
    final result = buffer.toString();
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

class FormatadorTelefone extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 11; i++) {
      if (i == 0) buffer.write('(');
      if (i == 2) buffer.write(') ');
      if (i == 7) buffer.write('-');
      buffer.write(digits[i]);
    }
    final result = buffer.toString();
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

/// Máscara de dinheiro no estilo dos apps de banco: os dígitos entram pela
/// direita, como centavos ("2", "25", "2,50", "25,00", "1.250,00").
class FormatadorMoeda extends TextInputFormatter {
  static const _maximoDeDigitos = 9; // até 9.999.999,99

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length > _maximoDeDigitos) {
      digits = digits.substring(0, _maximoDeDigitos);
    }
    digits = digits.replaceFirst(RegExp(r'^0+'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final centavos = digits.padLeft(3, '0');
    final inteiro = centavos.substring(0, centavos.length - 2);
    final decimal = centavos.substring(centavos.length - 2);
    final inteiroComPontos = inteiro.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    final result = '$inteiroComPontos,$decimal';
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }

  /// Converte o texto da máscara ("1.250,00") em número (1250.0).
  static double? valor(String texto) {
    final digits = texto.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return null;
    return int.parse(digits) / 100;
  }
}
