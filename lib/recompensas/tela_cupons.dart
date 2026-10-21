import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../nucleo/cores_app.dart';
import '../nucleo/registro_erros.dart';
import 'estilo_recompensas.dart';
import 'servico/servico_recompensas.dart';
import 'widgets/cartao_oferta.dart';

/// Cupons já resgatados (GET /rewards/redemptions), com o código para usar
/// na loja. [codigoEmDestaque] marca o cupom que acabou de ser resgatado.
class TelaCupons extends StatefulWidget {
  final String? codigoEmDestaque;

  const TelaCupons({super.key, this.codigoEmDestaque});

  @override
  State<TelaCupons> createState() => _TelaCuponsState();
}

class _TelaCuponsState extends State<TelaCupons> {
  ResultadoListaResgates? _resultado;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final servico = await ServicoRecompensas.autenticado();
    final resultado = await servico.carregarResgates();
    if (mounted) setState(() => _resultado = resultado);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.background,
      appBar: AppBar(
        title: Text(
          'Meus cupons',
          style: EstiloRecompensas.fonte(
            tamanho: 20,
            peso: FontWeight.bold,
            cor: Colors.white,
          ),
        ),
        backgroundColor: EstiloRecompensas.acao,
        foregroundColor: Colors.white,
      ),
      body: switch (_resultado) {
        null => const Center(
          child: CircularProgressIndicator(color: EstiloRecompensas.verde),
        ),
        ResgatesIndisponiveis(:final rotaAindaNaoPublicada) => _Mensagem(
          icone: Icons.cloud_off,
          titulo: rotaAindaNaoPublicada
              ? 'Os cupons vão aparecer aqui em breve'
              : 'Não foi possível carregar seus cupons',
          texto: rotaAindaNaoPublicada
              ? 'Seus resgates estão guardados. Eles aparecem nesta tela assim que o servidor for atualizado.'
              : 'Confira sua conexão e tente de novo.',
          aoTentarDeNovo: _carregar,
        ),
        ResgatesCarregados(:final itens) when itens.isEmpty => const _Mensagem(
          icone: Icons.local_offer_outlined,
          titulo: 'Você ainda não resgatou nenhum cupom',
          texto:
              'Fique abaixo do limite de CO₂ do mês para ganhar CO₂Coins e troque por desconto nos parceiros.',
        ),
        ResgatesCarregados(:final itens) => RefreshIndicator(
          color: EstiloRecompensas.verde,
          onRefresh: _carregar,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final resgate in itens)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CartaoCupom(
                    resgate: resgate,
                    emDestaque:
                        resgate.codigoCupom != null &&
                        resgate.codigoCupom == widget.codigoEmDestaque,
                  ),
                ),
            ],
          ),
        ),
      },
    );
  }
}

/// Card de um cupom resgatado, com o código, o botão de copiar e o link
/// da loja.
class CartaoCupom extends StatelessWidget {
  final Resgate resgate;
  final bool emDestaque;

  const CartaoCupom({
    super.key,
    required this.resgate,
    this.emDestaque = false,
  });

  Future<void> _copiar(BuildContext context, String codigo) async {
    await Clipboard.setData(ClipboardData(text: codigo));
    if (context.mounted) mostrarAvisoRecompensas(context, 'Código copiado');
  }

  Future<void> _abrirLoja(BuildContext context) async {
    var abriu = false;
    try {
      abriu = await launchUrl(Uri.parse(resgate.url!));
    } catch (e, pilha) {
      registrarErro(e, pilha, contexto: 'CartaoCupom._abrirLoja');
    }
    if (!abriu && context.mounted) {
      mostrarAvisoRecompensas(
        context,
        'Não foi possível abrir ${resgate.nomeParceiro}.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final codigo = resgate.codigoCupom;
    final resgatadoEm = resgate.resgatadoEm;
    final desconto = resgate.percentualDesconto;

    return Container(
      decoration: EstiloRecompensas.decoracaoCartao.copyWith(
        border: Border.all(
          color: emDestaque ? EstiloRecompensas.verdeClaro : CoresApp.border,
          width: emDestaque ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resgate.nomeParceiro,
                      style: EstiloRecompensas.nomeLoja,
                    ),
                    Text(
                      [
                        if (resgatadoEm != null)
                          'Resgatado em ${DateFormat('dd/MM/yyyy', 'pt_BR').format(resgatadoEm.toLocal())}',
                        '${resgate.custo} CO₂Coins',
                      ].join(' · '),
                      style: EstiloRecompensas.legenda,
                    ),
                  ],
                ),
              ),
              if (desconto != null) SeloDesconto(percentual: desconto),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
            decoration: BoxDecoration(
              color: CoresApp.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CoresApp.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    codigo ?? 'Código disponível em breve',
                    style: EstiloRecompensas.fonte(
                      tamanho: codigo == null ? 13 : 17,
                      peso: codigo == null
                          ? FontWeight.normal
                          : FontWeight.bold,
                      cor: codigo == null
                          ? CoresApp.textSecondary
                          : CoresApp.textPrimary,
                    ).copyWith(letterSpacing: codigo == null ? 0 : 1.5),
                  ),
                ),
                if (codigo != null)
                  IconButton(
                    tooltip: 'Copiar código',
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    color: EstiloRecompensas.verde,
                    onPressed: () => _copiar(context, codigo),
                  ),
              ],
            ),
          ),
          if (resgate.temSite) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: EstiloRecompensas.verde,
                ),
                onPressed: () => _abrirLoja(context),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(
                  'Abrir loja',
                  style: EstiloRecompensas.fonte(
                    peso: FontWeight.w600,
                    cor: EstiloRecompensas.verde,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Mensagem de lista vazia ou de erro, com botão de tentar de novo quando
/// [aoTentarDeNovo] é informado.
class _Mensagem extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String texto;
  final VoidCallback? aoTentarDeNovo;

  const _Mensagem({
    required this.icone,
    required this.titulo,
    required this.texto,
    this.aoTentarDeNovo,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 48, color: CoresApp.gray),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: EstiloRecompensas.fonte(
                tamanho: 16,
                peso: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: EstiloRecompensas.legenda,
            ),
            if (aoTentarDeNovo != null) ...[
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
          ],
        ),
      ),
    );
  }
}

/// Atalho na tela do Shopping Verde que abre os cupons.
class AtalhoCupons extends StatelessWidget {
  final int? quantidade;
  final VoidCallback aoTocar;

  const AtalhoCupons({
    super.key,
    required this.quantidade,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    final quantidade = this.quantidade;
    final subtitulo = switch (quantidade) {
      null => 'Veja os descontos que você já resgatou',
      0 => 'Nenhum cupom resgatado ainda',
      1 => '1 cupom resgatado',
      _ => '$quantidade cupons resgatados',
    };
    return Container(
      decoration: EstiloRecompensas.decoracaoCartao,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: aoTocar,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: EstiloRecompensas.verdeClaro.withAlpha(60),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_offer_outlined,
                    color: EstiloRecompensas.verde,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Meus cupons', style: EstiloRecompensas.nomeLoja),
                      Text(subtitulo, style: EstiloRecompensas.legenda),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: CoresApp.gray),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
