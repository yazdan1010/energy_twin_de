import 'dart:convert';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/custom_app_bar.dart';
import 'package:http/http.dart' as http;

class PriceDashboardScreen extends StatefulWidget {
  const PriceDashboardScreen({super.key, required this.themeNotifier});
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
    return 'https://energy-twin-de.onrender.com';
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
          _hourlyPrices = List<double>.from(
            data['hourly_prices'].map((x) {
              double wholesaleCent = x.toDouble() / 10.0;
              double retailCent = (wholesaleCent + 15.0) * 1.19;
              return retailCent;
            }),
          );

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
          // The Today / Tomorrow Toggle Switch
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
          SizedBox(height: 30),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                ? Center(
                    child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                  )
                : _buildDashboardLayout(theme, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardLayout(ThemeData theme, bool isDark) {
    int currentHour = DateTime.now().hour;

    // 1. Time-Aware Logic (Today vs Tomorrow)
    int searchStartHour = _selectedDay == 'today' ? (currentHour + 1) : 0;
    if (searchStartHour > 23) searchStartHour = 23;

    List<double> futurePrices = _hourlyPrices.isNotEmpty
        ? _hourlyPrices.sublist(searchStartHour)
        : [];

    double minPrice = futurePrices.isNotEmpty
        ? futurePrices.reduce((curr, next) => curr < next ? curr : next)
        : 0.0;

    int bestHour = futurePrices.isNotEmpty ? futurePrices.indexOf(minPrice) + searchStartHour : 0;

    // 2. Calculate Current Price and Average Price
    double currentPrice = 0.0;
    double averagePrice = 0.0;

    if (_hourlyPrices.isNotEmpty) {
      currentPrice = _selectedDay == 'today' ? _hourlyPrices[currentHour] : _hourlyPrices[0];
      averagePrice = _hourlyPrices.reduce((a, b) => a + b) / _hourlyPrices.length;
    }

    // 3. Dynamic KPI Card Content
    String card1Title = _selectedDay == 'today' ? 'Current Spot Price' : 'Average Daily Price';
    String card1Value = _selectedDay == 'today'
        ? '${currentPrice.toStringAsFixed(1)} ct'
        : '${averagePrice.toStringAsFixed(1)} ct';
    Color card1Color = (_selectedDay == 'today' ? currentPrice : averagePrice) < 15.0
        ? Colors.green
        : Colors.orange;

    String card2Title = _selectedDay == 'today' ? 'Heat Pump Status' : 'System Strategy';
    String card2Value = _selectedDay == 'today'
        ? (currentPrice < 15.0 ? 'Pre-Heating' : 'Idling')
        : (minPrice < 10.0 ? 'Deep Charge' : 'Smart Shift');
    String card2Subtitle = _selectedDay == 'today'
        ? (currentPrice < 15.0 ? 'Capitalizing on cheap energy' : 'Waiting for optimal window')
        : (minPrice < 10.0 ? 'Massive wind/solar savings available' : 'AI will avoid peak rates');
    IconData card2Icon = _selectedDay == 'today' ? Icons.heat_pump : Icons.auto_awesome;

    String card3Title = _selectedDay == 'today' ? 'Next Optimal Window' : 'Best Optimal Window';
    String card3Value = '${bestHour.toString().padLeft(2, '0')}:00';
    String card3Subtitle = 'Price drops to ${minPrice.toStringAsFixed(1)} ct/kWh';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Determine if we are on a wide screen (desktop/tablet) or narrow screen (mobile)
              final isWideScreen = constraints.maxWidth > 800;

              // Build the top row of KPI cards
              Widget kpiSection = isWideScreen
                  ? Row(
                      children: [
                        Expanded(
                          child: _buildKPICard(
                            theme,
                            isDark,
                            title: card1Title,
                            value: card1Value,
                            subtitle: 'per kWh',
                            icon: Icons.bolt,
                            color: card1Color,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildKPICard(
                            theme,
                            isDark,
                            title: card2Title,
                            value: card2Value,
                            subtitle: card2Subtitle,
                            icon: card2Icon,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildKPICard(
                            theme,
                            isDark,
                            title: card3Title,
                            value: card3Value,
                            subtitle: card3Subtitle,
                            icon: Icons.schedule,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _buildKPICard(
                          theme,
                          isDark,
                          title: card1Title,
                          value: card1Value,
                          subtitle: 'per kWh',
                          icon: Icons.bolt,
                          color: card1Color,
                        ),
                        const SizedBox(height: 16),
                        _buildKPICard(
                          theme,
                          isDark,
                          title: card2Title,
                          value: card2Value,
                          subtitle: card2Subtitle,
                          icon: card2Icon,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        _buildKPICard(
                          theme,
                          isDark,
                          title: card3Title,
                          value: card3Value,
                          subtitle: card3Subtitle,
                          icon: Icons.schedule,
                          color: theme.colorScheme.secondary,
                        ),
                      ],
                    );

              // Build the bottom section with Chart and Grid Intelligence
              Widget bottomSection = isWideScreen
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildChartCard(theme, isDark)),
                        const SizedBox(width: 24),
                        Expanded(flex: 1, child: _buildGridContextCard(theme, isDark)),
                      ],
                    )
                  : Column(
                      children: [
                        _buildChartCard(theme, isDark),
                        const SizedBox(height: 24),
                        _buildGridContextCard(theme, isDark),
                      ],
                    );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [kpiSection, const SizedBox(height: 32), bottomSection],
              );
            },
          ),
        ),
      ),
    );
  }

  // NOTE: Removed the 'width' parameter so it fluidly fills the Expanded widget
  Widget _buildKPICard(
    ThemeData theme,
    bool isDark, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 10),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              Icon(icon, color: color, size: 24),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(ThemeData theme, bool isDark) {
    int currentHour = DateTime.now().hour;
    // 1. Calculate dynamic Y-axis limits (Min - 5, Max + 5)
    double minY = 0.0;
    double maxY = 100.0; // Safe fallback

    if (_hourlyPrices.isNotEmpty) {
      double minPrice = _hourlyPrices.reduce((a, b) => a < b ? a : b);
      double maxPrice = _hourlyPrices.reduce((a, b) => a > b ? a : b);
      minY = minPrice - 3.0;
      maxY = maxPrice + 3.0;
    }

    List<FlSpot> visibleSpots = _hourlyPrices
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 10),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wholesale Market Forecast ($_targetDate)',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                // 2. APPLY THE DYNAMIC Y-AXIS LIMITS HERE
                minY: minY,
                maxY: maxY,
                minX: 0,
                maxX: 23,

                extraLinesData: ExtraLinesData(
                  verticalLines: _selectedDay == 'today'
                      ? [
                          VerticalLine(
                            x: currentHour.toDouble(),
                            color: Colors.redAccent,
                            strokeWidth: 1,
                            dashArray: [5, 5],
                            label: VerticalLineLabel(
                              show: true,
                              labelResolver: (line) => '',
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              alignment: Alignment.topRight,
                            ),
                          ),
                        ]
                      : [],
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: isDark ? Colors.white10 : Colors.black12, strokeWidth: 1),
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
                        child: Text(
                          '${value.toInt()}:00',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      // We can optionally set the Y-axis interval to scale nicely with the new limits
                      interval: ((maxY - minY) / 5).ceilToDouble(),
                      getTitlesWidget: (value, meta) {
                        // Only show titles that make sense within our limits to avoid clutter
                        if (value == minY || value == maxY) return const SizedBox.shrink();
                        return Text(
                          '${value.toInt()} ct',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: visibleSpots,
                    isCurved: true,
                    color: theme.colorScheme.primary,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, barData) {
                        return _selectedDay == 'today' && spot.x.toInt() == currentHour;
                      },
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 6,
                          color: Colors.redAccent,
                          strokeWidth: 3,
                          strokeColor: theme.colorScheme.surface,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: theme.colorScheme.primary.withAlpha(25),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => theme.colorScheme.onSurface,
                    getTooltipItems: (touchedSpots) => touchedSpots
                        .map(
                          (spot) => LineTooltipItem(
                            '${spot.x.toInt()}:00\n${spot.y.toStringAsFixed(1)} ct',
                            TextStyle(
                              color: theme.colorScheme.surface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                        .toList(),
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
      height: 400, // MATCHES THE CHART HEIGHT
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 10),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ], // ADDED MISSING SHADOW
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grid Intelligence',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // EXPANDED fills the remaining space, SPACE_BETWEEN distributes the rows evenly
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildContextRow(
                  theme,
                  isDark,
                  Icons.wb_sunny,
                  'Solar Physics',
                  'Mapped via Day-Ahead Forecast',
                  Colors.orange,
                ),
                const Divider(height: 1),
                _buildContextRow(
                  theme,
                  isDark,
                  Icons.air,
                  'Wind Physics',
                  'Modeled with Cubic Velocity',
                  Colors.lightBlue,
                ),
                const Divider(height: 1),
                _buildContextRow(
                  theme,
                  isDark,
                  Icons.memory,
                  'AI Confidence',
                  'Calibrated XGBoost Engine',
                  Colors.purple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextRow(
    ThemeData theme,
    bool isDark,
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12), // Slightly larger padding for better proportion
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4), // Breathing room for the text
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
