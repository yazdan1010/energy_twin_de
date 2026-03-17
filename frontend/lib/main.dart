import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);
void main() {
  runApp(const EnergyTwinApp());
}

class EnergyTwinApp extends StatelessWidget {
  const EnergyTwinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
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
          home: const AppShell(),
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
  int _currentIndex = 1; // Start on the Advisor screen for now

  final List<Widget> _screens = [
    const PriceDashboardScreen(), // Screen 0
    const AdvisorScreen(), // Screen 1
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
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// 2. The Interactive Advisor Screen (Task 1)
// ----------------------------------------------------------------------
class AdvisorScreen extends StatefulWidget {
  const AdvisorScreen({super.key});

  @override
  State<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends State<AdvisorScreen> {
  final TextEditingController _gasBillController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _roiData;
  String _errorMessage = '';

  String get _apiUrl {
    const port = '5001';
    const endpoint = '/simulate_investment';
    if (kIsWeb) return 'http://127.0.0.1:$port$endpoint';
    if (Platform.isAndroid) return 'http://10.0.2.2:$port$endpoint';
    return 'http://127.0.0.1:$port$endpoint';
  }

  Future<void> _calculateROI() async {
    // Validate user input
    final inputString = _gasBillController.text.trim();
    if (inputString.isEmpty) {
      setState(() => _errorMessage = 'Please enter your monthly gas bill.');
      return;
    }

    final double? userBill = double.tryParse(inputString);
    if (userBill == null || userBill <= 0) {
      setState(() => _errorMessage = 'Please enter a valid number greater than 0.');
      return;
    }

    // Unfocus the keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _roiData = null;
    });

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'monthly_gas_bill_eur': userBill}),
      );

      if (response.statusCode == 200) {
        setState(() => _roiData = jsonDecode(response.body));
      } else {
        setState(() => _errorMessage = 'API Error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Connection failed. Is Flask running?');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _gasBillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Investment Advisor', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(
              themeNotifier.value == ThemeMode.light ? Icons.dark_mode : Icons.light_mode,
              color: theme.colorScheme.primary,
            ),
            onPressed: () {
              // Toggle the theme between light and dark!
              themeNotifier.value = themeNotifier.value == ThemeMode.light
                  ? ThemeMode.dark
                  : ThemeMode.light;
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(24.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      'AI Heat Pump Analysis',
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your current monthly gas cost to simulate your personalized AI savings.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildInputCard(theme, isDark),
                    const SizedBox(height: 24),
                    if (_errorMessage.isNotEmpty) _buildErrorCard(theme),
                    if (_roiData != null) _buildResultsDashboard(theme, isDark),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            // Using .withAlpha() instead of .withOpacity() as requested!
            color: Colors.black.withAlpha(isDark ? 50 : 15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Heating Bill',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _gasBillController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Monthly Gas Bill',
              hintText: 'e.g. 150',
              prefixIcon: const Icon(Icons.euro),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              filled: true,
              fillColor: isDark ? theme.scaffoldBackgroundColor : Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _calculateROI,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: const Text(
                'Calculate Savings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsDashboard(ThemeData theme, bool isDark) {
    final savings = _roiData!['ai_annual_savings_eur'];
    final roiYears = _roiData!['estimated_roi_years'];

    // Emerald Green with 25 Alpha for the background tint
    final highlightColor = theme.colorScheme.primary.withAlpha(25);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: highlightColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.primary.withAlpha(75)),
          ),
          child: Column(
            children: [
              Text(
                'AI Annual Savings',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '€$savings',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text('Pays for itself in $roiYears Years', style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withAlpha(75)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 16),
          Expanded(
            child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// 3. The Live Day-Ahead Market Chart (Task 2)
// ----------------------------------------------------------------------
// ----------------------------------------------------------------------
// 3. The Professional "Bento Box" Market Dashboard
// ----------------------------------------------------------------------
class PriceDashboardScreen extends StatefulWidget {
  const PriceDashboardScreen({super.key});

  @override
  State<PriceDashboardScreen> createState() => _PriceDashboardScreenState();
}

class _PriceDashboardScreenState extends State<PriceDashboardScreen> {
  List<double> _hourlyPrices = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _targetDate = '';

  String get _apiUrl {
    const port = '5001';
    const endpoint = '/predict_tomorrow';
    if (kIsWeb) return 'http://127.0.0.1:$port$endpoint';
    if (Platform.isAndroid) return 'http://10.0.2.2:$port$endpoint';
    return 'http://127.0.0.1:$port$endpoint';
  }

  @override
  void initState() {
    super.initState();
    _fetchLiveForecast();
  }

  Future<void> _fetchLiveForecast() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _hourlyPrices = List<double>.from(data['hourly_prices'].map((x) => x.toDouble()));
          _targetDate = data['date'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'API Error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to connect to backend.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('EnergyTwin Command Center', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: theme.colorScheme.primary),
            onPressed: () => themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
              : _buildDashboardLayout(theme, isDark),
    );
  }

  Widget _buildDashboardLayout(ThemeData theme, bool isDark) {
    double minPrice = _hourlyPrices.reduce((curr, next) => curr < next ? curr : next);
    int bestHour = _hourlyPrices.indexOf(minPrice);
    
    // Simulate current time/price for the dashboard feel (assuming it's roughly hour 14 for the demo)
    double currentPrice = _hourlyPrices.isNotEmpty ? _hourlyPrices[14] : 0.0; 

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200), // Wide layout for web!
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('System Overview', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),
              
              // TOP ROW: KPI Cards (Responsive Wrap)
              Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  _buildKPICard(
                    theme, isDark,
                    title: 'Current Spot Price',
                    value: '€${currentPrice.toStringAsFixed(2)}',
                    subtitle: 'per MWh',
                    icon: Icons.bolt,
                    color: currentPrice < 50 ? Colors.green : Colors.orange,
                    width: 300,
                  ),
                  _buildKPICard(
                    theme, isDark,
                    title: 'Heat Pump Status',
                    value: currentPrice < 50 ? 'Pre-Heating' : 'Idling',
                    subtitle: currentPrice < 50 ? 'Capitalizing on cheap energy' : 'Waiting for optimal window',
                    icon: Icons.heat_pump,
                    color: theme.colorScheme.primary,
                    width: 300,
                  ),
                  _buildKPICard(
                    theme, isDark,
                    title: 'Next Optimal Window',
                    value: '${bestHour.toString().padLeft(2, '0')}:00',
                    subtitle: 'Price drops to €${minPrice.toStringAsFixed(2)}',
                    icon: Icons.schedule,
                    color: theme.colorScheme.secondary,
                    width: 300,
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // BOTTOM ROW: Main Chart + Context
              LayoutBuilder(
                builder: (context, constraints) {
                  // If screen is wide enough, put chart and context side-by-side
                  if (constraints.maxWidth > 800) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildChartCard(theme, isDark)),
                        const SizedBox(width: 24),
                        Expanded(flex: 1, child: _buildGridContextCard(theme, isDark)),
                      ],
                    );
                  }
                  // Otherwise, stack them for mobile/narrow screens
                  return Column(
                    children: [
                      _buildChartCard(theme, isDark),
                      const SizedBox(height: 24),
                      _buildGridContextCard(theme, isDark),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Generic reusable UI for Dashboard Widgets
  Widget _buildKPICard(ThemeData theme, bool isDark, {required String title, required String value, required String subtitle, required IconData icon, required Color color, required double width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 30 : 10), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: theme.textTheme.titleSmall?.copyWith(color: isDark ? Colors.white70 : Colors.black54)),
              Icon(icon, color: color, size: 24),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white54 : Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildChartCard(ThemeData theme, bool isDark) {
    return Container(
      height: 400, // Fixed height for the chart area
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 30 : 10), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Day-Ahead Market Forecast ($_targetDate)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: isDark ? Colors.white10 : Colors.black12, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 4,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text('${value.toInt()}:00', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 40,
                      getTitlesWidget: (value, meta) => Text('€${value.toInt()}', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 23,
                lineBarsData: [
                  LineChartBarData(
                    spots: _hourlyPrices.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                    isCurved: true,
                    color: theme.colorScheme.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: theme.colorScheme.primary.withAlpha(25),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => theme.colorScheme.onSurface,
                    getTooltipItems: (touchedSpots) => touchedSpots.map((spot) => LineTooltipItem(
                      '${spot.x.toInt()}:00\n€${spot.y.toStringAsFixed(1)}',
                      TextStyle(color: theme.colorScheme.surface, fontWeight: FontWeight.bold),
                    )).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridContextCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Grid Intelligence', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildContextRow(theme, isDark, Icons.wb_sunny, 'Solar Forecast', 'High Yield expected at 13:00', Colors.orange),
          const Divider(height: 32),
          _buildContextRow(theme, isDark, Icons.air, 'Wind Forecast', 'Moderate Offshore winds', Colors.lightBlue),
          const Divider(height: 32),
          _buildContextRow(theme, isDark, Icons.memory, 'AI Confidence', '94% (Trained on XGBoost)', Colors.purple),
        ],
      ),
    );
  }

  Widget _buildContextRow(ThemeData theme, bool isDark, IconData icon, String title, String subtitle, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white54 : Colors.black54)),
            ],
          ),
        ),
      ],
    );
  }
}
