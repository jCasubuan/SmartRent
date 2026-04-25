import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/screens/controllers/login_controller.dart';
import 'widgets/field_label.dart';
import 'widgets/input_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _controller = LoginController();

  bool _isLoading = false;
  bool _emailSent = false;

  // Rate limiting
  int _attemptCount = 0;
  static const int _maxAttempts = 3;
  bool get _isLimitReached => _attemptCount >= _maxAttempts;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isLimitReached) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _controller.sendPasswordReset(_emailController.text.trim());
      if (!mounted) return;
      setState(() {
        _emailSent = true;
        _attemptCount++;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _attemptCount++);
      _showError(_controller.mapForgotPasswordError(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _attemptCount++);
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: _emailSent && !_isLimitReached
              ? _buildSuccessState()
              : _isLimitReached
                  ? _buildLimitReachedState()
                  : _buildInputState(),
        ),
      ),
    );
  }

  Widget _buildInputState() {
    final remaining = _maxAttempts - _attemptCount;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find your account',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Enter your email address.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMid,
            ),
          ),

          const SizedBox(height: 24),

          const FieldLabel(label: 'EMAIL ADDRESS'),
          const SizedBox(height: 8),
          InputField(
            controller: _emailController,
            hint: 'example@gmail.com',
            prefixIcon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            validator: _controller.validateEmail,
          ),

          const SizedBox(height: 12),

          // Attempt counter warning
          if (_attemptCount > 0)
            Text(
              '$remaining attempt${remaining == 1 ? '' : 's'} remaining.',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.errorHighlight,
                fontWeight: FontWeight.w500,
              ),
            ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_isLoading || _isLimitReached) ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.defaultForeground,
                elevation: 0,
                disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
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
                      'Submit',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Check your email',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'We sent a password reset link to ${_emailController.text.trim()}. '
          'Click the link in the email to reset your password.\n\n'
          "Can't find it? Check your spam or junk folder.",
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textMid,
            height: 1.5,
          ),
        ),

        if (_attemptCount < _maxAttempts) ...[
          const SizedBox(height: 12),
          Text(
            'You have ${_maxAttempts - _attemptCount} reset attempt${_maxAttempts - _attemptCount == 1 ? '' : 's'} remaining.',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
            ),
          ),
        ],

        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.defaultForeground,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'Back to Sign In',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),

        // Resend option if attempts remain
        if (_attemptCount < _maxAttempts) ...[
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () => setState(() => _emailSent = false),
              child: const Text(
                'Try a different email',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLimitReachedState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Too many attempts',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'You have reached the maximum number of password reset attempts for this session. '
          'Please try signing in using a different method.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textMid,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 32),

        // Back to Sign In
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.defaultForeground,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'Back to Sign In',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Try Google or Facebook suggestion
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Try signing in with',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 6),
              Text(
                '• Continue with Google\n• Continue with Facebook',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMid,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}