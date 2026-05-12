import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/plan.dart';

class ContentCalendarWidget extends StatefulWidget {
  final List<CalendarEntry> entries;
  const ContentCalendarWidget({super.key, required this.entries});

  @override
  State<ContentCalendarWidget> createState() => _ContentCalendarWidgetState();
}

class _ContentCalendarWidgetState extends State<ContentCalendarWidget> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildWeekDays(),
          const SizedBox(height: 12),
          _buildDaysGrid(),
          const SizedBox(height: 24),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          DateFormat('MMMM yyyy').format(_focusedDay),
          style: GoogleFonts.syne(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111111),
          ),
        ),
        Row(
          children: [
            _navBtn(Icons.chevron_left, () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1))),
            const SizedBox(width: 8),
            _navBtn(Icons.chevron_right, () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1))),
          ],
        ),
      ],
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF6D4ED3)),
      ),
    );
  }

  Widget _buildWeekDays() {
    final days = ['DIM', 'LUN', 'MAR', 'MER', 'JEU', 'VEN', 'SAM'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((d) => Expanded(
        child: Center(
          child: Text(
            d,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF9090B0),
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildDaysGrid() {
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final daysInMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 for Sunday

    final days = <Widget>[];
    for (int i = 0; i < firstWeekday; i++) {
      days.add(const SizedBox());
    }

    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(_focusedDay.year, _focusedDay.month, i);
      final isToday = DateUtils.isSameDay(date, DateTime.now());
      final isSelected = DateUtils.isSameDay(date, _selectedDay);
      final entries = widget.entries.where((e) => DateUtils.isSameDay(e.scheduledDate, date)).toList();

      days.add(
        GestureDetector(
          onTap: () => setState(() => _selectedDay = date),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF6D4ED3) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$i',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : (isToday ? const Color(0xFF6D4ED3) : const Color(0xFF111111)),
                  ),
                ),
                if (entries.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: entries.take(3).map((e) => Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getPlatformColor(e.platform),
                      ),
                    )).toList(),
                  )
                else
                  const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 7,
      physics: const NeverScrollableScrollPhysics(),
      children: days,
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem('Instagram', const Color(0xFFE8366B)),
        const SizedBox(width: 16),
        _legendItem('Facebook', const Color(0xFF4267B2)),
        const SizedBox(width: 16),
        _legendItem('TikTok', const Color(0xFF111111)),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF9090B0))),
      ],
    );
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram': return const Color(0xFFE8366B);
      case 'facebook': return const Color(0xFF4267B2);
      case 'tiktok': return const Color(0xFF111111);
      default: return const Color(0xFF6D4ED3);
    }
  }
}
