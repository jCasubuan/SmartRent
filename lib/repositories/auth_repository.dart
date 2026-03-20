import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, client } 

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  Future<UserRole> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    final doc = await _firestore
      .collection('users')
      .doc(credential.user!.uid)
      .get();

    final role = doc.data()?['role'] ?? 'client';
    return role == 'admin' ? UserRole.admin : UserRole.client;
  }

  // Creates a new user account and saves their profile to Firestore
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _firestore
        .collection('users')
        .doc(credential.user!.uid)
        .set({
      'name': name,
      'email': email,
      'role': 'client',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

}