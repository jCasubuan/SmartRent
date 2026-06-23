import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_rent/screens/splash/splash_screen.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'firebase_options.dart';

void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Enable Firestore offline persistence with a 40MB cache limit.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 40 * 1024 * 1024, // 40 MB
    );

    // ── DEV SHORTCUT ────────────────────────────────────────────────────────
    // To skip login and jump straight to a screen during development:
    //   1. Add this import at the top of the file:
    //      import 'package:smart_rent/controllers/splash_controller.dart';
    //   2. Uncomment ONE line below. Only works in debug — no effect in release.
    //   3. Comment both back out before committing.
    //
    // SplashController.debugOverride = SplashDestination.landing;
    // SplashController.debugOverride = SplashDestination.clientHome;
    // SplashController.debugOverride = SplashDestination.adminHome;
    // ────────────────────────────────────────────────────────────────────────

    runApp(const SmartRentApp());
}

class SmartRentApp extends StatelessWidget {
  const SmartRentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartRent',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary
        ),
        useMaterial3: true,
        fontFamily: 'sans-serif',
        scaffoldBackgroundColor: AppColors.background,
      ),
      scrollBehavior: const ScrollBehavior().copyWith(
        overscroll: false,
      ),
      home: const SplashScreen(),
    );
  }
}