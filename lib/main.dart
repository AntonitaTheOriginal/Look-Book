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
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Hive.initFlutter();
  
  // Register Adapters
  Hive.registerAdapter(ClothesItemAdapter());
  Hive.registerAdapter(OutfitAdapter());

  // Clear old data for migration to new structured models as per user approval
  // We use v2 box names to avoid conflicts and ensure a clean start
  await Hive.openBox<ClothesItem>('clothesBox_v2');
  await Hive.openBox<Outfit>('savedOutfits_v2');
  await Hive.openBox('calendarBox'); 

  runApp(const LookBookApp());
}


class LookBookApp extends StatelessWidget {
  const LookBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LookBook',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F1ED),
        primaryColor: const Color(0xFFB08968),
        fontFamily: 'Roboto',
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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Box
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFB08968),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
            ),

            const SizedBox(height: 30),

            // Title
            const Text(
              "LookBook AI",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 10),

            // Subtitle
            Text(
              "Style smarter. Faster.",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Create outfits from your own closet using AI",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 40),

            // Color palette preview
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                colorCircle(0xFFD6CCC2),
                colorCircle(0xFFB08968),
                colorCircle(0xFF7F5539),
              ],
            ),

            const SizedBox(height: 50),

            // Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB08968),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                );
              },
              child: const Text("Get Started"),
            ),
          ],
        ),
      ),
    );
  }

  Widget colorCircle(int color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      height: 60,
      width: 60,
      decoration: BoxDecoration(
        color: Color(color),
        shape: BoxShape.circle,
      ),
    );
  }
}
