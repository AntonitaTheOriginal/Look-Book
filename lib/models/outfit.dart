import 'package:hive/hive.dart';
import 'clothes_item.dart';

class Outfit extends HiveObject {
  @HiveField(0)
  final ClothesItem? top;

  @HiveField(1)
  final ClothesItem? bottom;

  @HiveField(2)
  final ClothesItem? shoes;

  @HiveField(3)
  final DateTime generatedAt;

  @HiveField(4)
  int? userRating; // -1 for dislike, 1 for like, 0 for neutral

  @HiveField(5)
  final String? suggestionLabel;

  @HiveField(6)
  final Map<String, dynamic>? aiInsights; // Stores breakdown of the score

  Outfit({
    this.top,
    this.bottom,
    this.shoes,
    required this.generatedAt,
    this.userRating = 0,
    this.suggestionLabel,
    this.aiInsights,
  });
}

class OutfitAdapter extends TypeAdapter<Outfit> {
  @override
  final int typeId = 1;

  @override
  Outfit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Outfit(
      top: fields[0] as ClothesItem?,
      bottom: fields[1] as ClothesItem?,
      shoes: fields[2] as ClothesItem?,
      generatedAt: fields[3] as DateTime,
      userRating: fields[4] as int?,
      suggestionLabel: fields[5] as String?,
      aiInsights: (fields[6] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, Outfit obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)..write(obj.top)
      ..writeByte(1)..write(obj.bottom)
      ..writeByte(2)..write(obj.shoes)
      ..writeByte(3)..write(obj.generatedAt)
      ..writeByte(4)..write(obj.userRating)
      ..writeByte(5)..write(obj.suggestionLabel)
      ..writeByte(6)..write(obj.aiInsights);
  }
}
