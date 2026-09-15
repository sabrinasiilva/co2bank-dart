import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/app_colors.dart';
import '../../widgets/primary_button.dart';

class Step5Done extends StatelessWidget {
  final VoidCallback onStart;

  const Step5Done({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                  color: AppColors.darkGreen, shape: BoxShape.circle),
              child:
                  const Icon(Icons.check_rounded, size: 52, color: Colors.white),
            ),
            const SizedBox(height: 28),
            Text('Tudo pronto!',
                style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(
              'Sua conta está criada. Vamos começar a cuidar do seu bolso e do planeta.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  fontSize: 15, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 40),
            PrimaryButton(label: 'Começar', onPressed: onStart),
          ],
        ),
      ),
    );
  }
}
