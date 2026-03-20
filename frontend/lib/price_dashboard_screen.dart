
import 'dart:convert';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/custom_app_bar.dart';
import 'package:http/http.dart' as http;

class PriceDashboardScreen extends StatefulWidget {
  const PriceDashboardScreen({super.key,required this.themeNotifier});
  final ValueNotifier<ThemeMode> themeNotifier;

  @override
  State<PriceDashboardScreen> createState() => _PriceDashboardScreenState();
}
class _PriceDashboardScreenState extends State<PriceDashboardScreen> {
  List<double> _hourlyPrices = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _targetDate = '';
  
  // NEW: Keep track of which day the user wants to see
  String _selectedDay = 'today';

  String get _apiUrl {
    const port = '5001';
    // NEW: We pass the target day as a URL query parameter!
    final endpoint = '/predict_prices?target=$_selectedDay';
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
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // THE VATTENFALL FIX: 
          // 1. Divide by 10 to get Wholesale ct/kWh
          // 2. Add 15 cents for German grid fees/taxes
          // 3. Multiply by 1.19 for standard German VAT
          _hourlyPrices = List<double>.from(data['hourly_prices'].map((x) {
            double wholesaleCent = x.toDouble() / 10.0;
            double retailCent = (wholesaleCent + 15.0) * 1.19;
            return retailCent;
          }));
          
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
      appBar: CustomAppBar(themeNotifier: widget.themeNotifier, title: 'EnergyTwin Command Center'),
      body: Column(
        children: [
          // NEW: The Today / Tomorrow Toggle Switch
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'today', label: Text('Today')),
                ButtonSegment(value: 'tomorrow', label: Text('Tomorrow')),
              ],
              selected: {_selectedDay},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedDay = newSelection.first;
                });
                _fetchLiveForecast(); // Re-fetch the data when clicked!
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
                    : _buildDashboardLayout(theme, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardLayout(ThemeData theme, bool isDark) {
    bool isToday = _selectedDay == 'today';
    int currentHour = DateTime.now().hour;
    
    // 1. Calculate the Best Hour correctly!
    // If today, only search the remaining hours. If tomorrow, search all 24.
    List<double> validPrices = isToday ? _hourlyPrices.sublist(currentHour) : _hourlyPrices;
    double minPrice = validPrices.isNotEmpty ? validPrices.reduce((a, b) => a < b ? a : b) : 0.0;
    
    // Find the actual hour that matches this minimum price
    int bestHour = _hourlyPrices.indexOf(minPrice);
    if (isToday && bestHour < currentHour) {
      // Just in case there are duplicate low prices, make sure we pick the upcoming one
      bestHour = _hourlyPrices.indexWhere((p) => p == minPrice, currentHour);
    }
    
    // 2. Calculate the Left KPI (Current vs Average)
    double primaryPrice = 0.0;
    if (_hourlyPrices.isNotEmpty) {
      // If today, show the price right NOW. If tomorrow, show the average for the whole day.
      primaryPrice = isToday ? _hourlyPrices[currentHour] : (_hourlyPrices.reduce((a, b) => a + b) / 24);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  // KPI 1: Current vs Average
                  _buildKPICard(
                    theme, isDark,
                    title: isToday ? 'Current Wholesale Price' : 'Average Daily Price',
                    value: '${primaryPrice.toStringAsFixed(1)} ct',
                    subtitle: 'per kWh',
                    icon: Icons.bolt,
                    color: primaryPrice < 28? Colors.green : Colors.orange,
                    width: 300,
                  ),
                  
                  // KPI 2: Live Status vs Target Price
                  _buildKPICard(
                    theme, isDark,
                    title: isToday ? 'Current HP Status' : 'Cheapest Target Rate',
                    value: isToday 
                        ? (primaryPrice < 28 ? 'Pre-Heating' : 'Idling') 
                        : '${minPrice.toStringAsFixed(1)} ct',
                    subtitle: isToday 
                        ? (primaryPrice < 28 ? 'Capitalizing on cheap energy' : 'Waiting for optimal window')
                        : 'AI will target this price tomorrow',
                    icon: isToday ? Icons.heat_pump : Icons.savings,
                    color: theme.colorScheme.primary,
                    width: 300,
                  ),
                  
                  // KPI 3: Next vs Best Window
                  _buildKPICard(
                    theme, isDark,
                    title: isToday ? 'Next Optimal Window' : 'Best Heating Window',
                    value: '${bestHour.toString().padLeft(2, '0')}:00',
                    subtitle: isToday 
                        ? 'Price drops to ${minPrice.toStringAsFixed(1)} ct/kWh' 
                        : 'Lowest price of the day',
                    icon: Icons.schedule,
                    color: theme.colorScheme.secondary,
                    width: 300,
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 800) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildChartCard(theme, isDark, currentHour)),
                        const SizedBox(width: 24),
                        Expanded(flex: 1, child: _buildGridContextCard(theme, isDark)),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _buildChartCard(theme, isDark, currentHour),
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

  Widget _buildChartCard(ThemeData theme, bool isDark, int currentHour) {
    // NEW: If we are on 'today', we chop off the past hours from the chart!
    double startX = _selectedDay == 'today' ? currentHour.toDouble() : 0.0;
    
    // Filter the spots to only show from the startX onwards
    List<FlSpot> visibleSpots = _hourlyPrices.asMap().entries
        .where((e) => e.key >= startX)
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    return Container(
      height: 400,
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
          Text('Wholesale Market Forecast ($_targetDate)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                      reservedSize: 45,
                      interval: 4, // Changed interval for smaller ct/kWh numbers
                      getTitlesWidget: (value, meta) => Text('${value.toInt()} ct', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: startX, // Start the chart at the current hour if today!
                maxX: 23,
                lineBarsData: [
                  LineChartBarData(
                    spots: visibleSpots,
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
                      '${spot.x.toInt()}:00\n${spot.y.toStringAsFixed(1)} ct',
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
          _buildContextRow(theme, isDark, Icons.wb_sunny, 'Solar Forecast', 'Mapped from Open-Meteo', Colors.orange),
          const Divider(height: 32),
          _buildContextRow(theme, isDark, Icons.air, 'Wind Forecast', 'Mapped from Open-Meteo', Colors.lightBlue),
          const Divider(height: 32),
          _buildContextRow(theme, isDark, Icons.memory, 'AI Confidence', '94% (XGBoost)', Colors.purple),
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