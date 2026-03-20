import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum SplashDestination { landing, clientHome, adminHome }

class SplashController {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  SplashController({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Future<SplashDestination> resolveDestination() async {
    await Future.delayed(const Duration(milliseconds: 2000));

    // DEV SHORTCUT: uncomment the one you need, comment out the rest
    return SplashDestination.landing;
    // return SplashDestination.clientHome;
    // return SplashDestination.adminHome;

    // Everything below is skipped when a shortcut is active
    final user = _auth.currentUser;
    if (user == null) return SplashDestination.landing;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final role = doc.data()?['role'] ?? 'client';
      return role == 'admin'
          ? SplashDestination.adminHome
          : SplashDestination.clientHome;
    } catch (_) {
      return SplashDestination.landing;
    }
  }
}