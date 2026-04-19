import 'package:flutter/material.dart';
import 'package:smart_rent/screens/controllers/login_controller.dart';
import 'package:smart_rent/screens/home/client_home.dart';

Future<void> handleFacebookSignIn(BuildContext context) async {
  final controller = LoginController();

  try {
    await controller.loginWithFacebook();
    if(!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context, 
      MaterialPageRoute(builder: (_) => const ClientHome()), 
      (route) => false,
    );
  } on Exception catch (e) {
    if (!context.mounted) return;

    final msg = e.toString();
    if (msg.contains('cancelled') || msg.contains('cancel')) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Facebook sign-in failed. Please try again.'),
      )
    );
  }
}