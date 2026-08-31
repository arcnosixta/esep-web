import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/primary_button.dart';
import '../navigation/app_navigator.dart';
import '../services/supabase_service.dart';
import 'login_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _agreed = false;
  bool _loading = false;
  bool _obscure = true;
  bool _isOrg = false;
  final _orgNameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _orgNameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showError(context, 'Заполните имя, email и пароль');
      return;
    }

    if (_isOrg && _orgNameController.text.trim().isEmpty) {
      _showError(context, 'Укажите наименование организации');
      return;
    }

    if (!_agreed) {
      _showError(context, 'Примите условия использования');
      return;
    }

    setState(() => _loading = true);

    try {
      await SupabaseService.signUp(
        email: email,
        password: password,
        fullName: name,
        phone: phone,
        clientType: _isOrg ? 'org' : 'person',
        orgName: _isOrg ? _orgNameController.text.trim() : null,
      );
      if (mounted) {
        final c = AppColors.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Аккаунт создан! Проверьте email для подтверждения',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: c.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        _showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(BuildContext context, String message) {
    final c = AppColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: c.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(backgroundColor: c.background, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Text(
                  'Регистрация',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                    letterSpacing: -1.5,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: Text(
                  'Создайте аккаунт для оценки недвижимости',
                  style: TextStyle(fontSize: 15, color: c.textSecondary),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.border, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label('ИМЯ'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      style: TextStyle(color: c.textPrimary, fontSize: 15),
                      decoration: const InputDecoration(hintText: 'Введите имя'),
                    ),
                    const SizedBox(height: 20),
                    const _Label('ТЕЛЕФОН'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: c.textPrimary, fontSize: 15),
                      decoration: const InputDecoration(hintText: '+7 (___) ___-__-__'),
                    ),
                    const SizedBox(height: 20),
                    const _Label('EMAIL'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: c.textPrimary, fontSize: 15),
                      decoration: const InputDecoration(hintText: 'example@mail.com'),
                    ),
                    const SizedBox(height: 20),
                    const _Label('ПАРОЛЬ'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      style: TextStyle(color: c.textPrimary, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Минимум 8 символов',
                        suffixIcon: GestureDetector(
                          onTap: () => setState(() => _obscure = !_obscure),
                          child: Icon(
                            _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                            color: c.textHint,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _Label('ТИП АККАУНТА'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _typeChip('Физлицо', !_isOrg, () {
                          setState(() {
                            _isOrg = false;
                          });
                        }),
                        const SizedBox(width: 12),
                        _typeChip('Юрлицо', _isOrg, () {
                          setState(() {
                            _isOrg = true;
                          });
                        }),
                      ],
                    ),
                    if (_isOrg) ...[
                      const SizedBox(height: 20),
                      const _Label('НАИМЕНОВАНИЕ ОРГАНИЗАЦИИ'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _orgNameController,
                        style: TextStyle(color: c.textPrimary, fontSize: 15),
                        decoration: const InputDecoration(hintText: 'ТОО «Название»'),
                      ),
                    ],
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => setState(() => _agreed = !_agreed),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: _agreed ? c.accent : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _agreed ? c.accent : c.inputBorder,
                                width: 1.5,
                              ),
                            ),
                            child: _agreed ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                text: 'Я согласен с ',
                                style: TextStyle(fontSize: 13, color: c.textSecondary),
                                children: [
                                  TextSpan(
                                    text: 'условиями использования',
                                    style: TextStyle(color: c.accent, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    PrimaryButton(
                      label: _loading ? 'Регистрация...' : 'Зарегистрироваться',
                      onPressed: _loading ? null : _register,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: GestureDetector(
                        onTap: () => AppNavigator.push(context, const LoginScreen()),
                        child: RichText(
                          text: TextSpan(
                            text: 'Уже есть аккаунт? ',
                            style: TextStyle(fontSize: 14, color: c.textSecondary),
                            children: [
                              TextSpan(
                                text: 'Войти',
                                style: TextStyle(color: c.accent, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Text(
      text,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.textSecondary, letterSpacing: 0.8),
    );
  }
}

Widget _typeChip(String label, bool selected, VoidCallback onTap) {
  final c = AppColors.of(context);
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? c.accent : c.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: selected ? c.accent : c.border),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: selected ? Colors.white : c.textSecondary),
      ),
    ),
  );
}
