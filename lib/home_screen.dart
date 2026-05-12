import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import 'screens/closet_screen.dart';
import 'screens/laundry_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/analytics_screen.dart';
import 'utils/outfit_generator.dart';
import 'utils/weather_service.dart';
import 'utils/claude_service.dart';
import 'models/clothes_item.dart';
import 'main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  String _selectedCategory = "Casual";
  Map<String, dynamic>? _outfit;
  WeatherData? _weather;
  String? _advice;
  bool _isAiThinking = false;
  String _userName = "Fashionista";
  late AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
    _loadUserSettings();
    _fetchWeather();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _loadUserSettings() {
    final box = Hive.box('settingsBox');
    setState(() => _userName = box.get('userName', defaultValue: 'Fashionista'));
  }

  Future<void> _fetchWeather() async {
    setState(() => _weather = null);
    final weather = await WeatherService.getCurrentWeather();
    if (mounted) setState(() => _weather = weather);
  }

  Future<void> _generate({required bool hurry}) async {
    setState(() {
      _outfit = generateOutfit(
        weather: _weather,
        targetOccasion: _selectedCategory,
        targetPlace: _controller.text,
        hurryMode: hurry,
        boldMode: true,
      );
      _advice = null;
      _isAiThinking = true;
    });

    if (_outfit?['top'] == null && _outfit?['isDressOutfit'] != true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Not enough clean clothes! Check your laundry 🧺")),
        );
      }
      setState(() => _isAiThinking = false);
      return;
    }

    final advice = await ClaudeService.getStylistAdvice(
      top: _outfit!['top'] as ClothesItem?,
      bottom: _outfit!['bottom'] as ClothesItem?,
      shoes: _outfit!['shoes'] as ClothesItem?,
      weather: _weather,
      occasion: _selectedCategory,
    );

    if (mounted) setState(() { _advice = advice; _isAiThinking = false; });
  }

  Future<void> _wearToday() async {
    if (_outfit == null) return;
    final box = Hive.box<ClothesItem>('clothesBox_v2');
    final now = DateTime.now();
    for (final k in ['topKey', 'bottomKey', 'shoesKey']) {
      if (_outfit![k] != null) {
        final item = box.get(_outfit![k]);
        if (item != null) {
          if (k != 'shoesKey') item.isDirty = true;
          item.wearCount += 1;
          item.lastWornDate = now;
          await item.save();
        }
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Outfit logged! Clothes sent to laundry 🧺")),
      );
      setState(() => _outfit = null);
    }
  }

  Future<void> _scheduleOutfit() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.dark(primary: kGold, onPrimary: Colors.black)),
        child: child!,
      ),
    );
    if (date != null && _outfit != null) {
      final dateKey = date.toIso8601String().split('T')[0];
      await Hive.box('calendarBox').put(dateKey, {
        'top': _outfit!['top'] != null ? {'path': (_outfit!['top'] as ClothesItem).path} : null,
        'bottom': _outfit!['bottom'] != null ? {'path': (_outfit!['bottom'] as ClothesItem).path} : null,
        'shoes': _outfit!['shoes'] != null ? {'path': (_outfit!['shoes'] as ClothesItem).path} : null,
        'occasion': _controller.text.isNotEmpty ? _controller.text : _selectedCategory,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Scheduled to Calendar 📅")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("LOOKBOOK AI"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 100, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreeting(),
                  const SizedBox(height: 24),
                  _buildWeatherCard(),
                  const SizedBox(height: 32),
                  _buildOccasionSection(),
                  const SizedBox(height: 24),
                  _buildCategoryRow(),
                  const SizedBox(height: 28),
                  _buildActionButtons(),
                  const SizedBox(height: 40),
                  if (_outfit != null) ...[
                    _buildAiPanel(),
                    const SizedBox(height: 28),
                    _buildOutfitResult(),
                    const SizedBox(height: 20),
                    _buildOutfitActions(),
                    const SizedBox(height: 40),
                  ],
                  _buildQuickNav(),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Greeting ────────────────────────────────────────────────────────────────
  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? "Good Morning" : hour < 17 ? "Good Afternoon" : "Good Evening";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(greeting, style: const TextStyle(color: kTextSecondary, fontSize: 15)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(_userName,
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: kTextPrimary, letterSpacing: -0.5)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: kGold.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, size: 12, color: kGold),
                  SizedBox(width: 5),
                  Text("AI Stylist", style: TextStyle(color: kGold, fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Weather Card ─────────────────────────────────────────────────────────────
  Widget _buildWeatherCard() {
    return GestureDetector(
      onTap: _fetchWeather,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kBorder),
        ),
        child: _weather == null
          ? const Row(children: [
              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: kGold)),
              SizedBox(width: 14),
              Text("Fetching live weather...", style: TextStyle(color: kTextSecondary)),
              Spacer(),
              Icon(Icons.refresh, color: kTextSecondary, size: 18),
            ])
          : Row(
              children: [
                Text(_weather!.icon, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${_weather!.temperature.toStringAsFixed(1)}°C · ${_weather!.condition}",
                          style: const TextStyle(fontWeight: FontWeight.w800, color: kTextPrimary, fontSize: 15)),
                      const SizedBox(height: 3),
                      Text(WeatherService.getSuggestion(_weather!),
                          style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.refresh_rounded, color: kGold, size: 18),
              ],
            ),
      ),
    );
  }

  // ─── Occasion Input ──────────────────────────────────────────────────────────
  Widget _buildOccasionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Where are you headed?", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: kTextPrimary)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kBorder)),
          child: TextField(
            controller: _controller,
            style: const TextStyle(color: kTextPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: "Office meeting, dinner date, gym...",
              hintStyle: const TextStyle(color: kTextSecondary, fontSize: 14),
              filled: false,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 14, right: 10),
                child: Icon(Icons.place_outlined, color: kGold, size: 20),
              ),
              prefixIconConstraints: const BoxConstraints(),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Category Row ────────────────────────────────────────────────────────────
  Widget _buildCategoryRow() {
    const cats = ["Casual", "Work", "Party", "Formal", "Gym", "Date"];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final sel = _selectedCategory == cats[i];
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cats[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: sel ? kGold : kCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: sel ? Colors.transparent : kBorder),
              ),
              child: Text(cats[i],
                  style: TextStyle(color: sel ? Colors.black : kTextSecondary, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          );
        },
      ),
    );
  }

  // ─── Action Buttons ──────────────────────────────────────────────────────────
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _generate(hurry: true),
            child: Container(
              height: 56,
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kBorder)),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flash_on_rounded, color: kTextSecondary, size: 20),
                  SizedBox(width: 8),
                  Text("Hurry", style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: () => _generate(hurry: false),
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: const Text("Generate Outfit"),
          ),
        ),
      ],
    );
  }

  // ─── AI Panel ────────────────────────────────────────────────────────────────
  Widget _buildAiPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kGold.withOpacity(0.25)),
        boxShadow: [BoxShadow(color: kGold.withOpacity(0.06), blurRadius: 30, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: kGold, size: 16),
              const SizedBox(width: 8),
              const Text("CLAUDE'S VERDICT", style: TextStyle(fontWeight: FontWeight.w900, color: kGold, letterSpacing: 1.5, fontSize: 10)),
              const Spacer(),
              if (_isAiThinking)
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: kGold)),
            ],
          ),
          const SizedBox(height: 14),
          if (_isAiThinking)
            _buildShimmer()
          else if (_advice != null)
            Text(_advice!, style: const TextStyle(fontSize: 14, height: 1.65, color: kTextSecondary))
          else
            const Text("Styling your look...", style: TextStyle(color: kTextSecondary, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmerLine(1.0),
          const SizedBox(height: 8),
          _shimmerLine(0.85),
          const SizedBox(height: 8),
          _shimmerLine(0.6),
        ],
      ),
    );
  }

  Widget _shimmerLine(double widthFactor) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(height: 12, decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(6))),
    );
  }

  // ─── Outfit Result ───────────────────────────────────────────────────────────
  Widget _buildOutfitResult() {
    final isDress = _outfit!['isDressOutfit'] == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text("THE CURATED LOOK", style: TextStyle(fontWeight: FontWeight.w900, color: kGold, letterSpacing: 1.5, fontSize: 10)),
            Spacer(),
            Icon(Icons.verified_rounded, color: kGold, size: 14),
          ],
        ),
        const SizedBox(height: 16),
        if (!isDress && _outfit!['top'] != null)
          _buildItemCard(_outfit!['top'] as ClothesItem, "TOP"),
        if (!isDress) const SizedBox(height: 12),
        if (_outfit!['bottom'] != null)
          _buildItemCard(_outfit!['bottom'] as ClothesItem, isDress ? "DRESS" : "BOTTOM"),
        const SizedBox(height: 12),
        if (_outfit!['shoes'] != null)
          _buildItemCard(_outfit!['shoes'] as ClothesItem, "FOOTWEAR"),
      ],
    );
  }

  Widget _buildItemCard(ClothesItem item, String label) {
    return Container(
      height: 112,
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(22), border: Border.all(color: kBorder)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Row(
          children: [
            SizedBox(
              width: 112,
              child: Image.file(File(item.path), fit: BoxFit.cover),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 5),
                    Text(item.color.toUpperCase(),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kTextPrimary)),
                    if (item.occasion != null)
                      Text(item.occasion!, style: const TextStyle(fontSize: 11, color: kTextSecondary)),
                    if (item.tags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(spacing: 4, children: item.tags.take(3).map((t) =>
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(6)),
                          child: Text(t, style: const TextStyle(fontSize: 9, color: kTextSecondary)),
                        )).toList()),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Outfit Actions ──────────────────────────────────────────────────────────
  Widget _buildOutfitActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _wearToday,
            icon: const Icon(Icons.check_circle_rounded, size: 18),
            label: const Text("WEAR THIS TODAY"),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _scheduleOutfit,
                icon: const Icon(Icons.calendar_today_rounded, size: 16),
                label: const Text("Schedule"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _generate(hurry: false),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text("Reshuffle"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Quick Nav ───────────────────────────────────────────────────────────────
  Widget _buildQuickNav() {
    final items = [
      (Icons.checkroom_outlined, "Closet", () => Navigator.pushNamed(context, '/closet')),
      (Icons.calendar_today_outlined, "Calendar", () => Navigator.pushNamed(context, '/calendar')),
      (Icons.analytics_outlined, "Insights", () => Navigator.pushNamed(context, '/analytics')),
      (Icons.local_laundry_service_outlined, "Laundry", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LaundryScreen()))),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("QUICK ACCESS", style: TextStyle(fontWeight: FontWeight.w900, color: kTextSecondary, letterSpacing: 1.5, fontSize: 10)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: items.map((e) => _navPill(e.$1, e.$2, e.$3)).toList(),
        ),
      ],
    );
  }

  Widget _navPill(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder)),
            child: Icon(icon, color: kGold, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kTextSecondary)),
        ],
      ),
    );
  }

  // ─── Settings ────────────────────────────────────────────────────────────────
  void _showSettings() {
    final ctrl = TextEditingController(text: _userName);
    showModalBottomSheet(
      context: context,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text("Your Profile", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kTextPrimary)),
              const SizedBox(height: 6),
              const Text("This name is used by the AI Stylist when personalizing advice.", style: TextStyle(color: kTextSecondary, fontSize: 13)),
              const SizedBox(height: 22),
              Container(
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
                child: TextField(
                  controller: ctrl,
                  style: const TextStyle(color: kTextPrimary),
                  decoration: const InputDecoration(
                    labelText: "Your Name",
                    labelStyle: TextStyle(color: kGold),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (ctrl.text.trim().isNotEmpty) {
                      Hive.box('settingsBox').put('userName', ctrl.text.trim());
                      setState(() => _userName = ctrl.text.trim());
                    }
                    Navigator.pop(context);
                  },
                  child: const Text("SAVE"),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
