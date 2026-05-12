import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import '../models/clothes_item.dart';
import '../main.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<ClothesItem>('clothesBox_v2');
    final items = box.values.toList();
    final sorted = List<ClothesItem>.from(items)..sort((a, b) => b.wearCount.compareTo(a.wearCount));
    final topItems = sorted.where((i) => i.wearCount > 0).take(5).toList();
    final dormantItems = items.where((i) => i.wearCount == 0).toList();
    final dirtyItems = items.where((i) => i.isDirty).length;
    final totalWears = items.fold<int>(0, (sum, i) => sum + i.wearCount);

    return Scaffold(
      appBar: AppBar(title: const Text("INSIGHTS")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Overview stats
            Row(
              children: [
                _statCard("${items.length}", "Total Items", Icons.style_outlined),
                const SizedBox(width: 12),
                _statCard("$totalWears", "Total Wears", Icons.trending_up_rounded),
                const SizedBox(width: 12),
                _statCard("$dirtyItems", "In Laundry", Icons.local_laundry_service_outlined),
              ],
            ),
            const SizedBox(height: 28),

            // ── Category breakdown
            const Text("WARDROBE BREAKDOWN", style: TextStyle(fontWeight: FontWeight.w900, color: kGold, letterSpacing: 1.5, fontSize: 10)),
            const SizedBox(height: 14),
            _categoryBreakdown(items),

            const SizedBox(height: 28),

            // ── Top worn
            const Text("TOP STAPLES 🔥", style: TextStyle(fontWeight: FontWeight.w900, color: kGold, letterSpacing: 1.5, fontSize: 10)),
            const SizedBox(height: 14),
            topItems.isEmpty
              ? _emptyHint("Wear outfits to see your top staples")
              : _horizontalList(topItems, showWears: true),

            const SizedBox(height: 28),

            // ── Dormant
            const Text("UNWORN ITEMS 💤", style: TextStyle(fontWeight: FontWeight.w900, color: kGold, letterSpacing: 1.5, fontSize: 10)),
            const SizedBox(height: 14),
            dormantItems.isEmpty
              ? _emptyHint("Everything is being worn – great!")
              : _horizontalList(dormantItems, showWears: false),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: kGold, size: 20),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kTextPrimary)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: kTextSecondary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _categoryBreakdown(List<ClothesItem> items) {
    final cats = {'Tops': 0, 'Bottoms': 0, 'Dresses': 0, 'Footwear': 0};
    for (final i in items) cats[i.category] = (cats[i.category] ?? 0) + 1;
    final max = cats.values.fold(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder)),
      child: Column(
        children: cats.entries.map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              SizedBox(width: 70, child: Text(e.key, style: const TextStyle(color: kTextSecondary, fontSize: 12, fontWeight: FontWeight.w600))),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: max == 0 ? 0 : e.value / max,
                    minHeight: 8,
                    backgroundColor: kBorder,
                    valueColor: const AlwaysStoppedAnimation(kGold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text("${e.value}", style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.w800, fontSize: 12)),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _horizontalList(List<ClothesItem> items, {required bool showWears}) {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final item = items[i];
          return Container(
            width: 110,
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kBorder)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: Image.file(File(item.path), width: 110, fit: BoxFit.cover),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.category, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: kTextPrimary)),
                      const SizedBox(height: 2),
                      Text(
                        showWears ? "${item.wearCount} wears" : "Never worn",
                        style: TextStyle(fontSize: 9, color: showWears ? kGold : Colors.redAccent, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _emptyHint(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(text, style: const TextStyle(color: kTextSecondary, fontSize: 13)),
  );
}
