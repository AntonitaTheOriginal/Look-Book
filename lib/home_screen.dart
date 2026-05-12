import 'package:flutter/material.dart';
import 'screens/closet_screen.dart';
import 'screens/laundry_screen.dart';
import 'utils/outfit_generator.dart';
import 'utils/weather_service.dart';
import 'utils/claude_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import 'models/clothes_item.dart';
import 'models/outfit.dart';


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
  String? stylistAdvice;
  bool boldMode = true;
  bool isAiThinking = false;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    final weather = await WeatherService.getCurrentWeather();
    if (mounted) {
      setState(() {
        currentWeather = weather;
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _generate(bool isHurry) async {
    setState(() {
      outfit = generateOutfit(
        weather: currentWeather,
        targetOccasion: selectedCategory,
        targetPlace: controller.text,
        hurryMode: isHurry,
        boldMode: boldMode,
      );
      stylistAdvice = null;
      isAiThinking = true;
    });
    
    // Only show the warning if both top AND dress are missing (truly empty result)
    if (outfit?['top'] == null && outfit?['isDressOutfit'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Not enough clean clothes! Check your laundry. 🧺")),
      );
      setState(() => isAiThinking = false);
      return;
    }

    // Fetch AI Advice from Claude
    final advice = await ClaudeService.getStylistAdvice(
      top: outfit!['top'] as ClothesItem?,
      bottom: outfit!['bottom'] as ClothesItem?,
      shoes: outfit!['shoes'] as ClothesItem?,
      weather: currentWeather,
      occasion: selectedCategory,
    );

    if (mounted) {
      setState(() {
        stylistAdvice = advice;
        isAiThinking = false;
      });
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

            // 🌦️ Weather Display
            Container(
              margin: const EdgeInsets.only(bottom: 25),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
              ),
              child: currentWeather == null
                ? const Row(
                    children: [
                      CircularProgressIndicator(strokeWidth: 2),
                      SizedBox(width: 15),
                      Text("Fetching real-time weather...", style: TextStyle(color: Colors.grey)),
                    ],
                  )
                : Row(
                    children: [
                      Text(currentWeather!.icon, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${currentWeather!.temperature.toStringAsFixed(1)}°C - ${currentWeather!.condition}",
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(WeatherService.getSuggestion(currentWeather!),
                                style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18, color: Colors.brown),
                        onPressed: () {
                          setState(() => currentWeather = null);
                          _fetchWeather();
                        },
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
                
                // ✨ Claude AI Stylist Panel
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 25),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFFB08968).withOpacity(0.1), const Color(0xFFF5F1ED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: const Color(0xFFB08968).withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(color: Colors.brown.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Color(0xFFB08968), size: 20),
                          const SizedBox(width: 10),
                          const Text("Claude AI Stylist", 
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB08968), letterSpacing: 0.5)),
                          const Spacer(),
                          if (isAiThinking)
                            const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFB08968))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (isAiThinking)
                        const Text("Curating your look insights...", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 13))
                      else if (stylistAdvice != null)
                        Text(stylistAdvice!, 
                          style: const TextStyle(height: 1.5, color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w400))
                      else
                        const Text("Analyzing your style choices...", style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
                
                // 🧠 AI Insights Panel
                if (outfit!['aiInsights'] != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.brown.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.brown.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.psychology, color: Colors.brown, size: 20),
                            SizedBox(width: 8),
                            Text("AI Insights", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...(outfit!['aiInsights'] as Map<String, dynamic>).entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(child: Text(e.value.toString(), style: const TextStyle(fontSize: 12, color: Colors.black87))),
                            ],
                          ),
                        )).toList(),
                      ],
                    ),
                  ),

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
                        final box = Hive.box<ClothesItem>('clothesBox_v2');
                        final now = DateTime.now();

                        for (String k in ['topKey', 'bottomKey', 'shoesKey']) {
                          if (outfit![k] != null) {
                            final item = box.get(outfit![k]);
                            if (item != null) {
                              if (k != 'shoesKey') item.isDirty = true;
                              item.wearCount += 1;
                              item.lastWornDate = now;
                              await item.save();
                            }
                          }
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
              valueListenable: Hive.box<Outfit>('savedOutfits_v2').listenable(),
              builder: (context, Box<Outfit> box, _) {

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

    // Handle both Map (legacy/lucky dip) and ClothesItem (new)
    final String path = item is ClothesItem ? item.path : item['path'];
    final String color = item is ClothesItem ? item.color : item['color'];
    final String occasion = item is ClothesItem ? (item.occasion ?? "N/A") : (item['occasion'] ?? "N/A");
    final bool needsIroning = item is ClothesItem ? item.needsIroning : (item['needsIroning'] ?? false);

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
              File(path),
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
                  Text("$color • $occasion", 
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  if (item is ClothesItem && item.tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Wrap(
                        spacing: 4,
                        children: item.tags.take(2).map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.brown.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(tag, style: const TextStyle(fontSize: 9, color: Colors.brown)),
                        )).toList(),
                      ),
                    ),
                  const SizedBox(height: 5),

                  if (needsIroning)
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
