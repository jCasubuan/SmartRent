import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/widgets/app_footer.dart';
import 'package:smart_rent/screens/controllers/login_controller.dart';
import 'package:smart_rent/screens/controllers/google_sign_in_handler.dart';
import 'package:smart_rent/screens/controllers/facebook_sign_in_handler.dart';
import 'package:smart_rent/screens/home/client_home.dart';
import 'signin_screen.dart';
import 'signup_screen.dart';

// Landing page shown to unauthenticated users with options to sign in or create an account
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top - 
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
            children: [

              const Spacer(flex: 1),

              Image.asset(
                'assets/icons/smart_rent_logo.jpg',
                height: 80,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 1),

              const Text(
                'Premium Gown Rentals',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),

              // const Spacer(flex: 1),
              const SizedBox(height: 70),

              // Sign In button
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'SIGN IN',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Create Account button
              SizedBox(
                width: double.infinity,
                height: 45,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SignupScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'CREATE ACCOUNT',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Divider with "or"
              Row(
                children: const [
                  Expanded(child: Divider(color: AppColors.textMid)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or',
                      style: TextStyle(
                        color: AppColors.textMid,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.textMid)),
                ],
              ),

              const SizedBox(height: 24),

              // Continue with Google
              _SocialButton(
                icon: SvgPicture.asset(
                  'assets/icons/Google__G__logo.svg',
                  width: 20,
                  height: 20,
                ),
                label: 'Continue with Google',
                onTap: () => handleGoogleSignIn(context),
              ),

              const SizedBox(height: 10),

              // Continue with Facebook
              _SocialButton(
                icon: Image.asset(
                  'assets/icons/Facebook_Logo_Primary.png',
                  width: 20,
                  height: 20,
                ),
                label: 'Continue with Facebook',
                onTap: () => handleFacebookSignIn(context),
              ),

              const SizedBox(height: 10),

              // Continue anonymous
              _SocialButton(
                icon: const Icon(
                  Icons.person_outline,
                  size: 20,
                  color: AppColors.textDark,
                ),
                label: 'Continue as Guest',
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const ClientHome()),
                    (route) => false,
                  );
                },
              ),

              const Spacer(),
              const AppFooter(),

            ],
          ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: icon,
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textMid,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppColors.background,
        ),
      ),
    );
  }
}

