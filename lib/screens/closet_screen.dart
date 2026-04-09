import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:hive/hive.dart';
import '../utils/ai_analyzer.dart';

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
  final ImagePicker picker = ImagePicker();

  // Progress calculation
  double _calculateProgress(Box box) {
    final tops = box.values.where((i) => i['category'] == 'Tops').length;
    final bottoms = box.values.where((i) => i['category'] == 'Bottoms').length;
    final footwear = box.values.where((i) => i['category'] == 'Footwear').length;
    final dresses = box.values.where((i) => i['category'] == 'Dresses').length;
    // Target: 5 tops, 5 bottoms, 3 footwear, 2 dresses = 15 items total
    final score = (tops / 5 + bottoms / 5 + footwear / 3 + dresses / 2) / 4;
    return score.clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    loadImages();
  }

  Future<void> pickImage({ImageSource source = ImageSource.gallery}) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    setState(() => isScanning = true);
    final aiResults = await AiAnalyzer.analyzeImage(pickedFile.path);
    setState(() {
      selectedColor = aiResults['color']!;
      // Only suggest category from AI if it's a known one
      final aiCat = aiResults['category']!;
      if (['Tops', 'Bottoms', 'Footwear', 'Dresses'].contains(aiCat)) {
        selectedCategory = aiCat;
      }
      isScanning = false;
    });

    _showSaveSheet(pickedFile.path);
  }

  void _saveItem(String path) {
    final box = Hive.box('clothesBox');
    final isFootwear = selectedCategory == 'Footwear';
    box.add({
      "path": path,
      "category": selectedCategory,
      "color": selectedColor,
      "occasion": isFootwear ? null : selectedOccasion,
      "place": isFootwear ? null : selectedPlace,
      "needsIroning": isFootwear ? false : needsIroning,
      "isDirty": false,
      "isUsed": false,
      "wearCount": 0,
      "lastWornDate": null,
    });
    setState(() => images.add(File(path)));
  }

  void _showSaveSheet(String path) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: Color(0xFFF5F1ED),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("AI Detected Details",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.brown.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 12, color: Colors.brown),
                        SizedBox(width: 4),
                        Text("AI Scanned",
                            style: TextStyle(color: Colors.brown, fontSize: 11)),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 4),
              const Text("Review and adjust before saving",
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 20),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(File(path), height: 180, width: 180, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Category", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Tops','Bottoms','Dresses','Footwear'].map((cat) {
                    final isSel = selectedCategory == cat;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedCategory = cat),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel ? Colors.brown : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSel ? Colors.brown : Colors.grey.shade300),
                        ),
                        child: Text(cat, style: TextStyle(color: isSel ? Colors.white : Colors.black87)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              const Text("Primary Color", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['black','white','blue','brown','beige','red','green','yellow','pink','purple','orange','teal']
                      .map((col) {
                    final isSel = selectedColor == col;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedColor = col),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel ? Colors.brown : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSel ? Colors.brown : Colors.grey.shade300),
                        ),
                        child: Text(col, style: TextStyle(color: isSel ? Colors.white : Colors.black87, fontSize: 12)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              // Only show Occasion/Place/Ironing for non-Footwear
              if (selectedCategory != 'Footwear') ...[
                const SizedBox(height: 16),
                const Text("Occasion", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Work','Party','Casual','Formal'].map((occ) {
                      final isSel = selectedOccasion == occ;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedOccasion = occ),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? Colors.brown : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSel ? Colors.brown : Colors.grey.shade300),
                          ),
                          child: Text(occ, style: TextStyle(color: isSel ? Colors.white : Colors.black87, fontSize: 12)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.iron, color: Colors.brown),
                        SizedBox(width: 8),
                        Text("Needs Ironing?"),
                      ],
                    ),
                    Switch(
                      value: needsIroning,
                      activeColor: Colors.brown,
                      onChanged: (val) => setModalState(() => needsIroning = val),
                    ),
                  ],
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () {
                    _saveItem(path);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Item added to wardrobe! 🎉")),
                    );
                  },
                  child: const Text("Save to Wardrobe", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void loadImages() {
    try {
      final box = Hive.box('clothesBox');
      final storedItems = box.values.toList();

      setState(() {
        images = storedItems
            .map((item) => File(item['path']))
            .toList();
      });
    } catch (e) {
      debugPrint("Error loading images: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('clothesBox');
    final filteredItems = box.values
        .where((item) => item['category'] == selectedCategory)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F2EE),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔙 Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Build Your Closet",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("Describe your items for better matching",
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 📊 Dynamic Progress
                      Builder(builder: (context) {
                        final box = Hive.box('clothesBox');
                        final progress = _calculateProgress(box);
                        final pct = (progress * 100).toInt();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Closet $pct% complete",
                                style: const TextStyle(color: Colors.brown)),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.brown),
                              ),
                            ),
                          ],
                        );
                      }),

                      const SizedBox(height: 20),

                      // 📸 Upload Section
                      Row(
                        children: [
                          Expanded(
                            child: uploadCard(
                              Icons.camera_alt,
                              "Take Photo",
                              () => pickImage(source: ImageSource.camera),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: uploadCard(
                              Icons.photo_library,
                              "Gallery",
                              () => pickImage(source: ImageSource.gallery),
                            ),
                          ),
                        ],
                      ),
                      if (isScanning)
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.brown.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.brown)),
                              SizedBox(width: 12),
                              Text("AI is scanning your garment...", style: TextStyle(color: Colors.brown, fontSize: 13)),
                            ],
                          ),
                        ),

                      const SizedBox(height: 20),

                      // 🧥 Selection Groups
                      sectionTitle("1. Category"),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            categorySelectChip("Tops"),
                            categorySelectChip("Bottoms"),
                            categorySelectChip("Dresses"),
                            categorySelectChip("Footwear"),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      sectionTitle("2. Color Tag"),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            colorChip("black"),
                            colorChip("white"),
                            colorChip("blue"),
                            colorChip("brown"),
                            colorChip("beige"),
                            colorChip("red"),
                            colorChip("green"),
                            colorChip("yellow"),
                            colorChip("pink"),
                            colorChip("purple"),
                            colorChip("orange"),
                            colorChip("teal"),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      sectionTitle("3. Occasion & Place"),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            parameterChip("occasion", "Work", selectedOccasion == "Work"),
                            parameterChip("occasion", "Party", selectedOccasion == "Party"),
                            parameterChip("occasion", "Casual", selectedOccasion == "Casual"),
                            parameterChip("occasion", "Formal", selectedOccasion == "Formal"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            parameterChip("place", "Office", selectedPlace == "Office"),
                            parameterChip("place", "Outdoor", selectedPlace == "Outdoor"),
                            parameterChip("place", "Home", selectedPlace == "Home"),
                            parameterChip("place", "Gym", selectedPlace == "Gym"),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 👕 Ironing Switch
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.iron, color: Colors.brown),
                                SizedBox(width: 10),
                                Text("Needs Ironing?",
                                    style: TextStyle(fontWeight: FontWeight.w500)),
                              ],
                            ),
                            Switch(
                              value: needsIroning,
                              activeColor: Colors.brown,
                              onChanged: (val) {
                                setState(() {
                                  needsIroning = val;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      sectionTitle("Your Wardrobe ($selectedCategory)"),
                      const SizedBox(height: 10),

                      // 🧺 Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredItems.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.brown.withOpacity(0.1)),
                              image: DecorationImage(
                                image: FileImage(File(item['path'])),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.brown,
        onPressed: () => Navigator.pop(context),
        label: const Text("Save & Exit", style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.check, color: Colors.white),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16));
  }

  Widget parameterChip(String type, String value, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (type == "occasion") selectedOccasion = value;
          if (type == "place") selectedPlace = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.brown : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.brown : Colors.grey.shade300),
        ),
        child: Text(
          value,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget categorySelectChip(String category) {
    final isSelected = selectedCategory == category;
    final box = Hive.box('clothesBox');
    final count = box.values
        .where((item) => item['category'] == category)
        .length;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.brown : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.brown : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Text(
              category,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(width: 6),
            CircleAvatar(
              radius: 10,
              backgroundColor: isSelected ? Colors.white : Colors.grey.shade400,
              child: Text(
                "$count",
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.brown : Colors.white,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget colorChip(String color) {
    final isSelected = selectedColor == color;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedColor = color;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.brown : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.brown : Colors.grey.shade300),
        ),
        child: Text(
          color,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget uploadCard(IconData icon, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.brown, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(15),
          color: Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.brown, size: 28),
            const SizedBox(height: 4),
            Text(text, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget tagChip(String text) {
    return Chip(
      label: Text(text),
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey.shade300),
    );
  }
}
