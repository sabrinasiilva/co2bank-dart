import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/validators.dart';
import '../../data/auth_service.dart';
import '../shell.dart';
import '../widgets/step_indicator.dart';
import 'steps/step1_personal_data.dart';
import 'steps/step2_access.dart';
import 'steps/step3_facial.dart';
import 'steps/step3_open_finance.dart';
import 'steps/step4_eco_limit.dart';
import 'steps/step5_done.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 6;

  final Map<String, String?> _errors = {};

  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _birthDate;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  String? _facePhotoBase64;

  final Set<String> _connectedBanks = {};
  double _co2Limit = 200;
  bool _loading = false;
  String? _registerError;

  final _authService = AuthService();

  double get _passwordStrength =>
      Validators.passwordStrength(_passwordController.text);

  Color get _strengthColor {
    if (_passwordStrength < 0.34) return Colors.red;
    if (_passwordStrength < 0.67) return Colors.orange;
    return const Color(0xFF52B788);
  }

  String get _strengthLabel {
    if (_passwordStrength < 0.34) return 'Fraca';
    if (_passwordStrength < 0.67) return 'Média';
    return 'Forte';
  }

  bool _validateStep1() {
    final errs = <String, String?>{};
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      errs['name'] = 'Informe o nome completo';
    } else if (name.split(' ').length < 2) {
      errs['name'] = 'Informe o nome e o sobrenome';
    } else if (!RegExp(r'^[a-zA-ZÀ-ÿ\s]+$').hasMatch(name)) {
      errs['name'] = 'Nome deve conter apenas letras';
    }
    if (!Validators.isValidCpf(_cpfController.text)) {
      errs['cpf'] = 'CPF inválido';
    }
    if (!Validators.isValidPhone(_phoneController.text)) {
      errs['phone'] = 'Celular inválido';
    }
    if (_birthDate == null) errs['birthDate'] = 'Informe a data de nascimento';
    setState(() {
      _errors
        ..remove('name')
        ..remove('cpf')
        ..remove('phone')
        ..remove('birthDate')
        ..addAll(errs);
    });
    return errs.isEmpty;
  }

  bool _validateStep2() {
    final errs = <String, String?>{};
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      errs['email'] = 'Informe o e-mail';
    } else if (!Validators.isValidEmail(email)) {
      errs['email'] = 'E-mail inválido';
    }
    final password = _passwordController.text;
    if (password.isEmpty) {
      errs['password'] = 'Informe a senha';
    } else if (password.length < 8) {
      errs['password'] = 'A senha deve ter pelo menos 8 caracteres';
    } else if (!password.contains(RegExp(r'[A-Z]'))) {
      errs['password'] = 'A senha deve ter pelo menos uma letra maiúscula';
    } else if (!password.contains(RegExp(r'[0-9!@#$%^&*]'))) {
      errs['password'] = 'Use pelo menos um número ou caractere especial';
    }
    if (_confirmController.text.isEmpty) {
      errs['confirm'] = 'Confirme a senha';
    } else if (_confirmController.text != password) {
      errs['confirm'] = 'As senhas não coincidem';
    }
    setState(() {
      _errors
        ..remove('email')
        ..remove('password')
        ..remove('confirm')
        ..addAll(errs);
    });
    return errs.isEmpty;
  }

  void _tryAdvance() {
    bool valid = true;
    if (_currentStep == 0) valid = _validateStep1();
    if (_currentStep == 1) valid = _validateStep2();
    if (!valid) return;

    if (_currentStep == 4) {
      _doRegister();
      return;
    }

    _pageController.nextPage(
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    setState(() => _currentStep++);
  }

  Future<void> _doRegister() async {
    setState(() {
      _loading = true;
      _registerError = null;
    });

    final birthDate = _birthDate!;
    final result = await _authService.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      cpf: _cpfController.text,
      phone: _phoneController.text,
      birthDate:
          '${birthDate.year}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}',
      password: _passwordController.text,
      co2LimitKg: _co2Limit,
      facePhoto: _facePhotoBase64,
    );

    setState(() => _loading = false);

    if (result.success) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep++);
    } else {
      setState(() => _registerError = result.error);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _cpfController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.darkGreen,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [AppColors.darkGreen, Color(0xFF2D6A4F)],
              ),
            ),
          ),
          Positioned(
            top: topPadding + 12,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 20),
                    onPressed: _previousStep,
                  ),
                  const Spacer(),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.eco_rounded,
                        size: 24, color: AppColors.mintGreen),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: size.height * 0.78,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                    child: StepIndicator(
                        currentStep: _currentStep, totalSteps: _totalSteps),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        Step1PersonalData(
                          nameController: _nameController,
                          cpfController: _cpfController,
                          phoneController: _phoneController,
                          birthDate: _birthDate,
                          errors: _errors,
                          onContinue: _tryAdvance,
                          onBirthDateSelected: (date) => setState(() {
                            _birthDate = date;
                            _errors.remove('birthDate');
                          }),
                        ),
                        Step2Access(
                          emailController: _emailController,
                          passwordController: _passwordController,
                          confirmController: _confirmController,
                          obscurePassword: _obscurePassword,
                          obscureConfirm: _obscureConfirm,
                          passwordStrength: _passwordStrength,
                          strengthColor: _strengthColor,
                          strengthLabel: _strengthLabel,
                          errors: _errors,
                          onContinue: _tryAdvance,
                          onTogglePassword: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          onToggleConfirm: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                          onPasswordChanged: (_) => setState(() {}),
                          onConfirmChanged: (value) {
                            if (_errors['confirm'] != null) {
                              setState(() {
                                if (value == _passwordController.text) {
                                  _errors.remove('confirm');
                                } else {
                                  _errors['confirm'] = 'As senhas não coincidem';
                                }
                              });
                            }
                          },
                        ),
                        Step3Facial(
                          capturedPhotoBase64: _facePhotoBase64,
                          onPhotoCaptured: (b64) =>
                              setState(() => _facePhotoBase64 = b64),
                          onContinue: _tryAdvance,
                        ),
                        Step3OpenFinance(
                          connectedBanks: _connectedBanks,
                          onBankToggled: (bank) => setState(() {
                            _connectedBanks.contains(bank)
                                ? _connectedBanks.remove(bank)
                                : _connectedBanks.add(bank);
                          }),
                          onContinue: _tryAdvance,
                        ),
                        Step4EcoLimit(
                          co2Limit: _co2Limit,
                          onLimitChanged: (v) => setState(() => _co2Limit = v),
                          onContinue: _tryAdvance,
                          loading: _loading,
                          error: _registerError,
                        ),
                        Step5Done(
                          onStart: () => Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const Shell()),
                            (_) => false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
