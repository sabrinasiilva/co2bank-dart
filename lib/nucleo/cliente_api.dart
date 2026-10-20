import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const String urlBaseApi = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://co2bank-flask.onrender.com',
);

class ClienteApi {
  /// Fica true enquanto houver alguma requisição passando de
  /// [limiteRequisicaoLenta]. O backend está no plano gratuito do Render e,
  /// depois de um tempo parado, a primeira chamada pode levar até um minuto
  /// enquanto o servidor acorda; o app usa isso para avisar o usuário.
  static final servidorDemorando = ValueNotifier<bool>(false);

  static const limiteRequisicaoLenta = Duration(seconds: 4);

  /// Folga para o servidor acordar (até ~1 min) sem deixar a tela
  /// carregando para sempre se ele não responder.
  static const tempoLimite = Duration(seconds: 90);

  static int _requisicoesLentas = 0;

  final http.Client _cliente;
  String? _token;

  ClienteApi({http.Client? cliente}) : _cliente = cliente ?? http.Client();

  void definirToken(String token) => _token = token;

  Map<String, String> get _cabecalhos => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<RespostaApi> get(String caminho) => _enviar(
        () => _cliente.get(
          Uri.parse('$urlBaseApi$caminho'),
          headers: _cabecalhos,
        ),
      );

  Future<RespostaApi> post(String caminho, Map<String, dynamic> corpo) =>
      _enviar(
        () => _cliente.post(
          Uri.parse('$urlBaseApi$caminho'),
          headers: _cabecalhos,
          body: jsonEncode(corpo),
        ),
      );

  Future<RespostaApi> delete(String caminho) => _enviar(
        () => _cliente.delete(
          Uri.parse('$urlBaseApi$caminho'),
          headers: _cabecalhos,
        ),
      );

  Future<RespostaApi> _enviar(
      Future<http.Response> Function() requisicao) async {
    var ficouLenta = false;
    final cronometro = Timer(limiteRequisicaoLenta, () {
      ficouLenta = true;
      _requisicoesLentas++;
      servidorDemorando.value = true;
    });
    try {
      final resposta = await requisicao().timeout(tempoLimite);
      return RespostaApi(resposta.statusCode, _decodificar(resposta.body));
    } finally {
      cronometro.cancel();
      if (ficouLenta) {
        _requisicoesLentas--;
        servidorDemorando.value = _requisicoesLentas > 0;
      }
    }
  }

  dynamic _decodificar(String corpo) {
    try {
      return jsonDecode(corpo);
    } catch (_) {
      return {'error': 'Resposta inválida do servidor'};
    }
  }
}

class RespostaApi {
  final int codigoStatus;
  final dynamic _bruto;

  RespostaApi(this.codigoStatus, this._bruto);

  bool get sucesso => codigoStatus >= 200 && codigoStatus < 300;

  Map<String, dynamic> get corpo {
    final bruto = _bruto;
    if (bruto is Map<String, dynamic>) return bruto;
    return {};
  }

  List<dynamic> get listaCorpo {
    final bruto = _bruto;
    if (bruto is List) return bruto;
    return [];
  }

  String? get erro => corpo['error'] as String?;
}
