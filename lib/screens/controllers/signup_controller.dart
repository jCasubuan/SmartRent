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
      'weak-password'        => 'Password must be at least 12 characters and include uppercase, number, and special character.',
      _                      => 'Something went wrong. Please try again.',
    };
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your name';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your email';
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a password';
    if (value.length < 12) return 'Password must be at least 12 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Password must include at least one uppercase letter';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Password must include at least one number';
    if (!RegExp(r'[!@#\$&*~%^()_\-+=<>?/]').hasMatch(value)) return 'Password must include at least one special character';
    return null;
  }

  String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

}