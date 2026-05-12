import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'dart:io';
import '../models/clothes_item.dart';


class LaundryScreen extends StatefulWidget {
  const LaundryScreen({super.key});

  @override
  State<LaundryScreen> createState() => _LaundryScreenState();
}

class _LaundryScreenState extends State<LaundryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1ED),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Maintenance Hub",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.brown,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.brown,
          tabs: const [
            Tab(icon: Icon(Icons.local_laundry_service), text: "Laundry"),
            Tab(icon: Icon(Icons.cleaning_services), text: "Shoe Rack"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final box = Hive.box<ClothesItem>('clothesBox_v2');
              for (var key in box.keys) {
                final item = box.get(key);
                if (item != null && (item.isDirty == true)) {
                  item.isDirty = false;
                  await item.save();
                }
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("Everything is clean and polished! ✨")),
              );
            },

            child: const Text("All Clean",
                style: TextStyle(color: Colors.brown)),
          )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _laundryTab(context),
          _shoeRackTab(context),
        ],
      ),
    );
  }

  // 🧺 LAUNDRY TAB — Tops & Bottoms only
  Widget _laundryTab(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<ClothesItem>('clothesBox_v2').listenable(),
      builder: (context, Box<ClothesItem> box, _) {
        final dirtyItems = box.values
            .where((item) =>
                item.isDirty == true &&
                item.category != 'Footwear')
            .toList();


        if (dirtyItems.isEmpty) {
          return _emptyState(
            icon: Icons.local_laundry_service_outlined,
            message: "Laundry bag is empty! 🎉",
            subtitle: "Your clothes are clean and ready to wear.",
          );
        }

        return _itemGrid(dirtyItems, box, isShoeRack: false);

      },
    );
  }

  // 👟 SHOE RACK TAB — Footwear only
  Widget _shoeRackTab(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<ClothesItem>('clothesBox_v2').listenable(),
      builder: (context, Box<ClothesItem> box, _) {
        final usedShoes = box.values
            .where((item) =>
                item.category == 'Footwear' &&
                item.wearCount > 0) // Heuristic for "used" shoes since we removed isUsed
            .toList();


        if (usedShoes.isEmpty) {
          return _emptyState(
            icon: Icons.cleaning_services_outlined,
            message: "Shoe rack is tidy!",
            subtitle: "All shoes are polished and ready.",
          );
        }

        return _itemGrid(usedShoes, box, isShoeRack: true);

      },
    );
  }

  Widget _itemGrid(
      List<ClothesItem> items, Box<ClothesItem> box,
      {required bool isShoeRack}) {

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        final item = items[index];


        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.file(
                    File(item.path),
                    fit: BoxFit.cover,
                  ),

                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.category,
                        style: const TextStyle(fontWeight: FontWeight.bold)),

                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isShoeRack
                              ? const Color(0xFF5C4033)
                              : const Color(0xFFB08968),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          item.isDirty = false;
                          // For shoes, we just reset the wear count tracking for "used" status if we want
                          // but simpler is to just mark as "cleaned"
                          await item.save();
                        },

                        child: Text(
                          isShoeRack ? "Polish ✨" : "Wash 🫧",
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white),
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _emptyState(
      {required IconData icon,
      required String message,
      required String subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.brown.withOpacity(0.3)),
          const SizedBox(height: 20),
          Text(message,
              style: const TextStyle(fontSize: 18, color: Colors.grey)),
          Text(subtitle, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
