import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../utils/ai_analyzer.dart';
import '../models/clothes_item.dart';
import '../main.dart';

class ClosetScreen extends StatefulWidget {
  const ClosetScreen({super.key});

  @override
  State<ClosetScreen> createState() => _ClosetScreenState();
}

class _ClosetScreenState extends State<ClosetScreen> {
  String _filter = "Tops";
  bool _isScanning = false;
  final picker = ImagePicker();

  Future<void> _addItem({required ImageSource source}) async {
    final file = await picker.pickImage(source: source, imageQuality: 90);
    if (file == null) return;
    setState(() => _isScanning = true);

    try {
      final removedBgPath = await AiAnalyzer.removeBackground(file.path);
      final finalPath = removedBgPath ?? file.path;
      final ai = await AiAnalyzer.analyzeImage(finalPath);
      if (mounted) {
        setState(() => _isScanning = false);
        _showSaveSheet(finalPath, ai);
      }
    } catch (e) {
      setState(() => _isScanning = false);
      _showSaveSheet(file.path, {"color": "white", "tags": [], "category": "Tops"});
    }
  }

  void _showSaveSheet(String path, Map<String, dynamic> ai) {
    String category = ai['category'] ?? "Tops";
    String occasion = "Casual";
    bool ironing = false;
    final List<String> tags = List<String>.from(ai['tags'] ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (ctx, ss) => Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 4),
                child: Container(width: 36, height: 4, decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
              ),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Verify & Save", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kTextPrimary)),
                          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: kTextSecondary)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Image preview
                      Center(
                        child: Container(
                          height: 210,
                          width: 210,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: kBorder),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20)],
                            image: DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: kGold.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome, size: 12, color: kGold),
                              const SizedBox(width: 5),
                              Text("Detected: ${ai['color']?.toString().toUpperCase() ?? 'UNKNOWN'}",
                                  style: const TextStyle(color: kGold, fontSize: 11, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _sectionLabel("CATEGORY"),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: ['Tops', 'Bottoms', 'Dresses', 'Footwear'].map((c) =>
                          _chip(c, category == c, () => ss(() => category = c))).toList(),
                      ),
                      const SizedBox(height: 20),
                      _sectionLabel("FABRIC & WEATHER ATTRIBUTES"),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: ['Linen', 'Cotton', 'Breathable', 'Wool', 'Thermal', 'Waterproof', 'Windproof', 'Thin', 'Thick', 'Quick-dry']
                          .map((t) => _chip(t, tags.contains(t), () => ss(() { if (tags.contains(t)) tags.remove(t); else tags.add(t); }))).toList(),
                      ),
                      if (category != 'Footwear') ...[
                        const SizedBox(height: 20),
                        _sectionLabel("OCCASION"),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: ['Casual', 'Work', 'Party', 'Formal', 'Gym'].map((o) =>
                            _chip(o, occasion == o, () => ss(() => occasion = o))).toList(),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
                          child: SwitchListTile(
                            title: const Text("Needs Ironing?", style: TextStyle(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                            subtitle: const Text("Will be skipped in Hurry Mode", style: TextStyle(color: kTextSecondary, fontSize: 11)),
                            value: ironing,
                            onChanged: (v) => ss(() => ironing = v),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              // Fixed Save Button
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                decoration: BoxDecoration(
                  color: kSurface,
                  border: Border(top: BorderSide(color: kBorder)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _saveItem(path: path, category: category, color: ai['color'] ?? 'white',
                        occasion: occasion, ironing: ironing, tags: tags);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Row(children: [Icon(Icons.check_circle, color: kGold, size: 16), SizedBox(width: 8), Text("Added to Wardrobe!")]))
                      );
                    },
                    child: const Text("ADD TO WARDROBE"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveItem({required String path, required String category, required String color,
      required String occasion, required bool ironing, required List<String> tags}) {
    double formality = 0.4;
    if (occasion == 'Formal') formality = 0.9;
    else if (occasion == 'Work') formality = 0.7;
    else if (occasion == 'Party') formality = 0.6;

    final item = ClothesItem(
      path: path, category: category, color: color,
      occasion: category == 'Footwear' ? null : occasion,
      needsIroning: category == 'Footwear' ? false : ironing,
      isDirty: false, wearCount: 0,
      formalityScore: formality,
      weatherSuitability: ['All'],
      colorHue: 0.0,
      tags: List.from(tags),
    );
    Hive.box<ClothesItem>('clothesBox_v2').add(item);
    setState(() {});
  }

  Widget _sectionLabel(String text) =>
    Text(text, style: const TextStyle(fontWeight: FontWeight.w900, color: kGold, letterSpacing: 1.5, fontSize: 10));

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kGold : kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? Colors.transparent : kBorder),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.black : kTextSecondary, fontWeight: FontWeight.w700, fontSize: 12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<ClothesItem>('clothesBox_v2');
    final items = box.values.where((i) => i.category == _filter).toList();
    final all = box.values.toList();

    return Scaffold(
      appBar: AppBar(title: const Text("MY WARDROBE")),
      body: Column(
        children: [
          const SizedBox(height: 8),
          // ── Stats bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildStatsRow(all),
          ),
          const SizedBox(height: 20),
          // ── Upload buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(child: _uploadBtn(Icons.camera_alt_outlined, "Camera", ImageSource.camera)),
                const SizedBox(width: 12),
                Expanded(child: _uploadBtn(Icons.photo_library_outlined, "Gallery", ImageSource.gallery)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // ── Category filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: ['Tops', 'Bottoms', 'Dresses', 'Footwear'].map((c) {
                final sel = _filter == c;
                return GestureDetector(
                  onTap: () => setState(() => _filter = c),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Column(
                      children: [
                        Text(c, style: TextStyle(
                          color: sel ? kTextPrimary : kTextSecondary,
                          fontWeight: FontWeight.w800, fontSize: 14)),
                        const SizedBox(height: 5),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          height: 2, width: sel ? 24 : 0,
                          decoration: BoxDecoration(color: kGold, borderRadius: BorderRadius.circular(2)),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          // ── Grid or scanning state or empty
          Expanded(
            child: _isScanning
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
                  CircularProgressIndicator(color: kGold),
                  SizedBox(height: 16),
                  Text("AI is analyzing your item...", style: TextStyle(color: kTextSecondary)),
                ]))
              : items.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.style_outlined, size: 72, color: kBorder),
                    const SizedBox(height: 16),
                    Text("No ${_filter} yet", style: const TextStyle(color: kTextSecondary, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    const Text("Add items using the buttons above", style: TextStyle(color: kTextSecondary, fontSize: 12)),
                  ]))
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 0.75),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _clothesCard(items[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(List<ClothesItem> all) {
    final Map<String, int> counts = {'Tops': 0, 'Bottoms': 0, 'Dresses': 0, 'Footwear': 0};
    for (final i in all) { counts[i.category] = (counts[i.category] ?? 0) + 1; }
    return Row(
      children: counts.entries.map((e) => Expanded(child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
        child: Column(children: [
          Text("${e.value}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kTextPrimary)),
          const SizedBox(height: 2),
          Text(e.key, style: const TextStyle(fontSize: 9, color: kTextSecondary, fontWeight: FontWeight.w600)),
        ]),
      ))).toList(),
    );
  }

  Widget _uploadBtn(IconData icon, String label, ImageSource source) {
    return GestureDetector(
      onTap: () => _addItem(source: source),
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: kGold, size: 28),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _clothesCard(ClothesItem item) {
    return Container(
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(22), border: Border.all(color: kBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  child: Image.file(File(item.path), width: double.infinity, fit: BoxFit.cover),
                ),
                // Delete button
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: () async { await item.delete(); setState(() {}); },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, size: 12, color: Colors.white70),
                    ),
                  ),
                ),
                // Dirty/ironing badge
                if (item.isDirty || item.needsIroning)
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.85), borderRadius: BorderRadius.circular(6)),
                      child: Text(item.isDirty ? "🧺 Dirty" : "🪣 Iron", style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.color.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: kTextPrimary)),
                const SizedBox(height: 2),
                Text(item.occasion ?? "ANYTIME", style: const TextStyle(fontSize: 9, color: kTextSecondary, fontWeight: FontWeight.w600)),
                if (item.tags.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Wrap(spacing: 4, children: item.tags.take(2).map((t) =>
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(5)),
                      child: Text(t, style: const TextStyle(fontSize: 8, color: kTextSecondary)),
                    )).toList()),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
