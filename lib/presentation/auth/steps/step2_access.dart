import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/app_colors.dart';
import '../../widgets/auth_field.dart';
import '../../widgets/primary_button.dart';

class Step2Access extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool obscurePassword;
  final bool obscureConfirm;
  final double passwordStrength;
  final Color strengthColor;
  final String strengthLabel;
  final Map<String, String?> errors;
  final VoidCallback onContinue;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final void Function(String) onPasswordChanged;
  final void Function(String) onConfirmChanged;

  const Step2Access({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.confirmController,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.passwordStrength,
    required this.strengthColor,
    required this.strengthLabel,
    required this.errors,
    required this.onContinue,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onPasswordChanged,
    required this.onConfirmChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(),
          const SizedBox(height: 28),
          AuthField(
            controller: emailController,
            label: 'E-mail',
            hint: 'seu@email.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            error: errors['email'],
          ),
          const SizedBox(height: 16),
          AuthField(
            controller: passwordController,
            label: 'Senha',
            hint: '••••••••',
            icon: Icons.lock_outline,
            obscure: obscurePassword,
            error: errors['password'],
            onChanged: onPasswordChanged,
            suffix: _eyeButton(obscurePassword, onTogglePassword),
          ),
          if (passwordController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: passwordStrength,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation(strengthColor),
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(strengthLabel,
                    style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: strengthColor,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
          const SizedBox(height: 16),
          AuthField(
            controller: confirmController,
            label: 'Confirmar senha',
            hint: '••••••••',
            icon: Icons.lock_outline,
            obscure: obscureConfirm,
            error: errors['confirm'],
            onChanged: onConfirmChanged,
            suffix: _eyeButton(obscureConfirm, onToggleConfirm),
          ),
          const SizedBox(height: 32),
          PrimaryButton(label: 'Continuar', onPressed: onContinue),
        ],
      ),
    );
  }

  Widget _title() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Criar acesso',
            style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text('Etapa 2 de 5',
            style: GoogleFonts.outfit(
                fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _eyeButton(bool obscure, VoidCallback onTap) {
    return IconButton(
      icon: Icon(
          obscure
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: AppColors.textSecondary,
          size: 20),
      onPressed: onTap,
    );
  }
}
