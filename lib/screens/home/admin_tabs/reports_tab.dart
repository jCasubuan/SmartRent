import 'dart:math';

import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/utils/price_formatter.dart';
import 'package:smart_rent/core/utils/responsive_helper.dart';
import 'package:smart_rent/services/reports_service.dart';

/// Admin reports tab — shows revenue analytics from completed rentals.
/// Three dropdowns: Year → Month → Week, all dynamic from data.
class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  List<int> _years = [];
  int? _selectedYear;

  List<_MonthOption> _allMonths = [];
  List<_MonthOption> _filteredMonths = [];
  _MonthOption? _selectedMonth;

  String _selectedWeek = 'All Weeks';
  List<String> _weekOptions = ['All Weeks'];

  ReportData? _data;
  bool _isLoading = true;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final dates = await ReportsService.getAllCompletedDates();
    if (!mounted) return;

    final months = _buildMonthList(dates);
    final years = months.map((m) => m.year).toSet().toList()..sort();

    final now = DateTime.now();
    final currentYear = now.year;

    setState(() {
      _allMonths = months;
      _years = years.isEmpty ? [currentYear] : years;
      _selectedYear = _years.last;
      _isInitializing = false;
    });

    _updateMonthsForYear();
    _updateWeekOptions();
    _loadReport();
  }

  /// Builds list of months from the earliest transaction to current month.
  List<_MonthOption> _buildMonthList(List<DateTime> dates) {
    final now = DateTime.now();
    if (dates.isEmpty) {
      return [_MonthOption(year: now.year, month: now.month)];
    }

    final earliest = dates.reduce((a, b) => a.isBefore(b) ? a : b);
    final List<_MonthOption> months = [];
    var cursor = DateTime(earliest.year, earliest.month);
    final end = DateTime(now.year, now.month);

    while (!cursor.isAfter(end)) {
      months.add(_MonthOption(year: cursor.year, month: cursor.month));
      cursor = DateTime(cursor.year, cursor.month + 1);
    }

    return months;
  }

  void _updateMonthsForYear() {
    if (_selectedYear == null) return;
    final filtered =
        _allMonths.where((m) => m.year == _selectedYear).toList();

    setState(() {
      _filteredMonths = filtered;
      _selectedMonth = filtered.isNotEmpty ? filtered.last : null;
    });
  }

  void _updateWeekOptions() {
    if (_selectedMonth == null) {
      setState(() {
        _weekOptions = ['All Weeks'];
        _selectedWeek = 'All Weeks';
      });
      return;
    }

    final daysInMonth = DateTime(
      _selectedMonth!.year,
      _selectedMonth!.month + 1,
      0,
    ).day;

    final weekCount = (daysInMonth / 7).ceil();
    final options = <String>['All Weeks'];
    for (int i = 1; i <= weekCount; i++) {
      final startDay = (i - 1) * 7 + 1;
      final endDay = (i * 7).clamp(1, daysInMonth);
      options.add('Week $i ($startDay-$endDay)');
    }

    setState(() {
      _weekOptions = options;
      _selectedWeek = 'All Weeks';
    });
  }

  Future<void> _loadReport() async {
    if (_selectedMonth == null) return;
    setState(() => _isLoading = true);

    final year = _selectedMonth!.year;
    final month = _selectedMonth!.month;

    late DateTime from;
    late DateTime to;

    if (_selectedWeek == 'All Weeks') {
      from = DateTime(year, month, 1);
      to = DateTime(year, month + 1, 0, 23, 59, 59);
    } else {
      final weekNum = int.parse(_selectedWeek.split(' ')[1]);
      final startDay = (weekNum - 1) * 7 + 1;
      final daysInMonth = DateTime(year, month + 1, 0).day;
      final endDay = (weekNum * 7).clamp(1, daysInMonth);
      from = DateTime(year, month, startDay);
      to = DateTime(year, month, endDay, 23, 59, 59);
    }

    final data = await ReportsService.getReport(from: from, to: to);
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
    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceGrey,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Reports',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: r.sp(18),
          ),
        ),
      ),
      body: _isInitializing
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(r.s(16), r.s(8), r.s(16), r.s(32)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dropdowns row
                  Row(
                    children: [
                      // Year dropdown
                      Expanded(
                        flex: 2,
                        child: _DropdownChip(
                          value: '${_selectedYear ?? DateTime.now().year}',
                          items: _years.map((y) => '$y').toList(),
                          onChanged: (val) {
                            setState(() => _selectedYear = int.parse(val));
                            _updateMonthsForYear();
                            _updateWeekOptions();
                            _loadReport();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Month dropdown
                      Expanded(
                        flex: 3,
                        child: _DropdownChip(
                          value: _selectedMonth?.monthLabel ?? '',
                          items: _filteredMonths
                              .map((m) => m.monthLabel)
                              .toList(),
                          onChanged: (val) {
                            final selected = _filteredMonths
                                .firstWhere((m) => m.monthLabel == val);
                            setState(() => _selectedMonth = selected);
                            _updateWeekOptions();
                            _loadReport();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Week dropdown
                      Expanded(
                        flex: 4,
                        child: _DropdownChip(
                          value: _selectedWeek,
                          items: _weekOptions,
                          onChanged: (val) {
                            setState(() => _selectedWeek = val);
                            _loadReport();
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Revenue Overview ─────────────────────────────────────
                  const _SectionTitle(title: 'Revenue Overview'),
                  const SizedBox(height: 10),

                  // Chart card
                  _isLoading
                      ? const SizedBox(
                          height: 220,
                          child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary),
                          ),
                        )
                      : _ChartCard(data: _data!),

                  const SizedBox(height: 24),

                  // ── Key Metrics ────────────────────────────────────────────
                  if (!_isLoading && _data != null) ...[
                    const _SectionTitle(title: 'Key Metrics'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            title: 'Total Revenue',
                            value:
                                '₱${PriceFormatter.format(_data!.totalRevenue)}',
                            icon: Icons.account_balance_wallet_outlined,
                            color: AppColors.rentalApproved,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            title: 'Completed',
                            value: '${_data!.completedRentals}',
                            icon: Icons.check_circle_outline,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            title: 'Penalties',
                            value:
                                '₱${PriceFormatter.format(_data!.totalPenalties)}',
                            icon: Icons.warning_amber_outlined,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            title: 'Avg. Rental',
                            value:
                                '₱${PriceFormatter.format(_data!.averageRentalValue)}',
                            icon: Icons.trending_up_outlined,
                            color: AppColors.statusCleaning,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // ── Top Performing Gowns ───────────────────────────────────
                  if (!_isLoading &&
                      _data != null &&
                      _data!.gownRentalCounts.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const _SectionTitle(title: 'Top Performing Clothing'),
                    const SizedBox(height: 10),
                    _MostRentedSection(
                        gownCounts: _data!.gownRentalCounts),
                  ],
                ],
              ),
            ),
    );
  }
}

// ── Section title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

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

// ── Month option model ────────────────────────────────────────────────────────

class _MonthOption {
  final int year;
  final int month;

  const _MonthOption({required this.year, required this.month});

  /// Full label with year (e.g., "January 2026")
  String get label {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[month - 1]} $year';
  }

  /// Month name only (e.g., "January")
  String get monthLabel {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month - 1];
  }
}

// ── Dropdown chip ─────────────────────────────────────────────────────────────

class _DropdownChip extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _DropdownChip({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Guard: if value isn't in items, use first item
    final effectiveValue =
        items.contains(value) ? value : (items.isNotEmpty ? items.first : '');

    if (items.isEmpty || effectiveValue.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          '—',
          style: TextStyle(fontSize: 13, color: AppColors.textLight),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveValue,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down,
              color: AppColors.primary, size: 18),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      item,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// ── Chart card ────────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final ReportData data;
  const _ChartCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₱${PriceFormatter.format(data.totalRevenue)}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: data.revenueByDay.isEmpty
                ? const Center(
                    child: Text(
                      'No completed rentals in this period.',
                      style:
                          TextStyle(fontSize: 13, color: AppColors.textLight),
                    ),
                  )
                : _BarChart(revenueByDay: data.revenueByDay),
          ),
        ],
      ),
    );
  }
}

// ── Bar chart ─────────────────────────────────────────────────────────────────

class _BarChart extends StatelessWidget {
  final Map<String, double> revenueByDay;
  const _BarChart({required this.revenueByDay});

  @override
  Widget build(BuildContext context) {
    final entries = revenueByDay.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Show ALL entries — scrollable horizontally
    final visible = entries;

    final maxVal =
        visible.fold<double>(0, (m, e) => e.value > m ? e.value : m);

    // Calculate nice Y-axis steps
    final yMax = maxVal == 0 ? 1000.0 : _niceMax(maxVal);
    final steps = 5;
    final stepValue = yMax / steps;

    // Fixed width per bar — ensures readability
    const double barWidth = 48.0;
    final chartWidth = visible.length * barWidth;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Y-axis labels (fixed, doesn't scroll)
        SizedBox(
          width: 40,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(steps + 1, (i) {
              final value = yMax - (i * stepValue);
              return Text(
                _shortValue(value),
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textLight,
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 8),
        // Scrollable chart area
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: chartWidth < 200 ? 200 : chartWidth,
              child: Stack(
                children: [
                  // Grid lines
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(steps + 1, (i) {
                      return Container(
                        height: 1,
                        color: AppColors.border.withValues(alpha: 0.5),
                      );
                    }),
                  ),
                  // Bars
                  Positioned.fill(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: visible.map((entry) {
                        final ratio = yMax > 0 ? entry.value / yMax : 0.0;
                        final label = _formatDayLabel(entry.key);

                        return SizedBox(
                          width: barWidth,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  _shortValue(entry.value),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.textMid,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Flexible(
                                  child: FractionallySizedBox(
                                    heightFactor: ratio.clamp(0.02, 1.0),
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.textLight,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Rounds up to a nice round number for the Y-axis max.
  double _niceMax(double value) {
    if (value <= 0) return 1000;
    final magnitude = _pow10(log(value) ~/ ln10);
    final normalized = value / magnitude;
    double nice;
    if (normalized <= 1) {
      nice = 1;
    } else if (normalized <= 2) {
      nice = 2;
    } else if (normalized <= 5) {
      nice = 5;
    } else {
      nice = 10;
    }
    return nice * magnitude;
  }

  double _pow10(int exp) {
    double result = 1;
    if (exp >= 0) {
      for (int i = 0; i < exp; i++) {
        result *= 10;
      }
    } else {
      for (int i = 0; i < -exp; i++) {
        result /= 10;
      }
    }
    return result;
  }

  String _formatDayLabel(String dateKey) {
    try {
      final parts = dateKey.split('-');
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[month - 1]} $day';
    } catch (_) {
      return dateKey;
    }
  }

  String _shortValue(double val) {
    if (val >= 1000000) return '${(val / 1000000).toStringAsFixed(1)}M';
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(1)}k';
    return val.toStringAsFixed(0);
  }
}

// ── Metric card ───────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Most Rented Gowns section ─────────────────────────────────────────────────

class _MostRentedSection extends StatefulWidget {
  final List<GownRentalCount> gownCounts;
  const _MostRentedSection({required this.gownCounts});

  @override
  State<_MostRentedSection> createState() => _MostRentedSectionState();
}

class _MostRentedSectionState extends State<_MostRentedSection> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final all = widget.gownCounts;
    final visible = _showAll ? all : all.take(5).toList();
    final maxCount =
        all.isNotEmpty ? all.first.count : 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Most Rented Gowns',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                '${all.length} gown${all.length != 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Gown list with horizontal bars
          ...visible.asMap().entries.map((entry) {
            final index = entry.key;
            final gown = entry.value;
            final ratio = maxCount > 0 ? gown.count / maxCount : 0.0;

            return Padding(
              padding: EdgeInsets.only(bottom: index < visible.length - 1 ? 12 : 0),
              child: Row(
                children: [
                  // Rank number
                  SizedBox(
                    width: 20,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: index < 3
                            ? AppColors.primary
                            : AppColors.textLight,
                      ),
                    ),
                  ),

                  // Gown image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: gown.gownImageUrl.isNotEmpty
                        ? Image.network(
                            gown.gownImageUrl,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                _miniPlaceholder(),
                          )
                        : _miniPlaceholder(),
                  ),

                  const SizedBox(width: 10),

                  // Name + bar
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gown.gownName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Horizontal bar
                        Stack(
                          children: [
                            Container(
                              height: 8,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceGrey,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: ratio.clamp(0.05, 1.0),
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: index < 3
                                      ? AppColors.primary
                                      : AppColors.primary
                                          .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Count + earnings
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${gown.count}x',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        '₱${PriceFormatter.format(gown.totalEarnings)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          // See More / See Less button
          if (all.length > 5) ...[
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: () => setState(() => _showAll = !_showAll),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _showAll ? 'See Less' : 'See More',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniPlaceholder() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surfaceGrey,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.checkroom_outlined,
          color: AppColors.border, size: 18),
    );
  }
}
