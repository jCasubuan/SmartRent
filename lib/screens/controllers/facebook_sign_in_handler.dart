import 'package:flutter/material.dart';
import 'package:smart_rent/screens/auth/loading_screen.dart';
import 'package:smart_rent/screens/controllers/login_controller.dart';
import 'package:smart_rent/screens/home/client_home.dart';

Future<void> handleFacebookSignIn(BuildContext context) async {
  final controller = LoginController();

  // Show loading screen
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const LoadingScreen()),
  );

  try {
    await controller.loginWithFacebook();
    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ClientHome()),
      (route) => false,
    );
  } on Exception catch (e) {
    if (!context.mounted) return;

    // Pop loading screen
    Navigator.of(context).pop();

    final msg = e.toString();
    if (msg.contains('cancelled') || msg.contains('cancel')) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Facebook sign-in failed. Please try again.'),
      ),
    );
  }
}