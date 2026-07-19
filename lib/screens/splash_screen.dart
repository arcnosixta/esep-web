import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/primary_button.dart';
import '../navigation/app_navigator.dart';
import 'registration_screen.dart';
import 'app_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _buttonsController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _buttonsOpacity;
  late Animation<Offset> _buttonsSlide;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _buttonsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );
    _buttonsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonsController, curve: Curves.easeOut),
    );
    _buttonsSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _buttonsController, curve: Curves.easeOutCubic),
    );

    _logoController.forward();
    Future.delayed(
        const Duration(milliseconds: 400), () => _textController.forward());
    Future.delayed(
        const Duration(milliseconds: 700), () => _buttonsController.forward());
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _buttonsController.dispose();
    super.dispose();
  }

  void _enterApp() {
    AppNavigator.pushReplacement(context, const AppShell());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Gradient bg
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF14142A),
                  AppColors.background,
                ],
              ),
            ),
          ),
          // Glow
          Positioned(
            top: MediaQuery.of(context).size.height * 0.12,
            left: MediaQuery.of(context).size.width * 0.5 - 120,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.2),
                    AppColors.accent.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  // Logo
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (_, _) => Transform.scale(
                      scale: _logoScale.value,
                      child: Opacity(
                        opacity: _logoOpacity.value,
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            gradient: AppColors.accentGradient,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentGlow,
                                blurRadius: 40,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'E',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Title
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textOpacity,
                      child: Column(
                        children: [
                          const Text(
                            'ESEP',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: 6,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Оценка недвижимости\nза несколько минут',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 4),
                  // Buttons
                  SlideTransition(
                    position: _buttonsSlide,
                    child: FadeTransition(
                      opacity: _buttonsOpacity,
                      child: Column(
                        children: [
                          PrimaryButton(
                            label: 'Войти',
                            onPressed: _enterApp,
                          ),
                          const SizedBox(height: 14),
                          PrimaryButton(
                            label: 'Зарегистрироваться',
                            outlined: true,
                            onPressed: () => AppNavigator.push(
                              context,
                              const RegistrationScreen(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _enterApp,
                            child: const Text(
                              'Пропустить',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textHint,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
