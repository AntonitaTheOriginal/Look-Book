import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:hive/hive.dart';
import '../utils/ai_analyzer.dart';
import '../models/clothes_item.dart';

class ClosetScreen extends StatefulWidget {
  const ClosetScreen({super.key});

  @override
  _ClosetScreenState createState() => _ClosetScreenState();
}

class _ClosetScreenState extends State<ClosetScreen> {
  List<File> images = [];
  String selectedCategory = "Tops";
  String selectedColor = "white";
  String selectedOccasion = "Work";
  String selectedPlace = "Office";
  bool needsIroning = false;
  bool isScanning = false;
  String? processedPath;
  List<String> suggestedTags = [];
  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadImages();
  }

  void loadImages() {
    final box = Hive.box<ClothesItem>('clothesBox_v2');
    setState(() {
      images = box.values.map((item) => File(item.path)).toList();
    });
  }

  double _calculateProgress(Box box) {
    final tops = box.values.where((i) => i.category == 'Tops').length;
    final bottoms = box.values.where((i) => i.category == 'Bottoms').length;
    final footwear = box.values.where((i) => i.category == 'Footwear').length;
    final dresses = box.values.where((i) => i.category == 'Dresses').length;
    final score = (tops / 5 + bottoms / 5 + footwear / 3 + dresses / 2) / 4;
    return score.clamp(0.0, 1.0);
  }

  Future<void> pickImage({ImageSource source = ImageSource.gallery}) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    setState(() => isScanning = true);
    final removedBgPath = await AiAnalyzer.removeBackground(pickedFile.path);
    final aiResults = await AiAnalyzer.analyzeImage(removedBgPath ?? pickedFile.path);
    
    setState(() {
      processedPath = removedBgPath ?? pickedFile.path;
      selectedColor = aiResults['color']!;
      suggestedTags = List<String>.from(aiResults['tags'] ?? []);
      final aiCat = aiResults['category']!;
      if (['Tops', 'Bottoms', 'Footwear', 'Dresses'].contains(aiCat)) {
        selectedCategory = aiCat;
      }
      isScanning = false;
    });

    _showSaveSheet(processedPath!);
  }

  void _saveItem(String path) {
    final box = Hive.box<ClothesItem>('clothesBox_v2');
    final isFootwear = selectedCategory == 'Footwear';
    double formality = 0.5;
    if (selectedOccasion == 'Formal') formality = 0.9;
    if (selectedOccasion == 'Work') formality = 0.7;
    if (selectedOccasion == 'Casual') formality = 0.3;

    final item = ClothesItem(
      path: path,
      category: selectedCategory,
      color: selectedColor,
      occasion: isFootwear ? null : selectedOccasion,
      place: isFootwear ? null : selectedPlace,
      needsIroning: isFootwear ? false : needsIroning,
      isDirty: false,
      wearCount: 0,
      lastWornDate: null,
      formalityScore: formality,
      weatherSuitability: ['All'],
      colorHue: 0.0,
      tags: List.from(suggestedTags),
    );
    
    box.add(item);
    loadImages();
  }

  void _showSaveSheet(String path) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Color(0xFF1C1C1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Verify Details", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white54)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        height: 200, width: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          image: DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover),
                          boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _sheetSection("CATEGORY"),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      children: ['Tops','Bottoms','Dresses','Footwear'].map((cat) {
                        final isSel = selectedCategory == cat;
                        return _actionChip(cat, isSel, () => setModalState(() => selectedCategory = cat));
                      }).toList(),
                    ),
                    const SizedBox(height: 25),
                    _sheetSection("FABRIC & WEATHER"),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: [
                        'Linen', 'Breathable', 'Cotton', 'Wool', 'Thermal', 'Waterproof', 'Windproof', 'Thin', 'Thick'
                      ].map((tag) {
                        final isSelected = suggestedTags.contains(tag);
                        return _actionChip(tag, isSelected, () {
                          setModalState(() {
                            if (isSelected) suggestedTags.remove(tag);
                            else suggestedTags.add(tag);
                          });
                        });
                      }).toList(),
                    ),
                    const SizedBox(height: 25),
                    if (selectedCategory != 'Footwear') ...[
                      _sheetSection("OCCASION"),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        children: ['Work','Party','Casual','Formal'].map((occ) {
                          final isSel = selectedOccasion == occ;
                          return _actionChip(occ, isSel, () => setModalState(() => selectedOccasion = occ));
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      SwitchListTile(
                        title: const Text("Needs Ironing?", style: TextStyle(color: Colors.white, fontSize: 14)),
                        value: needsIroning,
                        activeColor: const Color(0xFFD4AF37),
                        onChanged: (v) => setModalState(() => needsIroning = v),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _saveItem(path);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Added to Wardrobe ✨")));
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

  Widget _sheetSection(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFD4AF37), fontSize: 11, letterSpacing: 1.5));
  }

  Widget _actionChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.1)),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<ClothesItem>('clothesBox_v2');
    final filteredItems = box.values.where((item) => item.category == selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("MY CLOSET", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 14, color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildProgressSection(box),
            const SizedBox(height: 30),
            _buildUploadSection(),
            const SizedBox(height: 30),
            _buildCategoryFilters(),
            const SizedBox(height: 25),
            Expanded(
              child: filteredItems.isEmpty 
                ? _buildEmptyState()
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.8
                    ),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) => _buildClothesCard(filteredItems[index]),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(Box box) {
    final progress = _calculateProgress(box);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("CAPSULE GOAL", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 1)),
            Text("${(progress * 100).toInt()}%", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(value: progress, minHeight: 4, backgroundColor: Colors.white10, valueColor: const AlwaysStoppedAnimation(Color(0xFFD4AF37))),
        ),
      ],
    );
  }

  Widget _buildUploadSection() {
    return Row(
      children: [
        Expanded(child: _uploadButton(Icons.camera_alt_outlined, "CAMERA", () => pickImage(source: ImageSource.camera))),
        const SizedBox(width: 15),
        Expanded(child: _uploadButton(Icons.photo_library_outlined, "GALLERY", () => pickImage(source: ImageSource.gallery))),
      ],
    );
  }

  Widget _uploadButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFD4AF37), size: 30),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['Tops','Bottoms','Dresses','Footwear'].map((cat) {
          final isSel = selectedCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => selectedCategory = cat),
            child: Container(
              margin: const EdgeInsets.only(right: 15),
              child: Column(
                children: [
                  Text(cat.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: isSel ? Colors.white : Colors.white24, letterSpacing: 1)),
                  if (isSel) Container(margin: const EdgeInsets.only(top: 4), height: 2, width: 20, color: const Color(0xFFD4AF37)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildClothesCard(ClothesItem item) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Image.file(File(item.path), width: double.infinity, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 10, right: 10,
                  child: GestureDetector(
                    onTap: () async {
                      await item.delete();
                      loadImages();
                    },
                    child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, size: 14, color: Colors.white70)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.color.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(item.occasion ?? "ANYTIME", style: const TextStyle(fontSize: 9, color: Colors.white38)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.style_outlined, color: Colors.white10, size: 80),
          const SizedBox(height: 20),
          Text("NO $selectedCategory FOUND", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 8),
          Text("Add items to start building your capsule", style: TextStyle(color: Colors.white10, fontSize: 12)),
        ],
      ),
    );
  }
}
