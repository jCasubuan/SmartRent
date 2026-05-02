import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/screens/auth/landing_page.dart';
import 'package:smart_rent/screens/home/client_home.dart';
import 'package:smart_rent/screens/home/admin_home.dart';
import 'splash_animations.dart';
import 'package:smart_rent/controllers/splash_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final SplashAnimations _animations;
  late final SplashController _controller;

  @override
  void initState() {
    super.initState();
    _animations = SplashAnimations.create(this);
    _controller = SplashController();

    _animations.forward();
    _resolveAndNavigate();
  }

  Future<void> _resolveAndNavigate() async {
    final destination = await _controller.resolveDestination();
    if (!mounted) return;
    _navigateTo(_destinationWidget(destination));
  }

  Widget _destinationWidget(SplashDestination destination) {
    return switch (destination) {
      SplashDestination.adminHome   => const AdminHome(),
      SplashDestination.clientHome  => const ClientHome(),
      SplashDestination.landing => const LandingPage(),
    };
  }

  void _navigateTo(Widget page) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _animations.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _animations.controller,
          builder: (context, child) => FadeTransition(
            opacity: _animations.fade,
            child: ScaleTransition(
              scale: _animations.scale,
              child: child,
            ),
          ),
          child: const _SplashContent(),
        ),
      ),
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/icons/smart_rent_logo.jpg',
          width: 260,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 48),
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}
