import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../nucleo/cores_app.dart';
import '../../../../nucleo/registro_erros.dart';
import '../../../compartilhado/widgets/botao_primario.dart';

class Etapa3VerificacaoFacial extends StatefulWidget {
  final String? fotoCapturadaBase64;
  final void Function(String? base64) aoCapturarFoto;
  final VoidCallback aoContinuar;

  const Etapa3VerificacaoFacial({
    super.key,
    required this.fotoCapturadaBase64,
    required this.aoCapturarFoto,
    required this.aoContinuar,
  });

  @override
  State<Etapa3VerificacaoFacial> createState() =>
      _Etapa3VerificacaoFacialState();
}

class _Etapa3VerificacaoFacialState extends State<Etapa3VerificacaoFacial> {
  bool _capturando = false;
  String? _erro;

  Future<void> _tirarSelfie() async {
    setState(() {
      _capturando = true;
      _erro = null;
    });
    try {
      final picker = ImagePicker();
      final foto = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 40,
        maxWidth: 400,
        maxHeight: 400,
      );

      if (foto != null) {
        final bytes = await foto.readAsBytes();
        final base64 = base64Encode(bytes);
        widget.aoCapturarFoto(base64);
      }
    } catch (e, pilha) {
      registrarErro(e, pilha,
          contexto: 'Etapa3VerificacaoFacial._tirarSelfie');
      setState(() => _erro = 'Não foi possível acessar a câmera.');
    } finally {
      setState(() => _capturando = false);
    }
  }

  void _retirar() => widget.aoCapturarFoto(null);

  @override
  Widget build(BuildContext context) {
    final temFoto = widget.fotoCapturadaBase64 != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verificação facial',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: CoresApp.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Etapa 3 de 5',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: CoresApp.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sua selfie é usada para reforçar a segurança da sua conta.',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: CoresApp.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          Center(
            child: temFoto
                ? _PreviewFoto(base64: widget.fotoCapturadaBase64!)
                : const _GuiaFacial(),
          ),
          const SizedBox(height: 28),
          if (_erro != null) ...[
            Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 14, color: Colors.red),
                const SizedBox(width: 6),
                Text(_erro!,
                    style: GoogleFonts.outfit(
                        fontSize: 13, color: Colors.red)),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (temFoto) ...[
            BotaoPrimario(
              rotulo: 'Continuar',
              aoTocar: widget.aoContinuar,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _retirar,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  'Tirar novamente',
                  style: GoogleFonts.outfit(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: CoresApp.textPrimary,
                  side: const BorderSide(color: CoresApp.border),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ] else ...[
            _capturando
                ? const Center(
                    child: CircularProgressIndicator(
                        color: CoresApp.primary))
                : BotaoPrimario(
                    rotulo: 'Tirar selfie',
                    aoTocar: _tirarSelfie,
                  ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: widget.aoContinuar,
                child: Text(
                  'Pular por agora',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: CoresApp.textSecondary,
                    decoration: TextDecoration.underline,
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

class _GuiaFacial extends StatelessWidget {
  const _GuiaFacial();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 200,
          height: 240,
          decoration: BoxDecoration(
            color: CoresApp.background,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: CoresApp.primaryMuted,
              width: 2.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.face_outlined,
                size: 80,
                color: CoresApp.primaryMuted.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'Posicione seu rosto\naqui',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: CoresApp.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        ..._cantos(),
      ],
    );
  }

  List<Widget> _cantos() {
    const tamanho = 20.0;
    const espessura = 3.0;
    const cor = CoresApp.primary;
    const offset = 0.0;

    return [
      Positioned(
        top: offset,
        left: 20,
        child: Container(
          width: tamanho,
          height: tamanho,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: cor, width: espessura),
              left: BorderSide(color: cor, width: espessura),
            ),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(4)),
          ),
        ),
      ),
      Positioned(
        top: offset,
        right: 20,
        child: Container(
          width: tamanho,
          height: tamanho,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: cor, width: espessura),
              right: BorderSide(color: cor, width: espessura),
            ),
            borderRadius: BorderRadius.only(topRight: Radius.circular(4)),
          ),
        ),
      ),
      Positioned(
        bottom: offset,
        left: 20,
        child: Container(
          width: tamanho,
          height: tamanho,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: cor, width: espessura),
              left: BorderSide(color: cor, width: espessura),
            ),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(4)),
          ),
        ),
      ),
      Positioned(
        bottom: offset,
        right: 20,
        child: Container(
          width: tamanho,
          height: tamanho,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: cor, width: espessura),
              right: BorderSide(color: cor, width: espessura),
            ),
            borderRadius:
                BorderRadius.only(bottomRight: Radius.circular(4)),
          ),
        ),
      ),
    ];
  }
}

class _PreviewFoto extends StatelessWidget {
  final String base64;

  const _PreviewFoto({required this.base64});

  @override
  Widget build(BuildContext context) {
    final Uint8List bytes = base64Decode(base64);

    return Stack(
      alignment: Alignment.topRight,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: Image.memory(
            bytes,
            width: 200,
            height: 240,
            fit: BoxFit.cover,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            color: CoresApp.primary,
            shape: BoxShape.circle,
          ),
          child:
              const Icon(Icons.check_rounded, size: 16, color: Colors.white),
        ),
      ],
    );
  }
}
