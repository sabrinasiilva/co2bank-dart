import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../nucleo/cores_app.dart';
import '../../compartilhado/widgets/botao_primario.dart';
import '../../transacoes/servico/servico_transacao.dart';
import '../bancos_open_finance.dart';
import '../servico/servico_open_finance.dart';
import 'progresso_etapas.dart';

/// Sincroniza os bancos mostrando cada etapa e, no fim, as compras importadas.
/// Devolve true se alguma compra nova entrou no extrato.
Future<bool> mostrarFolhaSincronizacao(
  BuildContext context, {
  required List<BancoOpenFinance> bancos,
  required Future<ResultadoSincronizacao> Function() sincronizar,
  required Future<List<ItemTransacao>> Function() carregarImportadas,
  VoidCallback? aoVerExtrato,
}) async {
  final houveNovas = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: CoresApp.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _FolhaSincronizacao(
      bancos: bancos,
      sincronizar: sincronizar,
      carregarImportadas: carregarImportadas,
      aoVerExtrato: aoVerExtrato,
    ),
  );
  return houveNovas ?? false;
}

class _FolhaSincronizacao extends StatefulWidget {
  final List<BancoOpenFinance> bancos;
  final Future<ResultadoSincronizacao> Function() sincronizar;
  final Future<List<ItemTransacao>> Function() carregarImportadas;
  final VoidCallback? aoVerExtrato;

  const _FolhaSincronizacao({
    required this.bancos,
    required this.sincronizar,
    required this.carregarImportadas,
    required this.aoVerExtrato,
  });

  @override
  State<_FolhaSincronizacao> createState() => _FolhaSincronizacaoState();
}

class _FolhaSincronizacaoState extends State<_FolhaSincronizacao> {
  int _etapa = 0;
  ResultadoSincronizacao? _resultado;
  List<ItemTransacao> _importadas = [];

  List<String> get _etapas => [
    'Conectando com ${_juntarNomes(widget.bancos.map((b) => b.nome))}',
    'Buscando as compras do mês',
    'Calculando o CO2 de cada compra',
  ];

  bool get _houveNovas => switch (_resultado) {
    SincronizacaoConcluida(:final novas) => novas > 0,
    _ => false,
  };

  @override
  void initState() {
    super.initState();
    _executar();
  }

  Future<(ResultadoSincronizacao, List<ItemTransacao>)>
  _sincronizarEBuscar() async {
    final resultado = await widget.sincronizar();
    if (resultado is SincronizacaoErro) return (resultado, <ItemTransacao>[]);
    return (resultado, await widget.carregarImportadas());
  }

  Future<void> _executar() async {
    setState(() {
      _resultado = null;
      _etapa = 0;
    });
    final (resultado, importadas) = await executarComEtapas(
      tarefa: _sincronizarEBuscar(),
      totalEtapas: _etapas.length,
      aoAvancar: (etapa) {
        if (mounted) setState(() => _etapa = etapa);
      },
    );
    if (!mounted) return;
    setState(() {
      _resultado = resultado;
      _importadas = importadas;
    });
  }

  void _verExtrato() {
    Navigator.pop(context, _houveNovas);
    widget.aoVerExtrato?.call();
  }

  @override
  Widget build(BuildContext context) {
    final resultado = _resultado;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
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
                ...switch (resultado) {
                  null => _sincronizando(),
                  SincronizacaoConcluida(:final novas, :final ignoradas) =>
                    _concluido(novas, ignoradas),
                  SincronizacaoErro(:final mensagem) => _erro(mensagem),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _sincronizando() {
    return [
      _Titulo('Sincronizando...'),
      const SizedBox(height: 20),
      ProgressoEtapas(etapas: _etapas, etapaAtual: _etapa),
      const SizedBox(height: 8),
    ];
  }

  List<Widget> _concluido(int novas, int ignoradas) {
    final co2Total = _importadas.fold<double>(0, (soma, t) => soma + t.co2Kg);
    final recentes = [..._importadas]
      ..sort((a, b) => b.ocorreuEm.compareTo(a.ocorreuEm));
    final nomesBancos = recentes
        .map((t) => bancoPorId(t.idBanco)?.nome)
        .whereType<String>()
        .toSet();

    return [
      Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: CoresApp.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              novas > 0 ? Icons.download_done_rounded : Icons.done_all_rounded,
              color: CoresApp.dark,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Titulo(switch (novas) {
                  0 => 'Tudo em dia',
                  1 => '1 compra importada',
                  _ => '$novas compras importadas',
                }),
                Text(
                  novas > 0
                      ? 'O CO2 de cada uma já foi calculado.'
                      : ignoradas > 0
                      ? 'Nenhuma compra nova. As $ignoradas encontradas já estavam no extrato.'
                      : 'Nenhuma compra nova desde a última sincronização.',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: CoresApp.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      if (recentes.isNotEmpty) ...[
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CoresApp.dark,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CO2 das compras do Open Finance este mês',
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.white60),
              ),
              const SizedBox(height: 4),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: co2Total),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, valor, _) => Text(
                  '${valor.toStringAsFixed(1)} kg',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: CoresApp.primary,
                  ),
                ),
              ),
              Text(
                '${recentes.length} ${recentes.length == 1 ? 'compra' : 'compras'}'
                '${nomesBancos.isEmpty ? '' : ' de ${_juntarNomes(nomesBancos)}'}',
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.white60),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          novas > 0 ? 'O que chegou' : 'Compras já importadas',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: CoresApp.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < recentes.length && i < 6; i++)
          _ItemImportado(transacao: recentes[i], ordem: i),
        if (recentes.length > 6)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'e mais ${recentes.length - 6} no extrato',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: CoresApp.textSecondary,
              ),
            ),
          ),
      ],
      const SizedBox(height: 24),
      if (widget.aoVerExtrato != null)
        BotaoPrimario(rotulo: 'Ver no extrato', aoTocar: _verExtrato),
      const SizedBox(height: 4),
      SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: () => Navigator.pop(context, _houveNovas),
          child: Text(
            'Fechar',
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: CoresApp.textSecondary,
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _erro(String mensagem) {
    return [
      _Titulo('Não deu para sincronizar'),
      const SizedBox(height: 6),
      Text(
        mensagem,
        style: GoogleFonts.outfit(fontSize: 14, color: CoresApp.textSecondary),
      ),
      const SizedBox(height: 24),
      BotaoPrimario(rotulo: 'Tentar de novo', aoTocar: _executar),
      const SizedBox(height: 4),
      SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Fechar',
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: CoresApp.textSecondary,
            ),
          ),
        ),
      ),
    ];
  }
}

String _juntarNomes(Iterable<String> nomes) {
  final lista = nomes.toList();
  if (lista.length <= 1) return lista.join();
  return '${lista.sublist(0, lista.length - 1).join(', ')} e ${lista.last}';
}

class _Titulo extends StatelessWidget {
  final String texto;

  const _Titulo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: CoresApp.textPrimary,
      ),
    );
  }
}

class _ItemImportado extends StatelessWidget {
  final ItemTransacao transacao;
  final int ordem;

  const _ItemImportado({required this.transacao, required this.ordem});

  @override
  Widget build(BuildContext context) {
    final banco = bancoPorId(transacao.idBanco);
    final formatadorMoeda = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    // Cada item entra um pouco depois do anterior, para a lista "chegar" aos poucos.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + ordem * 120),
      curve: Curves.easeOut,
      builder: (_, valor, filho) => Opacity(
        opacity: valor,
        child: Transform.translate(
          offset: Offset(0, (1 - valor) * 12),
          child: filho,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: CoresApp.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: (banco?.cor ?? CoresApp.gray).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                banco?.icone ?? Icons.account_balance,
                size: 16,
                color: banco?.cor ?? CoresApp.gray,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transacao.nomeEstabelecimento.isEmpty
                        ? transacao.rotuloCategoria
                        : transacao.nomeEstabelecimento,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: CoresApp.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    banco == null
                        ? transacao.rotuloCategoria
                        : '${transacao.rotuloCategoria} · ${banco.nome}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: CoresApp.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatadorMoeda.format(transacao.valor),
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CoresApp.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.eco_rounded,
                      size: 11,
                      color: CoresApp.darkGreen,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${transacao.co2Kg.toStringAsFixed(1)} kg',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: CoresApp.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
