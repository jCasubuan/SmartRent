import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/utils/responsive_helper.dart';
import 'package:smart_rent/core/widgets/action_card.dart';
import 'package:smart_rent/core/widgets/stat_summary_card.dart';
import 'package:smart_rent/screens/admin/cleaning/cleaning_screen.dart';
import 'package:smart_rent/screens/admin/customers/customer_list_screen.dart';
import 'package:smart_rent/screens/admin/gowns/add_gown_screen.dart';
import 'package:smart_rent/screens/admin/gowns/inventory_screen.dart';
import 'package:smart_rent/screens/admin/overdue/overdue_screen.dart';
import 'package:smart_rent/screens/admin/rented/rented_screen.dart';
import 'package:smart_rent/screens/admin/repair/repair_screen.dart';
import 'package:smart_rent/services/stats_service.dart';
import 'package:smart_rent/core/widgets/analytics_card.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(r.s(20), r.s(20), r.s(20), r.s(30)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Greeting row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                'assets/icons/smart_rent_logo.png',
                height: r.s(70),
                fit: BoxFit.contain,
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: r.s(12), vertical: r.s(6)),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMidGrey,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: AppColors.textLight, size: r.s(16)),
                    SizedBox(width: r.s(6)),
                    Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: r.sp(13),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: r.s(10)),
          const _DashboardSubTitle(title: 'Dashboard'),
          SizedBox(height: r.s(10)),

          // ── Live stats card ───────────────────────────────────────────────
          _LiveStatSummaryCard(),

          SizedBox(height: r.s(20)),

          // Action grid
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: r.s(12),
            mainAxisSpacing: r.s(12),
            childAspectRatio: 1.0,
            children: [
              ActionCard(
                label: 'Gowns',
                icon: Image.asset('assets/icons/total_gowns.png', height: r.s(50), width: r.s(50)),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InventoryScreen()),
                ),
              ),
              ActionCard(
                label: 'Customer',
                icon: Image.asset('assets/icons/customer.png', height: r.s(50), width: r.s(50)),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CustomerListScreen()),
                ),
              ),
              ActionCard(
                label: 'Overdue',
                icon: Image.asset('assets/icons/overdue.png', height: r.s(50), width: r.s(50)),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const OverdueScreen()),
                ),
              ),
              ActionCard(
                label: 'Cleaning',
                icon: Image.asset('assets/icons/cleaning.png', height: r.s(50), width: r.s(50)),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CleaningScreen()),
                ),
              ),
              ActionCard(
                label: 'Rented',
                icon: Image.asset('assets/icons/rented.png', height: r.s(50), width: r.s(50)),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RentedScreen()),
                ),
              ),
              ActionCard(
                label: 'Repair',
                icon: Icon(Icons.build_outlined,
                    size: r.s(50), color: AppColors.statusRepair),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RepairScreen()),
                ),
              ),
              ActionCard(
                label: 'Add Gown',
                icon: Image.asset('assets/icons/add_gown.png', height: r.s(50), width: r.s(50)),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddGownScreen()),
                ),
              ),
            ],
          ),

          SizedBox(height: r.s(30)),
          const _DashboardSubTitle(title: 'Analytics'),
          SizedBox(height: r.s(10)),
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
    final r = Responsive(context);
    return Text(
      title,
      style: TextStyle(
        fontSize: r.sp(15),
        fontWeight: FontWeight.w600,
        color: AppColors.textLight,
      ),
    );
  }
}
