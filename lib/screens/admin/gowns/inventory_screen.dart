import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/models/gown_model.dart';
import 'package:smart_rent/core/widgets/gown_card.dart';
import 'package:smart_rent/services/gown_service.dart';
import 'package:smart_rent/screens/admin/gowns/gown_detail_screen.dart';

/// Admin inventory screen — live stream of all gowns.
/// Search and sort are applied client-side on the streamed data.
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  String _sortBy = 'addedAt';
  bool _sortDescending = true;
  String _sortLabel = 'Newest First';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase().trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Sort + filter applied to the live stream data ─────────────────────────

  List<GownModel> _applySort(List<GownModel> gowns) {
    final sorted = List<GownModel>.from(gowns);
    sorted.sort((a, b) {
      int cmp;
      switch (_sortBy) {
        case 'name':
          cmp = a.name.compareTo(b.name);
        case 'rentalPrice':
          cmp = a.rentalPrice.compareTo(b.rentalPrice);
        default: // addedAt
          final aAt = a.addedAt ?? DateTime(2000);
          final bAt = b.addedAt ?? DateTime(2000);
          cmp = aAt.compareTo(bAt);
      }
      return _sortDescending ? -cmp : cmp;
    });
    return sorted;
  }

  List<GownModel> _applySearch(List<GownModel> gowns) {
    if (_searchQuery.isEmpty) return gowns;
    return gowns.where((g) {
      return g.name.toLowerCase().contains(_searchQuery) ||
          g.category.toLowerCase().contains(_searchQuery) ||
          g.color.toLowerCase().contains(_searchQuery) ||
          g.code.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final options = [
          {'label': 'Newest First',    'sortBy': 'addedAt',      'desc': true},
          {'label': 'Oldest First',    'sortBy': 'addedAt',      'desc': false},
          {'label': 'Name A-Z',        'sortBy': 'name',         'desc': false},
          {'label': 'Name Z-A',        'sortBy': 'name',         'desc': true},
          {'label': 'Price Low-High',  'sortBy': 'rentalPrice',  'desc': false},
          {'label': 'Price High-Low',  'sortBy': 'rentalPrice',  'desc': true},
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
                      color: isSelected ? AppColors.primary : AppColors.textDark,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
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
      body: StreamBuilder<List<GownModel>>(
        stream: GownService.gownsStream(),
        builder: (context, snapshot) {
          // ── Loading (first frame only) ────────────────────────────────────
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          // ── Error ─────────────────────────────────────────────────────────
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.wifi_off_outlined, size: 52, color: AppColors.border),
                    SizedBox(height: 16),
                    Text(
                      'No internet connection',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please check your connection and try again.',
                      style: TextStyle(fontSize: 13, color: AppColors.textMid, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // ── Data ──────────────────────────────────────────────────────────
          final allGowns = snapshot.data ?? [];
          final sorted = _applySort(allGowns);
          final visible = _applySearch(sorted);

          final totalGowns = allGowns.length;
          final availableGowns =
              allGowns.where((g) => g.status == 'available').length;

          return Column(
            children: [
              // Stats row
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    _StatCard(label: 'TOTAL GOWNS', value: '$totalGowns'),
                    const SizedBox(width: 12),
                    _StatCard(label: 'AVAILABLE', value: '$availableGowns'),
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
                          color: AppColors.surfaceGrey,
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
                child: visible.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No gowns in inventory yet.'
                              : 'No gowns match your search.',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textLight,
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 270,
                        ),
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final gown = visible[index];
                          return GownCard(
                            gown: gown,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GownDetailScreen(gown: gown),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Stats card ────────────────────────────────────────────────────────────────

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
          color: AppColors.surfaceGrey,
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
