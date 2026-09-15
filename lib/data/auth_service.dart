import '../core/api_client.dart';
import '../core/token_storage.dart';

class AuthResult {
  final bool success;
  final String? token;
  final String? error;

  AuthResult.ok(this.token)
      : success = true,
        error = null;

  AuthResult.fail(this.error)
      : success = false,
        token = null;
}

class AuthService {
  final ApiClient _client;

  AuthService({ApiClient? client}) : _client = client ?? ApiClient();

  Future<AuthResult> register({
    required String name,
    required String email,
    required String cpf,
    required String phone,
    required String birthDate,
    required String password,
    required double co2LimitKg,
  }) async {
    try {
      final response = await _client.post('/auth/register', {
        'name': name,
        'email': email,
        'cpf': cpf,
        'phone': phone,
        'birth_date': birthDate,
        'password': password,
        'co2_limit_kg': co2LimitKg,
      });

      if (response.ok) {
        final token = response.body['token'] as String;
        await TokenStorage.save(token);
        return AuthResult.ok(token);
      }

      return AuthResult.fail(response.error ?? 'Erro ao criar conta');
    } catch (_) {
      return AuthResult.fail('Não foi possível conectar ao servidor');
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (response.ok) {
        final token = response.body['token'] as String;
        await TokenStorage.save(token);
        return AuthResult.ok(token);
      }

      return AuthResult.fail(response.error ?? 'E-mail ou senha incorretos');
    } catch (_) {
      return AuthResult.fail('Não foi possível conectar ao servidor');
    }
  }
}
