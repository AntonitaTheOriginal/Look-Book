import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('calendarBox');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F1ED),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Outfit Calendar 📅", 
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _calendarHeader(),
          const SizedBox(height: 10),
          _calendarGrid(box),
          const Expanded(child: SizedBox()),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: const Text("Select a date to view your planned looks", 
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _calendarHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "${_getMonthName(focusedDay.month)} ${focusedDay.year}",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() => focusedDay = DateTime(focusedDay.year, focusedDay.month - 1)),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() => focusedDay = DateTime(focusedDay.year, focusedDay.month + 1)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _calendarGrid(Box box) {
    final daysInMonth = DateTime(focusedDay.year, focusedDay.month + 1, 0).day;
    final firstDayOfWeek = DateTime(focusedDay.year, focusedDay.month, 1).weekday % 7;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: daysInMonth + firstDayOfWeek,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 5,
          crossAxisSpacing: 5,
        ),
        itemBuilder: (context, index) {
          if (index < firstDayOfWeek) return const SizedBox();

          final day = index - firstDayOfWeek + 1;
          final date = DateTime(focusedDay.year, focusedDay.month, day);
          final dateKey = date.toIso8601String().split('T')[0];
          final hasOutfit = box.containsKey(dateKey);

          return GestureDetector(
            onTap: () {
              if (hasOutfit) {
                _showOutfitDetails(context, box.get(dateKey), dateKey);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: hasOutfit ? Colors.brown.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasOutfit ? Colors.brown : Colors.grey.shade200,
                  width: hasOutfit ? 2 : 1,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text("$day", 
                      style: TextStyle(
                        fontWeight: hasOutfit ? FontWeight.bold : FontWeight.normal,
                        color: hasOutfit ? Colors.brown : Colors.black,
                      )),
                  if (hasOutfit)
                    Positioned(
                      bottom: 4,
                      child: Container(
                        height: 4,
                        width: 4,
                        decoration: const BoxDecoration(
                          color: Colors.brown,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showOutfitDetails(BuildContext context, Map outfit, String dateKey) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Outfit for $dateKey", 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    Hive.box('calendarBox').delete(dateKey);
                    Navigator.pop(context);
                    setState(() {});
                  },
                )
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                _smallPreview(outfit['top']),
                const SizedBox(width: 10),
                _smallPreview(outfit['bottom']),
                const SizedBox(width: 10),
                _smallPreview(outfit['shoes']),
              ],
            ),
            const SizedBox(height: 20),
            Text("Occasion: ${outfit['occasion'] ?? 'General'}", 
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _smallPreview(dynamic item) {
    if (item == null) return const SizedBox();
    return Container(
      height: 80,
      width: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        image: DecorationImage(
          image: FileImage(File(item['path'])),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const names = ["", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
    return names[month];
  }
}
