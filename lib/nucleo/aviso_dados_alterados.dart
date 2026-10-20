import 'package:flutter/foundation.dart';

/// Aviso de que as compras mudaram (nova compra, sincronização do Open
/// Finance, banco desconectado). As abas escutam e recarregam os próprios
/// dados sem serem recriadas, então não perdem o scroll nem piscam.
class AvisoDadosAlterados extends ChangeNotifier {
  AvisoDadosAlterados._();

  static final instancia = AvisoDadosAlterados._();

  void avisar() => notifyListeners();
}
