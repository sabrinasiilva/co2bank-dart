import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../compartilhado/widgets/botao_primario.dart';
import '../../compartilhado/widgets/logo_co2bank.dart';
import '../../navegacao.dart';
import '../../nucleo/cores_app.dart';
import '../../open_finance/tela_open_finance.dart';
import '../../nucleo/tipografia.dart';

/// Primeira tela depois do cadastro: explica em poucos passos como o app
/// funciona e já oferece conectar o banco, para a Home não abrir vazia.
class TelaBoasVindas extends StatelessWidget {
  final String primeiroNome;

  /// O usuário já escolheu bancos no cadastro (a conexão roda em segundo plano).
  final bool bancoJaConectado;

  const TelaBoasVindas({
    super.key,
    this.primeiroNome = '',
    this.bancoJaConectado = false,
  });

  static const _passos = [
    (
      Icons.account_balance_rounded,
      'Conecte seu banco',
      'Pelo Open Finance suas compras chegam sozinhas. O acesso é só leitura.',
    ),
    (
      Icons.eco_rounded,
      'Veja o CO2 de cada compra',
      'Cada compra mostra quanto carbono ela gerou, sem você digitar nada.',
    ),
    (
      Icons.emoji_events_rounded,
      'Fique no limite e ganhe',
      'Acompanhe seu limite do mês e troque o que economizar por recompensas.',
    ),
  ];

  void _irParaInicio(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Navegacao()),
      (_) => false,
    );
  }

  Future<void> _conectarBanco(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TelaOpenFinance()),
    );
    if (context.mounted) _irParaInicio(context);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final saudacao = primeiroNome.isEmpty
        ? 'Que bom ter você aqui'
        : 'Que bom ter você aqui, $primeiroNome';

    return Scaffold(
      backgroundColor: CoresApp.primary,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: CoresApp.brandGradient),
          ),
          Positioned(
            top: size.height * 0.07,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const LogoCo2Bank(tamanho: 60, comSelo: true),
                const SizedBox(height: 10),
                Text(
                  'CO2Bank',
                  style: GoogleFonts.outfit(
                      fontSize: Tipografia.tituloSecao,
                      fontWeight: FontWeight.bold,
                      color: CoresApp.brandText),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: size.height * 0.74,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: CoresApp.background,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(saudacao,
                        style: GoogleFonts.outfit(
                            fontSize: Tipografia.titulo,
                            fontWeight: FontWeight.bold,
                            color: CoresApp.textPrimary)),
                    const SizedBox(height: 4),
                    Text('O CO2Bank funciona assim:',
                        style: GoogleFonts.outfit(
                            fontSize: Tipografia.corpo, color: CoresApp.textSecondary)),
                    const SizedBox(height: 24),
                    for (var i = 0; i < _passos.length; i++)
                      _Passo(
                        numero: i + 1,
                        icone: _passos[i].$1,
                        titulo: _passos[i].$2,
                        descricao: _passos[i].$3,
                      ),
                    const SizedBox(height: 16),
                    if (bancoJaConectado) ...[
                      BotaoPrimario(
                        rotulo: 'Começar',
                        aoTocar: () => _irParaInicio(context),
                      ),
                      const SizedBox(height: 8),
                      _BotaoSecundario(
                        rotulo: 'Ver meus bancos',
                        aoTocar: () => _conectarBanco(context),
                      ),
                    ] else ...[
                      BotaoPrimario(
                        rotulo: 'Conectar meu banco',
                        aoTocar: () => _conectarBanco(context),
                      ),
                      const SizedBox(height: 8),
                      _BotaoSecundario(
                        rotulo: 'Fazer isso depois',
                        aoTocar: () => _irParaInicio(context),
                      ),
                    ],
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

class _Passo extends StatelessWidget {
  final int numero;
  final IconData icone;
  final String titulo;
  final String descricao;

  const _Passo({
    required this.numero,
    required this.icone,
    required this.titulo,
    required this.descricao,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CoresApp.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: CoresApp.primaryMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icone, size: 20, color: CoresApp.brandText),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$numero. $titulo',
                    style: GoogleFonts.outfit(
                        fontSize: Tipografia.destaque,
                        fontWeight: FontWeight.w600,
                        color: CoresApp.textPrimary)),
                const SizedBox(height: 2),
                Text(descricao,
                    style: GoogleFonts.outfit(
                        fontSize: Tipografia.corpo,
                        color: CoresApp.textSecondary,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BotaoSecundario extends StatelessWidget {
  final String rotulo;
  final VoidCallback aoTocar;

  const _BotaoSecundario({required this.rotulo, required this.aoTocar});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton(
        onPressed: aoTocar,
        style: TextButton.styleFrom(foregroundColor: CoresApp.textPrimary),
        child: Text(rotulo,
            style: GoogleFonts.outfit(
                fontSize: Tipografia.destaque, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
