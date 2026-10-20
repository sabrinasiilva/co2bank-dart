import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../nucleo/cores_app.dart';
import '../../../../nucleo/formatadores_entrada.dart';
import '../../../compartilhado/widgets/campo_autenticacao.dart';
import '../../../compartilhado/widgets/botao_primario.dart';

class Etapa1DadosPessoais extends StatelessWidget {
  final TextEditingController controladorNome;
  final TextEditingController controladorCpf;
  final TextEditingController controladorTelefone;
  final DateTime? dataNascimento;
  final Map<String, String?> erros;
  final VoidCallback aoContinuar;
  final void Function(DateTime) aoSelecionarDataNascimento;

  const Etapa1DadosPessoais({
    super.key,
    required this.controladorNome,
    required this.controladorCpf,
    required this.controladorTelefone,
    required this.dataNascimento,
    required this.erros,
    required this.aoContinuar,
    required this.aoSelecionarDataNascimento,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titulo(),
          const SizedBox(height: 28),
          CampoAutenticacao(
            controlador: controladorNome,
            rotulo: 'Nome completo',
            dica: 'Seu nome e sobrenome',
            icone: Icons.person_outline,
            erro: erros['name'],
          ),
          const SizedBox(height: 16),
          CampoAutenticacao(
            controlador: controladorCpf,
            rotulo: 'CPF',
            dica: '000.000.000-00',
            icone: Icons.badge_outlined,
            tipoTeclado: TextInputType.number,
            formatadores: [FormatadorCpf()],
            erro: erros['cpf'],
          ),
          const SizedBox(height: 16),
          CampoAutenticacao(
            controlador: controladorTelefone,
            rotulo: 'Celular',
            dica: '(00) 00000-0000',
            icone: Icons.phone_outlined,
            tipoTeclado: TextInputType.phone,
            formatadores: [FormatadorTelefone()],
            erro: erros['phone'],
          ),
          const SizedBox(height: 16),
          _campoDdata(context),
          const SizedBox(height: 32),
          BotaoPrimario(rotulo: 'Continuar', aoTocar: aoContinuar),
        ],
      ),
    );
  }

  Widget _titulo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dados pessoais',
            style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: CoresApp.textPrimary)),
        const SizedBox(height: 4),
        Text('Etapa 1 de 5',
            style: GoogleFonts.outfit(
                fontSize: 13, color: CoresApp.textSecondary)),
      ],
    );
  }

  Widget _campoDdata(BuildContext context) {
    final temErro = erros['birthDate'] != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Data de nascimento',
            style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: CoresApp.textPrimary)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final data = await showDatePicker(
              context: context,
              initialDate: DateTime(2000),
              firstDate: DateTime(1930),
              lastDate:
                  DateTime.now().subtract(const Duration(days: 365 * 18)),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                        primary: CoresApp.dark)),
                child: child!,
              ),
            );
            if (data != null) aoSelecionarDataNascimento(data);
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: temErro ? Colors.red : CoresApp.border),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 20,
                    color: temErro
                        ? Colors.red
                        : CoresApp.textSecondary),
                const SizedBox(width: 12),
                Text(
                  dataNascimento == null
                      ? 'DD/MM/AAAA'
                      : '${dataNascimento!.day.toString().padLeft(2, '0')}/${dataNascimento!.month.toString().padLeft(2, '0')}/${dataNascimento!.year}',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: dataNascimento == null
                        ? (temErro
                            ? Colors.red
                            : CoresApp.textSecondary)
                        : CoresApp.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (temErro)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(erros['birthDate']!,
                style:
                    GoogleFonts.outfit(fontSize: 12, color: Colors.red)),
          ),
      ],
    );
  }
}
