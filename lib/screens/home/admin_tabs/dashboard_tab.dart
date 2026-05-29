import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/widgets/action_card.dart';
import 'package:smart_rent/core/widgets/stat_summary_card.dart';
import 'package:smart_rent/screens/admin/customers/customer_list_screen.dart';
import 'package:smart_rent/screens/admin/gowns/add_gown_screen.dart';
import 'package:smart_rent/screens/admin/gowns/inventory_screen.dart';
import 'package:smart_rent/services/stats_service.dart';
import 'package:smart_rent/core/widgets/analytics_card.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Greeting row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                'assets/icons/smart_rent_logo.png',
                height: 70,
                fit: BoxFit.contain,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMidGrey,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.person_outline, color: AppColors.textLight, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const _DashboardSubTitle(title: 'Dashboard'),
          const SizedBox(height: 10),

          // ── Live stats card ───────────────────────────────────────────────
          // Three independent StreamBuilders so each counter updates
          // independently without rebuilding the whole widget tree.
          _LiveStatSummaryCard(),

          const SizedBox(height: 20),

          // Action grid
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
            children: [
              ActionCard(
                label: 'Gowns',
                icon: Image.asset('assets/icons/total_gowns.png', height: 50, width: 50),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InventoryScreen()),
                ),
              ),
              ActionCard(
                label: 'Customer',
                icon: Image.asset('assets/icons/customer.png', height: 50, width: 50),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CustomerListScreen()),
                ),
              ),
              ActionCard(
                label: 'Overdue',
                icon: Image.asset('assets/icons/overdue.png', height: 50, width: 50),
                onTap: () {
                  // TODO: navigate to overdue list
                },
              ),
              ActionCard(
                label: 'Cleaning',
                icon: Image.asset('assets/icons/cleaning.png', height: 50, width: 50),
                onTap: () {
                  // TODO: navigate to cleaning list
                },
              ),
              ActionCard(
                label: 'Rented',
                icon: Image.asset('assets/icons/rented.png', height: 50, width: 50),
                onTap: () {
                  // TODO: navigate to rented list
                },
              ),
              ActionCard(
                label: 'Add Gown',
                icon: Image.asset('assets/icons/add_gown.png', height: 50, width: 50),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddGownScreen()),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),
          const _DashboardSubTitle(title: 'Analytics'),
          const SizedBox(height: 10),
          const AnalyticsCard(),
        ],
      ),
    );
  }
}

// ── Live stat summary card ────────────────────────────────────────────────────
// Wraps StatSummaryCard with three independent streams so each number
// updates in real time without a full page rebuild.

class _LiveStatSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: StatsService.totalGownsStream(),
      builder: (context, gownsSnap) {
        return StreamBuilder<int>(
          stream: StatsService.totalCustomersStream(),
          builder: (context, customersSnap) {
            return StreamBuilder<int>(
              stream: StatsService.totalOverdueStream(),
              builder: (context, overdueSnap) {
                return StatSummaryCard(
                  totalGowns: gownsSnap.data ?? 0,
                  totalCustomers: customersSnap.data ?? 0,
                  totalOverdue: overdueSnap.data ?? 0,
                );
              },
            );
          },
        );
      },
    );
  }
}

// ── Section subtitle ──────────────────────────────────────────────────────────

class _DashboardSubTitle extends StatelessWidget {
  final String title;

  const _DashboardSubTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textLight,
      ),
    );
  }
}
