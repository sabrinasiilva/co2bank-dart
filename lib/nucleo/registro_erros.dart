import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Registra um erro que o app tratou sem mostrar o motivo para a pessoa (o
/// catch devolve "indisponível", "erro de rede" etc.). Para quem usa o app nada
/// muda; a falha só deixa de sumir: vai para o DevTools com a pilha e, em
/// debug, aparece também no console do `flutter run`.
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
