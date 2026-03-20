// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:smart_rent/core/constants/app_colors.dart';
// import '../auth/landing_page.dart';
// import '../home/client_home.dart';
// import '../home/admin_home.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//   late Animation<double> _scaleAnimation;

//   @override
//   void initState() {
//     super.initState();

//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1500),
//     );

//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _animationController,
//         curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
//       ),
//     );

//     _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _animationController,
//         curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
//       ),
//     );

//     _animationController.forward();

//     _checkAuthAndNavigate();
//   }

//   Future<void> _checkAuthAndNavigate() async {
//     await Future.delayed(const Duration(milliseconds: 2000));

//     if (!mounted) return;

//     final user = FirebaseAuth.instance.currentUser;

//     if (user == null) {
//       _navigateTo(const LandingPage());  
//       //_navigateTo(const ClientHome());
//       //_navigateTo(const AdminHome());
//       return;
//     }

//     try {
//       final doc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .get();

//       if (!mounted) return;

//       final role = doc.data()?['role'] ?? 'client';

//       if (role == 'admin') {
//         _navigateTo(const AdminHome());
//       } else {
//         _navigateTo(const ClientHome());
//       }
//     } catch (e) {
//       if (mounted) _navigateTo(const LandingPage());
//     }
//   }

//   void _navigateTo(Widget page) {
//     Navigator.of(context).pushReplacement(
//       PageRouteBuilder(
//         pageBuilder: (_, __, ___) => page,
//         transitionDuration: const Duration(milliseconds: 600),
//         transitionsBuilder: (_, animation, __, child) {
//           return FadeTransition(opacity: animation, child: child);
//         },
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       body: Center(
//         child: AnimatedBuilder(
//           animation: _animationController,
//           builder: (context, child) {
//             return FadeTransition(
//               opacity: _fadeAnimation,
//               child: ScaleTransition(
//                 scale: _scaleAnimation,
//                 child: child,
//               ),
//             );
//           },
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               // Official SmartRent logo
//               Image.asset(
//                 'assets/icons/smart_rent_logo.jpg',
//                 width: 260,
//                 fit: BoxFit.contain,
//               ),
//               const SizedBox(height: 48),
//               // Loading indicator
//               const SizedBox(
//                 width: 24,
//                 height: 24,
//                 child: CircularProgressIndicator(
//                   strokeWidth: 2.5,
//                   valueColor: AlwaysStoppedAnimation<Color>(
//                     AppColors.primary,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/screens/auth/landing_page.dart';
import 'package:smart_rent/screens/home/client_home.dart';
import 'package:smart_rent/screens/home/admin_home.dart';
import 'splash_animations.dart';
import '../controllers/splash_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final SplashAnimations _animations;
  late final SplashController _controller;

  @override
  void initState() {
    super.initState();
    _animations = SplashAnimations.create(this);
    _controller = SplashController();

    _animations.forward();
    _resolveAndNavigate();
  }

  Future<void> _resolveAndNavigate() async {
    final destination = await _controller.resolveDestination();
    if (!mounted) return;
    _navigateTo(_destinationWidget(destination));
  }

  Widget _destinationWidget(SplashDestination destination) {
    return switch (destination) {
      SplashDestination.adminHome   => const AdminHome(),
      SplashDestination.clientHome  => const ClientHome(),
      SplashDestination.landing => const LandingPage(),
    };
  }

  void _navigateTo(Widget page) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _animations.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _animations.controller,
          builder: (context, child) => FadeTransition(
            opacity: _animations.fade,
            child: ScaleTransition(
              scale: _animations.scale,
              child: child,
            ),
          ),
          child: const _SplashContent(),
        ),
      ),
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/icons/smart_rent_logo.jpg',
          width: 260,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 48),
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}
