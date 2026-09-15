import '../core/api_client.dart';

class Co2BankApi {
  final ApiClient _client;

  Co2BankApi({ApiClient? client}) : _client = client ?? ApiClient();

  Future<bool> checkHealth() async {
    final result = await _client.get('/health');
    return result['status'] == 'ok';
  }
}
