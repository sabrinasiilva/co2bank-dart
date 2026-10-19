import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'nucleo/cores_app.dart';
import 'nucleo/notificacoes.dart';
import 'tela_splash.dart';

void main() {
  // A Outfit vem dentro do app (assets/google_fonts); não precisa baixar nada.
  GoogleFonts.config.allowRuntimeFetching = false;
  WidgetsFlutterBinding.ensureInitialized();
  // Sem await para não atrasar a abertura do app.
  unawaited(Notificacoes.iniciar());
  runApp(const AplicativoCo2Bank());
}

class AplicativoCo2Bank extends StatelessWidget {
  const AplicativoCo2Bank({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CO2Bank',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: CoresApp.darkGreen),
        scaffoldBackgroundColor: CoresApp.background,
        fontFamily: 'Outfit',
      ),
      home: const TelaSplash(),
    );
  }
}
