import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../nucleo/aviso_dados_alterados.dart';
import '../nucleo/cores_app.dart';
import '../nucleo/tipografia.dart';
import 'servico/atualizacao_app.dart';
import 'servico/servico_notificacoes.dart';
import 'tela_notificacoes.dart';

/// Sininho do topo da tela inicial, com a quantidade do que ainda não foi
/// visto: notificações novas do backend e a versão nova do app.
class SinoNotificacoes extends StatefulWidget {
  const SinoNotificacoes({super.key});

  @override
  State<SinoNotificacoes> createState() => _SinoNotificacoesState();
}

class _SinoNotificacoesState extends State<SinoNotificacoes> {
  int _naoLidas = 0;
  AtualizacaoDisponivel? _atualizacao;

  @override
  void initState() {
    super.initState();
    _atualizar();
    // Compra nova pode virar alerta da IA ou conquista.
    AvisoDadosAlterados.instancia.addListener(_atualizar);
  }

  @override
  void dispose() {
    AvisoDadosAlterados.instancia.removeListener(_atualizar);
    super.dispose();
  }

  Future<void> _atualizar() async {
    final servico = await ServicoNotificacoes.autenticado();
    final (central, atualizacao) =
        await (servico.carregar(), VerificadorAtualizacao.verificar()).wait;
    if (!mounted) return;
    setState(() {
      _naoLidas = central.naoLidas;
      _atualizacao = atualizacao;
    });
  }

  Future<void> _abrir() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TelaNotificacoes(atualizacao: _atualizacao)),
    );
    if (mounted) await _atualizar();
  }

  @override
  Widget build(BuildContext context) {
    final total = _naoLidas + (_atualizacao == null ? 0 : 1);
    return Semantics(
      button: true,
      label: total == 0 ? 'Notificações' : 'Notificações, $total novas',
      child: GestureDetector(
        onTap: _abrir,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_none_rounded,
                    size: 22, color: Colors.white),
              ),
              if (total > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: CoresApp.accentWarm,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: CoresApp.dark, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      total > 9 ? '9+' : '$total',
                      style: GoogleFonts.outfit(
                        fontSize: Tipografia.minimo - 1,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
