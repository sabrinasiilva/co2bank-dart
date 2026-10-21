import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Guarda no log um erro que a tela já tratou com uma mensagem genérica, como
/// "erro de rede". Quem usa o app não vê nada diferente; quem desenvolve
/// encontra o erro e a pilha no DevTools e no terminal do `flutter run`.
void registrarErro(Object erro, StackTrace pilha, {String? contexto}) {
  final mensagem = contexto == null ? '$erro' : '$contexto: $erro';
  developer.log(mensagem, name: 'co2bank', error: erro, stackTrace: pilha);
  if (kDebugMode) {
    debugPrintStack(
      label: '[co2bank] $mensagem',
      stackTrace: pilha,
      maxFrames: 8,
    );
  }
}
