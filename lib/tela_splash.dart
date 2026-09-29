import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'nucleo/cores_app.dart';
import 'autenticacao/telas/tela_login.dart';

class TelaSplash extends StatefulWidget {
  const TelaSplash({super.key});

  @override
  State<TelaSplash> createState() => _TelaSplashState();
}

class _TelaSplashState extends State<TelaSplash>
    with SingleTickerProviderStateMixin {
  late AnimationController _controlador;
  late Animation<double> _animacaoFade;
  late Animation<Offset> _animacaoDeslizamento;

  @override
  void initState() {
    super.initState();
    _controlador = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animacaoFade =
        CurvedAnimation(parent: _controlador, curve: Curves.easeIn);
    _animacaoDeslizamento = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controlador, curve: Curves.easeOut));

    _controlador.forward();

    Future.delayed(const Duration(milliseconds: 2500), () {
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
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.darkGreen,
      body: Center(
        child: FadeTransition(
          opacity: _animacaoFade,
          child: SlideTransition(
            position: _animacaoDeslizamento,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    size: 48,
                    color: CoresApp.mintGreen,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'CO2Bank',
                  style: GoogleFonts.outfit(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Seu bolso. O planeta. Em equilíbrio.',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
