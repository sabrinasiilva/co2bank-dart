import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import 'armazenamento_token.dart';
import 'cliente_api.dart';
import 'notificacoes.dart';

/// Chave pública (VAPID) do Web Push, gerada no console do Firebase em
/// Cloud Messaging > Web Push certificates. Só é usada na versão web:
/// flutter run -d chrome --dart-define=FIREBASE_VAPID_KEY=...
const String chaveVapidFirebase = String.fromEnvironment('FIREBASE_VAPID_KEY');

/// Chamado pelo Android quando chega um push com o app fechado ou em segundo
/// plano. Roda em um isolate separado, por isso precisa ser uma função de topo.
@pragma('vm:entry-point')
Future<void> tratarPushEmSegundoPlano(RemoteMessage mensagem) async {
  try {
    if (mensagem.notification != null) {
      // O próprio Android já mostrou a notificação; só evita que o app repita
      // o mesmo aviso quando for aberto.
      await Notificacoes.marcarAvisoDoMes();
      return;
    }
    final texto = PushFirebase._textoDoAlerta(mensagem);
    if (texto != null) await Notificacoes.avisarLimite(texto);
  } catch (_) {
    // Sem como avisar em segundo plano: o alerta aparece ao abrir o app.
  }
}

sealed class ResultadoPush {}

class PushAtivado extends ResultadoPush {
  final String token;
  PushAtivado(this.token);
}

/// Firebase ainda não configurado (firebase_options.dart provisório) ou
/// plataforma/navegador sem suporte a push.
class PushIndisponivel extends ResultadoPush {}

class PushSemPermissao extends ResultadoPush {}

/// O token foi obtido, mas o backend não aceitou ou não respondeu (por exemplo,
/// `POST /devices` ainda não existe e responde 404).
class PushNaoRegistrado extends ResultadoPush {}

/// Alerta do limite por push (Firebase Cloud Messaging), para avisar mesmo com
/// o app fechado. O backend envia o push quando o mês passa de 80% do limite
/// para os aparelhos cadastrados em `POST /devices`.
///
/// Tudo aqui é "melhor esforço": sem Firebase configurado, sem permissão ou sem
/// as rotas no backend, o app segue normal com a notificação local.
class PushFirebase {
  static Future<bool>? _iniciando;
  static StreamSubscription<String>? _assinaturaToken;
  static StreamSubscription<RemoteMessage>? _assinaturaMensagens;

  static const _tempoLimite = Duration(seconds: 5);
  static const _chaveToken = 'push_token_aparelho';

  static bool get suportado =>
      kIsWeb || defaultTargetPlatform == TargetPlatform.android;

  static String get _plataforma => kIsWeb ? 'web' : 'android';

  /// Inicia o Firebase e os ouvintes do push. Pode ser chamado várias vezes.
  /// Se as notificações já estavam ligadas, renova o cadastro do aparelho.
  static Future<bool> iniciar() => _iniciando ??= _iniciar().then((ok) {
        // Se falhou (ex.: sem rede na web), tenta de novo na próxima chamada.
        if (!ok) _iniciando = null;
        return ok;
      });

  static Future<bool> _iniciar() async {
    if (!suportado) return false;
    final FirebaseOptions opcoes;
    try {
      opcoes = DefaultFirebaseOptions.currentPlatform;
    } on UnsupportedError {
      // Ainda não rodaram `flutterfire configure`: segue sem push.
      return false;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: opcoes);
      }
      final mensageria = FirebaseMessaging.instance;
      if (!await mensageria.isSupported()) return false;

      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(tratarPushEmSegundoPlano);
      }
      // App aberto: o sistema não mostra o push sozinho, então vira
      // notificação local para o alerta não se perder.
      _assinaturaMensagens ??= FirebaseMessaging.onMessage.listen((mensagem) {
        final texto = _textoDoAlerta(mensagem);
        if (texto != null) unawaited(Notificacoes.avisarLimite(texto));
      });
      // O token de push do FCM (getToken/onTokenRefresh) é o que o backend usa
      // para enviar. As APIs novas (register/onRegistered) trabalham com outro
      // identificador, que o backend ainda não aceita.
      // ignore: deprecated_member_use
      _assinaturaToken ??= mensageria.onTokenRefresh.listen((token) async {
        if (await Notificacoes.estaoAtivas()) {
          await _guardarToken(token);
          await _registrarNoBackend(token);
        }
      });
    } catch (_) {
      return false;
    }

    if (await Notificacoes.estaoAtivas()) unawaited(_renovarCadastro());
    return true;
  }

  /// Liga o push: pede a permissão, pega o token e cadastra no backend.
  /// Deve ser chamado a partir do toque na opção do Perfil (por causa da web).
  static Future<ResultadoPush> ativar() async {
    if (!await iniciar()) return PushIndisponivel();
    try {
      final permissao = await FirebaseMessaging.instance.requestPermission();
      if (!_permitido(permissao.authorizationStatus)) return PushSemPermissao();

      final token = await _obterToken();
      if (token == null) return PushIndisponivel();
      // A pessoa pode ter desligado a opção enquanto o token era pedido.
      if (!await Notificacoes.estaoAtivas()) return PushIndisponivel();
      return await _registrarNoBackend(token)
          ? PushAtivado(token)
          : PushNaoRegistrado();
    } catch (_) {
      return PushIndisponivel();
    }
  }

  /// Desliga o push neste aparelho: tira o cadastro do backend e apaga o token.
  /// Chamar também ao sair da conta, ANTES de apagar o token de login.
  static Future<void> desativar() async {
    try {
      // Usa o token guardado: pedir um novo aqui abriria o pedido de permissão
      // do navegador bem na hora de sair da conta.
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_chaveToken);
      if (token == null) return;
      await _removerDoBackend(token);
      await prefs.remove(_chaveToken);
      // Apagar o token no FCM não precisa do login: não segura a saída.
      unawaited(_apagarTokenFcm());
    } catch (_) {
      // Sem rede: o backend descarta o token quando o FCM disser que expirou.
    }
  }

  static Future<void> _apagarTokenFcm() async {
    try {
      if (!await iniciar()) return;
      // ignore: deprecated_member_use
      await FirebaseMessaging.instance.deleteToken().timeout(_tempoLimite);
    } catch (_) {}
  }

  /// Cadastra de novo o token atual (o POST é idempotente), sem pedir permissão.
  static Future<void> _renovarCadastro() async {
    try {
      if (await ArmazenamentoToken.obter() == null) return;
      final configuracao =
          await FirebaseMessaging.instance.getNotificationSettings();
      if (!_permitido(configuracao.authorizationStatus)) return;
      final token = await _obterToken();
      if (token != null) await _registrarNoBackend(token);
    } catch (_) {
      // Tenta de novo na próxima abertura do app.
    }
  }

  static bool _permitido(AuthorizationStatus status) =>
      status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;

  static Future<String?> _obterToken() async {
    if (kIsWeb && chaveVapidFirebase.isEmpty) return null;
    final token = await FirebaseMessaging.instance
        // ignore: deprecated_member_use
        .getToken(
          vapidKey: kIsWeb ? chaveVapidFirebase : null,
          // Caminho relativo: respeita o <base href> (o site fica em
          // /co2bank-dart/ no GitHub Pages). Fica em firebase/ para não dividir
          // o escopo com o flutter_service_worker.js.
          serviceWorkerScriptPath:
              kIsWeb ? 'firebase/firebase-messaging-sw.js' : null,
        )
        .timeout(_tempoLimite);
    if (token == null || token.isEmpty) return null;
    // Para o teste pelo console do Firebase (só aparece no `flutter run`).
    if (kDebugMode) debugPrint('Token do push (FCM): $token');
    await _guardarToken(token);
    return token;
  }

  /// Guarda o token para conseguir tirar o cadastro depois (Perfil ou sair).
  static Future<void> _guardarToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveToken, token);
  }

  static Future<ClienteApi?> _clienteAutenticado() async {
    final jwt = await ArmazenamentoToken.obter();
    if (jwt == null) return null;
    return ClienteApi()..definirToken(jwt);
  }

  static Future<bool> _registrarNoBackend(String token) async {
    try {
      final cliente = await _clienteAutenticado();
      if (cliente == null) return false;
      final resposta = await cliente.post('/devices', {
        'token': token,
        'platform': _plataforma,
      }).timeout(_tempoLimite);
      return resposta.sucesso;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _removerDoBackend(String token) async {
    try {
      final cliente = await _clienteAutenticado();
      if (cliente == null) return;
      await cliente
          .delete('/devices/${Uri.encodeComponent(token)}')
          .timeout(_tempoLimite);
    } catch (_) {
      // 404 (rota ainda não existe) ou sem rede: nada a fazer.
    }
  }

  static String? _textoDoAlerta(RemoteMessage mensagem) {
    final texto = mensagem.notification?.body ??
        mensagem.data['body'] ??
        mensagem.data['message'] ??
        mensagem.data['mensagem'];
    if (texto is! String || texto.trim().isEmpty) return null;
    return texto;
  }
}
