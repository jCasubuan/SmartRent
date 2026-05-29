import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_rent/core/utils/guest_preferences.dart';

enum SplashDestination { landing, clientHome, adminHome }

/// Controls which screen the app navigates to after the splash.
///
/// Resolution order:
///   1. [debugOverride] — debug builds only, set in main.dart
///   2. Firebase user logged in → AdminHome or ClientHome based on role
///   3. Guest mode active (user previously tapped "Continue as Guest") → ClientHome
///   4. No session → LandingPage
class SplashController {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Debug-only override. Set to a [SplashDestination] value in debug builds
  /// to skip the Firebase lookup and go straight to a specific screen.
  ///
  /// Example (in main.dart):
  ///   SplashController.debugOverride = SplashDestination.adminHome;
  static SplashDestination? debugOverride;

  SplashController({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Future<SplashDestination> resolveDestination() async {
    await Future.delayed(const Duration(milliseconds: 2000));

    // Debug shortcut — only active in debug builds, never in release.
    if (kDebugMode && debugOverride != null) return debugOverride!;

    // Logged-in user — resolve their role from Firestore.
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        final role = doc.data()?['role'] ?? 'client';
        return role == 'admin'
            ? SplashDestination.adminHome
            : SplashDestination.clientHome;
      } catch (e) {
        debugPrint('[SplashController] Failed to resolve role: $e');
        return SplashDestination.clientHome;
      }
    }

    // No Firebase session — check if the user previously chose guest mode.
    final isGuest = await GuestPreferences.isGuestMode();
    if (isGuest) return SplashDestination.clientHome;

    // First launch or after logout — show the landing page.
    return SplashDestination.landing;
  }
}