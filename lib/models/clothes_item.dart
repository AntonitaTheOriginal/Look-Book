import 'package:hive/hive.dart';

class ClothesItem extends HiveObject {
  @HiveField(0)
  final String path;

  @HiveField(1)
  final String category;

  @HiveField(2)
  final String color;

  @HiveField(3)
  final String? occasion;

  @HiveField(4)
  final String? place;

  @HiveField(5)
  bool needsIroning;

  @HiveField(6)
  bool isDirty;

  @HiveField(7)
  int wearCount;

  @HiveField(8)
  DateTime? lastWornDate;

  // New Derived Fields for Hybrid Intelligence
  @HiveField(9)
  double formalityScore; // 0.0 (Casual) to 1.0 (Formal)

  @HiveField(10)
  List<String> weatherSuitability; // ['Hot', 'Cold', 'Rainy'] etc.

  @HiveField(11)
  double colorHue; // Hue value from 0-360

  @HiveField(12)
  Map<String, double> userPreferenceWeights;

  @HiveField(13)
  List<String> tags;

  ClothesItem({
    required this.path,
    required this.category,
    required this.color,
    this.occasion,
    this.place,
    this.needsIroning = false,
    this.isDirty = false,
    this.wearCount = 0,
    this.lastWornDate,
    this.formalityScore = 0.5,
    this.weatherSuitability = const ['All'],
    this.colorHue = 0.0,
    this.userPreferenceWeights = const {},
    this.tags = const [],
  });
}

class ClothesItemAdapter extends TypeAdapter<ClothesItem> {
  @override
  final int typeId = 0;

  @override
  ClothesItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClothesItem(
      path: fields[0] as String,
      category: fields[1] as String,
      color: fields[2] as String,
      occasion: fields[3] as String?,
      place: fields[4] as String?,
      needsIroning: fields[5] as bool,
      isDirty: fields[6] as bool,
      wearCount: fields[7] as int,
      lastWornDate: fields[8] as DateTime?,
      formalityScore: (fields[9] as num?)?.toDouble() ?? 0.5,
      weatherSuitability: (fields[10] as List?)?.cast<String>() ?? const ['All'],
      colorHue: (fields[11] as num?)?.toDouble() ?? 0.0,
      userPreferenceWeights: (fields[12] as Map?)?.cast<String, double>() ?? const {},
      tags: (fields[13] as List?)?.cast<String>() ?? const [],
    );
  }

  @override
  void write(BinaryWriter writer, ClothesItem obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)..write(obj.path)
      ..writeByte(1)..write(obj.category)
      ..writeByte(2)..write(obj.color)
      ..writeByte(3)..write(obj.occasion)
      ..writeByte(4)..write(obj.place)
      ..writeByte(5)..write(obj.needsIroning)
      ..writeByte(6)..write(obj.isDirty)
      ..writeByte(7)..write(obj.wearCount)
      ..writeByte(8)..write(obj.lastWornDate)
      ..writeByte(9)..write(obj.formalityScore)
      ..writeByte(10)..write(obj.weatherSuitability)
      ..writeByte(11)..write(obj.colorHue)
      ..writeByte(12)..write(obj.userPreferenceWeights)
      ..writeByte(13)..write(obj.tags);
  }
}

