import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../nucleo/aviso_dados_alterados.dart';
import '../nucleo/cores_app.dart';
import '../compartilhado/widgets/botao_primario.dart';
import '../transacoes/servico/servico_transacao.dart';
import 'bancos_open_finance.dart';
import 'servico/servico_open_finance.dart';
import 'widgets/folha_consentimento.dart';
import 'widgets/folha_sincronizacao.dart';

class TelaOpenFinance extends StatefulWidget {
  final VoidCallback? aoVerExtrato;

  const TelaOpenFinance({super.key, this.aoVerExtrato});

  @override
  State<TelaOpenFinance> createState() => _TelaOpenFinanceState();
}

class _TelaOpenFinanceState extends State<TelaOpenFinance> {
  ServicoOpenFinance? _servico;
  Map<String, ConexaoBanco> _conexoes = {};
  List<ItemTransacao> _importadas = [];
  bool _carregando = true;
  bool _indisponivel = false;
  final Set<String> _bancosEmAlteracao = {};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _indisponivel = false;
    });
    _servico ??= await ServicoOpenFinance.autenticado();
    final (resultado, importadas) = await (
      _servico!.listarConexoes(),
      _carregarImportadas(),
    ).wait;
    if (!mounted) return;
    setState(() {
      _carregando = false;
      _importadas = importadas;
      switch (resultado) {
        case ConexoesCarregadas(:final conexoes):
          _conexoes = {for (final c in conexoes) c.idBanco: c};
        case ConexoesIndisponiveis():
          _indisponivel = true;
      }
    });
  }

  Future<List<ItemTransacao>> _carregarImportadas() async {
    final agora = DateTime.now();
    final servico = await ServicoTransacao.autenticado();
    final transacoes = await servico.listarTransacoes(
      mes: agora.month,
      ano: agora.year,
    );
    return transacoes.where((t) => t.importadaOpenFinance).toList();
  }

  DateTime? get _ultimaSincronizacao {
    final datas = _conexoes.values
        .map((c) => c.ultimaSincronizacao)
        .whereType<DateTime>();
    if (datas.isEmpty) return null;
    return datas.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  int get _passoAtual {
    if (_conexoes.isEmpty) return 0;
    if (_importadas.isEmpty) return 1;
    return 3;
  }

  List<BancoOpenFinance> get _bancosConectados =>
      bancosOpenFinance.where((b) => _conexoes.containsKey(b.id)).toList();

  Future<void> _alternarBanco(BancoOpenFinance banco) async {
    if (_bancosEmAlteracao.contains(banco.id)) return;
    if (_conexoes.containsKey(banco.id)) {
      await _desconectar(banco);
    } else {
      await _conectar(banco);
    }
  }

  Future<void> _conectar(BancoOpenFinance banco) async {
    final conectado = await mostrarFolhaConsentimento(
      context,
      banco: banco,
      conectar: () => _servico!.conectar([banco.id]),
    );
    if (!conectado || !mounted) return;
    await _carregar();
    if (!mounted) return;
    _avisar(
      '${banco.nome} conectado. Sincronize para trazer as compras.',
      acao: SnackBarAction(label: 'Sincronizar', onPressed: _sincronizar),
    );
  }

  Future<void> _desconectar(BancoOpenFinance banco) async {
    if (!await _confirmarDesconexao(banco)) return;
    setState(() => _bancosEmAlteracao.add(banco.id));
    final resultado = await _servico!.desconectar(banco.id);
    if (!mounted) return;
    setState(() => _bancosEmAlteracao.remove(banco.id));
    switch (resultado) {
      case OperacaoConcluida():
        // As compras desse banco saíram do extrato: as abas precisam recarregar.
        AvisoDadosAlterados.instancia.avisar();
        await _carregar();
        if (!mounted) return;
        _avisar('${banco.nome} desconectado. As compras dele saíram do extrato.');
      case OperacaoErro(:final mensagem):
        _avisar(mensagem);
    }
  }

  Future<bool> _confirmarDesconexao(BancoOpenFinance banco) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: Text(
          'Desconectar ${banco.nome}?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'As compras importadas desse banco saem do extrato. As que você lançou manualmente continuam.',
          style: GoogleFonts.outfit(color: CoresApp.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.outfit(color: CoresApp.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: Text(
              'Desconectar',
              style: GoogleFonts.outfit(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    return confirmado ?? false;
  }

  Future<void> _sincronizar() async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final aoVerExtrato = widget.aoVerExtrato;
    final houveNovas = await mostrarFolhaSincronizacao(
      context,
      bancos: _bancosConectados,
      sincronizar: _servico!.sincronizar,
      carregarImportadas: _carregarImportadas,
      aoVerExtrato: aoVerExtrato == null
          ? null
          : () {
              Navigator.pop(context);
              aoVerExtrato();
            },
    );
    if (houveNovas) {
      AvisoDadosAlterados.instancia.avisar();
      // Compras novas podem ter levado o mês para perto do limite.
      final servico = await ServicoTransacao.autenticado();
      await servico.avisarSeLimiteAlto();
    }
    if (mounted) await _carregar();
  }

  void _avisar(String mensagem, {SnackBarAction? acao}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem, style: GoogleFonts.outfit()),
          behavior: SnackBarBehavior.floating,
          action: acao,
        ),
      );
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
          'Open Finance',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: _conteudo(),
    );
  }

  Widget _conteudo() {
    if (_carregando && _conexoes.isEmpty && !_indisponivel) {
      return const Center(
        child: CircularProgressIndicator(color: CoresApp.darkGreen),
      );
    }

    if (_indisponivel) {
      return _EstadoIndisponivel(aoTentarNovamente: _carregar);
    }

    return RefreshIndicator(
      color: CoresApp.darkGreen,
      onRefresh: _carregar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          _ComoFunciona(passoAtual: _passoAtual),
          const SizedBox(height: 20),
          _CartaoSincronizacao(
            ultimaSincronizacao: _ultimaSincronizacao,
            temConexoes: _conexoes.isNotEmpty,
            importadas: _importadas,
            aoSincronizar: _sincronizar,
          ),
          const SizedBox(height: 24),
          Text(
            'Seus bancos',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: CoresApp.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Toque em um banco para conectar ou desconectar.',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: CoresApp.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          for (final banco in bancosOpenFinance)
            _CartaoBanco(
              banco: banco,
              conexao: _conexoes[banco.id],
              importadas: _importadas
                  .where((t) => t.idBanco == banco.id)
                  .toList(),
              alterando: _bancosEmAlteracao.contains(banco.id),
              aoTocar: () => _alternarBanco(banco),
            ),
          const SizedBox(height: 12),
          Text(
            'O acesso é só leitura: o CO2Bank nunca movimenta seu dinheiro.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 12, color: CoresApp.gray),
          ),
        ],
      ),
    );
  }
}

class _ComoFunciona extends StatelessWidget {
  final int passoAtual;

  const _ComoFunciona({required this.passoAtual});

  static const _passos = [
    (Icons.account_balance_rounded, 'Conecte', 'seu banco'),
    (Icons.sync_rounded, 'Sincronize', 'as compras'),
    (Icons.eco_rounded, 'Acompanhe', 'o CO2'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CoresApp.dark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Como funciona',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Suas compras chegam sozinhas do banco e o CO2 de cada uma é calculado na hora.',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.white60,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < _passos.length; i++) ...[
                Expanded(
                  child: _Passo(
                    icone: _passos[i].$1,
                    titulo: _passos[i].$2,
                    subtitulo: _passos[i].$3,
                    feito: i < passoAtual,
                    atual: i == passoAtual,
                  ),
                ),
                if (i < _passos.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: i < passoAtual ? CoresApp.primary : Colors.white24,
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Passo extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final bool feito;
  final bool atual;

  const _Passo({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.feito,
    required this.atual,
  });

  @override
  Widget build(BuildContext context) {
    final destaque = feito || atual;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: feito
                ? CoresApp.primary
                : atual
                ? CoresApp.primary.withValues(alpha: 0.15)
                : Colors.white10,
            shape: BoxShape.circle,
            border: Border.all(
              color: destaque ? CoresApp.primary : Colors.white24,
              width: atual ? 2 : 1,
            ),
          ),
          child: Icon(
            feito ? Icons.check_rounded : icone,
            size: 20,
            color: feito
                ? CoresApp.dark
                : atual
                ? CoresApp.primary
                : Colors.white38,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          titulo,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: destaque ? Colors.white : Colors.white54,
          ),
        ),
        Text(
          subtitulo,
          style: GoogleFonts.outfit(fontSize: 11, color: Colors.white54),
        ),
      ],
    );
  }
}

class _CartaoSincronizacao extends StatelessWidget {
  final DateTime? ultimaSincronizacao;
  final bool temConexoes;
  final List<ItemTransacao> importadas;
  final VoidCallback aoSincronizar;

  const _CartaoSincronizacao({
    required this.ultimaSincronizacao,
    required this.temConexoes,
    required this.importadas,
    required this.aoSincronizar,
  });

  String get _descricao {
    if (!temConexoes) return 'Conecte pelo menos um banco para sincronizar';
    final ultima = ultimaSincronizacao;
    if (ultima == null) return 'Nenhuma sincronização feita ainda';
    final formatador = DateFormat("dd/MM 'às' HH:mm", 'pt_BR');
    return 'Última sincronização: ${formatador.format(ultima.toLocal())}';
  }

  @override
  Widget build(BuildContext context) {
    final co2 = importadas.fold<double>(0, (soma, t) => soma + t.co2Kg);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CoresApp.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CoresApp.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.sync_rounded,
                size: 20,
                color: CoresApp.textPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                'Sincronização',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: CoresApp.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _descricao,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: CoresApp.textSecondary,
            ),
          ),
          if (importadas.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                _Numero(
                  valor: '${importadas.length}',
                  rotulo: importadas.length == 1
                      ? 'compra importada'
                      : 'compras importadas',
                ),
                const SizedBox(width: 12),
                _Numero(
                  valor: '${co2.toStringAsFixed(1)} kg',
                  rotulo: 'de CO2 este mês',
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          BotaoPrimario(
            rotulo: 'Sincronizar agora',
            aoTocar: temConexoes ? aoSincronizar : null,
          ),
        ],
      ),
    );
  }
}

class _Numero extends StatelessWidget {
  final String valor;
  final String rotulo;

  const _Numero({required this.valor, required this.rotulo});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: CoresApp.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              valor,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: CoresApp.textPrimary,
              ),
            ),
            Text(
              rotulo,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: CoresApp.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartaoBanco extends StatelessWidget {
  final BancoOpenFinance banco;
  final ConexaoBanco? conexao;
  final List<ItemTransacao> importadas;
  final bool alterando;
  final VoidCallback aoTocar;

  const _CartaoBanco({
    required this.banco,
    required this.conexao,
    required this.importadas,
    required this.alterando,
    required this.aoTocar,
  });

  String _subtitulo(ConexaoBanco? conexao) {
    if (conexao == null) return 'Toque para conectar';
    if (importadas.isNotEmpty) {
      final co2 = importadas.fold<double>(0, (soma, t) => soma + t.co2Kg);
      final compras = importadas.length == 1 ? 'compra' : 'compras';
      return '${importadas.length} $compras · ${co2.toStringAsFixed(1)} kg CO2 este mês';
    }
    final data = DateFormat(
      'dd/MM/yyyy',
      'pt_BR',
    ).format(conexao.conectadoEm.toLocal());
    return 'Conectado em $data';
  }

  @override
  Widget build(BuildContext context) {
    final conexao = this.conexao;
    final conectado = conexao != null;

    return GestureDetector(
      onTap: aoTocar,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: CoresApp.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: conectado ? CoresApp.darkGreen : CoresApp.border,
            width: conectado ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: banco.cor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(banco.icone, size: 20, color: banco.cor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    banco.nome,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: CoresApp.textPrimary,
                    ),
                  ),
                  Text(
                    _subtitulo(conexao),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: CoresApp.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (alterando)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: CoresApp.darkGreen,
                ),
              )
            else if (conectado)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: CoresApp.primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Conectado',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CoresApp.dark,
                  ),
                ),
              )
            else
              const Icon(
                Icons.add_circle_outline_rounded,
                color: CoresApp.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}

class _EstadoIndisponivel extends StatelessWidget {
  final VoidCallback aoTentarNovamente;

  const _EstadoIndisponivel({required this.aoTentarNovamente});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: CoresApp.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Não foi possível carregar seus bancos',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CoresApp.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            BotaoPrimario(
              rotulo: 'Tentar novamente',
              aoTocar: aoTentarNovamente,
            ),
          ],
        ),
      ),
    );
  }
}
