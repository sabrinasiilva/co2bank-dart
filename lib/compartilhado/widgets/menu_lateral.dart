import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../nucleo/cores_app.dart';
import '../../nucleo/armazenamento_token.dart';
import '../../nucleo/push_firebase.dart';
import '../../perfil/servico/servico_usuario.dart';
import '../../autenticacao/telas/tela_login.dart';
import '../../recompensas/tela_recompensas.dart';
import '../../open_finance/tela_open_finance.dart';
import '../../nucleo/tipografia.dart';

class MenuLateral extends StatelessWidget {
  final int abaAtual;
  final ValueChanged<int> aoNavegar;

  const MenuLateral({
    super.key,
    required this.abaAtual,
    required this.aoNavegar,
  });

  static const _itens = [
    _ItemMenu(icone: Icons.home_rounded, rotulo: 'Início', indice: 0),
    _ItemMenu(
        icone: Icons.receipt_long_rounded,
        rotulo: 'Extrato de Transações',
        indice: 1),
    _ItemMenu(
        icone: Icons.eco_rounded, rotulo: 'Limite Ecológico', indice: 2),
    _ItemMenu(icone: Icons.person_rounded, rotulo: 'Perfil', indice: 3),
  ];

  void _navegar(BuildContext context, int indice) {
    Navigator.pop(context);
    aoNavegar(indice);
  }

  void _abrirRecompensas(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TelaRecompensas()),
    );
  }

  void _abrirOpenFinance(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TelaOpenFinance(aoVerExtrato: () => aoNavegar(1)),
      ),
    );
  }

  Future<void> _sair(BuildContext context) async {
    Navigator.pop(context);
    // Tira o aparelho do push antes de apagar o login (a rota exige o JWT).
    await PushFirebase.desativar();
    await ArmazenamentoToken.limpar();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const TelaLogin()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: CoresApp.surface,
      child: Column(
        children: [
          _CabecalhoDrawer(),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ..._itens.map(
                  (item) => _ItemDrawer(
                    icone: item.icone,
                    rotulo: item.rotulo,
                    ativo: abaAtual == item.indice,
                    aoTocar: () => _navegar(context, item.indice),
                  ),
                ),
                _ItemDrawer(
                  icone: Icons.star_rounded,
                  rotulo: 'Recompensas',
                  ativo: false,
                  aoTocar: () => _abrirRecompensas(context),
                ),
                _ItemDrawer(
                  icone: Icons.account_balance_rounded,
                  rotulo: 'Open Finance',
                  ativo: false,
                  aoTocar: () => _abrirOpenFinance(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _ItemDrawer(
            icone: Icons.logout_rounded,
            rotulo: 'Sair',
            ativo: false,
            perigoso: true,
            aoTocar: () => _sair(context),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _CabecalhoDrawer extends StatefulWidget {
  @override
  State<_CabecalhoDrawer> createState() => _CabecalhoDrawerState();
}

class _CabecalhoDrawerState extends State<_CabecalhoDrawer> {
  PerfilUsuario? _perfil;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    final servico = await ServicoUsuario.autenticado();
    final resultado = await servico.obterPerfil();
    switch (resultado) {
      case PerfilCarregado(:final perfil):
        if (mounted) setState(() => _perfil = perfil);
      case PerfilIndisponivel():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nome = _perfil?.nome ?? '';
    final email = _perfil?.email ?? '';
    final inicial = nome.isNotEmpty ? nome[0].toUpperCase() : '?';

    return Container(
      width: double.infinity,
      color: CoresApp.dark,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 28,
        left: 24,
        right: 24,
        bottom: 28,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: CoresApp.primaryMuted.withValues(alpha: 0.35),
              shape: BoxShape.circle,
              border: Border.all(color: CoresApp.primary, width: 2),
            ),
            child: Center(
              child: Text(
                inicial,
                style: GoogleFonts.outfit(
                  fontSize: Tipografia.tituloSecao,
                  fontWeight: FontWeight.bold,
                  color: CoresApp.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome.isEmpty ? 'Carregando...' : nome,
                  style: GoogleFonts.outfit(
                    fontSize: Tipografia.destaque,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: GoogleFonts.outfit(
                      fontSize: Tipografia.legenda,
                      color: Colors.white54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemDrawer extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final bool ativo;
  final bool perigoso;
  final VoidCallback aoTocar;

  const _ItemDrawer({
    required this.icone,
    required this.rotulo,
    required this.ativo,
    required this.aoTocar,
    this.perigoso = false,
  });

  @override
  Widget build(BuildContext context) {
    final cor = perigoso
        ? Colors.red
        : ativo
            ? CoresApp.dark
            : CoresApp.textSecondary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: ativo
            ? CoresApp.primaryMuted.withValues(alpha: 0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icone, size: 22, color: cor),
        title: Text(
          rotulo,
          style: GoogleFonts.outfit(
            fontSize: Tipografia.corpo,
            fontWeight: ativo ? FontWeight.w700 : FontWeight.w500,
            color: cor,
          ),
        ),
        trailing: ativo
            ? Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: CoresApp.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            : null,
        onTap: aoTocar,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _ItemMenu {
  final IconData icone;
  final String rotulo;
  final int indice;

  const _ItemMenu({
    required this.icone,
    required this.rotulo,
    required this.indice,
  });
}
