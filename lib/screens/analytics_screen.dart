import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('clothesBox');
    final items = box.values.toList();

    // 1. Sort by wearCount
    final sortedByWear = List.from(items);
    sortedByWear.sort((a, b) => (b['wearCount'] ?? 0).compareTo(a['wearCount'] ?? 0));

    // 2. Filter Top Items (Worn at least once)
    final topItems = sortedByWear.where((i) => (i['wearCount'] ?? 0) > 0).take(5).toList();

    // 3. Filter Dormant Items (Zero wears)
    final dormantItems = items.where((i) => (i['wearCount'] ?? 0) == 0).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F1ED),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Closet Insights 📊", 
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _overviewCard(items.length),
            const SizedBox(height: 25),
            
            const Text("Top 5 Staples 🔥", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (topItems.isEmpty)
              const Text("Wear more outfits to see your top staples!", 
                  style: TextStyle(color: Colors.grey, fontSize: 13))
            else
              _horizontalList(topItems),

            const SizedBox(height: 30),

            const Text("Dormant Items (Time for a change?) 💤", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (dormantItems.isEmpty)
              const Text("Everything is being used! Great job! 🎉", 
                  style: TextStyle(color: Colors.grey, fontSize: 13))
            else
              _horizontalList(dormantItems, isDormant: true),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _overviewCard(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFB08968),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Total Wardrobe", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text("$count Items", 
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          const LinearProgressIndicator(
            value: 0.7,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 10),
          const Text("Capacity is good! Plenty of room for more.", 
              style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _horizontalList(List items, {bool isDormant = false}) {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            margin: const EdgeInsets.only(right: 15),
            width: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: Image.file(
                      File(item['path']),
                      width: 110,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['category'], 
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      isDormant 
                        ? const Text("Never worn", style: TextStyle(fontSize: 9, color: Colors.red))
                        : Text("${item['wearCount']} wears", style: const TextStyle(fontSize: 9, color: Colors.green)),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
