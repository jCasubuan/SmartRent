import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/models/rental_model.dart';
import 'package:smart_rent/core/utils/price_formatter.dart';
import 'package:smart_rent/core/utils/responsive_helper.dart';
import 'package:smart_rent/core/widgets/cached_image.dart';
import 'package:smart_rent/core/widgets/field_label.dart';
import 'package:smart_rent/services/rental_service.dart';

/// Shows full details of a customer's rental request.
/// For pending requests: shows Modify button (top-right) and Cancel Request button.
/// For approved/declined/cancelled: read-only view.
class RequestDetailsScreen extends StatefulWidget {
  final RentalModel rental;

  const RequestDetailsScreen({super.key, required this.rental});

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  late RentalModel _rental;

  @override
  void initState() {
    super.initState();
    _rental = widget.rental;
  }

  final bool _isProcessing = false;

  bool get _isPending => _rental.status == 'pending';

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // ── Cancel flow ────────────────────────────────────────────────────────────

  void _showCancelSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CancelReasonSheet(
        gownName: _rental.gownName,
        onConfirm: (reason) async {
          Navigator.pop(ctx);
          final success = await RentalService.cancelRequest(
            rentalId: _rental.id,
            reason: reason,
          );
          if (!mounted) return;
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Your request has been cancelled.'),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
            Navigator.pop(context); // back to transactions tab
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Something went wrong. Please try again.'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        },
      ),
    );
  }

  // ── Modify flow ────────────────────────────────────────────────────────────

  void _openModify() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ModifyRequestScreen(rental: _rental),
      ),
    ).then((updated) {
      if (updated == true) {
        // Pop back to transactions — the stream will refresh automatically
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final resp = Responsive(context);
    final r = _rental;
    final statusColor = AppColors.rentalStatusColor(r.status);
    final hasImage = r.gownImageUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Request Details',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: resp.sp(18),
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isPending)
            Padding(
              padding: EdgeInsets.only(right: resp.s(12)),
              child: ElevatedButton(
                onPressed: _openModify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.defaultForeground,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                      horizontal: resp.s(16), vertical: resp.s(8)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Modify',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: resp.sp(14),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(resp.s(20), resp.s(8), resp.s(20), resp.s(32)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status label
            Text(
              r.status == 'pending'
                  ? 'Waiting for Confirmation'
                  : r.status == 'approved'
                      ? 'Booking Confirmed'
                      : r.status == 'picked_up'
                          ? 'Ongoing Rental'
                          : r.status == 'rejected'
                              ? 'Request Not Approved'
                              : r.status == 'completed'
                                  ? 'Rental Completed'
                                  : r.status == 'no_show'
                                      ? 'No-show — Booking Cancelled'
                                      : 'Cancelled',
              style: TextStyle(
                fontSize: resp.sp(18),
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),

            SizedBox(height: resp.s(16)),

            // Image + details row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gown image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: hasImage
                      ? CachedImage(
                          imageUrl: r.gownImageUrl,
                          width: resp.s(140),
                          height: resp.s(180),
                          fit: BoxFit.cover,
                        )
                      : _imagePlaceholder(resp),
                ),

                SizedBox(width: resp.s(16)),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gown Details section
                      Text(
                        'Gown Details',
                        style: TextStyle(
                          fontSize: resp.sp(14),
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: resp.s(6)),
                      _DetailLine('Category', r.gownCategory),
                      _DetailLine('Color', r.gownColor),
                      _DetailLine(
                          'Price', '₱${PriceFormatter.format(r.gownPrice)}'),

                      SizedBox(height: resp.s(14)),

                      // Rental Details section
                      Text(
                        'Rental Details',
                        style: TextStyle(
                          fontSize: resp.sp(14),
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: resp.s(6)),
                      _DetailLine('Gown', r.gownName),
                      _DetailLine('Pick up', _formatDate(r.pickupDate)),
                      _DetailLine('Return', _formatDate(r.returnDate)),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: resp.s(20)),
            const Divider(color: AppColors.border),
            SizedBox(height: resp.s(16)),

            // Customer info
            Text(
              'Your Information',
              style: TextStyle(
                fontSize: resp.sp(14),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: resp.s(8)),
            _DetailLine('Name', r.customerName),
            _DetailLine('Phone', r.phone),

            // Cancellation reason (if cancelled)
            if (r.status == 'cancelled' &&
                r.cancellationReason != null) ...[
              SizedBox(height: resp.s(16)),
              const Divider(color: AppColors.border),
              SizedBox(height: resp.s(12)),
              Text(
                'Cancellation Reason',
                style: TextStyle(
                  fontSize: resp.sp(14),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: resp.s(6)),
              Text(
                r.cancellationReason!,
                style: TextStyle(
                  fontSize: resp.sp(14),
                  color: AppColors.textMid,
                  height: 1.5,
                ),
              ),
            ],

            SizedBox(height: resp.s(32)),

            // Cancel Request button — only for pending
            if (_isPending)
              SizedBox(
                width: double.infinity,
                height: resp.s(52),
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _showCancelSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.defaultForeground,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Cancel Request',
                    style: TextStyle(
                      fontSize: resp.sp(16),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder(Responsive resp) {
    return Container(
      width: resp.s(140),
      height: resp.s(180),
      decoration: BoxDecoration(
        color: AppColors.surfaceGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.checkroom_outlined,
          color: AppColors.border, size: resp.s(40)),
    );
  }
}

// ── Detail line ───────────────────────────────────────────────────────────────

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;

  const _DetailLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Padding(
      padding: EdgeInsets.only(bottom: r.s(4)),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: r.sp(13), height: 1.5),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(color: AppColors.textLight),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: AppColors.textMid),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cancel reason bottom sheet ────────────────────────────────────────────────

class _CancelReasonSheet extends StatefulWidget {
  final String gownName;
  final void Function(String reason) onConfirm;

  const _CancelReasonSheet({
    required this.gownName,
    required this.onConfirm,
  });

  @override
  State<_CancelReasonSheet> createState() => _CancelReasonSheetState();
}

class _CancelReasonSheetState extends State<_CancelReasonSheet> {
  static const _reasons = [
    'Too pricey',
    'Change of plans',
    'Found another option',
    'Wrong dates selected',
    'Others',
  ];

  String? _selectedReason;
  final _othersController = TextEditingController();

  @override
  void dispose() {
    _othersController.dispose();
    super.dispose();
  }

  bool get _canConfirm {
    if (_selectedReason == null) return false;
    if (_selectedReason == 'Others') {
      return _othersController.text.trim().isNotEmpty;
    }
    return true;
  }

  String get _finalReason {
    if (_selectedReason == 'Others') {
      return 'Others: ${_othersController.text.trim()}';
    }
    return _selectedReason!;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Why are you cancelling?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Let us know why you\'re cancelling your request for "${widget.gownName}".',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMid,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Reason chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _reasons.map((reason) {
                final isSelected = _selectedReason == reason;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedReason = reason;
                    if (reason != 'Others') _othersController.clear();
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceGrey,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      reason,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? AppColors.defaultForeground
                            : AppColors.textDark,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            // Others text field
            if (_selectedReason == 'Others') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _othersController,
                maxLines: 3,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textDark),
                decoration: InputDecoration(
                  hintText: 'Tell us a bit more...',
                  hintStyle: const TextStyle(
                      color: AppColors.inputHint, fontSize: 14),
                  contentPadding: const EdgeInsets.all(14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Confirm button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _canConfirm
                    ? () => widget.onConfirm(_finalReason)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.defaultForeground,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.35),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Yes, Cancel My Request',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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

// ── Modify request screen ─────────────────────────────────────────────────────

class _ModifyRequestScreen extends StatefulWidget {
  final RentalModel rental;

  const _ModifyRequestScreen({required this.rental});

  @override
  State<_ModifyRequestScreen> createState() => _ModifyRequestScreenState();
}

class _ModifyRequestScreenState extends State<_ModifyRequestScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  DateTime? _pickupDate;
  DateTime? _returnDate;
  bool _isSaving = false;
  bool _submitAttempted = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.rental.customerName);
    _phoneController = TextEditingController(text: widget.rental.phone);
    _pickupDate = widget.rental.pickupDate;
    _returnDate = widget.rental.returnDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$mm/$dd/${date.year}';
  }

  Future<void> _pickDate({required bool isPickup}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
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
        if (_returnDate != null && _returnDate!.isBefore(picked)) {
          _returnDate = null;
        }
      } else {
        _returnDate = picked;
      }
    });
  }

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

  Future<void> _save() async {
    setState(() => _submitAttempted = true);
    if (!_formKey.currentState!.validate()) return;
    if (_pickupDate == null || _returnDate == null) return;

    setState(() => _isSaving = true);

    final success = await RentalService.updateRequest(
      rentalId: widget.rental.id,
      customerName: _nameController.text.trim(),
      phone: _normalisePhone(_phoneController.text),
      pickupDate: _pickupDate!,
      returnDate: _returnDate!,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Your request has been updated.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Something went wrong. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Modify Request',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gown name — read-only
                const FieldLabel(label: 'GOWN NAME'),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceGrey,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    widget.rental.gownName,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMid,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const FieldLabel(label: 'CUSTOMER NAME'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
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

                const FieldLabel(label: 'PICK-UP DATE'),
                const SizedBox(height: 8),
                _DateField(
                  value: _formatDate(_pickupDate),
                  hint: 'MM/DD/YYYY',
                  onTap: () => _pickDate(isPickup: true),
                  hasError: _submitAttempted && _pickupDate == null,
                ),

                const SizedBox(height: 20),

                const FieldLabel(label: 'RETURN DATE'),
                const SizedBox(height: 8),
                _DateField(
                  value: _formatDate(_returnDate),
                  hint: 'MM/DD/YYYY',
                  onTap: () => _pickDate(isPickup: false),
                  hasError: _submitAttempted && _returnDate == null,
                ),

                const SizedBox(height: 36),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
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
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.defaultForeground),
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
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
}

class _DateField extends StatelessWidget {
  final String value;
  final String hint;
  final VoidCallback onTap;
  final bool hasError;

  const _DateField({
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
            const Icon(Icons.calendar_today_outlined,
                color: AppColors.textLight, size: 18),
          ],
        ),
      ),
    );
  }
}
