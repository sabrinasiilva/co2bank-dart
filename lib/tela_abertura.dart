import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'nucleo/cores_app.dart';
import 'compartilhado/widgets/logo_animada.dart';
import 'autenticacao/telas/tela_login.dart';
import 'nucleo/tipografia.dart';

/// Abertura do app: a logo se monta peça por peça (o "C" se desenha, a semente
/// cai e as folhas brotam) e o nome aparece letra por letra embaixo.
class TelaAbertura extends StatefulWidget {
  const TelaAbertura({super.key});

  @override
  State<TelaAbertura> createState() => _TelaAberturaState();
}

class _TelaAberturaState extends State<TelaAbertura>
    with SingleTickerProviderStateMixin {
  static const _nome = 'CO2Bank';

  late final AnimationController _controlador;
  late final Animation<double> _montagemLogo;
  Timer? _timerParaLogin;

  @override
  void initState() {
    super.initState();
    _controlador = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    );
    _montagemLogo = CurvedAnimation(
      parent: _controlador,
      curve: const Interval(0, 0.72),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controlador.isAnimating || _controlador.isCompleted) return;
    // Quem desligou as animações no celular vai direto para o fim.
    if (MediaQuery.of(context).disableAnimations) {
      _controlador.value = 1;
      _timerParaLogin = Timer(const Duration(milliseconds: 600), _irParaLogin);
      return;
    }
    _controlador.forward().whenComplete(() {
      _timerParaLogin = Timer(const Duration(milliseconds: 350), _irParaLogin);
    });
  }

  void _irParaLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const TelaLogin(),
        transitionDuration: const Duration(milliseconds: 550),
        transitionsBuilder: (_, animacao, _, filho) {
          final suave = CurvedAnimation(parent: animacao, curve: Curves.easeOut);
          return FadeTransition(
            opacity: suave,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.04, end: 1).animate(suave),
              child: filho,
            ),
          );
        },
      ),
    );
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
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LogoAnimada(progresso: _montagemLogo, largura: 170),
            const SizedBox(height: 28),
            AnimatedBuilder(
              animation: _controlador,
              builder: (context, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < _nome.length; i++) _letra(i),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Cada letra sobe e aparece um pouco depois da anterior.
  Widget _letra(int indice) {
    const inicio = 0.66;
    const passo = 0.035;
    final comeco = inicio + indice * passo;
    final t = Interval(comeco, (comeco + 0.14).clamp(0, 1), curve: Curves.easeOut)
        .transform(_controlador.value);
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, (1 - t) * 12),
        child: Text(
          _nome[indice],
          style: GoogleFonts.outfit(
            fontSize: Tipografia.marca,
            fontWeight: FontWeight.bold,
            color: CoresApp.brandText,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
