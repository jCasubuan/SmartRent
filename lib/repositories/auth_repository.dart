import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

enum UserRole { admin, client }

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  Future<UserRole> signIn({
  required String email,
  required String password,
}) async {
  final credential = await _auth.signInWithEmailAndPassword(
    email: email,
    password: password,
  );

  final user = credential.user!;
  final role = await _getRoleOrCreate(user);
  return role == 'admin' ? UserRole.admin : UserRole.client;
}

Future<String> _getRoleOrCreate(User user) async {
  final docRef = _firestore.collection('users').doc(user.uid);
  final doc = await docRef.get();

  if (!doc.exists) {
    // First sign in after verification — create the Firestore document now
    await docRef.set({
      'name': user.displayName ?? '',
      'email': user.email ?? '',
      'role': 'client',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return 'client';
  }

  return doc.data()?['role'] ?? 'client';
}

  Future<void> signUp({
  required String name,
  required String email,
  required String password,
}) async {
  final credential = await _auth.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );

  // Update display name so we can retrieve it later
  await credential.user!.updateDisplayName(name);

  // Send verification email
  await credential.user!.sendEmailVerification();

  // Sign them out immediately — they must verify before accessing the app
  await _auth.signOut();
}

  Future<UserRole> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();

    if (googleUser == null) throw Exception('cancelled');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user!;

    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'role': 'client',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return UserRole.client;
  }

  Future<UserRole> signInWithFacebook() async {
    final result = await FacebookAuth.instance.login(
      permissions: ['email', 'public_profile'],
    );

    if (result.status == LoginStatus.cancelled) {
      throw Exception('cancelled');
    }

    if (result.status != LoginStatus.success) {
      throw Exception('Facebook Login failed');
    }

    // Get user data including profile picture from Facebook Graph API
    final userData = await FacebookAuth.instance.getUserData(
      fields: 'name,email,picture.width(200).height(200)',
    );

    final credential = FacebookAuthProvider.credential(
      result.accessToken!.tokenString,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user!;

    // Extract photo URL from Facebook Graph API response
    final pictureUrl = userData['picture']?['data']?['url'] as String?;

    // Update Firebase Auth profile with Facebook photo
    if (pictureUrl != null) {
      await user.updatePhotoURL(pictureUrl);
    }

    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'name': userData['name'] ?? user.displayName ?? '',
        'email': userData['email'] ?? user.email ?? '',
        'role': 'client',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return UserRole.client;
  }
}