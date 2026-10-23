import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../nucleo/cores_app.dart';
import '../../compartilhado/widgets/botao_primario.dart';
import '../../compartilhado/widgets/logo_co2bank.dart';
import '../bancos_open_finance.dart';
import '../servico/servico_open_finance.dart';
import 'progresso_etapas.dart';
import '../../nucleo/tipografia.dart';

/// Abre a jornada de consentimento do Open Finance para [banco].
/// Devolve true se o banco foi conectado.
Future<bool> mostrarFolhaConsentimento(
  BuildContext context, {
  required BancoOpenFinance banco,
  required Future<ResultadoOperacaoOpenFinance> Function() conectar,
}) async {
  final conectado = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: CoresApp.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _FolhaConsentimento(banco: banco, conectar: conectar),
  );
  return conectado ?? false;
}

enum _Fase { pedido, autorizando, concluido, erro }

class _FolhaConsentimento extends StatefulWidget {
  final BancoOpenFinance banco;
  final Future<ResultadoOperacaoOpenFinance> Function() conectar;

  const _FolhaConsentimento({required this.banco, required this.conectar});

  @override
  State<_FolhaConsentimento> createState() => _FolhaConsentimentoState();
}

class _FolhaConsentimentoState extends State<_FolhaConsentimento> {
  _Fase _fase = _Fase.pedido;
  int _etapa = 0;
  String _mensagemErro = '';

  List<String> get _etapas => [
    'Abrindo o ${widget.banco.nome}',
    'Confirmando sua identidade no banco',
    'Registrando o consentimento',
  ];

  Future<void> _autorizar() async {
    setState(() => _fase = _Fase.autorizando);
    final resultado = await executarComEtapas(
      tarefa: widget.conectar(),
      totalEtapas: _etapas.length,
      aoAvancar: (etapa) {
        if (mounted) setState(() => _etapa = etapa);
      },
    );
    if (!mounted) return;
    setState(() {
      switch (resultado) {
        case OperacaoConcluida():
          _fase = _Fase.concluido;
        case OperacaoErro(:final mensagem):
          _fase = _Fase.erro;
          _mensagemErro = mensagem;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CoresApp.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _CabecalhoConexao(banco: widget.banco, fase: _fase),
              const SizedBox(height: 20),
              ...switch (_fase) {
                _Fase.pedido => _pedido(),
                _Fase.autorizando => _autorizando(),
                _Fase.concluido => _concluido(),
                _Fase.erro => _erro(),
              },
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _pedido() {
    final nome = widget.banco.nome;
    return [
      Text(
        'Conectar $nome',
        style: GoogleFonts.outfit(
          fontSize: Tipografia.tituloSecao,
          fontWeight: FontWeight.bold,
          color: CoresApp.textPrimary,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'O CO2Bank vai pedir ao $nome permissão para ler suas compras e calcular o CO2 de cada uma.',
        style: GoogleFonts.outfit(
          fontSize: Tipografia.corpo,
          color: CoresApp.textSecondary,
          height: 1.4,
        ),
      ),
      const SizedBox(height: 20),
      const _TituloSecao('O CO2Bank poderá'),
      const _ItemPermissao(
        permitido: true,
        texto: 'Ver as compras do cartão e da conta',
      ),
      const _ItemPermissao(
        permitido: true,
        texto: 'Ver data, valor e tipo de estabelecimento',
      ),
      const SizedBox(height: 14),
      const _TituloSecao('O CO2Bank não poderá'),
      const _ItemPermissao(
        permitido: false,
        texto: 'Fazer pagamentos ou transferências',
      ),
      const _ItemPermissao(
        permitido: false,
        texto: 'Ver sua senha ou mexer no seu dinheiro',
      ),
      const SizedBox(height: 16),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CoresApp.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.schedule_rounded,
              size: 18,
              color: CoresApp.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Válido por 12 meses. Você pode desconectar quando quiser.',
                style: GoogleFonts.outfit(
                  fontSize: Tipografia.corpo,
                  color: CoresApp.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      BotaoPrimario(rotulo: 'Autorizar no $nome', aoTocar: _autorizar),
      const SizedBox(height: 4),
      SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Agora não',
            style: GoogleFonts.outfit(
              fontSize: Tipografia.destaque,
              color: CoresApp.textSecondary,
            ),
          ),
        ),
      ),
      Center(
        child: Text(
          'Protótipo: o consentimento é simulado.',
          style: GoogleFonts.outfit(fontSize: Tipografia.minimo, color: CoresApp.gray),
        ),
      ),
    ];
  }

  List<Widget> _autorizando() {
    return [
      Text(
        'Conectando...',
        style: GoogleFonts.outfit(
          fontSize: Tipografia.tituloSecao,
          fontWeight: FontWeight.bold,
          color: CoresApp.textPrimary,
        ),
      ),
      const SizedBox(height: 20),
      ProgressoEtapas(etapas: _etapas, etapaAtual: _etapa),
      const SizedBox(height: 8),
    ];
  }

  List<Widget> _concluido() {
    return [
      Text(
        '${widget.banco.nome} conectado',
        style: GoogleFonts.outfit(
          fontSize: Tipografia.tituloSecao,
          fontWeight: FontWeight.bold,
          color: CoresApp.textPrimary,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Agora é só sincronizar para trazer o histórico de compras.',
        style: GoogleFonts.outfit(fontSize: Tipografia.corpo, color: CoresApp.textSecondary),
      ),
      const SizedBox(height: 20),
      ProgressoEtapas(
        etapas: _etapas,
        etapaAtual: _etapas.length,
        concluido: true,
      ),
      const SizedBox(height: 24),
      BotaoPrimario(
        rotulo: 'Continuar',
        aoTocar: () => Navigator.pop(context, true),
      ),
    ];
  }

  List<Widget> _erro() {
    return [
      Text(
        'Não deu para conectar',
        style: GoogleFonts.outfit(
          fontSize: Tipografia.tituloSecao,
          fontWeight: FontWeight.bold,
          color: CoresApp.textPrimary,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        _mensagemErro,
        style: GoogleFonts.outfit(fontSize: Tipografia.corpo, color: CoresApp.textSecondary),
      ),
      const SizedBox(height: 24),
      BotaoPrimario(
        rotulo: 'Tentar de novo',
        aoTocar: () => setState(() {
          _fase = _Fase.pedido;
          _etapa = 0;
        }),
      ),
      const SizedBox(height: 4),
      SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Fechar',
            style: GoogleFonts.outfit(
              fontSize: Tipografia.destaque,
              color: CoresApp.textSecondary,
            ),
          ),
        ),
      ),
    ];
  }
}

class _CabecalhoConexao extends StatelessWidget {
  final BancoOpenFinance banco;
  final _Fase fase;

  const _CabecalhoConexao({required this.banco, required this.fase});

  @override
  Widget build(BuildContext context) {
    final conectado = fase == _Fase.concluido;
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: CoresApp.surface,
              shape: BoxShape.circle,
              border: Border.all(color: CoresApp.border),
            ),
            child: const LogoCo2Bank(tamanho: 42),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                conectado ? Icons.check_circle_rounded : Icons.sync_alt_rounded,
                key: ValueKey(conectado),
                size: 26,
                color: conectado ? CoresApp.primary : CoresApp.textSecondary,
              ),
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: banco.cor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(banco.icone, size: 26, color: banco.cor),
          ),
        ],
      ),
    );
  }
}

class _TituloSecao extends StatelessWidget {
  final String texto;

  const _TituloSecao(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        texto,
        style: GoogleFonts.outfit(
          fontSize: Tipografia.corpo,
          fontWeight: FontWeight.w600,
          color: CoresApp.textPrimary,
        ),
      ),
    );
  }
}

class _ItemPermissao extends StatelessWidget {
  final bool permitido;
  final String texto;

  const _ItemPermissao({required this.permitido, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            permitido ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 20,
            color: permitido ? CoresApp.primary : Colors.red.shade300,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: GoogleFonts.outfit(
                fontSize: Tipografia.corpo,
                color: CoresApp.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
