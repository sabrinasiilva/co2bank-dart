import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../compartilhado/widgets/aviso_erro_carregamento.dart';
import '../../nucleo/aviso_dados_alterados.dart';
import '../../nucleo/cores_app.dart';
import '../../transacoes/servico/servico_transacao.dart';
import '../icone_categoria.dart';
import 'tela_detalhe_transacao.dart';
import '../../open_finance/widgets/selo_open_finance.dart';
import '../../nucleo/tipografia.dart';

class AbaExtrato extends StatefulWidget {
  const AbaExtrato({super.key});

  @override
  State<AbaExtrato> createState() => _AbaExtratoState();
}

class _AbaExtratoState extends State<AbaExtrato> {
  late Future<List<ItemTransacao>> _dados;
  Future<List<ItemTransacao>>? _cargaEmSegundoPlano;
  int _mes = DateTime.now().month;
  int _ano = DateTime.now().year;
  /// Categoria escolhida nos filtros do topo; nulo mostra todas.
  String? _categoria;

  @override
  void initState() {
    super.initState();
    _dados = _carregar();
    AvisoDadosAlterados.instancia.addListener(_recarregarEmSegundoPlano);
  }

  @override
  void dispose() {
    AvisoDadosAlterados.instancia.removeListener(_recarregarEmSegundoPlano);
    super.dispose();
  }

  /// Busca de novo sem trocar a lista pelo carregando: o extrato visível fica
  /// no lugar (com o mesmo scroll) até as compras novas chegarem.
  Future<void> _recarregarEmSegundoPlano() async {
    final mes = _mes;
    final ano = _ano;
    final carga = _carregar();
    _cargaEmSegundoPlano = carga;
    final List<ItemTransacao> transacoes;
    try {
      transacoes = await carga;
    } catch (_) {
      return; // Mantém o extrato que já estava na tela.
    }
    // Ignora se a pessoa trocou de mês ou se outro aviso chegou nesse meio-tempo.
    if (!mounted || carga != _cargaEmSegundoPlano) return;
    if (mes != _mes || ano != _ano) return;
    setState(() => _dados = SynchronousFuture(transacoes));
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
      _categoria = null;
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
                    fontSize: Tipografia.titulo,
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

                if (snapshot.hasError) {
                  return RefreshIndicator(
                    onRefresh: () async => _atualizar(),
                    color: CoresApp.primary,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.55,
                          child: Center(
                            child: AvisoErroCarregamento(
                              titulo: 'Não foi possível carregar o extrato',
                              aoTentarNovamente: _atualizar,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                                        fontSize: Tipografia.corpo,
                                        color: CoresApp.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : _ListaPorDia(
                          transacoes: transacoes,
                          categoria: _categoria,
                          aoFiltrar: (categoria) =>
                              setState(() => _categoria = categoria),
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
              fontSize: Tipografia.corpo,
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

  String get _tagIcone => 'extrato-${tx.id}';

  @override
  Widget build(BuildContext context) {
    final formatadorMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => TelaDetalheTransacao(transacao: tx, tagIcone: _tagIcone)),
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
            Hero(
              tag: _tagIcone,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: CoresApp.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconePorCategoria(tx.rotuloCategoria),
                    size: 22, color: CoresApp.gray),
              ),
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
                      fontSize: Tipografia.corpo,
                      fontWeight: FontWeight.w600,
                      color: CoresApp.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    tx.rotuloCategoria,
                    style: GoogleFonts.outfit(
                      fontSize: Tipografia.legenda,
                      color: CoresApp.textSecondary,
                    ),
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
                    fontSize: Tipografia.destaque,
                    fontWeight: FontWeight.bold,
                    color: CoresApp.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.eco_rounded, size: 11, color: CoresApp.dark),
                    const SizedBox(width: 2),
                    Text(
                      '${_kg(tx.co2Kg)} kg',
                      style: GoogleFonts.outfit(
                        fontSize: Tipografia.minimo,
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

String _kg(double valor) => valor.toStringAsFixed(1).replaceAll('.', ',');

/// Compras agrupadas por dia ("Hoje", "Ontem", "Segunda, 12 de outubro"),
/// com o CO2 de cada dia e filtros de categoria no topo.
class _ListaPorDia extends StatelessWidget {
  final List<ItemTransacao> transacoes;
  final String? categoria;
  final ValueChanged<String?> aoFiltrar;

  const _ListaPorDia({
    required this.transacoes,
    required this.categoria,
    required this.aoFiltrar,
  });

  @override
  Widget build(BuildContext context) {
    // Categorias do mês, das que têm mais compras para as que têm menos.
    final contagem = <String, int>{};
    for (final tx in transacoes) {
      contagem[tx.rotuloCategoria] = (contagem[tx.rotuloCategoria] ?? 0) + 1;
    }
    final categorias = contagem.keys.toList()
      ..sort((a, b) => contagem[b]!.compareTo(contagem[a]!));

    final visiveis = categoria == null
        ? transacoes
        : transacoes.where((tx) => tx.rotuloCategoria == categoria).toList();

    final dias = <DateTime, List<ItemTransacao>>{};
    for (final tx in visiveis) {
      final local = tx.ocorreuEm.toLocal();
      dias.putIfAbsent(DateTime(local.year, local.month, local.day), () => []).add(tx);
    }
    final ordem = dias.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 96),
      children: [
        if (categorias.length > 1)
          _FiltrosCategoria(
            categorias: categorias,
            escolhida: categoria,
            aoEscolher: aoFiltrar,
          ),
        for (final dia in ordem) ...[
          _CabecalhoDia(dia: dia, compras: dias[dia]!),
          for (final tx in dias[dia]!)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: _CartaoTransacao(tx: tx),
            ),
        ],
      ],
    );
  }
}

class _FiltrosCategoria extends StatelessWidget {
  final List<String> categorias;
  final String? escolhida;
  final ValueChanged<String?> aoEscolher;

  const _FiltrosCategoria({
    required this.categorias,
    required this.escolhida,
    required this.aoEscolher,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
        children: [
          _filtro(
            rotulo: 'Todas',
            ativo: escolhida == null,
            aoTocar: () => aoEscolher(null),
          ),
          for (final categoria in categorias)
            _filtro(
              rotulo: categoria,
              icone: iconePorCategoria(categoria),
              ativo: escolhida == categoria,
              aoTocar: () => aoEscolher(escolhida == categoria ? null : categoria),
            ),
        ],
      ),
    );
  }

  Widget _filtro({
    required String rotulo,
    required bool ativo,
    required VoidCallback aoTocar,
    IconData? icone,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: ativo,
        onSelected: (_) => aoTocar(),
        showCheckmark: false,
        avatar: icone == null
            ? null
            : Icon(icone, size: 16, color: ativo ? Colors.white : CoresApp.gray),
        label: Text(rotulo),
        labelStyle: GoogleFonts.outfit(
          fontSize: Tipografia.legenda,
          fontWeight: FontWeight.w600,
          color: ativo ? Colors.white : CoresApp.textPrimary,
        ),
        backgroundColor: CoresApp.surface,
        selectedColor: CoresApp.dark,
        side: BorderSide(color: ativo ? CoresApp.dark : CoresApp.border),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
    );
  }
}

class _CabecalhoDia extends StatelessWidget {
  final DateTime dia;
  final List<ItemTransacao> compras;

  const _CabecalhoDia({required this.dia, required this.compras});

  String get _rotulo {
    final hoje = DateTime.now();
    final dataHoje = DateTime(hoje.year, hoje.month, hoje.day);
    final diferenca = dataHoje.difference(dia).inDays;
    if (diferenca == 0) return 'Hoje';
    if (diferenca == 1) return 'Ontem';
    // "segunda-feira" vira "Segunda".
    final semana = DateFormat('EEEE', 'pt_BR').format(dia).split('-').first;
    final data = DateFormat("d 'de' MMMM", 'pt_BR').format(dia);
    return '${semana[0].toUpperCase()}${semana.substring(1)}, $data';
  }

  @override
  Widget build(BuildContext context) {
    final co2 = compras.fold<double>(0, (soma, tx) => soma + tx.co2Kg);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _rotulo,
              style: GoogleFonts.outfit(
                fontSize: Tipografia.corpo,
                fontWeight: FontWeight.w700,
                color: CoresApp.textPrimary,
              ),
            ),
          ),
          const Icon(Icons.eco_rounded, size: 14, color: CoresApp.textSecondary),
          const SizedBox(width: 4),
          Text(
            '${_kg(co2)} kg de CO2',
            style: GoogleFonts.outfit(
              fontSize: Tipografia.legenda,
              fontWeight: FontWeight.w600,
              color: CoresApp.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
