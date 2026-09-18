import '../core/api_client.dart';
import '../core/token_storage.dart';

class ForgotPasswordResult {
  final bool success;
  final String? resetToken;
  final String? error;

  ForgotPasswordResult.ok(this.resetToken) : success = true, error = null;
  ForgotPasswordResult.fail(this.error) : success = false, resetToken = null;
}

class ResetPasswordResult {
  final bool success;
  final String? error;

  ResetPasswordResult.ok() : success = true, error = null;
  ResetPasswordResult.fail(this.error) : success = false;
}

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
    String? facePhoto,
  }) async {
    try {
      final body = {
        'name': name,
        'email': email,
        'cpf': cpf,
        'phone': phone,
        'birth_date': birthDate,
        'password': password,
        'co2_limit_kg': co2LimitKg,
        if (facePhoto != null) 'face_photo': facePhoto,
      };
      final response = await _client.post('/auth/register', body);

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

  Future<ForgotPasswordResult> verifyForgotPassword({
    required String email,
    required String cpf,
    required String birthDate,
  }) async {
    try {
      final response = await _client.post('/auth/forgot-password/verify', {
        'email': email,
        'cpf': cpf,
        'birth_date': birthDate,
      });
      if (response.ok) {
        return ForgotPasswordResult.ok(response.body['reset_token'] as String);
      }
      return ForgotPasswordResult.fail(response.error ?? 'Dados inválidos');
    } catch (_) {
      return ForgotPasswordResult.fail('Não foi possível conectar ao servidor');
    }
  }

  Future<ResetPasswordResult> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      final response = await _client.post('/auth/reset-password', {
        'reset_token': resetToken,
        'new_password': newPassword,
      });
      if (response.ok) return ResetPasswordResult.ok();
      return ResetPasswordResult.fail(response.error ?? 'Erro ao redefinir senha');
    } catch (_) {
      return ResetPasswordResult.fail('Não foi possível conectar ao servidor');
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
