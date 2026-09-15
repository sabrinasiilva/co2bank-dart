import '../core/api_client.dart';

class Co2BankApi {
  final ApiClient _client;

  Co2BankApi({ApiClient? client}) : _client = client ?? ApiClient();

  Future<bool> checkHealth() async {
    final response = await _client.get('/health');
    return response.ok && response.body['status'] == 'ok';
  }
}
