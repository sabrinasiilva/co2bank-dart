import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/app_colors.dart';
import '../../core/input_formatters.dart';
import '../../data/auth_service.dart';
import '../widgets/auth_field.dart';
import '../widgets/primary_button.dart';

enum _Step { email, biometric, identity, newPassword, done }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _localAuth = LocalAuthentication();
  final _authService = AuthService();

  _Step _step = _Step.email;
  bool _loading = false;
  String? _error;

  final _emailCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  DateTime? _birthDate;
  String? _resetToken;
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _cpfCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Step transitions ──────────────────────────────────────────────

  Future<void> _proceedFromEmail() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Informe seu e-mail');
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(_emailCtrl.text.trim())) {
      setState(() => _error = 'E-mail inválido');
      return;
    }
    setState(() { _error = null; _step = _Step.biometric; });
    await _triggerBiometric();
  }

  Future<void> _triggerBiometric() async {
    setState(() { _loading = true; _error = null; });
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final deviceSupported = await _localAuth.isDeviceSupported();

      if (!canCheck && !deviceSupported) {
        setState(() { _loading = false; _step = _Step.identity; });
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Confirme sua identidade para redefinir a senha',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        setState(() { _loading = false; _step = _Step.identity; });
      } else {
        setState(() { _loading = false; _error = 'Autenticação não confirmada. Tente novamente.'; });
      }
    } on PlatformException catch (e) {
      if (e.code == 'NotEnrolled' || e.code == 'NotAvailable' || e.code == 'LockedOut') {
        setState(() { _loading = false; _step = _Step.identity; });
      } else {
        setState(() { _loading = false; _error = 'Erro na autenticação biométrica.'; });
      }
    }
  }

  Future<void> _verifyIdentity() async {
    final cpf = _cpfCtrl.text.trim();
    if (cpf.isEmpty || _birthDate == null) {
      setState(() => _error = 'Preencha todos os campos');
      return;
    }

    setState(() { _loading = true; _error = null; });

    final birthDate =
        '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}';

    final result = await _authService.verifyForgotPassword(
      email: _emailCtrl.text.trim(),
      cpf: cpf,
      birthDate: birthDate,
    );

    setState(() => _loading = false);

    if (result.success) {
      setState(() { _resetToken = result.resetToken; _step = _Step.newPassword; });
    } else {
      setState(() => _error = result.error ?? 'Dados inválidos');
    }
  }

  Future<void> _submitNewPassword() async {
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (pass.length < 6) {
      setState(() => _error = 'A senha deve ter pelo menos 6 caracteres');
      return;
    }
    if (pass != confirm) {
      setState(() => _error = 'As senhas não coincidem');
      return;
    }

    setState(() { _loading = true; _error = null; });

    final result = await _authService.resetPassword(
      resetToken: _resetToken!,
      newPassword: pass,
    );

    setState(() => _loading = false);

    if (result.success) {
      setState(() => _step = _Step.done);
    } else {
      setState(() => _error = result.error ?? 'Erro ao redefinir senha');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────

  int get _dotIndex {
    switch (_step) {
      case _Step.email: return 0;
      case _Step.biometric:
      case _Step.identity: return 1;
      case _Step.newPassword: return 2;
      case _Step.done: return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Stack(
        children: [
          // back button
          Positioned(
            top: top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // header
          Positioned(
            top: top + 56,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.primaryMuted.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.primaryMuted.withOpacity(0.4), width: 1.5),
                  ),
                  child: const Icon(Icons.shield_rounded,
                      size: 34, color: AppColors.primaryMuted),
                ),
                const SizedBox(height: 14),
                Text(
                  'Redefinir senha',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Verificação em 3 etapas',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 16),
                _StepDots(activeIndex: _dotIndex),
              ],
            ),
          ),

          // bottom card
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: size.height * 0.60,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: _buildStepContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case _Step.email:
        return _StepEmail(
          key: const ValueKey('email'),
          ctrl: _emailCtrl,
          error: _error,
          loading: _loading,
          onNext: _proceedFromEmail,
        );
      case _Step.biometric:
        return _StepBiometric(
          key: const ValueKey('biometric'),
          loading: _loading,
          error: _error,
          onRetry: _triggerBiometric,
        );
      case _Step.identity:
        return _StepIdentity(
          key: const ValueKey('identity'),
          cpfCtrl: _cpfCtrl,
          birthDate: _birthDate,
          onBirthDateSelected: (d) => setState(() { _birthDate = d; _error = null; }),
          error: _error,
          loading: _loading,
          onNext: _verifyIdentity,
        );
      case _Step.newPassword:
        return _StepNewPassword(
          key: const ValueKey('newPassword'),
          passCtrl: _passCtrl,
          confirmCtrl: _confirmCtrl,
          obscurePass: _obscurePass,
          obscureConfirm: _obscureConfirm,
          onTogglePass: () => setState(() => _obscurePass = !_obscurePass),
          onToggleConfirm: () => setState(() => _obscureConfirm = !_obscureConfirm),
          error: _error,
          loading: _loading,
          onNext: _submitNewPassword,
        );
      case _Step.done:
        return _StepDone(
          key: const ValueKey('done'),
          onBack: () => Navigator.pop(context),
        );
    }
  }
}

// ── Step dots ────────────────────────────────────────────────────────

class _StepDots extends StatelessWidget {
  final int activeIndex;

  const _StepDots({required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final isActive = i == activeIndex || i < activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == activeIndex ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryMuted : Colors.white24,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ── Step 1: Email ────────────────────────────────────────────────────

class _StepEmail extends StatelessWidget {
  final TextEditingController ctrl;
  final String? error;
  final bool loading;
  final VoidCallback onNext;

  const _StepEmail({
    super.key,
    required this.ctrl,
    required this.error,
    required this.loading,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Informe seu e-mail',
              style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text('Vamos verificar sua identidade antes de continuar.',
              style: GoogleFonts.outfit(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 28),
          AuthField(
            controller: ctrl,
            label: 'E-mail cadastrado',
            hint: 'seu@email.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            _ErrorText(error!),
          ],
          const SizedBox(height: 28),
          loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : PrimaryButton(label: 'Continuar', onPressed: onNext),
          const SizedBox(height: 16),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.fingerprint_rounded,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text('Confirmação biométrica na próxima etapa',
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 2: Biometric ────────────────────────────────────────────────

class _StepBiometric extends StatelessWidget {
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  const _StepBiometric({
    super.key,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: loading
                  ? AppColors.primaryMuted.withOpacity(0.15)
                  : (error != null
                      ? Colors.red.withOpacity(0.1)
                      : AppColors.primaryMuted.withOpacity(0.15)),
              shape: BoxShape.circle,
              border: Border.all(
                color: loading
                    ? AppColors.primaryMuted
                    : (error != null ? Colors.red : AppColors.primaryMuted),
                width: 2,
              ),
            ),
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: AppColors.primaryMuted),
                  )
                : Icon(
                    error != null
                        ? Icons.fingerprint_rounded
                        : Icons.check_rounded,
                    size: 40,
                    color: error != null ? Colors.red : AppColors.primaryMuted,
                  ),
          ),
          const SizedBox(height: 24),
          Text(
            loading ? 'Aguarde...' : 'Verificação biométrica',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loading
                ? 'Confirme com sua digital ou reconhecimento facial'
                : (error ?? ''),
            style: GoogleFonts.outfit(
                fontSize: 13,
                color: error != null ? Colors.red : AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (error != null) ...[
            const SizedBox(height: 24),
            PrimaryButton(label: 'Tentar novamente', onPressed: onRetry),
          ],
        ],
      ),
    );
  }
}

// ── Step 3: Identity ─────────────────────────────────────────────────

class _StepIdentity extends StatelessWidget {
  final TextEditingController cpfCtrl;
  final DateTime? birthDate;
  final void Function(DateTime) onBirthDateSelected;
  final String? error;
  final bool loading;
  final VoidCallback onNext;

  const _StepIdentity({
    super.key,
    required this.cpfCtrl,
    required this.birthDate,
    required this.onBirthDateSelected,
    required this.error,
    required this.loading,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final birthLabel = birthDate == null
        ? 'DD/MM/AAAA'
        : '${birthDate!.day.toString().padLeft(2, '0')}/'
            '${birthDate!.month.toString().padLeft(2, '0')}/'
            '${birthDate!.year}';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Verifique sua identidade',
              style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text('Confirme os dados cadastrados na sua conta.',
              style: GoogleFonts.outfit(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 28),
          AuthField(
            controller: cpfCtrl,
            label: 'CPF',
            hint: '000.000.000-00',
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [CpfInputFormatter()],
          ),
          const SizedBox(height: 16),
          // Date picker
          Column(
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
                    initialDate: DateTime(1990),
                    firstDate: DateTime(1930),
                    lastDate: DateTime.now()
                        .subtract(const Duration(days: 365 * 18)),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.light(
                            primary: AppColors.dark),
                      ),
                      child: child!,
                    ),
                  );
                  if (date != null) onBirthDateSelected(date);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 20, color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Text(birthLabel,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: birthDate == null
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            _ErrorText(error!),
          ],
          const SizedBox(height: 28),
          loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : PrimaryButton(label: 'Verificar identidade', onPressed: onNext),
        ],
      ),
    );
  }
}

// ── Step 4: New password ─────────────────────────────────────────────

class _StepNewPassword extends StatelessWidget {
  final TextEditingController passCtrl;
  final TextEditingController confirmCtrl;
  final bool obscurePass;
  final bool obscureConfirm;
  final VoidCallback onTogglePass;
  final VoidCallback onToggleConfirm;
  final String? error;
  final bool loading;
  final VoidCallback onNext;

  const _StepNewPassword({
    super.key,
    required this.passCtrl,
    required this.confirmCtrl,
    required this.obscurePass,
    required this.obscureConfirm,
    required this.onTogglePass,
    required this.onToggleConfirm,
    required this.error,
    required this.loading,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Crie uma nova senha',
              style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text('Escolha uma senha forte com pelo menos 6 caracteres.',
              style: GoogleFonts.outfit(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 28),
          AuthField(
            controller: passCtrl,
            label: 'Nova senha',
            hint: '••••••••',
            icon: Icons.lock_outline,
            obscure: obscurePass,
            suffix: IconButton(
              icon: Icon(
                obscurePass
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: onTogglePass,
            ),
          ),
          const SizedBox(height: 16),
          AuthField(
            controller: confirmCtrl,
            label: 'Confirmar senha',
            hint: '••••••••',
            icon: Icons.lock_outline,
            obscure: obscureConfirm,
            suffix: IconButton(
              icon: Icon(
                obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: onToggleConfirm,
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            _ErrorText(error!),
          ],
          const SizedBox(height: 28),
          loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : PrimaryButton(label: 'Redefinir senha', onPressed: onNext),
        ],
      ),
    );
  }
}

// ── Step 5: Done ─────────────────────────────────────────────────────

class _StepDone extends StatelessWidget {
  final VoidCallback onBack;

  const _StepDone({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                size: 44, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text('Senha redefinida!',
              style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(
            'Sua senha foi alterada com sucesso.\nEntre com a nova senha.',
            style: GoogleFonts.outfit(
                fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          PrimaryButton(label: 'Ir para o login', onPressed: onBack),
        ],
      ),
    );
  }
}

// ── Shared ────────────────────────────────────────────────────────────

class _ErrorText extends StatelessWidget {
  final String message;
  const _ErrorText(this.message);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.error_outline_rounded, size: 14, color: Colors.red),
        const SizedBox(width: 6),
        Expanded(
          child: Text(message,
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.red)),
        ),
      ],
    );
  }
}
