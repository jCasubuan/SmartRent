import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_rent/repositories/auth_repository.dart';

class SignupController {
  final AuthRepository _authRepository;

  SignupController({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await _authRepository.signUp(name: name, email: email, password: password);
  }

  String mapError(FirebaseAuthException e) {
    return switch (e.code) {
      'email-already-in-use' => 'This email is already registered.',
      'invalid-email'        => 'Please enter a valid email address.',
      'weak-password'        => 'Password should be at least 6 characters.',
      _                      => 'Something went wrong. Please try again.',
    };
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your name';
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your email';
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter a password';
    if (value.length < 6) return 'Password should be at least 6 characters';
    return null;
  }

  String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.trim().isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

}