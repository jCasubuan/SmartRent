import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/models/gown_model.dart';
import 'package:smart_rent/core/utils/price_formatter.dart';
import 'package:smart_rent/core/utils/responsive_helper.dart';
import 'package:smart_rent/core/widgets/field_label.dart';
import 'package:smart_rent/services/rental_service.dart';

/// Rental request form shown when a logged-in user taps "Rent this Gown".
///
/// Flow:
///   1. User fills all fields.
///   2. Taps "Submit Request" → policy confirmation dialog appears.
///   3. User reads policies, ticks the checkbox, taps "Confirm Request".
///   4. Firestore write happens → success dialog → back to gown detail.
class RentalRequestScreen extends StatefulWidget {
  final GownModel gown;

  const RentalRequestScreen({super.key, required this.gown});

  @override
  State<RentalRequestScreen> createState() => _RentalRequestScreenState();
}

class _RentalRequestScreenState extends State<RentalRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _phoneController = TextEditingController();

  DateTime? _pickupDate;
  DateTime? _returnDate;
  bool _isSubmitting = false;

  // Tracks whether the user attempted to submit (used to show date errors)
  bool _submitAttempted = false;

  @override
  void initState() {
    super.initState();
    _prefillCustomerInfo();
  }

  /// Pre-fills customer name and phone from the user's most recent rental.
  /// Fields remain editable — this is just a convenience for returning customers.
  Future<void> _prefillCustomerInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final info = await RentalService.getLastCustomerInfo(user.uid);
    if (info != null && mounted) {
      if (_customerNameController.text.isEmpty) {
        _customerNameController.text = info.name;
      }
      if (_phoneController.text.isEmpty) {
        _phoneController.text = info.phone;
      }
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ── Date picker ────────────────────────────────────────────────────────────

  Future<void> _pickDate({required bool isPickup}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Pick-up: minimum today. Return: minimum = pickup date + 1 day (no same-day returns).
    final firstDate = isPickup
        ? today
        : (_pickupDate?.add(const Duration(days: 1)) ?? today.add(const Duration(days: 1)));
    final initialDate = isPickup
        ? (_pickupDate ?? today)
        : (_returnDate ?? firstDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 2),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.defaultForeground,
            onSurface: AppColors.textDark,
          ),
        ),
        child: child!,
      ),
    );

    if (picked == null) return;

    setState(() {
      if (isPickup) {
        _pickupDate = picked;
        // Clear return date if it's now before the new pickup date
        if (_returnDate != null && _returnDate!.isBefore(picked)) {
          _returnDate = null;
        }
      } else {
        _returnDate = picked;
      }
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$mm/$dd/$yyyy';
  }

  // ── Info dialogs ───────────────────────────────────────────────────────────

  void _showPickupInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text(
              'Pick-up Date',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: const Text(
          'This is the day you\'ll come to the shop to get the gown.\n\n'
          'Once your booking is confirmed, please make sure to pick it up '
          'on this date. If you don\'t show up, your booking may be '
          'marked as a no-show and the gown will be made available to others.',
          style: TextStyle(fontSize: 14, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Got it',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReturnInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text(
              'Return Date',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: const Text(
          'This is the day you\'ll bring the gown back to the shop.\n\n'
          'Please return it on time — we\'ll send you a reminder the day before.\n\n'
          'Returning the gown late will result in a charge of ₱500 for every '
          'extra day it is kept.',
          style: TextStyle(fontSize: 14, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Got it',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Phone validation ───────────────────────────────────────────────────────

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }
    final v = value.trim();
    if (v.length != 11) {
      return 'Phone number must be exactly 11 digits';
    }
    if (!v.startsWith('09')) {
      return 'Phone number must start with 09';
    }
    if (!RegExp(r'^09\d{9}$').hasMatch(v)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  String _normalisePhone(String value) {
    return value.trim();
  }

  // ── Submit flow ────────────────────────────────────────────────────────────

  // Step 1: validate form + dates, then show policy dialog
  void _onSubmitPressed() {
    setState(() => _submitAttempted = true);

    if (!_formKey.currentState!.validate()) return;
    if (_pickupDate == null) {
      _showError('Please choose a pick-up date before continuing.');
      return;
    }
    if (_returnDate == null) {
      _showError('Please choose a return date before continuing.');
      return;
    }

    _showPolicyDialog();
  }

  // Step 2: policy confirmation dialog with checkbox + Confirm button
  void _showPolicyDialog() {
    bool agreed = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Rental Policy',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Please read and agree to the following before sending your request:',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMid,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Policy 1 — Pick-up
                _PolicyPoint(
                  icon: Icons.schedule_outlined,
                  title: 'Pick Up on Your Scheduled Date',
                  body:
                      'Once your booking is confirmed, please come to the '
                      'shop on the pick-up date you selected. If you don\'t '
                      'show up, your booking may be marked as a no-show '
                      'and the gown will be made available to others.',
                ),

                const SizedBox(height: 12),

                // Policy 2 — Late return
                _PolicyPoint(
                  icon: Icons.warning_amber_outlined,
                  title: 'Return on the Agreed Date',
                  body:
                      'Please bring the gown back on the date you chose. '
                      'If it\'s returned late, a fee of ₱500 will be added '
                      'for each extra day.',
                ),

                const SizedBox(height: 20),

                // Checkbox
                GestureDetector(
                  onTap: () =>
                      setDialogState(() => agreed = !agreed),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: agreed,
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (v) => setDialogState(
                              () => agreed = v ?? false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'I have read and agree to the rental terms above.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textDark,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textMid,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              // Greyed out until checkbox is ticked
              onPressed: agreed
                  ? () {
                      Navigator.pop(ctx);
                      _doSubmit();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.defaultForeground,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.35),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Confirm Request',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 3: actual Firestore write
  Future<void> _doSubmit() async {
    setState(() => _isSubmitting = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isSubmitting = false);
      _showError('Please sign in first to send a rental request.');
      return;
    }

    final success = await RentalService.submitRequest(
      gownId: widget.gown.id,
      gownName: widget.gown.name,
      gownCode: widget.gown.code,
      gownImageUrl: widget.gown.imageUrls.isNotEmpty
          ? widget.gown.imageUrls.first
          : '',
      gownCategory: widget.gown.category,
      gownColor: widget.gown.color,
      gownPrice: widget.gown.rentalPrice,
      customerId: user.uid,
      customerName: _customerNameController.text.trim(),
      phone: _normalisePhone(_phoneController.text),
      pickupDate: _pickupDate!,
      returnDate: _returnDate!,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      _showSuccessDialog();
    } else {
      _showError('Something went wrong. Please check your connection and try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline,
                color: AppColors.primary, size: 24),
            SizedBox(width: 8),
            Text(
              'Request Submitted',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'Your request for "${widget.gown.name}" has been sent! '
          'We\'ll let you know once the shop confirms your booking.',
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, true); // Signal successful submission
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.defaultForeground,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Done',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: AppColors.textDark, size: r.s(20)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Rental Request',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: r.sp(18),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(r.s(24), r.s(16), r.s(24), r.s(32)),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Gown summary card ──────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(r.s(16)),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceGrey,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: widget.gown.imageUrls.isNotEmpty
                            ? Image.network(
                                widget.gown.imageUrls.first,
                                width: r.s(60),
                                height: r.s(60),
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    _imagePlaceholder(r),
                              )
                            : _imagePlaceholder(r),
                      ),
                      SizedBox(width: r.s(12)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.gown.name,
                              style: TextStyle(
                                fontSize: r.sp(15),
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: r.s(2)),
                            Text(
                              '₱${PriceFormatter.format(widget.gown.rentalPrice)}',
                              style: TextStyle(
                                fontSize: r.sp(14),
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              widget.gown.category,
                              style: TextStyle(
                                fontSize: r.sp(12),
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: r.s(28)),

                // ── Gown Name (read-only) ──────────────────────────────────
                const FieldLabel(label: 'GOWN NAME'),
                const SizedBox(height: 8),
                _ReadOnlyField(value: widget.gown.name),

                const SizedBox(height: 20),

                // ── Customer Name ──────────────────────────────────────────
                const FieldLabel(label: 'CUSTOMER NAME'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _customerNameController,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 50,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r"[a-zA-ZÀ-ÿ\s'\-\.]")),
                  ],
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textDark),
                  decoration: _inputDecoration('Enter full name'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    final name = v.trim();
                    if (name.length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    if (!RegExp(r'^[a-zA-ZÀ-ÿ]').hasMatch(name)) {
                      return 'Name must start with a letter';
                    }
                    if (!RegExp(r'[a-zA-ZÀ-ÿ]$').hasMatch(name)) {
                      return 'Name must end with a letter';
                    }
                    if (name.replaceAll(RegExp(r'[^a-zA-ZÀ-ÿ]'), '').length < 2) {
                      return 'Name must contain at least 2 letters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ── Phone Number ───────────────────────────────────────────
                const FieldLabel(label: 'PHONE NUMBER'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textDark),
                  decoration:
                      _inputDecoration('09XXXXXXXXX'),
                  validator: _validatePhone,
                ),

                const SizedBox(height: 20),

                // ── Pick-up Date ───────────────────────────────────────────
                _DateFieldLabel(
                  label: 'PICK-UP DATE',
                  onInfoTap: _showPickupInfo,
                ),
                const SizedBox(height: 8),
                _DatePickerField(
                  value: _formatDate(_pickupDate),
                  hint: 'MM/DD/YYYY',
                  onTap: () => _pickDate(isPickup: true),
                  hasError: _submitAttempted && _pickupDate == null,
                ),
                if (_submitAttempted && _pickupDate == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 6, left: 12),
                    child: Text(
                      'Please choose a pick-up date',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.error),
                    ),
                  ),

                const SizedBox(height: 20),

                // ── Return Date ────────────────────────────────────────────
                _DateFieldLabel(
                  label: 'RETURN DATE',
                  onInfoTap: _showReturnInfo,
                ),
                const SizedBox(height: 8),
                _DatePickerField(
                  value: _formatDate(_returnDate),
                  hint: 'MM/DD/YYYY',
                  onTap: () => _pickDate(isPickup: false),
                  hasError: _submitAttempted && _returnDate == null,
                ),
                if (_submitAttempted && _returnDate == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 6, left: 12),
                    child: Text(
                      'Please choose a return date',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.error),
                    ),
                  ),

                const SizedBox(height: 36),

                // ── Submit button ──────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: r.s(52),
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _onSubmitPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.defaultForeground,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            width: r.s(22),
                            height: r.s(22),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.defaultForeground),
                            ),
                          )
                        : Text(
                            'Submit Request',
                            style: TextStyle(
                              fontSize: r.sp(16),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          const TextStyle(color: AppColors.inputHint, fontSize: 14),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  Widget _imagePlaceholder(Responsive r) {
    return Container(
      width: r.s(60),
      height: r.s(60),
      color: AppColors.border,
      child: Icon(Icons.checkroom_outlined,
          color: AppColors.background, size: r.s(28)),
    );
  }
}

// ── Date field label with info icon ──────────────────────────────────────────

class _DateFieldLabel extends StatelessWidget {
  final String label;
  final VoidCallback onInfoTap;

  const _DateFieldLabel({
    required this.label,
    required this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: onInfoTap,
          child: const Icon(
            Icons.info_outline,
            size: 16,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

// ── Policy point row ──────────────────────────────────────────────────────────

class _PolicyPoint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _PolicyPoint({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceGrey,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMid,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Read-only field ───────────────────────────────────────────────────────────

class _ReadOnlyField extends StatelessWidget {
  final String value;

  const _ReadOnlyField({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceGrey,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textMid,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── Date picker field ─────────────────────────────────────────────────────────

class _DatePickerField extends StatelessWidget {
  final String value;
  final String hint;
  final VoidCallback onTap;
  final bool hasError;

  const _DatePickerField({
    required this.value,
    required this.hint,
    required this.onTap,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = value.isEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasError ? AppColors.error : AppColors.border,
            width: hasError ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                isEmpty ? hint : value,
                style: TextStyle(
                  fontSize: 14,
                  color: isEmpty
                      ? AppColors.inputHint
                      : AppColors.textDark,
                ),
              ),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              color: AppColors.textLight,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
