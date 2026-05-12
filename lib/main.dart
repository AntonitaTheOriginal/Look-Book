import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'screens/closet_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/analytics_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'models/clothes_item.dart';
import 'models/outfit.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Load secrets
    await dotenv.load(fileName: ".env");

    await Hive.initFlutter();
    
    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ClothesItemAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(OutfitAdapter());
    }

    // Open Boxes
    await Hive.openBox<ClothesItem>('clothesBox_v2');
    await Hive.openBox<Outfit>('savedOutfits_v2');
    await Hive.openBox('calendarBox'); 
    
    // User Settings Box
    final settingsBox = await Hive.openBox('settingsBox');
    if (settingsBox.get('userName') == null) {
      settingsBox.put('userName', 'Fashionista');
    }

    runApp(const LookBookApp());
  } catch (e) {
    debugPrint("Initialization Error: $e");
    runApp(const LookBookApp());
  }
}


class LookBookApp extends StatelessWidget {
  const LookBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LookBook AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F10),
        primaryColor: const Color(0xFFD4AF37), // Metallic Gold
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4AF37),
          secondary: Color(0xFFE5E5E5),
          surface: Color(0xFF1C1C1E),
        ),
        fontFamily: 'Inter', // We'll assume Inter is available or use Roboto
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -1),
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.white70),
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD4AF37),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/closet': (context) => const ClosetScreen(),
        '/calendar': (context) => const CalendarScreen(),
        '/analytics': (context) => const AnalyticsScreen(),
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0F10), Color(0xFF1C1C1E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Box
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.3), blurRadius: 40, offset: const Offset(0, 10))
                  ],
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.black, size: 50),
              ),

              const SizedBox(height: 60),

              // Title
              const Text(
                "LOOKBOOK AI",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 15),

              // Subtitle
              Text(
                "Personalized style, curated by intelligence.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.5),
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 80),

              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 10,
                    shadowColor: const Color(0xFFD4AF37).withOpacity(0.4),
                  ),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                  child: const Text(
                    "BEGIN JOURNEY",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
