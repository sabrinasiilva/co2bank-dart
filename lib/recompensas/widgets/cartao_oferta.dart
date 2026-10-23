import 'package:flutter/material.dart';
import '../../nucleo/cores_app.dart';
import '../estilo_recompensas.dart';
import '../oferta.dart';

/// Card de uma oferta. Tocar no card abre o site da loja (quando ela tem
/// site) e o botão resgata o desconto. Se a loja já foi resgatada no mês,
/// o botão abre o cupom em vez de resgatar de novo.
class CartaoOferta extends StatelessWidget {
  final Oferta oferta;
  final int saldo;
  final String? cupomDoMes;
  final VoidCallback aoAbrir;
  final VoidCallback aoResgatar;
  final VoidCallback aoVerCupom;

  const CartaoOferta({
    super.key,
    required this.oferta,
    required this.saldo,
    this.cupomDoMes,
    required this.aoAbrir,
    required this.aoResgatar,
    required this.aoVerCupom,
  });

  bool get _jaResgatada => cupomDoMes != null;
  bool get _podeResgatar => !_jaResgatada && saldo >= oferta.custo;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: EstiloRecompensas.decoracaoCartao,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: oferta.temSite ? aoAbrir : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LogoLoja(oferta: oferta),
                    const SizedBox(width: 14),
                    Expanded(child: InfoOferta(oferta: oferta)),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _jaResgatada
                        ? 1
                        : LogicaRecompensas.progresso(saldo, oferta.custo),
                    minHeight: 8,
                    backgroundColor: CoresApp.border,
                    color: _podeResgatar || _jaResgatada
                        ? EstiloRecompensas.verdeClaro
                        : EstiloRecompensas.dourado,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _jaResgatada
                          ? _CupomDoMes(codigo: cupomDoMes!)
                          : SituacaoOferta(oferta: oferta, saldo: saldo),
                    ),
                    if (_jaResgatada)
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: EstiloRecompensas.acao,
                          side: const BorderSide(color: EstiloRecompensas.acao),
                          shape: const StadiumBorder(),
                          textStyle: EstiloRecompensas.fonte(
                            peso: FontWeight.w600,
                          ),
                        ),
                        onPressed: aoVerCupom,
                        child: const Text('Ver cupom'),
                      )
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EstiloRecompensas.acao,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          textStyle: EstiloRecompensas.fonte(
                            peso: FontWeight.w600,
                          ),
                        ),
                        onPressed: _podeResgatar ? aoResgatar : null,
                        child: const Text('Resgatar'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Situação da oferta quando o cupom do mês já foi resgatado.
class _CupomDoMes extends StatelessWidget {
  final String codigo;

  const _CupomDoMes({required this.codigo});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resgatado este mês',
          style: EstiloRecompensas.fonte(
            peso: FontWeight.bold,
            tamanho: 13,
            cor: EstiloRecompensas.verde,
          ),
        ),
        Text(codigo, style: EstiloRecompensas.legenda),
      ],
    );
  }
}

/// Pergunta se a pessoa quer mesmo gastar as CO₂Coins nessa oferta.
/// Devolve true só se ela confirmar.
Future<bool> confirmarResgate(BuildContext context, Oferta oferta) async {
  final confirmou = await showDialog<bool>(
    context: context,
    builder: (contextoDialogo) => AlertDialog(
      title: Text(
        'Resgatar desconto?',
        style: EstiloRecompensas.fonte(tamanho: 20, peso: FontWeight.bold),
      ),
      content: Text(
        'Você vai usar ${LogicaRecompensas.formatar(oferta.custo)} CO₂Coins para '
        'garantir "${oferta.descricao}" na ${oferta.loja}.',
        style: EstiloRecompensas.fonte(cor: CoresApp.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(contextoDialogo, false),
          child: Text(
            'Cancelar',
            style: EstiloRecompensas.fonte(cor: CoresApp.textSecondary),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: EstiloRecompensas.acao,
          ),
          onPressed: () => Navigator.pop(contextoDialogo, true),
          child: Text(
            'Resgatar',
            style: EstiloRecompensas.fonte(
              cor: Colors.white,
              peso: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
  return confirmou ?? false;
}

/// Aviso curto na parte de baixo da tela. Esconde o aviso anterior para as
/// mensagens não se empilharem.
void mostrarAvisoRecompensas(
  BuildContext context,
  String mensagem, {
  SnackBarAction? acao,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          mensagem,
          style: EstiloRecompensas.fonte(cor: Colors.white),
        ),
        action: acao,
        behavior: SnackBarBehavior.floating,
      ),
    );
}
