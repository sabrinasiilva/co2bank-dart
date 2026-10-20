import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../nucleo/cores_app.dart';
import '../../transacoes/servico/servico_transacao.dart';
import '../icone_categoria.dart';
import 'tela_detalhe_transacao.dart';
import '../../open_finance/widgets/selo_open_finance.dart';

class AbaTransacoes extends StatefulWidget {
  const AbaTransacoes({super.key});

  @override
  State<AbaTransacoes> createState() => _AbaTransacoesState();
}

class _AbaTransacoesState extends State<AbaTransacoes> {
  late Future<List<ItemTransacao>> _dados;
  int _mes = DateTime.now().month;
  int _ano = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _dados = _carregar();
  }

  Future<List<ItemTransacao>> _carregar() async {
    final servico = await ServicoTransacao.autenticado();
    return servico.listarTransacoes(mes: _mes, ano: _ano);
  }

  void _alterarMes(int delta) {
    final candidato = DateTime(_ano, _mes + delta);
    final agora = DateTime.now();
    if (candidato.isAfter(DateTime(agora.year, agora.month))) return;
    setState(() {
      _mes = candidato.month;
      _ano = candidato.year;
      _dados = _carregar();
    });
  }

  void _atualizar() => setState(() => _dados = _carregar());

  @override
  Widget build(BuildContext context) {
    const meses = [
      '', 'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
    ];

    final agora = DateTime.now();
    final mesAtual = _mes == agora.month && _ano == agora.year;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Row(
              children: [
                Text(
                  'Extrato',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: CoresApp.textPrimary,
                  ),
                ),
                const Spacer(),
                _SeletorMes(
                  rotulo: '${meses[_mes]} $_ano',
                  aoAnterior: () => _alterarMes(-1),
                  aoProximo: mesAtual ? null : () => _alterarMes(1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<ItemTransacao>>(
              future: _dados,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator(color: CoresApp.primary),
                  );
                }

                final transacoes = snapshot.data ?? [];

                return RefreshIndicator(
                  onRefresh: () async => _atualizar(),
                  color: CoresApp.primary,
                  child: transacoes.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.55,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.receipt_long_rounded,
                                        size: 48, color: CoresApp.border),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Nenhuma movimentação neste período',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        color: CoresApp.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                          itemCount: transacoes.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _CartaoTransacao(tx: transacoes[i]),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SeletorMes extends StatelessWidget {
  final String rotulo;
  final VoidCallback aoAnterior;
  final VoidCallback? aoProximo;

  const _SeletorMes({
    required this.rotulo,
    required this.aoAnterior,
    required this.aoProximo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CoresApp.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CoresApp.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 20),
            onPressed: aoAnterior,
            color: CoresApp.textSecondary,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
          Text(
            rotulo,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CoresApp.textPrimary,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: aoProximo != null ? CoresApp.textSecondary : CoresApp.border,
            ),
            onPressed: aoProximo,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _CartaoTransacao extends StatelessWidget {
  final ItemTransacao tx;

  const _CartaoTransacao({required this.tx});

  @override
  Widget build(BuildContext context) {
    final formatadorMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final formatadorData = DateFormat('dd/MM', 'pt_BR');

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TelaDetalheTransacao(transacao: tx)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CoresApp.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: CoresApp.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconePorCategoria(tx.rotuloCategoria),
                  size: 22, color: CoresApp.gray),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.nomeEstabelecimento.isEmpty
                        ? tx.rotuloCategoria
                        : tx.nomeEstabelecimento,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: CoresApp.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Text(
                        tx.rotuloCategoria,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: CoresApp.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: CoresApp.border,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        formatadorData.format(tx.ocorreuEm),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: CoresApp.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (tx.importadaOpenFinance) SeloOpenFinance(idBanco: tx.idBanco),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatadorMoeda.format(tx.valor),
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: CoresApp.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.eco_rounded, size: 11, color: CoresApp.dark),
                    const SizedBox(width: 2),
                    Text(
                      '${tx.co2Kg.toStringAsFixed(1)} kg',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: CoresApp.dark,
                        fontWeight: FontWeight.w600,
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
