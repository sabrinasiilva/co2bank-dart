import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../nucleo/registro_erros.dart';

/// Entrar de novo sem digitar tudo, como nos apps de banco: o e-mail fica
/// salvo e, se a pessoa quiser, a biometria do próprio celular (digital ou
/// rosto) libera o login.
///
/// Com a biometria ativa, o e-mail e a senha ficam no cofre do sistema
/// (Keystore no Android), e o app só lê de lá depois que o celular confirma
/// a digital ou o rosto. A senha nunca fica no SharedPreferences.
class AcessoBiometrico {
  AcessoBiometrico._();

  static const _chaveEmail = 'ultimo_email';
  static const _chaveJaPerguntou = 'biometria_ja_perguntou';
  static const _chaveCredenciais = 'credenciais_biometria';

  static final _biometria = LocalAuthentication();
  static const _cofre = FlutterSecureStorage();

  static Future<String?> emailSalvo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_chaveEmail);
  }

  static Future<void> salvarEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveEmail, email.trim().toLowerCase());
  }

  /// Se o celular tem algum bloqueio de tela que o app pode pedir: digital,
  /// rosto ou o PIN, padrão ou senha do próprio aparelho. Na web nunca tem.
  static Future<bool> disponivel() async {
    if (kIsWeb) return false;
    try {
      return await _biometria.isDeviceSupported();
    } catch (e, pilha) {
      registrarErro(e, pilha, contexto: 'AcessoBiometrico.disponivel');
      return false;
    }
  }

  /// Se a pessoa ativou a biometria para o e-mail salvo.
  static Future<bool> ativa() async {
    if (kIsWeb) return false;
    final email = await emailSalvo();
    final credenciais = await _lerCofre();
    return credenciais != null && credenciais.email == email;
  }

  /// Já perguntamos se ela quer usar a biometria (para não perguntar de novo
  /// a cada login quando ela disse "agora não").
  static Future<bool> jaPerguntou() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_chaveJaPerguntou) ?? false;
  }

  static Future<void> marcarPerguntado() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chaveJaPerguntou, true);
  }

  /// Pede a digital ou o rosto. Se a pessoa preferir, o próprio sistema deixa
  /// usar o PIN ou o padrão do celular.
  static Future<bool> confirmarIdentidade(String motivo) async {
    try {
      return await _biometria.authenticate(
        localizedReason: motivo,
        options: const AuthenticationOptions(stickyAuth: true),
      );
    } on PlatformException catch (e, pilha) {
      registrarErro(e, pilha, contexto: 'AcessoBiometrico.confirmarIdentidade');
      return false;
    }
  }

  /// Liga a biometria: confirma a identidade e guarda as credenciais no cofre.
  static Future<bool> ativar({required String email, required String senha}) async {
    final confirmou =
        await confirmarIdentidade('Confirme para entrar com biometria no CO2Bank');
    if (!confirmou) return false;
    try {
      await _cofre.write(
        key: _chaveCredenciais,
        value: jsonEncode({'email': email.trim().toLowerCase(), 'senha': senha}),
      );
      await salvarEmail(email);
      return true;
    } catch (e, pilha) {
      registrarErro(e, pilha, contexto: 'AcessoBiometrico.ativar');
      return false;
    }
  }

  static Future<void> desativar() async {
    try {
      await _cofre.delete(key: _chaveCredenciais);
    } catch (e, pilha) {
      registrarErro(e, pilha, contexto: 'AcessoBiometrico.desativar');
    }
  }

  /// Pede a biometria e devolve o e-mail e a senha guardados, ou nulo se a
  /// pessoa cancelou ou a biometria não está ativa.
  static Future<({String email, String senha})?> credenciais() async {
    final guardadas = await _lerCofre();
    if (guardadas == null) return null;
    final confirmou = await confirmarIdentidade('Entre no CO2Bank');
    return confirmou ? guardadas : null;
  }

  static Future<({String email, String senha})?> _lerCofre() async {
    try {
      final texto = await _cofre.read(key: _chaveCredenciais);
      if (texto == null) return null;
      final dados = jsonDecode(texto) as Map<String, dynamic>;
      return (email: dados['email'] as String, senha: dados['senha'] as String);
    } catch (e, pilha) {
      registrarErro(e, pilha, contexto: 'AcessoBiometrico._lerCofre');
      return null;
    }
  }
}
