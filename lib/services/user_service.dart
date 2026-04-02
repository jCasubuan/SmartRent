import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Returns the first name of the currently logged in user
  static Future<String?> getCurrentUserFirstName() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final fullName = doc.data()?['name']?.toString() ?? '';
      return fullName.split(' ').first;
    } catch (_) {
      return null;
    }
  }

  // Returns the full user document data
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  // Returns the role of the currently logged in user
  static Future<String?> getCurrentUserRole() async {
    final data = await getCurrentUserData();
    return data?['role']?.toString();
  }

  // Signs out the current user
  static Future<void> signOut() async {
    await _auth.signOut();
  }
}