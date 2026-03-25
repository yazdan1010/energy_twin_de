import 'package:flutter/material.dart';
import 'package:frontend/advisor_screen.dart';
import 'package:frontend/price_dashboard_screen.dart';
import 'package:frontend/solar_dashboard_screen.dart';
import 'package:google_fonts/google_fonts.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);
void main() {
  runApp(const EnergyTwinApp());
}

class EnergyTwinApp extends StatelessWidget {
  const EnergyTwinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, _) {
        return MaterialApp(
          title: 'EnergyTwin Pro',
          debugShowCheckedModeBanner: false,

          // Now it listens to our manual toggle!
          themeMode: currentMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF059669),
              secondary: Color(0xFF0284C7),
              surface: Color(0xFFF8FAFC),
              onSurface: Color(0xFF0F172A),
            ),
            textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
            scaffoldBackgroundColor: const Color(0xFFF1F5F9),
          ),

          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF10B981),
              secondary: Color(0xFF38BDF8),
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
            textTheme: GoogleFonts.interTextTheme(
              ThemeData.dark().textTheme,
            ).apply(bodyColor: Colors.white, displayColor: Colors.white),
            scaffoldBackgroundColor: const Color(0xFF0F172A),
          ),
          home: AppShell(),
        );
      },
    );
  }
}

// ----------------------------------------------------------------------
// 1. The App Shell (Navigation Bar & Screen Management)
// ----------------------------------------------------------------------
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0; // Start on the Advisor screen for now

  final List<Widget> _screens = [
    PriceDashboardScreen(themeNotifier: themeNotifier), // Screen 0
    AdvisorScreen(themeNotifier: themeNotifier),
    SolarDashboardScreen(themeNotifier: themeNotifier), // Screen 1
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Prices',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate),
            label: 'Advisor',
          ),
          NavigationDestination(icon: Icon(Icons.solar_power), label: 'Solar AI'),
        ],
      ),
    );
  }
}
