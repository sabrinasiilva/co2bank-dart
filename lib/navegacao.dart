import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'nucleo/aviso_dados_alterados.dart';
import 'nucleo/cores_app.dart';
import 'inicio/aba_inicio.dart';
import 'transacoes/telas/aba_transacoes.dart';
import 'transacoes/telas/tela_nova_compra.dart';
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

  Future<void> _abrirNovaCompra() async {
    final registrou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TelaNovaCompra()),
    );
    if (registrou == true) AvisoDadosAlterados.instancia.avisar();
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
      ),
      // Quando chegam dados novos, cada aba recarrega sozinha ao ouvir o
      // AvisoDadosAlterados, sem ser recriada.
      body: IndexedStack(index: _abaAtual, children: _abas),
      // Nova compra só faz sentido nas abas que mostram as compras.
      floatingActionButton: _abaAtual <= 1
          ? FloatingActionButton.extended(
              onPressed: _abrirNovaCompra,
              backgroundColor: CoresApp.dark,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Nova compra',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
            )
          : null,
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
