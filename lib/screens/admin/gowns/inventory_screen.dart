import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/models/gown_model.dart';
import 'package:smart_rent/core/utils/price_formatter.dart';
import 'package:smart_rent/services/gown_service.dart';
import 'package:smart_rent/screens/admin/gowns/gown_detail_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();

  List<GownModel> _gowns = [];
  List<GownModel> _filteredGowns = [];
  bool _isLoading = true;
  int _totalGowns = 0;
  int _availableGowns = 0;

  String _sortBy = 'addedAt';
  bool _sortDescending = true;
  String _sortLabel = 'Newest First';

  @override
  void initState() {
    super.initState();
    _loadGowns();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGowns() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      GownService.getGownsFiltered(
        sortBy: _sortBy,
        descending: _sortDescending,
      ),
      GownService.getAvailableCount(),
    ]);

    if (mounted) {
      setState(() {
        _gowns = results[0] as List<GownModel>;
        _filteredGowns = _gowns;
        _totalGowns = _gowns.length;
        _availableGowns = results[1] as int;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredGowns = _gowns.where((g) {
        return g.name.toLowerCase().contains(query) ||
            g.category.toLowerCase().contains(query) ||
            g.color.toLowerCase().contains(query) ||
            g.code.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final options = [
          {'label': 'Newest First', 'sortBy': 'addedAt', 'desc': true},
          {'label': 'Oldest First', 'sortBy': 'addedAt', 'desc': false},
          {'label': 'Name A-Z', 'sortBy': 'name', 'desc': false},
          {'label': 'Name Z-A', 'sortBy': 'name', 'desc': true},
          {'label': 'Price Low-High', 'sortBy': 'rentalPrice', 'desc': false},
          {'label': 'Price High-Low', 'sortBy': 'rentalPrice', 'desc': true},
        ];

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sort By',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              ...options.map((option) {
                final isSelected = _sortLabel == option['label'];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    option['label'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textDark,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _sortBy = option['sortBy'] as String;
                      _sortDescending = option['desc'] as bool;
                      _sortLabel = option['label'] as String;
                    });
                    _loadGowns();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Inventory',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Stats row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                _StatCard(
                  label: 'TOTAL GOWNS',
                  value: _isLoading ? '-' : '$_totalGowns',
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'AVAILABLE',
                  value: _isLoading ? '-' : '$_availableGowns',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Search bar + sort button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
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
                      decoration: const InputDecoration(
                        hintText: 'Search by name, category, color...',
                        hintStyle: TextStyle(
                            color: AppColors.textLight, fontSize: 13),
                        prefixIcon: Icon(Icons.search,
                            color: AppColors.textLight, size: 20),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _showSortSheet,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.sort,
                      color: AppColors.textDark,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Gown grid
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : _filteredGowns.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty
                              ? 'No gowns in inventory yet.'
                              : 'No gowns match your search.',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textLight,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadGowns,
                        color: AppColors.primary,
                        child: GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.62,
                          ),
                          itemCount: _filteredGowns.length,
                          itemBuilder: (context, index) {
                            return _GownCard(gown: _filteredGowns[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// Stats card widget
class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textLight,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Gown card widget
class _GownCard extends StatelessWidget {
  final GownModel gown;

  const _GownCard({required this.gown});

  Color _statusColor(String status) => AppColors.gownStatusColor(status);
  String _statusLabel(String status) => AppColors.gownStatusLabel(status);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
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
          // Image with status badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: gown.imageUrls.isNotEmpty
                    ? Image.network(
                        gown.imageUrls.first,
                        width: double.infinity,
                        height: 140,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
              // ClipRRect(
              //   borderRadius: const BorderRadius.vertical(
              //     top: Radius.circular(12),
              //   ),
              //   child: gown.imageUrls.isNotEmpty
              //       ? Container(
              //           width: double.infinity,
              //           height: 140,
              //           color: const Color(0xFFF5F5F5), // ← background for letterbox areas
              //           child: Image.network(
              //             gown.imageUrls.first,
              //             width: double.infinity,
              //             height: 140,
              //             fit: BoxFit.contain, // ← was BoxFit.cover
              //             errorBuilder: (_, __, ___) => _imagePlaceholder(),
              //           ),
              //         )
              //       : _imagePlaceholder(),
              // ),
              // Status badge
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(gown.status),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _statusLabel(gown.status),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.defaultForeground,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Gown info
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gown.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '₱${PriceFormatter.format(gown.rentalPrice)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Category: ${gown.category}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Color: ${gown.color}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const Spacer(),

          // View Details button
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: SizedBox(
              width: double.infinity,
              height: 32,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GownDetailScreen(gown: gown),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.defaultForeground,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'View Details',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 140,
      color: AppColors.surfaceGrey,
      child: const Icon(
        Icons.checkroom_outlined,
        color: AppColors.border,
        size: 40,
      ),
    );
  }
}