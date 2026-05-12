import 'package:flutter/material.dart';
import 'screens/closet_screen.dart';
import 'screens/laundry_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/analytics_screen.dart';
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
  String userName = "Fashionista";

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
    _fetchWeather();
  }

  void _loadUserSettings() {
    final box = Hive.box('settingsBox');
    setState(() {
      userName = box.get('userName', defaultValue: 'Fashionista');
    });
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
    
    if (outfit?['top'] == null && outfit?['isDressOutfit'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Not enough clean clothes! 🧺")),
      );
      setState(() => isAiThinking = false);
      return;
    }

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("LOOKBOOK AI", 
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16, color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            onPressed: () => _showSettings(),
          ),
          const SizedBox(width: 10)
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0F10), Color(0xFF1C1C1E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 100, left: 20, right: 20, bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Good Day,", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16)),
              const SizedBox(height: 4),
              Text(userName, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              
              const SizedBox(height: 30),
              _buildWeatherCard(),

              const SizedBox(height: 25),
              const Text("What's the occasion?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 15),
              
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "E.g. Summer Date, Business Lunch...",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  filled: true,
                  fillColor: const Color(0xFF2C2C2E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37)),
                ),
              ),

              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ["Work", "Casual", "Party", "Formal", "Gym"].map((cat) => _buildCategoryChip(cat)).toList(),
                ),
              ),

              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(child: _buildActionButton(Icons.flash_on, "Hurry", () => _generate(true), isPrimary: false)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildActionButton(Icons.auto_awesome, "Stylize", () => _generate(false), isPrimary: true)),
                ],
              ),

              if (outfit != null) ...[
                const SizedBox(height: 40),
                _buildAiStylistPanel(),
                
                const Row(
                  children: [
                    Text("THE CURATED LOOK", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12, color: Color(0xFFD4AF37))),
                    Spacer(),
                    Icon(Icons.verified, color: Color(0xFFD4AF37), size: 14),
                  ],
                ),
                const SizedBox(height: 20),
                
                if (outfit!['isDressOutfit'] != true)
                  _buildOutfitCard(outfit!['top'], "TOP PIECE"),
                if (outfit!['isDressOutfit'] != true)
                  const SizedBox(height: 15),
                _buildOutfitCard(outfit!['bottom'], outfit!['isDressOutfit'] == true ? "DRESS 👗" : "BOTTOM PIECE"),
                const SizedBox(height: 15),
                _buildOutfitCard(outfit!['shoes'], "FOOTWEAR"),

                const SizedBox(height: 30),
                _buildActionButtonsRow(),
              ],

              const SizedBox(height: 40),
              const Text("QUICK ACCESS", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12, color: Colors.white30)),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _navItem(context, Icons.checkroom_outlined, "Closet", () => Navigator.pushNamed(context, '/closet')),
                  _navItem(context, Icons.calendar_today_outlined, "Calendar", () => Navigator.pushNamed(context, '/calendar')),
                  _navItem(context, Icons.analytics_outlined, "Analytics", () => Navigator.pushNamed(context, '/analytics')),
                  _navItem(context, Icons.wash_outlined, "Laundry", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LaundryScreen()))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettings() {
    final TextEditingController nameEditController = TextEditingController(text: userName);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Profile Settings", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 20),
              TextField(
                controller: nameEditController,
                decoration: const InputDecoration(
                  labelText: "Your Name",
                  labelStyle: TextStyle(color: Color(0xFFD4AF37)),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Hive.box('settingsBox').put('userName', nameEditController.text);
                    setState(() => userName = nameEditController.text);
                    Navigator.pop(context);
                  }, 
                  child: const Text("SAVE CHANGES")
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    if (currentWeather == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(24)),
        child: const Row(children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD4AF37))), SizedBox(width: 15), Text("Loading weather...", style: TextStyle(color: Colors.white54))]),
      );
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Text(currentWeather!.icon, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text("${currentWeather!.temperature.toStringAsFixed(1)}°C  |  ${currentWeather!.condition.toUpperCase()}", 
                      style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 14, color: Colors.white)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        setState(() => currentWeather = null);
                        _fetchWeather();
                      },
                      child: const Icon(Icons.refresh, size: 14, color: Color(0xFFD4AF37)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(WeatherService.getSuggestion(currentWeather!), 
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String cat) {
    final isSel = selectedCategory == cat;
    return GestureDetector(
      onTap: () => setState(() => selectedCategory = cat),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSel ? Colors.transparent : Colors.white.withOpacity(0.1)),
        ),
        child: Text(cat, style: TextStyle(color: isSel ? Colors.black : Colors.white70, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap, {required bool isPrimary}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? const Color(0xFFD4AF37) : const Color(0xFF1C1C1E),
        foregroundColor: isPrimary ? Colors.black : Colors.white,
        side: isPrimary ? BorderSide.none : BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildAiStylistPanel() {
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
        boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.05), blurRadius: 30)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 20),
              const SizedBox(width: 10),
              const Text("AI STYLIST VERDICT", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFD4AF37), letterSpacing: 1, fontSize: 12)),
              const Spacer(),
              if (isAiThinking) const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD4AF37))),
            ],
          ),
          const SizedBox(height: 15),
          if (stylistAdvice != null)
            Text(stylistAdvice!, style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.white70))
          else
            Text("Waiting for Claude's expert opinion...", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.3))),
        ],
      ),
    );
  }

  Widget _buildOutfitCard(dynamic item, String label) {
    if (item == null) return const SizedBox();
    final String path = item is ClothesItem ? item.path : item['path'];
    final String color = item is ClothesItem ? item.color : item['color'];

    return Container(
      height: 120,
      decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
            child: Image.file(File(path), width: 100, height: 120, fit: BoxFit.cover),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Color(0xFFD4AF37), letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(color.toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  if (item is ClothesItem) Wrap(
                    spacing: 4,
                    children: item.tags.take(2).map((t) => Text("#$t", style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.4)))).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsRow() {
    return Row(
      children: [
        Expanded(child: OutlinedButton(
          onPressed: () {}, 
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white24),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
          ),
          child: const Text("SCHEDULE")
        )),
        const SizedBox(width: 15),
        Expanded(child: ElevatedButton(onPressed: () {}, child: const Text("WEAR TODAY"))),
      ],
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
            child: Icon(icon, color: const Color(0xFFD4AF37), size: 22),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white38)),
        ],
      ),
    );
  }
}
