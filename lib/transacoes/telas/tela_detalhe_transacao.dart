import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../nucleo/cores_app.dart';
import '../../open_finance/bancos_open_finance.dart';
import '../../open_finance/widgets/selo_open_finance.dart';
import '../icone_categoria.dart';
import '../servico/servico_transacao.dart';

class TelaDetalheTransacao extends StatefulWidget {
  final ItemTransacao transacao;

  const TelaDetalheTransacao({super.key, required this.transacao});

  @override
  State<TelaDetalheTransacao> createState() => _TelaDetalheTransacaoState();
}

class _TelaDetalheTransacaoState extends State<TelaDetalheTransacao> {
  late ItemTransacao _transacao = widget.transacao;
  double? _limiteKg;

  @override
  void initState() {
    super.initState();
    _completarDados();
  }

  // A tela abre na hora com o item que veio da lista; a API só completa o que
  // faltar e traz o limite do mês para calcular quanto a compra representa.
  Future<void> _completarDados() async {
    final servico = await ServicoTransacao.autenticado();
    final data = _transacao.ocorreuEm;
    final (detalhe, resumo) = await (
      servico.obterTransacao(_transacao.id),
      servico.resumoMensal(mes: data.month, ano: data.year),
    ).wait;
    if (!mounted) return;
    setState(() {
      if (detalhe case DetalheCarregado(:final transacao)) {
        _transacao = transacao;
      }
      if (resumo case ResumoCarregado(:final resumo)) {
        _limiteKg = resumo.limiteKg;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.background,
      appBar: AppBar(
        backgroundColor: CoresApp.dark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Detalhes da compra',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          _Cabecalho(transacao: _transacao),
          const SizedBox(height: 16),
          _CartaoCo2(transacao: _transacao, limiteKg: _limiteKg),
          const SizedBox(height: 16),
          _CartaoInformacoes(transacao: _transacao),
          const SizedBox(height: 16),
          Text(
            'O CO2 é uma estimativa calculada a partir da categoria do '
            'estabelecimento (MCC) e do valor da compra.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 12, color: CoresApp.gray),
          ),
        ],
      ),
    );
  }
}

String _dataPorExtenso(DateTime data) {
  final local = data.toLocal();
  final dia = DateFormat("d 'de' MMMM 'de' y", 'pt_BR').format(local);
  // Compras do Open Finance chegam só com a data, sem horário.
  if (local.hour == 0 && local.minute == 0) return dia;
  return '$dia às ${DateFormat('HH:mm', 'pt_BR').format(local)}';
}

class _Cabecalho extends StatelessWidget {
  final ItemTransacao transacao;

  const _Cabecalho({required this.transacao});

  @override
  Widget build(BuildContext context) {
    final moeda = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
    final nome = transacao.nomeEstabelecimento.isEmpty
        ? transacao.rotuloCategoria
        : transacao.nomeEstabelecimento;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CoresApp.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CoresApp.border),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: CoresApp.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              iconePorCategoria(transacao.rotuloCategoria),
              size: 28,
              color: CoresApp.gray,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            nome,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: CoresApp.textPrimary,
            ),
          ),
          Text(
            transacao.rotuloCategoria,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: CoresApp.textSecondary,
            ),
          ),
          if (transacao.importadaOpenFinance)
            SeloOpenFinance(idBanco: transacao.idBanco),
          const SizedBox(height: 16),
          Text(
            moeda.format(transacao.valor),
            style: GoogleFonts.outfit(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: CoresApp.textPrimary,
            ),
          ),
          Text(
            _dataPorExtenso(transacao.ocorreuEm),
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: CoresApp.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoCo2 extends StatelessWidget {
  final ItemTransacao transacao;
  final double? limiteKg;

  const _CartaoCo2({required this.transacao, required this.limiteKg});

  @override
  Widget build(BuildContext context) {
    final kgPor100 = transacao.valor > 0
        ? transacao.co2Kg / transacao.valor * 100
        : 0.0;
    final limite = limiteKg;
    final parcela = limite != null && limite > 0
        ? (transacao.co2Kg / limite).clamp(0.0, 1.0)
        : null;
    final mes = DateFormat(
      'MMMM',
      'pt_BR',
    ).format(transacao.ocorreuEm.toLocal());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CoresApp.dark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco_rounded, size: 18, color: CoresApp.primary),
              const SizedBox(width: 6),
              Text(
                'Pegada de carbono desta compra',
                style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${transacao.co2Kg.toStringAsFixed(2)} kg de CO2',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: CoresApp.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cerca de ${kgPor100.toStringAsFixed(1)} kg a cada R\$ 100 gastos '
            'em ${transacao.rotuloCategoria}',
            style: GoogleFonts.outfit(fontSize: 13, color: Colors.white60),
          ),
          if (parcela != null) ...[
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: parcela),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (_, valor, _) => LinearProgressIndicator(
                  value: valor,
                  minHeight: 8,
                  backgroundColor: Colors.white12,
                  color: CoresApp.accent,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Representa ${(parcela * 100).toStringAsFixed(1)}% do seu limite '
              'de ${limite!.toStringAsFixed(0)} kg em $mes',
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }
}

class _CartaoInformacoes extends StatelessWidget {
  final ItemTransacao transacao;

  const _CartaoInformacoes({required this.transacao});

  @override
  Widget build(BuildContext context) {
    final banco = bancoPorId(transacao.idBanco);
    final origem = transacao.importadaOpenFinance
        ? 'Open Finance${banco == null ? '' : ' · ${banco.nome}'}'
        : 'Lançamento manual';
    final registradaEm = transacao.registradaEm;

    final linhas = <(String, String)>[
      ('Categoria', transacao.rotuloCategoria),
      if (transacao.codigoCategoria != null)
        ('Código do estabelecimento (MCC)', transacao.codigoCategoria!),
      ('Data da compra', _dataPorExtenso(transacao.ocorreuEm)),
      ('Origem', origem),
      if (registradaEm != null)
        (
          'Registrada no app',
          DateFormat(
            "dd/MM/yyyy 'às' HH:mm",
            'pt_BR',
          ).format(registradaEm.toLocal()),
        ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: CoresApp.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CoresApp.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < linhas.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      linhas[i].$1,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: CoresApp.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      linhas[i].$2,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CoresApp.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (i < linhas.length - 1)
              const Divider(height: 1, color: CoresApp.border),
          ],
        ],
      ),
    );
  }
}
