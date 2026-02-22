import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_localizations.dart';
import '../../models/plan.dart';
import '../../view_models/plan_view_model.dart';
import '../../view_models/brand_view_model.dart';
import '../../models/brand.dart';
import '../../widgets/day_detail_sheet.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  bool _isMonthlyView = true;
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String? _selectedBrandId; // null = all brands
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlanViewModel>().loadAllCalendar();
    });
  }

  // ─── Month helpers ────────────────────────────────────────────────────────

  String get _monthLabel {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[_currentMonth.month - 1]} ${_currentMonth.year}';
  }

  void _prevMonth() => setState(() {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      });

  void _nextMonth() => setState(() {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      });

  // ─── Entry filters ────────────────────────────────────────────────────────

  List<CalendarEntry> _filtered(List<CalendarEntry> all) {
    if (_selectedBrandId == null) return all;
    return all.where((e) => e.brandId == _selectedBrandId).toList();
  }

  /// Returns a map of day-of-month → entries for the current month view.
  Map<int, List<CalendarEntry>> _monthEntries(List<CalendarEntry> entries) {
    final result = <int, List<CalendarEntry>>{};
    for (final e in entries) {
      if (e.scheduledDate.year == _currentMonth.year &&
          e.scheduledDate.month == _currentMonth.month) {
        result.putIfAbsent(e.scheduledDate.day, () => []).add(e);
      }
    }
    return result;
  }

  /// Returns entries for the current ISO week relative to today (Mon–Sun).
  List<CalendarEntry> _weekEntries(List<CalendarEntry> entries) {
    final now = DateTime.now();
    // Monday of current week
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    return entries.where((e) {
      final d = e.scheduledDate;
      return !d.isBefore(DateTime(monday.year, monday.month, monday.day)) &&
          !d.isAfter(DateTime(sunday.year, sunday.month, sunday.day, 23, 59));
    }).toList();
  }

  // ─── Brand color ──────────────────────────────────────────────────────────

  static const _palette = [
    Color(0xFFFF6B6B),
    Color(0xFF6BCB77),
    Color(0xFF4D96FF),
    Color(0xFFFFD93D),
    Color(0xFFC77DFF),
    Color(0xFFFF9F43),
    Color(0xFF00CFDD),
  ];

  Color _brandColor(String brandId) =>
      _palette[brandId.codeUnits.fold(0, (a, b) => a + b) % _palette.length];

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlanViewModel, BrandViewModel>(
      builder: (context, planVm, brandVm, _) {
        final filtered = _filtered(planVm.allCalendarEntries);

        return Scaffold(
          key: _scaffoldKey,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                _buildFilters(context, brandVm),
                if (_isMonthlyView) _buildSmartRotationBanner(context),
                if (planVm.isLoading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (planVm.error != null)
                  _buildError(context, planVm)
                else
                  Expanded(
                    child: _isMonthlyView
                        ? _buildMonthlyGrid(
                            context, filtered, planVm.plans, brandVm.brands)
                        : _buildWeeklyListView(context, filtered, brandVm),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          // Month navigation
          GestureDetector(
            onTap: _prevMonth,
            child: Icon(Icons.chevron_left_rounded, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              _monthLabel,
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ),
          GestureDetector(
            onTap: _nextMonth,
            child: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          // View toggle
          _ViewToggleBtn(
            label: 'MO',
            isActive: _isMonthlyView,
            onTap: () => setState(() => _isMonthlyView = true),
          ),
          const SizedBox(width: 4),
          _ViewToggleBtn(
            label: 'WK',
            isActive: !_isMonthlyView,
            onTap: () => setState(() => _isMonthlyView = false),
          ),
          const SizedBox(width: 12),
          // Menu
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                border: Border.all(color: cs.outlineVariant),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.menu_rounded, size: 20, color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Filters ──────────────────────────────────────────────────────────────

  Widget _buildFilters(BuildContext context, BrandViewModel brandVm) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _FilterChip(
            label: context.tr('cal_all_brands'),
            color: cs.primary,
            isActive: _selectedBrandId == null,
            onTap: () => setState(() => _selectedBrandId = null),
          ),
          ...brandVm.brands.map((brand) {
            final color = _brandColor(brand.id ?? brand.name);
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _FilterChip(
                label: brand.name,
                color: color,
                isActive: _selectedBrandId == (brand.id ?? brand.name),
                onTap: () =>
                    setState(() => _selectedBrandId = brand.id ?? brand.name),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Smart Rotation Banner ────────────────────────────────────────────────

  Widget _buildSmartRotationBanner(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: 0.06),
            cs.secondary.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Text('🔄', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('cal_smart_rotation'),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface)),
                Text(context.tr('cal_ai_spacing'),
                    style:
                        TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(context.tr('cal_on'),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: cs.primary)),
          ),
        ],
      ),
    );
  }

  // ─── Monthly Grid ─────────────────────────────────────────────────────────

  Widget _buildMonthlyGrid(
    BuildContext context,
    List<CalendarEntry> entries,
    List<Plan> plans,
    List<Brand> brands,
  ) {
    final cs = Theme.of(context).colorScheme;
    final byDay = _monthEntries(entries);

    // Day-of-week header
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    // First weekday of month (1=Mon … 7=Sun)
    final firstWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;
    final daysInMonth =
        DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final leadingBlanks = firstWeekday - 1; // 0-based blanks before day 1
    final totalCells = leadingBlanks + daysInMonth;
    final rows = (totalCells / 7).ceil();

    final today = DateTime.now();
    final isCurrentMonth = today.year == _currentMonth.year &&
        today.month == _currentMonth.month;

    return Column(
      children: [
        // Day-of-week row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: dayLabels
                .map((l) => Expanded(
                      child: Center(
                        child: Text(l,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant)),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.82,
            ),
            itemCount: rows * 7,
            itemBuilder: (context, index) {
              final dayNum = index - leadingBlanks + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const SizedBox();
              }

              final isToday =
                  isCurrentMonth && dayNum == today.day;
              final dayEntries = byDay[dayNum] ?? [];

              // Collect unique brand colors for this day (max 3 dots)
              final colors = dayEntries
                  .map((e) => _brandColor(e.brandId))
                  .toSet()
                  .take(3)
                  .toList();

              return GestureDetector(
                onTap: () {
                  final selectedDate = DateTime(
                      _currentMonth.year, _currentMonth.month, dayNum);
                  showDayDetailSheet(
                    context,
                    date: selectedDate,
                    entries: dayEntries,
                    plans: plans,
                    brands: brands,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isToday
                        ? cs.primary.withValues(alpha: 0.08)
                        : null,
                    border: Border.all(
                        color: isToday
                            ? cs.primary.withValues(alpha: 0.3)
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 11,
                          color: isToday
                              ? cs.primary
                              : cs.onSurfaceVariant,
                          fontWeight: isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (colors.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: colors
                              .map((c) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 1),
                                    child: _CalDot(color: c),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Weekly List View ─────────────────────────────────────────────────────

  Widget _buildWeeklyListView(BuildContext context,
      List<CalendarEntry> entries, BrandViewModel brandVm) {
    final cs = Theme.of(context).colorScheme;
    final weekEntries = _weekEntries(entries);

    if (weekEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(context.tr('cal_no_posts'),
                style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(context.tr('cal_activate_plan'),
                style: TextStyle(
                    fontSize: 12, color: cs.onSurfaceVariant.withValues(alpha: 0.7))),
          ],
        ),
      );
    }

    // Group by day key "MONDAY, FEB 16"
    final grouped = <String, List<CalendarEntry>>{};
    for (final entry in weekEntries) {
      final key = _dayKey(entry.scheduledDate);
      grouped.putIfAbsent(key, () => []).add(entry);
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final da = grouped[a]!.first.scheduledDate;
        final db = grouped[b]!.first.scheduledDate;
        return da.compareTo(db);
      });

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
      children: [
        for (final key in sortedKeys) ...[
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              key,
              style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600),
            ),
          ),
          ...grouped[key]!.map((entry) {
            final color = _brandColor(entry.brandId);
            // Find brand name
            final brand = brandVm.brands
                .cast<Brand?>()
                .firstWhere((b) => b?.id == entry.brandId || b?.name == entry.brandId,
                    orElse: () => null);
            return _PostCard(
              brandColor: color,
              title: entry.title ?? 'Untitled Post',
              meta: [
                if (entry.format != null) entry.format!.label,
                entry.platform,
                if (entry.pillar != null) entry.pillar!,
              ].join(' · '),
              status: entry.status.label,
              statusColor: _statusColor(entry.status, cs),
              scheduledTime: entry.scheduledTime,
              brandName: brand?.name,
            );
          }),
        ],
      ],
    );
  }

  // ─── Error ────────────────────────────────────────────────────────────────

  Widget _buildError(BuildContext context, PlanViewModel vm) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined,
                  size: 48, color: cs.error.withValues(alpha: 0.7)),
              const SizedBox(height: 12),
              Text(context.tr('cal_load_error'),
                  style: TextStyle(
                      color: cs.onSurface, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(vm.error ?? 'Unknown error',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurfaceVariant)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: vm.loadAllCalendar,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(context.tr('retry')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _dayKey(DateTime date) {
    const weekdays = [
      'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'
    ];
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  Color _statusColor(CalendarEntryStatus status, ColorScheme cs) {
    switch (status) {
      case CalendarEntryStatus.published:
        return Colors.green;
      case CalendarEntryStatus.cancelled:
        return cs.error;
      case CalendarEntryStatus.scheduled:
        return cs.primary;
    }
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _ViewToggleBtn extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ViewToggleBtn(
      {required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? cs.primary.withValues(alpha: 0.1)
              : cs.surfaceContainerHighest,
          border: Border.all(
              color: isActive ? cs.primary : cs.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? cs.primary : cs.onSurfaceVariant,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback? onTap;

  const _FilterChip({
    required this.label,
    required this.color,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.12) : cs.surfaceContainerHighest,
          border: Border.all(
              color: isActive ? color : cs.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 7,
                height: 7,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: isActive ? color : cs.onSurfaceVariant,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

class _CalDot extends StatelessWidget {
  final Color color;
  const _CalDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}

class _PostCard extends StatelessWidget {
  final Color brandColor;
  final String title;
  final String meta;
  final String status;
  final Color statusColor;
  final String? scheduledTime;
  final String? brandName;

  const _PostCard({
    required this.brandColor,
    required this.title,
    required this.meta,
    required this.status,
    required this.statusColor,
    this.scheduledTime,
    this.brandName,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
                color: brandColor,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(meta,
                    style: TextStyle(
                        fontSize: 10, color: cs.onSurfaceVariant)),
                if (scheduledTime != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 10,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
                      const SizedBox(width: 3),
                      Text(scheduledTime!,
                          style: TextStyle(
                              fontSize: 10,
                              color: cs.onSurfaceVariant
                                  .withValues(alpha: 0.7))),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: statusColor),
            ),
          ),
        ],
      ),
    );
  }
}
