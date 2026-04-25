import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_rent/repositories/auth_repository.dart';

export 'package:smart_rent/repositories/auth_repository.dart' show UserRole;

enum LoginDestination { admin, client }

class LoginController {
  final AuthRepository _repository;

  LoginController({AuthRepository? repository})
      : _repository = repository ?? AuthRepository();

  Future<LoginDestination> login({
    required String email,
    required String password,
  }) async {
    final role = await _repository.signIn(email: email, password: password);
    return role == UserRole.admin
        ? LoginDestination.admin
        : LoginDestination.client;
  }

  // Google Sign-In — always returns client
  Future<LoginDestination> loginWithGoogle() async {
    await _repository.signInWithGoogle();
    return LoginDestination.client;
  }

  // Facebook Sign-In — always returns client
  Future<LoginDestination> loginWithFacebook() async {
    await _repository.signInWithFacebook();
    return LoginDestination.client;
  }

  // Resends verification email to the currently signed in user
  Future<void> resendVerificationEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Forgot password
  Future<void> sendPasswordReset(String email) async {
  await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
}

String mapForgotPasswordError(FirebaseAuthException e) {
  return switch (e.code) {
    'user-not-found'  => 'No account found with this email.',
    'invalid-email'   => 'Please enter a valid email address.',
    _                 => 'Something went wrong. Please try again.',
  };
}

  String mapError(FirebaseAuthException e) {
    return switch (e.code) {
      'user-not-found'     => 'No account found with this email.',
      'wrong-password'     => 'Incorrect password. Please try again.',
      'invalid-email'      => 'Please enter a valid email address.',
      'user-disabled'      => 'This account has been disabled.',
      'invalid-credential' => 'Invalid email or password.',
      _                    => 'Something went wrong. Please try again.',
    };
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your email';
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password';
    return null;
  }
}