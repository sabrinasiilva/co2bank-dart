import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'nucleo/cores_app.dart';
import 'inicio/aba_inicio.dart';
import 'transacoes/telas/aba_transacoes.dart';
import 'co2/aba_co2.dart';
import 'perfil/aba_perfil.dart';
import 'compartilhado/widgets/menu_lateral.dart';

class Navegacao extends StatefulWidget {
  const Navegacao({super.key});

  @override
  State<Navegacao> createState() => _NavegacaoState();
}

class _NavegacaoState extends State<Navegacao> {
  int _abaAtual = 0;
  int _versaoDados = 0;
  late final List<Widget> _abas;

  @override
  void initState() {
    super.initState();
    _abas = [
      AbaInicio(aoVerTransacoes: () => setState(() => _abaAtual = 1)),
      const AbaTransacoes(),
      const AbaCo2(),
      const AbaPerfil(),
    ];
  }

  static const _itensNavegacao = [
    BottomNavigationBarItem(
        icon: Icon(Icons.home_rounded), label: 'Início'),
    BottomNavigationBarItem(
        icon: Icon(Icons.receipt_long_rounded), label: 'Extrato'),
    BottomNavigationBarItem(
        icon: Icon(Icons.eco_rounded), label: 'CO2'),
    BottomNavigationBarItem(
        icon: Icon(Icons.person_rounded), label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.background,
      drawer: MenuLateral(
        abaAtual: _abaAtual,
        aoNavegar: (i) => setState(() => _abaAtual = i),
        aoDadosAlterados: () => setState(() => _versaoDados++),
      ),
      // A chave muda quando chegam dados novos (ex.: sincronização do Open
      // Finance), o que recria as abas e faz cada uma buscar de novo na API.
      body: IndexedStack(
        index: _abaAtual,
        children: [
          for (var i = 0; i < _abas.length; i++)
            KeyedSubtree(key: ValueKey('$i-$_versaoDados'), child: _abas[i]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _abaAtual,
        onTap: (i) => setState(() => _abaAtual = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: CoresApp.surface,
        selectedItemColor: CoresApp.dark,
        unselectedItemColor: CoresApp.gray,
        selectedLabelStyle: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.outfit(fontSize: 11),
        elevation: 0,
        items: _itensNavegacao,
      ),
    );
  }
}
