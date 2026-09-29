import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../nucleo/cores_app.dart';
import '../nucleo/armazenamento_token.dart';
import '../perfil/servico/servico_usuario.dart';
import '../autenticacao/telas/tela_login.dart';

class AbaPerfil extends StatefulWidget {
  const AbaPerfil({super.key});

  @override
  State<AbaPerfil> createState() => _AbaPerfilState();
}

class _AbaPerfilState extends State<AbaPerfil> {
  late Future<ResultadoPerfil> _dados;

  @override
  void initState() {
    super.initState();
    _dados = _carregar();
  }

  Future<ResultadoPerfil> _carregar() async {
    final servico = await ServicoUsuario.autenticado();
    return servico.obterPerfil();
  }

  Future<void> _sair() async {
    await ArmazenamentoToken.limpar();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const TelaLogin()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<ResultadoPerfil>(
        future: _dados,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: CoresApp.darkGreen),
            );
          }

          final PerfilUsuario? perfil = switch (snapshot.data) {
            PerfilCarregado(:final perfil) => perfil,
            _ => null,
          };

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              Text(
                'Perfil',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: CoresApp.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: CoresApp.dark,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      perfil?.nome.isNotEmpty == true
                          ? perfil!.nome[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: CoresApp.darkGreen,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (perfil != null) ...[
                Center(
                  child: Text(
                    perfil.nome,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: CoresApp.textPrimary,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    perfil.email,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: CoresApp.textSecondary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              _CartaoInfo(
                itens: [
                  if (perfil != null) ...[
                    _LinhaInfo(rotulo: 'CPF', valor: perfil.cpf),
                    _LinhaInfo(rotulo: 'Telefone', valor: perfil.telefone),
                    _LinhaInfo(
                      rotulo: 'Limite de CO2',
                      valor: '${perfil.limiteCo2Kg.toStringAsFixed(0)} kg/mês',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _sair,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CoresApp.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.logout_rounded,
                          size: 20, color: Colors.red),
                      const SizedBox(width: 12),
                      Text(
                        'Sair da conta',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CartaoInfo extends StatelessWidget {
  final List<Widget> itens;

  const _CartaoInfo({required this.itens});

  @override
  Widget build(BuildContext context) {
    if (itens.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: CoresApp.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: itens),
    );
  }
}

class _LinhaInfo extends StatelessWidget {
  final String rotulo;
  final String valor;

  const _LinhaInfo({required this.rotulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            rotulo,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: CoresApp.textSecondary,
            ),
          ),
          Text(
            valor,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CoresApp.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
