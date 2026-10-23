import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../../nucleo/registro_erros.dart';

/// Versão nova do APK publicada pelo GitHub Actions.
class AtualizacaoDisponivel {
  final String versao;
  final int build;
  final Uri linkApk;

  const AtualizacaoDisponivel({
    required this.versao,
    required this.build,
    required this.linkApk,
  });
}

/// O app é instalado pelo APK, fora da Play Store, então ninguém fica sabendo
/// quando sai versão nova. A cada publicação, o workflow grava um versao.json
/// no site com o número do build; aqui o app compara com o build instalado.
class VerificadorAtualizacao {
  VerificadorAtualizacao._();

  static final _endereco =
      Uri.parse('https://sabrinasiilva.github.io/co2bank-dart/versao.json');

  static AtualizacaoDisponivel? _ultima;
  static DateTime? _consultadoEm;

  /// Nulo quando o app está atualizado, na web (o site já abre sempre na
  /// versão nova) ou rodando pelo `flutter run`.
  static Future<AtualizacaoDisponivel?> verificar() async {
    if (kIsWeb || kDebugMode || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }
    // Uma consulta a cada 10 minutos basta.
    final agora = DateTime.now();
    if (_consultadoEm != null && agora.difference(_consultadoEm!).inMinutes < 10) {
      return _ultima;
    }
    try {
      final instalado = await PackageInfo.fromPlatform();
      // O parâmetro evita receber uma cópia antiga guardada em cache.
      final resposta = await http
          .get(_endereco.replace(queryParameters: {'t': '${agora.millisecondsSinceEpoch}'}))
          .timeout(const Duration(seconds: 10));
      if (resposta.statusCode != 200) return null;
      _ultima = comparar(
        buildInstalado: int.tryParse(instalado.buildNumber) ?? 0,
        publicado: jsonDecode(resposta.body) as Map<String, dynamic>,
      );
      _consultadoEm = agora;
      return _ultima;
    } catch (e, pilha) {
      registrarErro(e, pilha, contexto: 'VerificadorAtualizacao.verificar');
      return null;
    }
  }

  /// Regra separada da rede para dar para testar.
  @visibleForTesting
  static AtualizacaoDisponivel? comparar({
    required int buildInstalado,
    required Map<String, dynamic> publicado,
  }) {
    final build = publicado['build'] as int? ?? 0;
    final link = Uri.tryParse(publicado['apk'] as String? ?? '');
    if (build <= buildInstalado || link == null || !link.hasScheme) return null;
    return AtualizacaoDisponivel(
      versao: publicado['versao'] as String? ?? '',
      build: build,
      linkApk: link,
    );
  }
}
