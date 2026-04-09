import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_rent/screens/splash/splash_screen.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'firebase_options.dart';

void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
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