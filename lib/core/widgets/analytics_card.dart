import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/utils/price_formatter.dart';
import 'package:smart_rent/core/utils/responsive_helper.dart';
import 'package:smart_rent/services/reports_service.dart';

/// Dashboard analytics summary card.
/// Shows this month's revenue and completed rental count.
/// Tapping navigates to the full Reports tab.
class AnalyticsCard extends StatefulWidget {
  const AnalyticsCard({super.key});

  @override
  State<AnalyticsCard> createState() => _AnalyticsCardState();
}

class _AnalyticsCardState extends State<AnalyticsCard> {
  ReportData? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await ReportsService.getThisMonthSummary();
    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(r.s(20)),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _isLoading
          ? SizedBox(
              height: r.s(80),
              child: const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2.5),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'This Month',
                      style: TextStyle(
                        fontSize: r.sp(14),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      _currentMonthLabel(),
                      style: TextStyle(
                        fontSize: r.sp(11),
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: r.s(16)),

                // Revenue + Completed row
                Row(
                  children: [
                    Expanded(
                      child: _MiniMetric(
                        label: 'Revenue',
                        value: '₱${PriceFormatter.format(_data?.totalRevenue ?? 0)}',
                        icon: Icons.account_balance_wallet_outlined,
                        color: AppColors.rentalApproved,
                      ),
                    ),
                    SizedBox(width: r.s(16)),
                    Expanded(
                      child: _MiniMetric(
                        label: 'Completed',
                        value: '${_data?.completedRentals ?? 0}',
                        icon: Icons.check_circle_outline,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: r.s(16)),
                    Expanded(
                      child: _MiniMetric(
                        label: 'Penalties',
                        value: '₱${PriceFormatter.format(_data?.totalPenalties ?? 0)}',
                        icon: Icons.warning_amber_outlined,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  String _currentMonthLabel() {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.year}';
  }
}

// ── Mini metric widget ────────────────────────────────────────────────────────

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Column(
      children: [
        Icon(icon, color: color, size: r.s(22)),
        SizedBox(height: r.s(6)),
        Text(
          value,
          style: TextStyle(
            fontSize: r.sp(13),
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: r.s(2)),
        Text(
          label,
          style: TextStyle(
            fontSize: r.sp(10),
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }
}
