import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/utils/logout_helper.dart';
import 'package:smart_rent/core/utils/responsive_helper.dart';
import 'package:smart_rent/screens/auth/landing_page.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  String? _name;
  String? _email;
  String? _photoUrl;
  bool _isLoading = true;
  bool _isEmailPassword = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _appVersion = info.version);
    }
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    _photoUrl = user.photoURL;
    _email = user.email;

    // Check if user signed in with email/password (no OAuth provider)
    _isEmailPassword = user.providerData.any((p) => p.providerId == 'password');

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (mounted) {
        setState(() {
          _name = doc.data()?['name'] ?? user.displayName ?? '';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout(BuildContext context) =>
      LogoutHelper.logout(context);

  Future<void> _editName() async {
    final controller = TextEditingController(text: _name);
    String? errorText;

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Edit Name',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: const TextStyle(fontSize: 13),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 8),
                Text(errorText!,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.error)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: AppColors.textMid,
                      fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty || name.length < 2) {
                  setDialogState(
                      () => errorText = 'Name must be at least 2 characters.');
                  return;
                }
                Navigator.pop(ctx, name);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.defaultForeground,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );

    if (newName == null || !mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'name': newName});
      setState(() => _name = newName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Name updated successfully.'),
            backgroundColor: AppColors.rentalApproved,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update name. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _changePassword() async {
    final currentPwController = TextEditingController();
    final newPwController = TextEditingController();
    final confirmPwController = TextEditingController();
    String? errorText;

    final success = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Change Password',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPwController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    labelStyle: const TextStyle(fontSize: 13),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPwController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    labelStyle: const TextStyle(fontSize: 13),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPwController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    labelStyle: const TextStyle(fontSize: 13),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 10),
                  Text(errorText!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.error)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: AppColors.textMid,
                      fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () async {
                final currentPw = currentPwController.text.trim();
                final newPw = newPwController.text.trim();
                final confirmPw = confirmPwController.text.trim();

                if (currentPw.isEmpty || newPw.isEmpty || confirmPw.isEmpty) {
                  setDialogState(
                      () => errorText = 'Please fill in all fields.');
                  return;
                }
                if (newPw.length < 6) {
                  setDialogState(() => errorText =
                      'New password must be at least 6 characters.');
                  return;
                }
                if (newPw != confirmPw) {
                  setDialogState(
                      () => errorText = 'New passwords do not match.');
                  return;
                }

                try {
                  final user = FirebaseAuth.instance.currentUser!;
                  final credential = EmailAuthProvider.credential(
                    email: user.email!,
                    password: currentPw,
                  );
                  await user.reauthenticateWithCredential(credential);
                  await user.updatePassword(newPw);
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } on FirebaseAuthException catch (e) {
                  final msg = switch (e.code) {
                    'wrong-password' => 'Current password is incorrect.',
                    'weak-password' =>
                      'New password is too weak. Use at least 6 characters.',
                    _ => 'Failed to change password. Please try again.',
                  };
                  setDialogState(() => errorText = msg);
                } catch (_) {
                  setDialogState(() => errorText =
                      'Failed to change password. Please try again.');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.defaultForeground,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Update',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );

    if (success == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password changed successfully.'),
          backgroundColor: AppColors.rentalApproved,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final user = FirebaseAuth.instance.currentUser;

    // ── Guest state ──────────────────────────────────────────────────────────
    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'Profile',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w700,
              fontSize: r.sp(18),
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: r.s(40)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_outline,
                  size: r.s(80),
                  color: AppColors.border,
                ),
                SizedBox(height: r.s(16)),
                Text(
                  'You\'re browsing as a guest',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: r.sp(16),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: r.s(8)),
                Text(
                  'Sign in to view your profile and keep track of your rentals.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: r.sp(13),
                    color: AppColors.textMid,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: r.s(32)),
                SizedBox(
                  width: double.infinity,
                  height: r.s(50),
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LandingPage(),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.defaultForeground,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      'SIGN IN',
                      style: TextStyle(
                        fontSize: r.sp(15),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Loading state ────────────────────────────────────────────────────────
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // ── Logged-in state ──────────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceGrey,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Profile',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: r.sp(18),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(r.s(20), r.s(16), r.s(20), r.s(40)),
        child: Column(
          children: [
            // ── Profile card ─────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(r.s(20)),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar
                  _photoUrl != null
                      ? CircleAvatar(
                          radius: r.s(40),
                          backgroundImage: NetworkImage(_photoUrl!),
                        )
                      : Container(
                          width: r.s(80),
                          height: r.s(80),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_outline,
                            size: r.s(40),
                            color: AppColors.primary,
                          ),
                        ),
                  SizedBox(height: r.s(14)),
                  Text(
                    _name ?? '',
                    style: TextStyle(
                      fontSize: r.sp(18),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (_email != null && _email!.isNotEmpty) ...[
                    SizedBox(height: r.s(4)),
                    Text(
                      _email!,
                      style: TextStyle(
                        fontSize: r.sp(13),
                        color: AppColors.textMid,
                      ),
                    ),
                  ],
                  SizedBox(height: r.s(6)),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: r.s(12), vertical: r.s(4)),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _isEmailPassword
                          ? 'Email & Password'
                          : 'Signed in with Facebook/Google',
                      style: TextStyle(
                        fontSize: r.sp(11),
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: r.s(24)),

            // ── Account section ──────────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(r.s(16), r.s(14), r.s(16), r.s(4)),
                    child: Text(
                      'Account',
                      style: TextStyle(
                        fontSize: r.sp(13),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textLight,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  // Edit Name — available for all users
                  _SettingsTile(
                    icon: Icons.edit_outlined,
                    label: 'Edit Name',
                    onTap: _editName,
                  ),
                  // Change Password — only for email/password users
                  if (_isEmailPassword)
                    _SettingsTile(
                      icon: Icons.lock_outline,
                      label: 'Change Password',
                      onTap: _changePassword,
                    ),
                  SizedBox(height: r.s(4)),
                ],
              ),
            ),

            SizedBox(height: r.s(16)),

            // ── About section ────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: r.s(16), vertical: r.s(14)),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: r.s(22), color: AppColors.textMid),
                  SizedBox(width: r.s(14)),
                  Expanded(
                    child: Text(
                      'App Version',
                      style: TextStyle(
                        fontSize: r.sp(14),
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Text(
                    _appVersion.isEmpty ? '...' : _appVersion,
                    style: TextStyle(
                      fontSize: r.sp(13),
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: r.s(32)),

            // ── Logout button ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: r.s(50),
              child: OutlinedButton.icon(
                onPressed: () => _handleLogout(context),
                icon: Icon(Icons.logout_outlined, size: r.s(20)),
                label: Text(
                  'LOG OUT',
                  style: TextStyle(
                    fontSize: r.sp(15),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side:
                      const BorderSide(color: AppColors.error, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Settings tile ─────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: r.s(16), vertical: r.s(14)),
        child: Row(
          children: [
            Icon(icon, size: r.s(22), color: AppColors.textMid),
            SizedBox(width: r.s(14)),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: r.sp(14),
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
            ),
            Icon(Icons.chevron_right,
                size: r.s(20), color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
