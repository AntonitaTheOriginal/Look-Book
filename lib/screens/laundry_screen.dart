import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import '../models/clothes_item.dart';
import '../main.dart';

class LaundryScreen extends StatefulWidget {
  const LaundryScreen({super.key});

  @override
  State<LaundryScreen> createState() => _LaundryScreenState();
}

class _LaundryScreenState extends State<LaundryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("MAINTENANCE HUB"),
        actions: [
          TextButton(
            onPressed: _markAllClean,
            child: const Text("All Clean ✨", style: TextStyle(color: kGold, fontWeight: FontWeight.w700)),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.local_laundry_service_outlined), text: "Laundry"),
            Tab(icon: Icon(Icons.cleaning_services_outlined), text: "Shoe Rack"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_laundryTab(), _shoeRackTab()],
      ),
    );
  }

  Future<void> _markAllClean() async {
    final box = Hive.box<ClothesItem>('clothesBox_v2');
    for (final item in box.values) {
      if (item.isDirty) {
        item.isDirty = false;
        await item.save();
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All clothes are clean! ✨")));
      setState(() {});
    }
  }

  Widget _laundryTab() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<ClothesItem>('clothesBox_v2').listenable(),
      builder: (_, Box<ClothesItem> box, __) {
        final dirty = box.values.where((i) => i.isDirty && i.category != 'Footwear').toList();
        if (dirty.isEmpty) return _empty(Icons.local_laundry_service_outlined, "Laundry bag is empty! 🎉", "All your clothes are fresh.");
        return _grid(dirty, isShoes: false);
      },
    );
  }

  Widget _shoeRackTab() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<ClothesItem>('clothesBox_v2').listenable(),
      builder: (_, Box<ClothesItem> box, __) {
        final shoes = box.values.where((i) => i.category == 'Footwear' && i.wearCount > 0).toList();
        if (shoes.isEmpty) return _empty(Icons.cleaning_services_outlined, "Shoe rack is tidy!", "All shoes are polished.");
        return _grid(shoes, isShoes: true);
      },
    );
  }

  Widget _grid(List<ClothesItem> items, {required bool isShoes}) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 0.78),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        return Container(
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(22), border: Border.all(color: kBorder)),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  child: Image.file(File(item.path), width: double.infinity, fit: BoxFit.cover),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.color.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, color: kTextPrimary, fontSize: 11)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          item.isDirty = false;
                          await item.save();
                        },
                        child: Text(isShoes ? "Polish ✨" : "Washed 🫧", style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _empty(IconData icon, String title, String sub) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: kBorder),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 6),
          Text(sub, style: const TextStyle(color: kTextSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
