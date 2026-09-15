import 'dart:convert';

import 'package:http/http.dart' as http;

/// Endereço base da API do backend (Co2Bank-flask) em desenvolvimento local.
/// Em Android emulator, "localhost" da máquina host é 10.0.2.2.
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:5000',
);

class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> get(String path) async {
    final response = await _client.get(Uri.parse('$apiBaseUrl$path'));
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
