import 'package:flutter/material.dart';
import 'screens/closet_screen.dart';
import 'screens/laundry_screen.dart';
import 'utils/outfit_generator.dart';
import 'utils/weather_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController controller = TextEditingController();
  String selectedCategory = "Work";
  Map<String, dynamic>? outfit;
  WeatherData? currentWeather;
  bool boldMode = true;

  @override
  void initState() {
    super.initState();
    currentWeather = WeatherService.getCurrentWeather();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _generate(bool isHurry) {
    setState(() {
      outfit = generateOutfit(
        weather: currentWeather,
        targetOccasion: selectedCategory,
        targetPlace: controller.text,
        hurryMode: isHurry,
        boldMode: boldMode,
      );
    });
    
    // Only show the warning if both top AND dress are missing (truly empty result)
    if (outfit?['top'] == null && outfit?['isDressOutfit'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Not enough clean clothes! Check your laundry. 🧺")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.auto_awesome, color: Colors.brown),
        title: const Text("LookBook AI", style: TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            icon: const Icon(Icons.local_laundry_service, color: Colors.brown),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LaundryScreen()),
            ),
          ),
          const SizedBox(width: 10)
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "What are you getting ready for?",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                // 💎 Style Mode Toggle
                GestureDetector(
                  onTap: () {
                    setState(() {
                      boldMode = !boldMode;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: boldMode ? Colors.brown : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(boldMode ? Icons.auto_awesome : Icons.security, 
                            size: 14, color: boldMode ? Colors.white : Colors.black54),
                        const SizedBox(width: 4),
                        Text(boldMode ? "Bold" : "Safe", 
                            style: TextStyle(color: boldMode ? Colors.white : Colors.black54, fontSize: 12)),
                      ],
                    ),
                  ),
                )
              ],
            ),

            const SizedBox(height: 15),

            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: "Office meeting, date, gym...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Type occasion or place for smart matching",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            // 📍 Navigation Quick Links
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(context, Icons.calendar_month, "Calendar", () => Navigator.pushNamed(context, '/calendar')),
                _navItem(context, Icons.bar_chart, "Analytics", () => Navigator.pushNamed(context, '/analytics')),
                _navItem(context, Icons.checkroom, "Closet", () => Navigator.pushNamed(context, '/closet')),
              ],
            ),

            const SizedBox(height: 25),

            Row(
              children: [
                chip("Work"),
                chip("College"),
                chip("Party"),
                chip("Casual"),
              ],
            ),

            const SizedBox(height: 25),

            if (currentWeather != null)
              Container(
                margin: const EdgeInsets.only(bottom: 25),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Text(currentWeather!.icon, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${currentWeather!.temperature}°C - ${currentWeather!.condition}",
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(WeatherService.getSuggestion(currentWeather!.temperature),
                              style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    )
                  ],
                ),
              ),

            GestureDetector(
              onTap: () => _generate(true),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFB08968),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flash_on, color: Colors.white),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Hurry Mode",
                            style: TextStyle(color: Colors.white, fontSize: 16)),
                        Text("Pick a clean, no-iron outfit right now",
                            style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () => _generate(false),
                child: const Text(
                  "Generate Perfect Outfit",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 🎲 Lucky Dip
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: const BorderSide(color: Colors.brown),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                icon: const Text("🎲", style: TextStyle(fontSize: 16)),
                label: const Text("Lucky Dip", style: TextStyle(color: Colors.brown)),
                onPressed: () {
                  setState(() {
                    outfit = generateOutfit(
                      weather: currentWeather,
                      luckyDip: true,
                    );
                  });
                },
              ),
            ),

            if (outfit != null && (outfit!['top'] != null || outfit!['isDressOutfit'] == true)) ...[
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Your Outfit 🔥",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.brown.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      outfit!['harmony'] ?? "", 
                      style: const TextStyle(color: Colors.brown, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Column(
                children: [
                  // Skip Top card for dress outfits
                  if (outfit!['isDressOutfit'] != true)
                    outfitCard(outfit!['top'], "Top"),
                  if (outfit!['isDressOutfit'] != true)
                    const SizedBox(height: 15),
                  outfitCard(outfit!['bottom'],
                      outfit!['isDressOutfit'] == true ? "Dress 👗" : "Bottom"),
                  const SizedBox(height: 15),
                  outfitCard(outfit!['shoes'], "Shoes"),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                          builder: (context, child) => Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(primary: Colors.brown),
                            ),
                            child: child!,
                          ),
                        );
                        if (date != null) {
                          final dateKey = date.toIso8601String().split('T')[0];
                          final box = Hive.box('calendarBox');
                          await box.put(dateKey, {
                            'top': outfit!['top'],
                            'bottom': outfit!['bottom'],
                            'shoes': outfit!['shoes'],
                            'occasion': controller.text,
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Outfit scheduled on calendar! 📅")),
                          );
                        }
                      },
                      child: const Text("Schedule 📅", style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                      onPressed: () async {
                        final box = Hive.box('clothesBox');
                        final now = DateTime.now().toIso8601String();

                        for (String k in ['topKey', 'bottomKey']) {
                          if (outfit![k] != null) {
                            final item = box.get(outfit![k]);
                            item['isDirty'] = true;
                            item['wearCount'] = (item['wearCount'] ?? 0) + 1;
                            item['lastWornDate'] = now;
                            await box.put(outfit![k], item);
                          }
                        }
                        // Footwear: use 'isUsed' not 'isDirty'
                        if (outfit!['shoesKey'] != null) {
                          final item = box.get(outfit!['shoesKey']);
                          item['isUsed'] = true;
                          item['wearCount'] = (item['wearCount'] ?? 0) + 1;
                          item['lastWornDate'] = now;
                          await box.put(outfit!['shoesKey'], item);
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Outfit tracked! Clothes to laundry, shoes to rack. 🧺👟")),
                        );
                        setState(() => outfit = null);
                      },
                      child: const Text("Wear Today ✨", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 40),

            // 🌟 Favorites Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Your LookBook ❤️",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                TextButton(
                  onPressed: () {},
                  child: const Text("View All", style: TextStyle(color: Colors.grey)),
                )
              ],
            ),
            
            const SizedBox(height: 10),
            
            ValueListenableBuilder(
              valueListenable: Hive.box('savedOutfitsBox').listenable(),
              builder: (context, Box box, _) {
                if (box.isEmpty) {
                  return const Text("No saved looks yet.");
                }

                return SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: box.length,
                    itemBuilder: (context, index) {
                      final item = box.getAt(index);
                      return Container(
                        margin: const EdgeInsets.only(right: 15),
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.brown.withOpacity(0.1)),
                        ),
                        child: const Center(child: Icon(Icons.favorite, color: Colors.brown, size: 20)),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget chip(String text) {
    final isSelected = selectedCategory == text;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = text;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFB08968) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.brown : Colors.grey.shade300),
        ),
        child: Text(
          text,
          style: TextStyle(color: isSelected ? Colors.white : Colors.black87),
        ),
      ),
    );
  }

  Widget outfitCard(dynamic item, String label) {
    if (item == null) return const SizedBox();

    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
            child: Image.file(
              File(item['path']),
              width: 120,
              height: 140,
              fit: BoxFit.cover,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 5),
                  Text("${item['color']} • ${item['occasion']} • ${item['place']}", 
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 5),
                  if (item['needsIroning'] == true)
                    const Row(
                      children: [
                        Icon(Icons.iron, size: 12, color: Colors.orange),
                        SizedBox(width: 4),
                        Text("Needs Ironing", style: TextStyle(color: Colors.orange, fontSize: 10)),
                      ],
                    )
                  else
                    const Row(
                      children: [
                        Icon(Icons.bolt, size: 12, color: Colors.green),
                        SizedBox(width: 4),
                        Text("Ready to go", style: TextStyle(color: Colors.green, fontSize: 10)),
                      ],
                    ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.brown),
          onPressed: onTap,
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
      ],
    );
  }
}
