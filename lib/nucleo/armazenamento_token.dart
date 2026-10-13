import 'package:shared_preferences/shared_preferences.dart';

class ArmazenamentoToken {
  static const _chave = 'auth_token';

  static Future<void> salvar(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chave, token);
  }

  static Future<String?> obter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_chave);
  }

  static Future<void> limpar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chave);
  }
}
