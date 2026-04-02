import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/widgets/action_card.dart';
import 'package:smart_rent/core/widgets/stat_summary_card.dart';
import 'package:smart_rent/services/user_service.dart';
import 'package:smart_rent/core/widgets/analytics_card.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  String? _adminName;

  // All stats set to 0 — database ready
  int _totalGowns = 0;
  int _totalCustomers = 0;
  int _totalOverdue = 0;
  int _totalCleaning = 0;
  int _totalRented = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final name = await UserService.getCurrentUserFirstName();
    if (mounted) {
      setState(() {
        _adminName = name;
      });
    }
    // TODO: fetch stats from Firestore via a StatsService in future sprint
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Greeting row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hello, ${_adminName ?? 'Admin'}!',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // TODO: navigate to profile
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: AppColors.textLight,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            _DashboardSubTitle(title: 'Dashboard'),

            const SizedBox(height: 10),

            // Stats summary card
            StatSummaryCard(
              totalGowns: _totalGowns,
              totalCustomers: _totalCustomers,
              totalOverdue: _totalOverdue,
            ),

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
                  onTap: () {
                    // TODO: navigate to gowns inventory
                  },
                ),
                ActionCard(
                  label: 'Customer',
                  icon: Image.asset('assets/icons/customer.png', height: 50, width: 50),
                  onTap: () {
                    // TODO: navigate to customers list
                  },
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
                  onTap: () {
                    // TODO: navigate to add gown screen
                  },
                ),
              ],
            ),

            const SizedBox(height: 30),

            _DashboardSubTitle(title: 'Analytics'),
            const SizedBox(height: 10),
            const AnalyticsCard(),

            // AnalyticsCard(
            //   title: 'Rental Overview',
            //   subtitle: 'This Month',
            //   chart: YourChartWidget(), // pass fl_chart, syncfusion, etc.
            // ),

          ],
        ),
      ),
    );
  }
}

class _DashboardSubTitle extends StatelessWidget{
  final String title;

  const _DashboardSubTitle({
    required this.title,
  });

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