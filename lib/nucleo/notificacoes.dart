import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'registro_erros.dart';

/// Notificação no celular (ou no navegador) quando o limite de CO2 do mês passa
/// de 80%. É uma notificação local: o próprio app dispara quando consulta o
/// alerta no backend. Com o app fechado, quem avisa é o push (push_firebase.dart).
class Notificacoes {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _iniciado = false;

  static const _chaveAtivas = 'notificacoes_ativas';
  static const _chaveUltimoAviso = 'notificacoes_ultimo_aviso_limite';
  static const _idAvisoLimite = 1;

  static const _detalhes = NotificationDetails(
    android: AndroidNotificationDetails(
      'alertas_limite',
      'Alertas do limite de CO2',
      channelDescription: 'Aviso quando o limite ecológico do mês passa de 80%',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
    web: WebNotificationDetails(),
  );

  static bool get suportado =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  static Future<void> iniciar() async {
    if (!suportado || _iniciado) return;
    try {
      final ok = await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          // A permissão é pedida só quando a pessoa liga a opção no Perfil.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          web: WebInitializationSettings(),
        ),
      );
      _iniciado = ok ?? false;
    } catch (e, pilha) {
      registrarErro(e, pilha, contexto: 'Notificacoes.iniciar');
      _iniciado = false;
    }
  }

  static Future<bool> estaoAtivas() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_chaveAtivas) ?? false;
  }

  /// Pede a permissão ao sistema. No navegador e no iPhone isso só funciona se
  /// for chamado a partir de um toque da pessoa (por isso fica na opção do Perfil).
  static Future<bool> ativar() async {
    if (!suportado) return false;
    await iniciar();
    if (!_iniciado) return false;

    bool? permitido;
    if (kIsWeb) {
      permitido = await _plugin
          .resolvePlatformSpecificImplementation<
            WebFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      permitido = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } else {
      permitido = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, sound: true);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chaveAtivas, permitido ?? false);
    return permitido ?? false;
  }

  static Future<void> desativar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chaveAtivas, false);
  }

  /// Mostra o aviso do limite, no máximo uma vez por mês.
  static Future<void> avisarLimite(String mensagem) async {
    if (!suportado || !await estaoAtivas()) return;
    await iniciar();
    if (!_iniciado) return;

    final mesAtual = _mesAtual();
    final prefs = await SharedPreferences.getInstance();
    // O push com o app fechado grava o aviso em outro isolate; relê do disco.
    await prefs.reload();
    if (prefs.getString(_chaveUltimoAviso) == mesAtual) return;

    try {
      await _plugin.show(
        id: _idAvisoLimite,
        title: 'Atenção ao seu limite de CO2',
        body: mensagem,
        notificationDetails: _detalhes,
      );
      await prefs.setString(_chaveUltimoAviso, mesAtual);
    } catch (e, pilha) {
      // Sem permissão ou sem suporte: o aviso continua aparecendo na tela inicial.
      registrarErro(e, pilha, contexto: 'Notificacoes.avisarLimite');
    }
  }

  /// Guarda que o aviso deste mês já foi dado (por exemplo, pelo push que chegou
  /// com o app fechado), para o app não repetir a mesma notificação depois.
  static Future<void> marcarAvisoDoMes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveUltimoAviso, _mesAtual());
  }

  static String _mesAtual() {
    final agora = DateTime.now();
    return '${agora.year}-${agora.month.toString().padLeft(2, '0')}';
  }
}
