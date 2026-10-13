import 'dart:convert';

import 'package:http/http.dart' as http;

const String urlBaseApi = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://co2bank-flask.onrender.com',
);

class ClienteApi {
  final http.Client _cliente;
  String? _token;

  ClienteApi({http.Client? cliente}) : _cliente = cliente ?? http.Client();

  void definirToken(String token) => _token = token;

  Map<String, String> get _cabecalhos => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<RespostaApi> get(String caminho) async {
    final resposta = await _cliente.get(
      Uri.parse('$urlBaseApi$caminho'),
      headers: _cabecalhos,
    );
    return RespostaApi(resposta.statusCode, _decodificar(resposta.body));
  }

  Future<RespostaApi> post(String caminho, Map<String, dynamic> corpo) async {
    final resposta = await _cliente.post(
      Uri.parse('$urlBaseApi$caminho'),
      headers: _cabecalhos,
      body: jsonEncode(corpo),
    );
    return RespostaApi(resposta.statusCode, _decodificar(resposta.body));
  }

  Future<RespostaApi> delete(String caminho) async {
    final resposta = await _cliente.delete(
      Uri.parse('$urlBaseApi$caminho'),
      headers: _cabecalhos,
    );
    return RespostaApi(resposta.statusCode, _decodificar(resposta.body));
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
