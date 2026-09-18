import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/app_colors.dart';
import '../../widgets/primary_button.dart';

class Step3Facial extends StatefulWidget {
  final String? capturedPhotoBase64;
  final void Function(String? base64) onPhotoCaptured;
  final VoidCallback onContinue;

  const Step3Facial({
    super.key,
    required this.capturedPhotoBase64,
    required this.onPhotoCaptured,
    required this.onContinue,
  });

  @override
  State<Step3Facial> createState() => _Step3FacialState();
}

class _Step3FacialState extends State<Step3Facial> {
  bool _capturing = false;
  String? _error;

  Future<void> _takeSelfie() async {
    setState(() { _capturing = true; _error = null; });
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 40,
        maxWidth: 400,
        maxHeight: 400,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        final base64 = base64Encode(bytes);
        widget.onPhotoCaptured(base64);
      }
    } catch (e) {
      setState(() => _error = 'Não foi possível acessar a câmera.');
    } finally {
      setState(() => _capturing = false);
    }
  }

  void _retake() => widget.onPhotoCaptured(null);

  @override
  Widget build(BuildContext context) {
    final hasFace = widget.capturedPhotoBase64 != null;

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
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Etapa 3 de 5',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sua selfie é usada para confirmar sua identidade ao redefinir a senha.',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),

          // Face preview or guide
          Center(
            child: hasFace
                ? _PhotoPreview(base64: widget.capturedPhotoBase64!)
                : const _FaceGuide(),
          ),

          const SizedBox(height: 28),

          if (_error != null) ...[
            Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 14, color: Colors.red),
                const SizedBox(width: 6),
                Text(_error!,
                    style: GoogleFonts.outfit(
                        fontSize: 13, color: Colors.red)),
              ],
            ),
            const SizedBox(height: 16),
          ],

          if (hasFace) ...[
            PrimaryButton(
              label: 'Continuar',
              onPressed: widget.onContinue,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _retake,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  'Tirar novamente',
                  style: GoogleFonts.outfit(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ] else ...[
            _capturing
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary))
                : PrimaryButton(
                    label: 'Tirar selfie',
                    onPressed: _takeSelfie,
                  ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: widget.onContinue,
                child: Text(
                  'Pular por agora',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppColors.textSecondary,
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

// ── Face guide oval ──────────────────────────────────────────────────

class _FaceGuide extends StatelessWidget {
  const _FaceGuide();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 200,
          height: 240,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: AppColors.primaryMuted,
              width: 2.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.face_outlined,
                size: 80,
                color: AppColors.primaryMuted.withOpacity(0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'Posicione seu rosto\naqui',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        // corner indicators
        ..._corners(),
      ],
    );
  }

  List<Widget> _corners() {
    const size = 20.0;
    const thickness = 3.0;
    const color = AppColors.primary;
    const offset = 0.0;

    return [
      Positioned(
        top: offset,
        left: 20,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: thickness),
              left: BorderSide(color: color, width: thickness),
            ),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(4)),
          ),
        ),
      ),
      Positioned(
        top: offset,
        right: 20,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: thickness),
              right: BorderSide(color: color, width: thickness),
            ),
            borderRadius: BorderRadius.only(topRight: Radius.circular(4)),
          ),
        ),
      ),
      Positioned(
        bottom: offset,
        left: 20,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: thickness),
              left: BorderSide(color: color, width: thickness),
            ),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(4)),
          ),
        ),
      ),
      Positioned(
        bottom: offset,
        right: 20,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: thickness),
              right: BorderSide(color: color, width: thickness),
            ),
            borderRadius: BorderRadius.only(bottomRight: Radius.circular(4)),
          ),
        ),
      ),
    ];
  }
}

// ── Photo preview ────────────────────────────────────────────────────

class _PhotoPreview extends StatelessWidget {
  final String base64;

  const _PhotoPreview({required this.base64});

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
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded,
              size: 16, color: Colors.white),
        ),
      ],
    );
  }
}
