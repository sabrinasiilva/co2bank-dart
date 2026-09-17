import '../core/api_client.dart';
import '../core/token_storage.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String cpf;
  final String phone;
  final double co2LimitKg;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.cpf,
    required this.phone,
    required this.co2LimitKg,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        cpf: json['cpf'] as String,
        phone: json['phone'] as String? ?? '',
        co2LimitKg: (json['co2_limit_kg'] as num).toDouble(),
      );
}

class UserService {
  final ApiClient _client;

  UserService._(this._client);

  static Future<UserService> authenticated() async {
    final client = ApiClient();
    final token = await TokenStorage.get();
    if (token != null) client.setToken(token);
    return UserService._(client);
  }

  Future<UserProfile?> getMe() async {
    try {
      final response = await _client.get('/auth/me');
      if (response.ok) return UserProfile.fromJson(response.body);
      return null;
    } catch (_) {
      return null;
    }
  }
}
