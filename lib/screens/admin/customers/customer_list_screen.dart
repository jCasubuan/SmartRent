import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/utils/responsive_helper.dart';
import 'package:smart_rent/services/customer_service.dart';
import 'package:smart_rent/screens/admin/customers/customer_history_screen.dart';

/// Admin customer list — a flat, searchable list of ALL customers who have
/// ever interacted with the system. Tap a customer to see their Approved
/// and Declined history. Supports multi-select + delete.
class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

const int _pageSize = 20;

class _CustomerListScreenState extends State<CustomerListScreen> {
  final _searchController = TextEditingController();

  List<CustomerEntry> _all = [];
  List<CustomerEntry> _filtered = [];
  bool _isLoading = true;
  bool _showAll = false;
  bool _selectAll = false;
  final Set<String> _selected = {};
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    final customers = await CustomerService.getAllCustomers();
    if (mounted) {
      setState(() {
        _all = customers;
        _filtered = customers;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final q = _searchController.text.toLowerCase().trim();
    setState(() {
      _showAll = false;
      _selectAll = false;
      _selected.clear();
      if (q.isEmpty) {
        _filtered = _all;
      } else {
        _filtered = _all.where((c) {
          return c.customerName.toLowerCase().contains(q) ||
              c.phone.contains(q);
        }).toList();
      }
    });
  }

  // ── Selection ───────────────────────────────────────────────────────────

  List<CustomerEntry> get _visible {
    if (_showAll || _filtered.length <= _pageSize) return _filtered;
    return _filtered.take(_pageSize).toList();
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      if (_selectAll) {
        _selected.addAll(_visible.map((c) => c.customerId));
      } else {
        _selected.clear();
      }
    });
  }

  void _toggleSelect(String customerId) {
    setState(() {
      if (_selected.contains(customerId)) {
        _selected.remove(customerId);
        _selectAll = false;
      } else {
        _selected.add(customerId);
        if (_selected.length == _visible.length) _selectAll = true;
      }
    });
  }

  // ── Delete ──────────────────────────────────────────────────────────────

  Future<void> _confirmDelete() async {
    if (_selected.isEmpty) return;

    final count = _selected.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Customers',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        content: Text(
          'Are you sure you want to delete $count '
          'customer${count > 1 ? 's' : ''}?\n\n'
          'This will permanently remove all their rental records.',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textMid,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                  color: AppColors.textMid, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                  color: AppColors.error, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);

    final success =
        await CustomerService.deleteCustomerRecords(_selected.toList());

    if (mounted) {
      setState(() => _isDeleting = false);

      if (success) {
        _selected.clear();
        _selectAll = false;
        await _loadCustomers();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '$count customer${count > 1 ? 's' : ''} deleted.'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete. Please try again.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: AppColors.textDark, size: r.s(20)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Customers',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: r.sp(18),
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // ── Search bar ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceGrey,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textDark),
                    decoration: InputDecoration(
                      hintText: 'Search by name, phone',
                      hintStyle: const TextStyle(
                          color: AppColors.textLight, fontSize: 13),
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.textLight, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close,
                                  color: AppColors.textLight, size: 18),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Content ─────────────────────────────────────────────────
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary),
                      )
                    : _filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.people_outline,
                                    size: 52, color: AppColors.border),
                                const SizedBox(height: 12),
                                Text(
                                  _searchController.text.isEmpty
                                      ? 'No customers yet.'
                                      : 'No customers match your search.',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              // Select All + Delete row
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 4, 16, 0),
                                child: Row(
                                  children: [
                                    // Delete button
                                    if (_selected.isNotEmpty)
                                      GestureDetector(
                                        onTap: _confirmDelete,
                                        child: Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppColors.error
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                              color: AppColors.error
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                  Icons.delete_outline,
                                                  size: 16,
                                                  color: AppColors.error),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Delete (${_selected.length})',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.error,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                    const Spacer(),

                                    const Text(
                                      'Select All',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Checkbox(
                                        value: _selectAll,
                                        activeColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        onChanged: _toggleSelectAll,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Customer list
                              Expanded(
                                child: ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 8, 16, 16),
                                  itemCount: _visible.length +
                                      (_filtered.length > _pageSize &&
                                              !_showAll
                                          ? 1
                                          : 0),
                                  separatorBuilder: (_, __) =>
                                      const Divider(
                                          color: AppColors.border,
                                          height: 1),
                                  itemBuilder: (context, index) {
                                    if (index == _visible.length) {
                                      return _ShowAllButton(
                                        remaining: _filtered.length -
                                            _pageSize,
                                        onTap: () => setState(
                                            () => _showAll = true),
                                      );
                                    }

                                    final customer = _visible[index];
                                    return _CustomerRow(
                                      customer: customer,
                                      isSelected: _selected
                                          .contains(customer.customerId),
                                      onCheckChanged: (_) =>
                                          _toggleSelect(
                                              customer.customerId),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              CustomerHistoryScreen(
                                            customer: customer,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
              ),
            ],
          ),

          // Loading overlay during delete
          if (_isDeleting)
            Container(
              color: AppColors.overlayModal,
              child: const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Customer row ──────────────────────────────────────────────────────────────

class _CustomerRow extends StatelessWidget {
  final CustomerEntry customer;
  final bool isSelected;
  final ValueChanged<bool?> onCheckChanged;
  final VoidCallback onTap;

  const _CustomerRow({
    required this.customer,
    required this.isSelected,
    required this.onCheckChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            // Checkbox
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: isSelected,
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
                onChanged: onCheckChanged,
              ),
            ),

            const SizedBox(width: 12),

            // Avatar
            _CustomerAvatar(
              name: customer.customerName,
              photoUrl: customer.photoUrl,
            ),

            const SizedBox(width: 12),

            // Name + phone
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.customerName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined,
                          size: 12, color: AppColors.textLight),
                      const SizedBox(width: 4),
                      Text(
                        customer.phone,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Rental count badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${customer.totalRentals}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Customer avatar ───────────────────────────────────────────────────────────

class _CustomerAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;

  const _CustomerAvatar({required this.name, this.photoUrl});

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      backgroundImage:
          photoUrl != null ? NetworkImage(photoUrl!) : null,
      child: photoUrl == null
          ? Text(
              _initials,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            )
          : null,
    );
  }
}

// ── Show all button ───────────────────────────────────────────────────────────

class _ShowAllButton extends StatelessWidget {
  final int remaining;
  final VoidCallback onTap;

  const _ShowAllButton({required this.remaining, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          'Show all customers ($remaining more)',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
