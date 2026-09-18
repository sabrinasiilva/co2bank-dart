import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/input_formatters.dart';
import '../../widgets/auth_field.dart';
import '../../widgets/primary_button.dart';

class Step1PersonalData extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController cpfController;
  final TextEditingController phoneController;
  final DateTime? birthDate;
  final Map<String, String?> errors;
  final VoidCallback onContinue;
  final void Function(DateTime) onBirthDateSelected;

  const Step1PersonalData({
    super.key,
    required this.nameController,
    required this.cpfController,
    required this.phoneController,
    required this.birthDate,
    required this.errors,
    required this.onContinue,
    required this.onBirthDateSelected,
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
            controller: nameController,
            label: 'Nome completo',
            hint: 'Seu nome e sobrenome',
            icon: Icons.person_outline,
            error: errors['name'],
          ),
          const SizedBox(height: 16),
          AuthField(
            controller: cpfController,
            label: 'CPF',
            hint: '000.000.000-00',
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [CpfInputFormatter()],
            error: errors['cpf'],
          ),
          const SizedBox(height: 16),
          AuthField(
            controller: phoneController,
            label: 'Celular',
            hint: '(00) 00000-0000',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            inputFormatters: [PhoneInputFormatter()],
            error: errors['phone'],
          ),
          const SizedBox(height: 16),
          _dateField(context),
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
        Text('Dados pessoais',
            style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text('Etapa 1 de 5',
            style: GoogleFonts.outfit(
                fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _dateField(BuildContext context) {
    final hasError = errors['birthDate'] != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Data de nascimento',
            style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime(2000),
              firstDate: DateTime(1930),
              lastDate:
                  DateTime.now().subtract(const Duration(days: 365 * 18)),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                    colorScheme:
                        const ColorScheme.light(primary: AppColors.darkGreen)),
                child: child!,
              ),
            );
            if (date != null) onBirthDateSelected(date);
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: hasError ? Colors.red : AppColors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 20,
                    color: hasError ? Colors.red : AppColors.textSecondary),
                const SizedBox(width: 12),
                Text(
                  birthDate == null
                      ? 'DD/MM/AAAA'
                      : '${birthDate!.day.toString().padLeft(2, '0')}/${birthDate!.month.toString().padLeft(2, '0')}/${birthDate!.year}',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: birthDate == null
                        ? (hasError ? Colors.red : AppColors.textSecondary)
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(errors['birthDate']!,
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.red)),
          ),
      ],
    );
  }
}
