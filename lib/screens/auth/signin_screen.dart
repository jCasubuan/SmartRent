import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/widgets/app_footer.dart';
import 'package:smart_rent/screens/auth/loading_screen.dart';
import 'package:smart_rent/controllers/login_controller.dart';
import 'package:smart_rent/controllers/google_sign_in_handler.dart';
import 'package:smart_rent/controllers/facebook_sign_in_handler.dart';
import 'package:smart_rent/screens/auth/forgot_password_screen.dart';
import 'package:smart_rent/screens/auth/signup_screen.dart';
import 'package:smart_rent/screens/home/client_home.dart';
import 'package:smart_rent/screens/home/admin_home.dart';
import 'package:smart_rent/core/widgets/field_label.dart';
import 'package:smart_rent/core/widgets/input_field.dart';
import 'package:smart_rent/core/widgets/social_icon_button.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _controller = LoginController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  // Rate limiting
  int _failedAttempts = 0;
  static const int _maxAttempts = 5;
  bool _isLockedOut = false;
  int _lockoutSecondsRemaining = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _startLockoutTimer() async {
    setState(() {
      _isLockedOut = true;
      _lockoutSecondsRemaining = 30;
    });

    while (_lockoutSecondsRemaining > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _lockoutSecondsRemaining--);
    }

    if (!mounted) return;
    setState(() {
      _isLockedOut = false;
      _failedAttempts = 0;
    });
  }

  Future<void> _handleLogin() async {
    if (_isLockedOut) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Show loading screen
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoadingScreen()),
    );

    try {
      final destination = await _controller.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      // Email verification check — only for clients
      if (destination == LoginDestination.client) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && !user.emailVerified) {
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          Navigator.of(context).pop(); // pop loading screen
          _showUnverifiedDialog(user.email ?? '');
          return;
        }
      }

      setState(() {
        _failedAttempts = 0;
        _isLockedOut = false;
      });

      final page = destination == LoginDestination.admin
          ? const AdminHome()
          : const ClientHome();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => page),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      Navigator.of(context).pop(); // pop loading screen

      setState(() => _failedAttempts++);

      if (_failedAttempts >= _maxAttempts) {
        _startLockoutTimer();
        _showError('Too many failed attempts. Please wait 30 seconds.');
      } else {
        final remaining = _maxAttempts - _failedAttempts;
        _showError(
          '${_controller.mapError(e)} $remaining attempt${remaining == 1 ? '' : 's'} remaining.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // pop loading screen
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showUnverifiedDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Email Not Verified',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Please verify your email address before signing in. '
          'Check your inbox at $email for the verification link.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await _controller.resendVerificationEmail();
                await FirebaseAuth.instance.signOut();
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                if (!mounted) return;
                _showError('Verification email resent. Check your inbox and spam folder.');
              } catch (_) {
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
              }
            },
            child: const Text(
              'Resend Email',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text(
              'OK',
              style: TextStyle(
                color: AppColors.textMid,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorHighlight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),

                      Center(
                        child: Image.asset(
                          'assets/icons/smart_rent_logo.jpg',
                          height: 80,
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Email
                      const FieldLabel(label: 'EMAIL ADDRESS'),
                      const SizedBox(height: 8),
                      InputField(
                        controller: _emailController,
                        hint: 'example@gmail.com',
                        prefixIcon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        validator: _controller.validateEmail,
                      ),

                      const SizedBox(height: 20),

                      // Password
                      const FieldLabel(label: 'PASSWORD'),
                      const SizedBox(height: 8),
                      InputField(
                        controller: _passwordController,
                        hint: '••••••••••',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textLight,
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        validator: _controller.validatePassword,
                      ),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Lockout message
                      if (_isLockedOut)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Too many attempts. Try again in $_lockoutSecondsRemaining seconds.',
                            style: const TextStyle(
                              color: AppColors.errorHighlight,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      // Sign In button
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: (_isLoading || _isLockedOut)
                              ? null
                              : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.defaultForeground,
                            elevation: 0,
                            disabledBackgroundColor:
                                AppColors.primary.withValues(alpha: 0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.defaultForeground),
                                  ),
                                )
                              : const Text(
                                  'SIGN IN',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Divider
                      Row(
                        children: const [
                          Expanded(child: Divider(color: AppColors.textDark)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'or',
                              style: TextStyle(
                                color: AppColors.textDark,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: AppColors.textDark)),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Social buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SocialIconButton(
                            icon: SvgPicture.asset(
                              'assets/icons/Google__G__logo.svg',
                              height: 20,
                              width: 20,
                            ),
                            onTap: () => handleGoogleSignIn(context),
                          ),
                          const SizedBox(width: 16),
                          SocialIconButton(
                            icon: Image.asset(
                              'assets/icons/Facebook_Logo_Primary.png',
                              height: 20,
                              width: 20,
                            ),
                            onTap: () => handleFacebookSignIn(context),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Sign Up redirect
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textDark,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SignupScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),
                    ],
                  ),
                ),
              ),
            ),
            if (MediaQuery.of(context).viewInsets.bottom == 0)
              const Center(child: AppFooter()),
          ],
        ),
      ),
    );
  }
}