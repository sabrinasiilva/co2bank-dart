import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../compartilhado/widgets/botao_primario.dart';
import '../../compartilhado/widgets/campo_autenticacao.dart';
import '../../nucleo/cores_app.dart';
import '../../nucleo/formatadores_entrada.dart';
import '../icone_categoria.dart';
import '../servico/servico_transacao.dart';

/// Simula o impacto de uma compra no limite antes de fazer e, se a pessoa
/// quiser, registra a compra. Devolve true quando uma compra foi registrada.
class TelaNovaCompra extends StatefulWidget {
  const TelaNovaCompra({super.key});

  @override
  State<TelaNovaCompra> createState() => _TelaNovaCompraState();
}

class _TelaNovaCompraState extends State<TelaNovaCompra> {
  final _controladorValor = TextEditingController();
  final _controladorNome = TextEditingController();
  ServicoTransacao? _servico;
  List<CategoriaCompra>? _categorias;
  CategoriaCompra? _categoria;
  DateTime _data = DateTime.now();
  EstimativaCompra? _estimativa;
  String? _erroSimulacao;
  bool _simulando = false;
  bool _registrando = false;
  String? _erroValor;
  String? _erroCategoria;
  String? _erroNome;

  @override
  void initState() {
    super.initState();
    _carregarCategorias();
  }

  @override
  void dispose() {
    _controladorValor.dispose();
    _controladorNome.dispose();
    super.dispose();
  }

  Future<void> _carregarCategorias() async {
    _servico ??= await ServicoTransacao.autenticado();
    final resultado = await _servico!.listarCategorias();
    if (!mounted) return;
    setState(() {
      _categorias = switch (resultado) {
        CategoriasCarregadas(:final categorias) => categorias,
        CategoriasDeReserva() => categoriasDeReserva,
      };
    });
  }

  double? get _valor => FormatadorMoeda.valor(_controladorValor.text);

  // Qualquer mudança no formulário invalida a simulação anterior.
  void _limparSimulacao() {
    if (_estimativa == null && _erroSimulacao == null) return;
    setState(() {
      _estimativa = null;
      _erroSimulacao = null;
    });
  }

  bool _validar({required bool exigeNome}) {
    final valor = _valor;
    setState(() {
      _erroValor = valor == null || valor <= 0
          ? 'Informe o valor da compra'
          : null;
      _erroCategoria = _categoria == null ? 'Escolha uma categoria' : null;
      _erroNome = exigeNome && _controladorNome.text.trim().isEmpty
          ? 'Informe onde foi a compra'
          : null;
    });
    return _erroValor == null && _erroCategoria == null && _erroNome == null;
  }

  Future<void> _simular() async {
    FocusScope.of(context).unfocus();
    if (!_validar(exigeNome: false)) return;
    setState(() {
      _simulando = true;
      _erroSimulacao = null;
    });
    final resultado = await _servico!.estimarCompra(
      codigoCategoria: _categoria!.codigo,
      valor: _valor!,
    );
    if (!mounted) return;
    setState(() {
      _simulando = false;
      switch (resultado) {
        case EstimativaCalculada(:final estimativa):
          _estimativa = estimativa;
        case EstimativaErro(:final mensagem):
          _erroSimulacao = mensagem;
      }
    });
  }

  Future<void> _registrar() async {
    FocusScope.of(context).unfocus();
    if (!_validar(exigeNome: true)) return;
    setState(() => _registrando = true);
    final hoje = DateTime.now();
    final ehHoje =
        _data.year == hoje.year &&
        _data.month == hoje.month &&
        _data.day == hoje.day;
    final resultado = await _servico!.criarTransacao(
      nomeEstabelecimento: _controladorNome.text.trim(),
      codigoCategoria: _categoria!.codigo,
      valor: _valor!,
      ocorreuEm: ehHoje
          ? null
          : DateTime(_data.year, _data.month, _data.day, 12),
    );
    if (!mounted) return;
    setState(() => _registrando = false);

    switch (resultado) {
      case TransacaoRegistrada(:final transacao):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Compra registrada: ${transacao.co2Kg.toStringAsFixed(1)} kg de CO2',
              style: GoogleFonts.outfit(),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      case RegistroErro(:final mensagem):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensagem, style: GoogleFonts.outfit()),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<void> _escolherData() async {
    final hoje = DateTime.now();
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(hoje.year - 1, hoje.month, hoje.day),
      lastDate: hoje,
      locale: const Locale('pt', 'BR'),
    );
    if (escolhida != null) setState(() => _data = escolhida);
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
          'Nova compra',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(
              'Simule o impacto antes de comprar ou registre uma compra que você já fez.',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: CoresApp.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            CampoAutenticacao(
              controlador: _controladorValor,
              rotulo: 'Valor (R\$)',
              dica: '0,00',
              icone: Icons.payments_outlined,
              erro: _erroValor,
              tipoTeclado: TextInputType.number,
              formatadores: [FormatadorMoeda()],
              aoAlterar: (_) {
                if (_erroValor != null) setState(() => _erroValor = null);
                _limparSimulacao();
              },
            ),
            const SizedBox(height: 20),
            _SeletorCategoria(
              categorias: _categorias,
              selecionada: _categoria,
              erro: _erroCategoria,
              aoSelecionar: (c) {
                setState(() {
                  _categoria = c;
                  _erroCategoria = null;
                });
                _limparSimulacao();
              },
            ),
            const SizedBox(height: 20),
            CampoAutenticacao(
              controlador: _controladorNome,
              rotulo: 'Onde foi a compra',
              dica: 'Ex.: Posto Ipiranga (opcional para simular)',
              icone: Icons.storefront_outlined,
              erro: _erroNome,
              aoAlterar: (_) {
                if (_erroNome != null) setState(() => _erroNome = null);
              },
            ),
            const SizedBox(height: 20),
            _CampoData(data: _data, aoTocar: _escolherData),
            const SizedBox(height: 24),
            BotaoPrimario(
              rotulo: 'Simular impacto',
              carregando: _simulando,
              aoTocar: _registrando ? null : _simular,
            ),
            if (_estimativa != null) ...[
              const SizedBox(height: 16),
              _ResultadoSimulacao(estimativa: _estimativa!),
            ],
            if (_erroSimulacao != null) ...[
              const SizedBox(height: 16),
              _AvisoErro(mensagem: _erroSimulacao!),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: _registrando || _simulando ? null : _registrar,
                style: OutlinedButton.styleFrom(
                  foregroundColor: CoresApp.textPrimary,
                  side: const BorderSide(color: CoresApp.dark, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _registrando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: CoresApp.textPrimary,
                        ),
                      )
                    : Text(
                        'Registrar compra',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeletorCategoria extends StatelessWidget {
  final List<CategoriaCompra>? categorias;
  final CategoriaCompra? selecionada;
  final String? erro;
  final ValueChanged<CategoriaCompra> aoSelecionar;

  const _SeletorCategoria({
    required this.categorias,
    required this.selecionada,
    required this.erro,
    required this.aoSelecionar,
  });

  @override
  Widget build(BuildContext context) {
    final categorias = this.categorias;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categoria',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: CoresApp.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (categorias == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: CoresApp.primary,
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in categorias)
                _ChipCategoria(
                  categoria: c,
                  selecionada: selecionada?.codigo == c.codigo,
                  aoTocar: () => aoSelecionar(c),
                ),
            ],
          ),
        if (erro != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              erro!,
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.red),
            ),
          ),
      ],
    );
  }
}

class _ChipCategoria extends StatelessWidget {
  final CategoriaCompra categoria;
  final bool selecionada;
  final VoidCallback aoTocar;

  const _ChipCategoria({
    required this.categoria,
    required this.selecionada,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: aoTocar,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selecionada
              ? CoresApp.primary.withValues(alpha: 0.35)
              : CoresApp.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selecionada ? CoresApp.brandText : CoresApp.border,
            width: selecionada ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              iconePorCategoria(categoria.rotulo),
              size: 16,
              color: selecionada ? CoresApp.brandText : CoresApp.gray,
            ),
            const SizedBox(width: 6),
            Text(
              categoria.rotulo,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: selecionada ? FontWeight.w700 : FontWeight.w500,
                color: selecionada ? CoresApp.brandText : CoresApp.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampoData extends StatelessWidget {
  final DateTime data;
  final VoidCallback aoTocar;

  const _CampoData({required this.data, required this.aoTocar});

  @override
  Widget build(BuildContext context) {
    final hoje = DateTime.now();
    final ehHoje =
        data.year == hoje.year &&
        data.month == hoje.month &&
        data.day == hoje.day;
    final texto = ehHoje
        ? 'Hoje, ${DateFormat("d 'de' MMMM", 'pt_BR').format(data)}'
        : DateFormat("d 'de' MMMM 'de' y", 'pt_BR').format(data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data da compra (para registrar)',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: CoresApp.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: aoTocar,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: CoresApp.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CoresApp.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: CoresApp.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    texto,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: CoresApp.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.edit_calendar_outlined,
                  size: 18,
                  color: CoresApp.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultadoSimulacao extends StatelessWidget {
  final EstimativaCompra estimativa;

  const _ResultadoSimulacao({required this.estimativa});

  @override
  Widget build(BuildContext context) {
    final antes = estimativa.percentualAntes;
    final depois = estimativa.percentualDepois;
    final perto = !estimativa.passaDoLimite && depois >= 80;

    final (
      Color cor,
      IconData icone,
      String titulo,
      String texto,
    ) = estimativa.passaDoLimite
        ? (
            CoresApp.accentWarm,
            Icons.warning_amber_rounded,
            'Essa compra passaria do seu limite',
            'Ela levaria você de ${antes.toStringAsFixed(0)}% para '
                '${depois.toStringAsFixed(0)}% do limite do mês. '
                'Que tal adiar ou escolher outra opção?',
          )
        : perto
        ? (
            CoresApp.accentWarm,
            Icons.info_outline_rounded,
            'Fica perto do limite',
            'Você ficaria em ${depois.toStringAsFixed(0)}% do limite '
                'do mês. Vale pensar se dá para esperar.',
          )
        : (
            CoresApp.brandText,
            Icons.check_circle_outline_rounded,
            'Tranquilo',
            'Você ficaria em ${depois.toStringAsFixed(0)}% do limite do mês.',
          );

    // A barra vai até 100% ou até onde a compra levaria, o que for maior.
    final escala = depois > 100 ? depois : 100.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CoresApp.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: cor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            texto,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: CoresApp.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${estimativa.co2Kg.toStringAsFixed(1)} kg de CO2 estimados',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: CoresApp.textPrimary,
            ),
          ),
          Text(
            'em ${estimativa.rotuloCategoria}',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: CoresApp.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (_, restricoes) {
              final largura = restricoes.maxWidth;
              final xAntes = largura * (antes / escala).clamp(0.0, 1.0);
              final xDepois = largura * (depois / escala).clamp(0.0, 1.0);
              final xLimite = largura * (100 / escala);
              return SizedBox(
                height: 14,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: CoresApp.background,
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: xAntes, end: xDepois),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (_, x, _) => Container(
                        width: x,
                        decoration: BoxDecoration(
                          color: estimativa.passaDoLimite
                              ? CoresApp.accentWarm
                              : CoresApp.primary.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                    ),
                    Container(
                      width: xAntes,
                      decoration: BoxDecoration(
                        color: CoresApp.brandText,
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    Positioned(
                      left: xLimite - 1,
                      top: -4,
                      bottom: -4,
                      child: Container(width: 2, color: CoresApp.dark),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _ItemLegenda(
                cor: CoresApp.brandText,
                texto: 'Hoje: ${antes.toStringAsFixed(0)}%',
              ),
              _ItemLegenda(
                cor: estimativa.passaDoLimite
                    ? CoresApp.accentWarm
                    : CoresApp.primary.withValues(alpha: 0.5),
                texto: 'Com a compra: ${depois.toStringAsFixed(0)}%',
              ),
              _ItemLegenda(
                cor: CoresApp.dark,
                texto: 'Limite: ${estimativa.limiteKg.toStringAsFixed(0)} kg',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'É só uma simulação: nada foi salvo no seu extrato.',
            style: GoogleFonts.outfit(fontSize: 12, color: CoresApp.gray),
          ),
        ],
      ),
    );
  }
}

class _ItemLegenda extends StatelessWidget {
  final Color cor;
  final String texto;

  const _ItemLegenda({required this.cor, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: CoresApp.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _AvisoErro extends StatelessWidget {
  final String mensagem;

  const _AvisoErro({required this.mensagem});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CoresApp.accentWarm.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 20,
            color: CoresApp.accentWarm,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$mensagem Você ainda pode registrar a compra.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: CoresApp.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
