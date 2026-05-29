import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Returns the first name of the currently logged-in user, or null if not signed in.
  static Future<String?> getCurrentUserFirstName() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final fullName = doc.data()?['name']?.toString() ?? '';
      return fullName.split(' ').first;
    } catch (e) {
      debugPrint('[UserService.getCurrentUserFirstName] $e');
      return null;
    }
  }

  /// Returns the full Firestore user document data, or null on failure.
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data();
    } catch (e) {
      debugPrint('[UserService.getCurrentUserData] $e');
      return null;
    }
  }

  /// Returns the role string ('admin' or 'client') of the current user.
  static Future<String?> getCurrentUserRole() async {
    final data = await getCurrentUserData();
    return data?['role']?.toString();
  }

  /// Signs out the current user from Firebase Auth.
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── Bookmarks ─────────────────────────────────────────────────────────────

  /// Returns the list of bookmarked gown IDs for the current user.
  /// Returns an empty list if not signed in or on failure.
  static Future<List<String>> getBookmarks() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final raw = doc.data()?['bookmarks'];
      if (raw == null) return [];
      return List<String>.from(raw as List);
    } catch (e) {
      debugPrint('[UserService.getBookmarks] $e');
      return [];
    }
  }

  /// Adds [gownId] to the current user's bookmarks.
  /// Uses Firestore arrayUnion so it is safe to call even if already bookmarked.
  static Future<void> addBookmark(String gownId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'bookmarks': FieldValue.arrayUnion([gownId]),
      });
    } catch (e) {
      debugPrint('[UserService.addBookmark] $e');
    }
  }

  /// Removes [gownId] from the current user's bookmarks.
  /// Uses Firestore arrayRemove so it is safe to call even if not bookmarked.
  static Future<void> removeBookmark(String gownId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'bookmarks': FieldValue.arrayRemove([gownId]),
      });
    } catch (e) {
      debugPrint('[UserService.removeBookmark] $e');
    }
  }
}
