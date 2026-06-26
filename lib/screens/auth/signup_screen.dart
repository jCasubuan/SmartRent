import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/utils/responsive_helper.dart';
import 'package:smart_rent/core/widgets/app_footer.dart';
import 'package:smart_rent/controllers/signup_controller.dart';
import 'package:smart_rent/screens/auth/signin_screen.dart';
import 'package:smart_rent/core/widgets/field_label.dart';
import 'package:smart_rent/core/widgets/input_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _controller = SignupController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _controller.signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      // Show verification email dialog before navigating
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Verify Your Email',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'A verification link has been sent to ${_emailController.text.trim()}. '
            'Please check your inbox and verify your email before signing in. \n\n'
            "In case you can't find it, check your spam or junk folder",
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );

      if (!mounted) return;

      // After dialog is dismissed, go to login screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SigninScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(_controller.mapError(e));
    } catch (e) {
      if (!mounted) return;
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
    final r = Responsive(context);
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
        title: Text(
          'Create Account',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: r.sp(18),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding:
                    EdgeInsets.symmetric(horizontal: r.s(24), vertical: r.s(16)),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: r.s(8)),

                      // Form card
                      Container(
                        padding: EdgeInsets.all(r.s(24)),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.background.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name
                            const FieldLabel(label: 'Name'),
                            SizedBox(height: r.s(8)),
                            InputField(
                              controller: _nameController,
                              hint: 'Full Name',
                              prefixIcon: Icons.person_outline,
                              maxLength: 50,
                              textCapitalization: TextCapitalization.words,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r"[a-zA-ZÀ-ÿ\s\-']")),
                              ],
                              validator: _controller.validateName,
                            ),

                            SizedBox(height: r.s(20)),

                            // Email
                            const FieldLabel(label: 'Email'),
                            SizedBox(height: r.s(8)),
                            InputField(
                              controller: _emailController,
                              hint: 'example@gmail.com',
                              prefixIcon: Icons.mail_outline,
                              keyboardType: TextInputType.emailAddress,
                              maxLength: 100,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-Z0-9@._\-+]')),
                              ],
                              validator: _controller.validateEmail,
                            ),

                            SizedBox(height: r.s(20)),

                            // Password
                            const FieldLabel(label: 'Password'),
                            SizedBox(height: r.s(8)),
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
                                  size: r.s(20),
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                              validator: _controller.validatePassword,
                            ),

                            SizedBox(height: r.s(20)),

                            // Confirm Password
                            const FieldLabel(label: 'Confirm Password'),
                            SizedBox(height: r.s(8)),
                            InputField(
                              controller: _confirmPasswordController,
                              hint: '••••••••••',
                              prefixIcon: Icons.lock_outline,
                              obscureText: _obscureConfirmPassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.textLight,
                                  size: r.s(20),
                                ),
                                onPressed: () => setState(() =>
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword),
                              ),
                              validator: (val) =>
                                  _controller.validateConfirmPassword(
                                      val, _passwordController.text),
                            ),

                            SizedBox(height: r.s(28)),

                            // Create Account button
                            SizedBox(
                              width: double.infinity,
                              height: r.s(52),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSignup,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.defaultForeground,
                                  elevation: 0,
                                  disabledBackgroundColor:
                                      AppColors.primary.withValues(alpha: 0.6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        width: r.s(22),
                                        height: r.s(22),
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  AppColors.defaultForeground),
                                        ),
                                      )
                                    : Text(
                                        'Create Account',
                                        style: TextStyle(
                                          fontSize: r.sp(15),
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: r.s(24)),

                      // Terms and Privacy
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text: 'By clicking continue, you agree to our ',
                          style: TextStyle(
                              fontSize: r.sp(11), color: AppColors.textLight),
                          children: [
                            TextSpan(
                              text: 'Terms of Service',
                              style: TextStyle(
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
                                fontSize: r.sp(11),
                              ),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
                                fontSize: r.sp(11),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: r.s(20)),

                      // Already have an account
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: TextStyle(
                                fontSize: r.sp(13), color: AppColors.textLight),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SigninScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: r.sp(13),
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: r.s(16)),
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