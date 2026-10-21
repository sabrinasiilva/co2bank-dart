import 'package:flutter/material.dart';
import '../nucleo/cores_app.dart';
import 'estilo_recompensas.dart';
import 'oferta.dart';
import 'servico/servico_recompensas.dart';
import 'tela_conquistas.dart';
import 'tela_cupons.dart';
import 'widgets/cabecalho_recompensas.dart';
import 'widgets/cartao_oferta.dart';

/// Shopping Verde: saldo de CO₂Coins, atalhos para conquistas e cupons e a
/// lista de parceiros com busca e resgate.
class TelaRecompensas extends StatefulWidget {
  const TelaRecompensas({super.key});

  @override
  State<TelaRecompensas> createState() => _TelaRecompensasState();
}

class _TelaRecompensasState extends State<TelaRecompensas> {
  final _controladorBusca = TextEditingController();
  ServicoRecompensas? _servico;
  ResumoCoins? _resumo;
  ResumoConquistas? _conquistas;
  int? _quantidadeCupons;
  bool _carregando = true;
  bool _falhou = false;
  bool _resgatando = false;
  String _busca = '';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _controladorBusca.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _falhou = false;
    });
    _servico ??= await ServicoRecompensas.autenticado();
    final (coins, conquistas, resgates) = await (
      _servico!.carregarCoins(),
      _servico!.carregarConquistas(),
      _servico!.carregarResgates(),
    ).wait;
    if (!mounted) return;
    setState(() {
      _carregando = false;
      if (conquistas case ConquistasCarregadas(:final resumo)) {
        _conquistas = resumo;
      }
      if (resgates case ResgatesCarregados(:final itens)) {
        _quantidadeCupons = itens.length;
      }
      switch (coins) {
        case CoinsCarregados(:final resumo):
          _resumo = resumo;
        case CoinsIndisponiveis():
          _falhou = true;
      }
    });
  }

  Future<void> _abrirCupons({String? codigoEmDestaque}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TelaCupons(codigoEmDestaque: codigoEmDestaque),
      ),
    );
    if (mounted) await _carregar();
  }

  Future<void> _abrirConquistas() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TelaConquistas()),
    );
    if (mounted) await _carregar();
  }

  Future<void> _abrirLoja(Oferta oferta) async {
    final abriu = await LogicaRecompensas.abrirLoja(oferta);
    if (!abriu && mounted) {
      mostrarAvisoRecompensas(context, 'Não foi possível abrir ${oferta.loja}.');
    }
  }

  Future<void> _resgatar(Oferta oferta) async {
    if (_resgatando) return;
    final confirmou = await confirmarResgate(context, oferta);
    if (!confirmou || !mounted) return;

    setState(() => _resgatando = true);
    final resultado = await _servico!.resgatar(oferta);
    if (!mounted) return;
    setState(() => _resgatando = false);

    switch (resultado) {
      case ResgateConcluido(:final codigoCupom):
        mostrarAvisoRecompensas(
          context,
          codigoCupom == null
              ? 'Cupom da ${oferta.loja} resgatado!'
              : 'Cupom da ${oferta.loja} resgatado: $codigoCupom',
          acao: SnackBarAction(
            label: 'Ver cupom',
            onPressed: () => _abrirCupons(codigoEmDestaque: codigoCupom),
          ),
        );
        await _carregar();
      case ResgateFalhou(:final mensagem):
        mostrarAvisoRecompensas(context, mensagem);
        await _carregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Shopping Verde',
          style: EstiloRecompensas.fonte(
            tamanho: 20,
            peso: FontWeight.bold,
            cor: Colors.white,
          ),
        ),
        backgroundColor: EstiloRecompensas.acao,
        foregroundColor: Colors.white,
      ),
      body: _corpo(),
    );
  }

  Widget _corpo() {
    final resumo = _resumo;
    if (resumo == null) {
      if (_carregando) {
        return const Center(
          child: CircularProgressIndicator(color: EstiloRecompensas.verde),
        );
      }
      return _ErroCarregamento(aoTentarDeNovo: _carregar);
    }

    // Enquanto um resgate está em andamento, o saldo vai a zero na tela para
    // nenhum outro botão de "Resgatar" ficar ativo ao mesmo tempo.
    final saldo = _resgatando ? 0 : resumo.disponiveis;
    final ofertas = LogicaRecompensas.filtrar(resumo.ofertas, _busca);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: RefreshIndicator(
        color: EstiloRecompensas.verde,
        onRefresh: _carregar,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CartaoSaldo(
              saldo: resumo.disponiveis,
              ganhos: resumo.ganhos,
              kgEconomizados: resumo.kgEconomizados,
            ),
            if (_falhou)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Não deu para atualizar o saldo agora. Puxe para baixo para tentar de novo.',
                  style: EstiloRecompensas.fonte(cor: EstiloRecompensas.alerta),
                ),
              ),
            const SizedBox(height: 12),
            AtalhoConquistas(
              conquistadas: _conquistas?.totalConquistadas,
              total: _conquistas?.total,
              aoTocar: _abrirConquistas,
            ),
            const SizedBox(height: 12),
            AtalhoCupons(quantidade: _quantidadeCupons, aoTocar: _abrirCupons),
            const SizedBox(height: 20),
            CampoBusca(
              controlador: _controladorBusca,
              aoAlterar: (texto) => setState(() => _busca = texto),
            ),
            const SizedBox(height: 24),
            Text('Descontos em Parceiros', style: EstiloRecompensas.tituloSecao),
            const SizedBox(height: 12),
            if (ofertas.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    'Nenhum parceiro encontrado',
                    style: EstiloRecompensas.legenda,
                  ),
                ),
              ),
            for (final oferta in ofertas)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CartaoOferta(
                  oferta: oferta,
                  saldo: saldo,
                  aoAbrir: () => _abrirLoja(oferta),
                  aoResgatar: () => _resgatar(oferta),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Aparece quando não dá para carregar o saldo e os parceiros.
class _ErroCarregamento extends StatelessWidget {
  final VoidCallback aoTentarDeNovo;

  const _ErroCarregamento({required this.aoTentarDeNovo});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: CoresApp.gray),
            const SizedBox(height: 16),
            Text(
              'Não foi possível carregar suas recompensas',
              textAlign: TextAlign.center,
              style: EstiloRecompensas.fonte(
                tamanho: 16,
                peso: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: EstiloRecompensas.acao,
              ),
              onPressed: aoTentarDeNovo,
              child: Text(
                'Tentar novamente',
                style: EstiloRecompensas.fonte(cor: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
