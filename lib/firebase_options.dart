// PROVISÓRIO: o projeto Firebase do CO2Bank ainda não foi configurado.
//
// O comando `flutterfire configure --platforms=android,web` vai SOBRESCREVER
// este arquivo com as chaves do projeto (passo a passo em docs/FIREBASE.md).
// Enquanto isso, `currentPlatform` lança UnsupportedError e o app só pula o
// push (lib/nucleo/push_firebase.dart): a notificação local continua valendo.
//
// Estas opções são de app cliente, não são segredo: podem ir para o repositório.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Mesmo formato do arquivo gerado pelo FlutterFire CLI.
///
/// ```dart
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Firebase ainda não configurado: rode `flutterfire configure` '
      '(veja docs/FIREBASE.md).',
    );
  }
}
