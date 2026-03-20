import 'package:flutter/material.dart';

class SplashAnimations {
  final AnimationController controller;
  final Animation<double> fade;
  final Animation<double> scale;

  SplashAnimations._({
    required this.controller,
    required this.fade,
    required this.scale,
  });

  factory SplashAnimations.create(TickerProvider vsync) {
    final controller = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 1500),
    );

    final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    final scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    return SplashAnimations._(controller: controller, fade: fade, scale: scale);
  }

  void forward() => controller.forward();

  void dispose() => controller.dispose();
}