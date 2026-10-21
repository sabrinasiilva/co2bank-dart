import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'nucleo/cores_app.dart';
import 'compartilhado/widgets/logo_co2bank.dart';
import 'autenticacao/telas/tela_login.dart';

class TelaAbertura extends StatefulWidget {
  const TelaAbertura({super.key});

  @override
  State<TelaAbertura> createState() => _TelaAberturaState();
}

class _TelaAberturaState extends State<TelaAbertura>
    with SingleTickerProviderStateMixin {
  late AnimationController _controlador;
  late Animation<double> _animacaoFade;
  late Animation<Offset> _animacaoDeslizamento;
  Timer? _timerParaLogin;

  @override
  void initState() {
    super.initState();
    _controlador = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animacaoFade = CurvedAnimation(parent: _controlador, curve: Curves.easeIn);
    _animacaoDeslizamento = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controlador, curve: Curves.easeOut));

    _controlador.forward();

    _timerParaLogin = Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const TelaLogin(),
          transitionsBuilder: (_, animacao, _, filho) =>
              FadeTransition(opacity: animacao, child: filho),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timerParaLogin?.cancel();
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.surface,
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: MediaQuery.of(context).size.height * 0.22,
            child: const DecoratedBox(
              decoration: BoxDecoration(gradient: CoresApp.brandGradient),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _animacaoFade,
              child: SlideTransition(
                position: _animacaoDeslizamento,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LogoCo2Bank(tamanho: 120),
                    const SizedBox(height: 24),
                    Text(
                      'CO2Bank',
                      style: GoogleFonts.outfit(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: CoresApp.brandText,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'As finanças de quem se importa.',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: CoresApp.textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
