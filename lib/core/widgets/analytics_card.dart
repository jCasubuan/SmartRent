import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';

class AnalyticsCard extends StatelessWidget {
  // Chart widget to render — pass any chart here in future sprint
  final Widget? chart;

  // Title of the analytics section
  final String title;

  // Optional subtitle or date range label
  final String? subtitle;

  const AnalyticsCard({
    super.key,
    this.chart,
    this.title = 'Rental Overview',
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Chart area — shows placeholder if no chart provided
          SizedBox(
            width: double.infinity,
            height: 200,
            child: chart ??
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bar_chart_outlined,
                      size: 48,
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Analytics coming soon',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textLight,
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