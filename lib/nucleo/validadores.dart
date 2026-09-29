class Validadores {
  static bool cpfValido(String cpf) {
    final digits = cpf.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length != 11) return false;
    if (RegExp(r'^(\d)\1{10}$').hasMatch(digits)) return false;

    int sum = 0;
    for (int i = 0; i < 9; i++) { sum += int.parse(digits[i]) * (10 - i); }
    int r = (sum * 10) % 11;
    if (r >= 10) r = 0;
    if (r != int.parse(digits[9])) return false;

    sum = 0;
    for (int i = 0; i < 10; i++) { sum += int.parse(digits[i]) * (11 - i); }
    r = (sum * 10) % 11;
    if (r >= 10) r = 0;
    return r == int.parse(digits[10]);
  }

  static bool emailValido(String email) =>
      RegExp(r'^[\w\.\-\+]+@[\w\-]+\.\w{2,}$').hasMatch(email.trim());

  static bool telefoneValido(String telefone) {
    final digits = telefone.replaceAll(RegExp(r'[^\d]'), '');
    return digits.length >= 10 && digits.length <= 11;
  }

  static double forcaDaSenha(String senha) {
    if (senha.isEmpty) return 0;
    double s = 0;
    if (senha.length >= 8) s += 0.33;
    if (senha.contains(RegExp(r'[A-Z]'))) s += 0.33;
    if (senha.contains(RegExp(r'[0-9!@#$%^&*]'))) s += 0.34;
    return s;
  }
}
