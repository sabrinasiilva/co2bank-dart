import 'dart:convert';

import 'package:http/http.dart' as http;

const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:5000',
);

class ApiClient {
  final http.Client _client;
  String? _token;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  void setToken(String token) => _token = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<ApiResponse> get(String path) async {
    final response = await _client.get(
      Uri.parse('$apiBaseUrl$path'),
      headers: _headers,
    );
    return ApiResponse(response.statusCode, _decode(response.body));
  }

  Future<ApiResponse> post(String path, Map<String, dynamic> body) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return ApiResponse(response.statusCode, _decode(response.body));
  }

  Map<String, dynamic> _decode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {'error': 'Resposta inválida do servidor'};
    }
  }
}

class ApiResponse {
  final int statusCode;
  final Map<String, dynamic> body;

  ApiResponse(this.statusCode, this.body);

  bool get ok => statusCode >= 200 && statusCode < 300;
  String? get error => body['error'] as String?;
}
