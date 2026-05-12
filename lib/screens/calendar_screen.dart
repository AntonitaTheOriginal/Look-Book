import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import '../main.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focused = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('calendarBox');

    return Scaffold(
      appBar: AppBar(title: const Text("OUTFIT CALENDAR")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildDayLabels(),
            const SizedBox(height: 8),
            _buildGrid(box),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kBorder)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: kGold, size: 16),
                  SizedBox(width: 10),
                  Expanded(child: Text("Tap a highlighted date to view your planned outfit.", style: TextStyle(color: kTextSecondary, fontSize: 13))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    const months = ["", "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"];
    return Row(
      children: [
        Text("${months[_focused.month]} ${_focused.year}",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kTextPrimary)),
        const Spacer(),
        _headerBtn(Icons.chevron_left, () => setState(() => _focused = DateTime(_focused.year, _focused.month - 1))),
        const SizedBox(width: 4),
        _headerBtn(Icons.chevron_right, () => setState(() => _focused = DateTime(_focused.year, _focused.month + 1))),
      ],
    );
  }

  Widget _headerBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
        child: Icon(icon, color: kTextSecondary, size: 18),
      ),
    );
  }

  Widget _buildDayLabels() {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Row(
      children: days.map((d) => Expanded(child: Center(
        child: Text(d, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: kTextSecondary)),
      ))).toList(),
    );
  }

  Widget _buildGrid(Box box) {
    final daysInMonth = DateTime(_focused.year, _focused.month + 1, 0).day;
    final firstWeekday = DateTime(_focused.year, _focused.month, 1).weekday % 7;
    final today = DateTime.now();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7, mainAxisSpacing: 6, crossAxisSpacing: 6),
      itemCount: daysInMonth + firstWeekday,
      itemBuilder: (_, index) {
        if (index < firstWeekday) return const SizedBox();
        final day = index - firstWeekday + 1;
        final date = DateTime(_focused.year, _focused.month, day);
        final dateKey = "${_focused.year}-${_focused.month.toString().padLeft(2,'0')}-${day.toString().padLeft(2,'0')}";
        final hasOutfit = box.containsKey(dateKey);
        final isToday = date.day == today.day && date.month == today.month && date.year == today.year;

        return GestureDetector(
          onTap: hasOutfit ? () => _showOutfitDetail(box.get(dateKey), dateKey) : null,
          child: Container(
            decoration: BoxDecoration(
              color: isToday ? kGold.withOpacity(0.15) : hasOutfit ? kGold.withOpacity(0.08) : kCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isToday ? kGold : hasOutfit ? kGold.withOpacity(0.4) : kBorder,
                width: isToday ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("$day", style: TextStyle(
                  fontSize: 12,
                  fontWeight: hasOutfit || isToday ? FontWeight.w900 : FontWeight.w500,
                  color: isToday ? kGold : hasOutfit ? kTextPrimary : kTextSecondary,
                )),
                if (hasOutfit) Container(
                  width: 4, height: 4,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: const BoxDecoration(color: kGold, shape: BoxShape.circle),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOutfitDetail(dynamic outfit, String dateKey) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text("Outfit for $dateKey", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kTextPrimary)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () {
                    Hive.box('calendarBox').delete(dateKey);
                    Navigator.pop(context);
                    setState(() {});
                  },
                ),
              ],
            ),
            if (outfit['occasion'] != null) ...[
              const SizedBox(height: 4),
              Text(outfit['occasion'], style: const TextStyle(color: kGold, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                _preview(outfit['top']),
                const SizedBox(width: 12),
                _preview(outfit['bottom']),
                const SizedBox(width: 12),
                _preview(outfit['shoes']),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _preview(dynamic item) {
    if (item == null || item['path'] == null) return const SizedBox(width: 90, height: 90);
    return Container(
      width: 90, height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        image: DecorationImage(image: FileImage(File(item['path'])), fit: BoxFit.cover),
      ),
    );
  }
}
