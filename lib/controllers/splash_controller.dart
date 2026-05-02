import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum SplashDestination { landing, clientHome, adminHome }

/// Controls which screen the app navigates to after the splash.
///
/// In debug mode you can override the destination by setting
/// [debugOverride] before the splash resolves.
class SplashController {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Debug-only override. Set to a [SplashDestination] value in debug builds
  /// to skip the Firebase lookup and go straight to a specific screen.
  ///
  /// Example (in main.dart or a test):
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

    final user = _auth.currentUser;
    if (user == null) return SplashDestination.landing;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final role = doc.data()?['role'] ?? 'client';
      return role == 'admin'
          ? SplashDestination.adminHome
          : SplashDestination.clientHome;
    } catch (e) {
      debugPrint('[SplashController] Failed to resolve role: $e');
      return SplashDestination.landing;
    }
  }
}