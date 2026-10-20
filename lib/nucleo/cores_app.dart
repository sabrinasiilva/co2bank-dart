import 'package:flutter/material.dart';

class CoresApp {
  static const primary = Color(0xFF7ED957);
  static const primaryMuted = Color(0xFFC5E264);
  static const accent = Color(0xFFFFDE59);
  static const accentWarm = Color(0xFFFF914D);
  static const dark = Color(0xFF000000);
  static const gray = Color(0xFF737373);
  static const background = Color(0xFFF5F5F5);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF737373);
  static const border = Color(0xFFE5E7EB);

  // Nomes antigos, de antes da paleta preto + verde. darkGreen virou preto e já
  // deixou elementos invisíveis sobre cards pretos, por isso está depreciado.
  @Deprecated('É preto, não verde. Use CoresApp.dark ou CoresApp.primary.')
  static const darkGreen = dark;
  static const mintGreen = primary;
  static const orange = accentWarm;

  // Verde escuro do nome "CO2Bank" e dos títulos no material da marca (Canva).
  static const brandText = Color(0xFF2E4D1B);
  static const brandGradient = LinearGradient(
    colors: [primary, primaryMuted],
  );
}
