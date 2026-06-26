import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/utils/guest_preferences.dart';
import 'package:smart_rent/core/utils/responsive_helper.dart';
import 'package:smart_rent/core/widgets/app_footer.dart';
import 'package:smart_rent/controllers/google_sign_in_handler.dart';
import 'package:smart_rent/controllers/facebook_sign_in_handler.dart';
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
    final r = Responsive(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: r.s(32)),
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
                height: r.s(80),
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 1),

              Text(
                'Premium Gown Rentals',
                style: TextStyle(
                  fontSize: r.sp(16),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),

              // const Spacer(flex: 1),
              SizedBox(height: r.s(70)),

              // Sign In button
              SizedBox(
                width: double.infinity,
                height: r.s(45),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SigninScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.defaultForeground,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'SIGN IN',
                    style: TextStyle(
                      fontSize: r.sp(15),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),

              SizedBox(height: r.s(14)),

              // Create Account button
              SizedBox(
                width: double.infinity,
                height: r.s(45),
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
                  child: Text(
                    'CREATE ACCOUNT',
                    style: TextStyle(
                      fontSize: r.sp(15),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),

              SizedBox(height: r.s(28)),

              // Divider with "or"
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.textMid)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: r.s(12)),
                    child: Text(
                      'or',
                      style: TextStyle(
                        color: AppColors.textMid,
                        fontSize: r.sp(13),
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.textMid)),
                ],
              ),

              SizedBox(height: r.s(24)),

              // Continue with Google
              _SocialButton(
                icon: SvgPicture.asset(
                  'assets/icons/Google__G__logo.svg',
                  width: r.s(20),
                  height: r.s(20),
                ),
                label: 'Continue with Google',
                onTap: () => handleGoogleSignIn(context),
              ),

              SizedBox(height: r.s(10)),

              // Continue with Facebook
              _SocialButton(
                icon: Image.asset(
                  'assets/icons/Facebook_Logo_Primary.png',
                  width: r.s(20),
                  height: r.s(20),
                ),
                label: 'Continue with Facebook',
                onTap: () => handleFacebookSignIn(context),
              ),

              SizedBox(height: r.s(10)),

              // Continue anonymous
              _SocialButton(
                icon: Icon(
                  Icons.person_outline,
                  size: r.s(20),
                  color: AppColors.textDark,
                ),
                label: 'Continue as Guest',
                onTap: () async {
                  // Persist guest session so the user isn't shown this
                  // page again on next launch unless they log out.
                  await GuestPreferences.setGuestMode();
                  if (!context.mounted) return;
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
    final r = Responsive(context);
    return SizedBox(
      width: double.infinity,
      height: r.s(50),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: icon,
        label: Text(
          label,
          style: TextStyle(
            fontSize: r.sp(14),
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

