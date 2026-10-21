import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../nucleo/cores_app.dart';
import 'estilo_recompensas.dart';
import 'servico/servico_recompensas.dart';

/// Ícone de cada conquista, a partir do nome que vem do backend.
/// Conquista nova com outro ícone precisa de uma linha aqui.
IconData iconeDaConquista(String nome) => switch (nome) {
  'foot_print' => Icons.directions_walk,
  'eco' => Icons.eco,
  'shield' => Icons.shield,
  'category' => Icons.category,
  'calendar' => Icons.calendar_month,
  _ => Icons.emoji_events,
};

/// Lista das conquistas (GET /rewards), com o resumo no topo.
class TelaConquistas extends StatefulWidget {
  const TelaConquistas({super.key});

  @override
  State<TelaConquistas> createState() => _TelaConquistasState();
}

class _TelaConquistasState extends State<TelaConquistas> {
  ResumoConquistas? _resumo;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    final servico = await ServicoRecompensas.autenticado();
    final resultado = await servico.carregarConquistas();
    if (!mounted) return;
    setState(() {
      _carregando = false;
      if (resultado case ConquistasCarregadas(:final resumo)) _resumo = resumo;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Conquistas',
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: CoresApp.gray),
              const SizedBox(height: 16),
              Text(
                'Não foi possível carregar suas conquistas',
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
                onPressed: _carregar,
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

    // Conquistadas primeiro, na ordem em que vieram do backend.
    final itens = [
      ...resumo.itens.where((c) => c.conquistada),
      ...resumo.itens.where((c) => !c.conquistada),
    ];

    return RefreshIndicator(
      color: EstiloRecompensas.verde,
      onRefresh: _carregar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CartaoResumoConquistas(
            conquistadas: resumo.totalConquistadas,
            total: resumo.total,
          ),
          const SizedBox(height: 24),
          Text('Suas conquistas', style: EstiloRecompensas.tituloSecao),
          const SizedBox(height: 12),
          for (final conquista in itens)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CartaoConquista(conquista: conquista),
            ),
        ],
      ),
    );
  }
}

/// Cartão do topo com "X de Y conquistadas" e a barra de progresso.
class CartaoResumoConquistas extends StatelessWidget {
  final int conquistadas;
  final int total;

  const CartaoResumoConquistas({
    super.key,
    required this.conquistadas,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final progresso =
        total > 0 ? (conquistadas / total).clamp(0.0, 1.0) : 0.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: EstiloRecompensas.gradienteSaldo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events,
                color: EstiloRecompensas.verde,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text('Suas conquistas', style: _textoDoCartao),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$conquistadas de $total conquistadas',
            style: EstiloRecompensas.fonte(
              cor: EstiloRecompensas.verde,
              tamanho: 28,
              peso: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progresso),
              duration: const Duration(milliseconds: 700),
              builder: (_, valor, _) => LinearProgressIndicator(
                value: valor,
                minHeight: 10,
                backgroundColor: EstiloRecompensas.verde.withAlpha(40),
                color: EstiloRecompensas.verde,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            conquistadas >= total
                ? 'Você conquistou todas!'
                : 'Faltam ${total - conquistadas} para completar',
            style: _textoDoCartao,
          ),
        ],
      ),
    );
  }
}

final _textoDoCartao = EstiloRecompensas.fonte(cor: EstiloRecompensas.verde);

/// Card de uma conquista: verde quando já foi ganha, cinza com cadeado quando
/// ainda não.
class CartaoConquista extends StatelessWidget {
  final Conquista conquista;

  const CartaoConquista({super.key, required this.conquista});

  @override
  Widget build(BuildContext context) {
    final conquistada = conquista.conquistada;
    final conquistadaEm = conquista.conquistadaEm;
    final cor = conquistada ? EstiloRecompensas.verde : CoresApp.gray;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: conquistada
            ? EstiloRecompensas.verdeClaro.withAlpha(40)
            : CoresApp.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: conquistada
              ? EstiloRecompensas.verdeClaro.withAlpha(120)
              : CoresApp.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: conquistada ? EstiloRecompensas.verdeClaro : CoresApp.border,
              shape: BoxShape.circle,
            ),
            child: Icon(
              conquistada
                  ? iconeDaConquista(conquista.icone)
                  : Icons.lock_outline,
              color: conquistada ? CoresApp.dark : CoresApp.gray,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(conquista.titulo, style: EstiloRecompensas.nomeLoja),
                const SizedBox(height: 2),
                Text(conquista.descricao, style: EstiloRecompensas.legenda),
                const SizedBox(height: 6),
                Text(
                  conquistada
                      ? conquistadaEm == null
                            ? 'Conquistada'
                            : 'Conquistada em ${DateFormat('dd/MM/yyyy', 'pt_BR').format(conquistadaEm.toLocal())}'
                      : 'Ainda não conquistada',
                  style: EstiloRecompensas.fonte(
                    tamanho: 13,
                    peso: FontWeight.bold,
                    cor: cor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Atalho na tela do Shopping Verde que abre as conquistas.
class AtalhoConquistas extends StatelessWidget {
  final int? conquistadas;
  final int? total;
  final VoidCallback aoTocar;

  const AtalhoConquistas({
    super.key,
    required this.conquistadas,
    required this.total,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    final subtitulo = conquistadas != null && total != null
        ? '$conquistadas de $total conquistadas'
        : 'Veja as conquistas que você já ganhou';
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
                    color: EstiloRecompensas.dourado.withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: EstiloRecompensas.alerta,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Conquistas', style: EstiloRecompensas.nomeLoja),
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
