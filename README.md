# LookBook AI

A smart, AI-powered digital closet and outfit generator built with Flutter.

## Core Features & Technical Details

### 1. Digital Closet Management (`closet_screen.dart`)
- **Wardrobe Digitization**: Users can add clothing items via camera or gallery using the `image_picker` plugin.
- **AI-Powered Analysis**: Images are processed using `PaletteGenerator` to automatically detect the primary color of the garment.
- **Categorization**: Items are stored in specific categories (Tops, Bottoms, Dresses, Footwear) with customizable tags (Occasion, Place, Needs Ironing).
- **Local Storage**: All wardrobe data is persisted locally using `Hive` (NoSQL database), specifically in the `clothesBox`. The app tracks metadata such as `isDirty`, `wearCount`, and `lastWornDate`.

### 2. Smart Outfit Generation (`outfit_generator.dart`)
- **Algorithmic Styling**: Generates outfits based on color theory logic. It calculates hue differences to suggest Monochromatic, Complementary, or Analogous combinations.
- **Context-Aware Selection**: Filters items based on selected occasion, place, and whether the user is in a "Hurry Mode" (excluding items that need ironing).
- **Recency Penalty**: Prioritizes fresh combinations by applying a penalty score to items worn recently (`lastWornDate`).
- **Lucky Dip Mode**: Bypasses standard filters to offer completely randomized outfit suggestions for discovery.
- **Weather Integration**: Considers current weather data to guide outfit suggestions.

### 3. Wardrobe Maintenance & Laundry (`laundry_screen.dart`)
- **State Tracking**: Once an outfit is marked as "Worn Today", its components are flagged as `isDirty` (or `isUsed` for footwear).
- **Laundry Hub**: Separates items into 'Laundry' (Tops, Bottoms, Dresses) and 'Shoe Rack' (Footwear). Items here are excluded from future outfit generation until cleaned.
- **One-Tap Clean**: Users can globally or individually mark items as clean, resetting their dirty status in the `Hive` database and returning them to the active closet pool.

### 4. Outfit Calendar (`calendar_screen.dart`)
- **Scheduling**: Users can schedule generated outfits for future dates.
- **Persistence**: Scheduled looks are saved to the `calendarBox` using ISO 8601 date strings as keys.
- **Visual Grid**: Renders a dynamic calendar grid showing days with planned outfits, allowing users to modify or delete scheduled looks.

### 5. Closet Analytics (`analytics_screen.dart`)
- **Data Visualization**: Reads from the `clothesBox` to compute wardrobe utilization metrics.
- **Staples vs. Dormant**: Sorts items by `wearCount` to identify top 5 most worn items ("Staples") and items with zero wears ("Dormant"), helping users understand their styling habits.

## Technical Stack
- **Framework**: Flutter / Dart
- **State Management**: StatefulWidgets & ValueListenableBuilder (Hive)
- **Local Database**: Hive (Flutter-optimized NoSQL)
- **Image Processing**: `palette_generator` for color extraction
- **UI Architecture**: Custom theming with a refined brown/beige glassmorphism aesthetic.
