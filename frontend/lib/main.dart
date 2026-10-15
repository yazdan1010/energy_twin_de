import 'package:flutter/material.dart';
import 'package:frontend/advisor_screen.dart';
import 'package:frontend/home_screen.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/price_dashboard_screen.dart';
import 'package:frontend/solar_dashboard_screen.dart';
import 'package:frontend/ui/glass_nav_bar.dart';
import 'package:frontend/ui/kit.dart';
import 'package:frontend/ui/locale_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

const kBackendUrl = 'https://energy-twin-de.onrender.com';

// Fires the moment the app launches — wakes Render before the user touches anything.
// All screens await this future; if the server is already warm it resolves instantly.
final Future<void> serverWarmup = http
    .get(Uri.parse('$kBackendUrl/'))
    .timeout(const Duration(seconds: 90))
    .then((_) {})
    .catchError((_) {});

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await localeController.load();
  runApp(const EnergyTwinApp());
}

class EnergyTwinApp extends StatelessWidget { 
  const EnergyTwinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([themeNotifier, localeController]),
      builder: (context, _) {
        final currentMode = themeNotifier.value;
        return MaterialApp(
          onGenerateTitle: (context) => context.l10n.appTitle,
          debugShowCheckedModeBanner: false,
          locale: localeController.value,
          supportedLocales: LocaleController.supported,
          localizationsDelegates: AppLocalizations.localizationsDelegates,

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
            scaffoldBackgroundColor: const AppPalette(false).bg,
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
            scaffoldBackgroundColor: const AppPalette(true).bg,
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
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    HomeScreen(themeNotifier: themeNotifier, onNavigate: _goTo),
    PriceDashboardScreen(themeNotifier: themeNotifier),
    AdvisorScreen(themeNotifier: themeNotifier),
    SolarDashboardScreen(themeNotifier: themeNotifier),
  ];

  void _goTo(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.02), end: Offset.zero).animate(anim),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey(_currentIndex), child: _screens[_currentIndex]),
      ),
      bottomNavigationBar: GlassNavBar(
        index: _currentIndex,
        onChanged: _goTo,
        items: [
          GlassNavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            label: context.l10n.navHome,
            colors: [AppColors.emerald, AppColors.sky],
          ),
          GlassNavItem(
            icon: Icons.insights_outlined,
            selectedIcon: Icons.insights_rounded,
            label: context.l10n.navPrices,
            colors: [AppColors.sky, AppColors.indigo],
          ),
          GlassNavItem(
            icon: Icons.heat_pump_outlined,
            selectedIcon: Icons.heat_pump_rounded,
            label: context.l10n.navAdvisor,
            colors: [AppColors.emerald, AppColors.teal],
          ),
          GlassNavItem(
            icon: Icons.solar_power_outlined,
            selectedIcon: Icons.solar_power_rounded,
            label: context.l10n.navSolar,
            colors: [AppColors.amber, AppColors.orange],
          ),
        ],
      ),
    );
  }
}
