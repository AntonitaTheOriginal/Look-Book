import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import 'models/clothes_item.dart';
import 'models/outfit.dart';
import 'home_screen.dart';
import 'screens/closet_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/analytics_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env");

    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ClothesItemAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(OutfitAdapter());

    await Hive.openBox<ClothesItem>('clothesBox_v2');
    await Hive.openBox<Outfit>('savedOutfits_v2');
    await Hive.openBox('calendarBox');
    await Hive.openBox('settingsBox');

    final settingsBox = Hive.box('settingsBox');
    if (settingsBox.get('userName') == null) {
      settingsBox.put('userName', 'Fashionista');
    }

    runApp(const LookBookApp());
  } catch (e) {
    debugPrint("Init Error: $e");
    runApp(const LookBookApp());
  }
}

// ─── Design Tokens ─────────────────────────────────────────────────────────────
const kBg = Color(0xFF0D0D0F);
const kSurface = Color(0xFF161618);
const kCard = Color(0xFF1E1E21);
const kGold = Color(0xFFD4AF37);
const kGoldLight = Color(0xFFE8C84A);
const kTextPrimary = Colors.white;
const kTextSecondary = Color(0xFF8E8E93);
const kBorder = Color(0xFF2C2C2E);

class LookBookApp extends StatelessWidget {
  const LookBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LookBook AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBg,
        primaryColor: kGold,
        colorScheme: const ColorScheme.dark(
          primary: kGold,
          secondary: kTextSecondary,
          surface: kSurface,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: kTextPrimary, letterSpacing: -0.5),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kTextPrimary),
          titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTextPrimary, letterSpacing: 0.5),
          bodyMedium: TextStyle(fontSize: 14, color: kTextSecondary, height: 1.5),
          labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: kGold, letterSpacing: 1.5),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kGold,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: kTextPrimary,
            side: const BorderSide(color: kBorder, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.5),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2.5, fontSize: 13, color: kTextPrimary),
          iconTheme: IconThemeData(color: kTextSecondary),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: kGold,
          unselectedLabelColor: kTextSecondary,
          indicatorColor: kGold,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? kGold : kTextSecondary),
          trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? kGold.withOpacity(0.3) : kBorder),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: kCard,
          contentTextStyle: const TextStyle(color: kTextPrimary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
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

// ─── Splash Screen ──────────────────────────────────────────────────────────────
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // ── Logo
              Container(
                height: 110,
                width: 110,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kGoldLight, kGold, Color(0xFFB8860B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(color: kGold.withOpacity(0.35), blurRadius: 50, offset: const Offset(0, 16))],
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.black, size: 52),
              ),
              const SizedBox(height: 40),
              // ── Title
              const Text("LOOKBOOK AI",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 5, color: kTextPrimary)),
              const SizedBox(height: 14),
              const Text(
                "Your AI personal stylist.\nDress for where you're going.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: kTextSecondary, height: 1.6),
              ),
              const Spacer(flex: 2),
              // ── Features
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _featurePill(Icons.wb_sunny_outlined, "Weather"),
                  const SizedBox(width: 10),
                  _featurePill(Icons.auto_awesome, "Claude AI"),
                  const SizedBox(width: 10),
                  _featurePill(Icons.style_outlined, "Smart Fit"),
                ],
              ),
              const Spacer(),
              // ── CTA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    shadowColor: kGold.withOpacity(0.5),
                    elevation: 16,
                  ),
                  onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                  child: const Text("BEGIN YOUR JOURNEY", style: TextStyle(letterSpacing: 1.5, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featurePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: kGold),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
