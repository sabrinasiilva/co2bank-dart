import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'nucleo/cores_app.dart';
import 'tela_splash.dart';

void main() {
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
