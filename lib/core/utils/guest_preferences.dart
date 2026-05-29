import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the guest session state across app restarts.
///
/// When a user taps "Continue as Guest", [setGuestMode] is called.
/// On next launch, [SplashController] checks [isGuestMode] and routes
/// directly to [ClientHome] without showing [LandingPage] again.
///
/// The flag is cleared by [clear] — called on logout and when the user
/// signs in with a real account. Uninstalling the app also clears it.
class GuestPreferences {
  GuestPreferences._();

  static const _keyGuestMode = 'guest_mode';

  /// Returns true if the user previously chose "Continue as Guest"
  /// and has not since logged out or signed in.
  static Future<bool> isGuestMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyGuestMode) ?? false;
    } catch (e) {
      debugPrint('[GuestPreferences.isGuestMode] $e');
      return false;
    }
  }

  /// Marks the user as a guest. Call this when "Continue as Guest" is tapped.
  static Future<void> setGuestMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyGuestMode, true);
    } catch (e) {
      debugPrint('[GuestPreferences.setGuestMode] $e');
    }
  }

  /// Clears the guest flag. Call this on logout or when the user signs in
  /// with a real account (Google, Facebook, email/password).
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyGuestMode);
    } catch (e) {
      debugPrint('[GuestPreferences.clear] $e');
    }
  }
}
