import 'dart:async';
import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:frontend/custom_app_bar.dart';
import 'package:frontend/main.dart' show serverWarmup, kBackendUrl;
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
  String _loadingMessage = 'Loading prices...';
  String _dataSource = '';

  String _selectedDay = 'today';
  static List<double>? _cachedTodayPrices;
  static String? _cachedTodayDate;
  static String? _cachedTodaySource;
  static List<double>? _cachedTomorrowPrices;
  static String? _cachedTomorrowDate;
  static String? _cachedTomorrowSource;

  @override
  void initState() {
    super.initState();
    if (_selectedDay == 'today' && _cachedTodayPrices != null) {
      _hourlyPrices = _cachedTodayPrices!;
      _targetDate = _cachedTodayDate!;
      _dataSource = _cachedTodaySource ?? '';
      _isLoading = false;
    } else {
      _fetchLiveForecast();
    }
  }

  Future<void> _fetchLiveForecast({int attempt = 1}) async {
    if (_selectedDay == 'today' && _cachedTodayPrices != null) {
      setState(() {
        _hourlyPrices = _cachedTodayPrices!;
        _targetDate = _cachedTodayDate!;
        _dataSource = _cachedTodaySource ?? '';
        _isLoading = false;
        _errorMessage = '';
      });
      return;
    }
    if (_selectedDay == 'tomorrow' && _cachedTomorrowPrices != null) {
      setState(() {
        _hourlyPrices = _cachedTomorrowPrices!;
        _targetDate = _cachedTomorrowDate!;
        _dataSource = _cachedTomorrowSource ?? '';
        _isLoading = false;
        _errorMessage = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _loadingMessage =
          attempt == 1 ? 'Connecting to server...' : 'Retrying... (attempt $attempt of 3)';
    });

    Future.delayed(const Duration(seconds: 6), () {
      if (mounted && _isLoading) setState(() => _loadingMessage = 'Server is warming up...');
    });
    Future.delayed(const Duration(seconds: 35), () {
      if (mounted && _isLoading) setState(() => _loadingMessage = 'Almost there...');
    });

    await serverWarmup;
    if (!mounted) return;

    try {
      final response = await http
          .get(Uri.parse('$kBackendUrl/predict_prices?target=$_selectedDay'))
          .timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final source = data['source'] as String? ?? '';
        final fetchedPrices = List<double>.from(
          data['hourly_prices'].map((x) {
            double wholesaleCent = x.toDouble() / 10.0;
            return (wholesaleCent + 15.0) * 1.19;
          }),
        );
        final fetchedDate = data['date'] as String? ?? 'Unknown Date';
        setState(() {
          _hourlyPrices = fetchedPrices;
          _targetDate = fetchedDate;
          _dataSource = source;
          if (_selectedDay == 'today') {
            _cachedTodayPrices = fetchedPrices;
            _cachedTodayDate = fetchedDate;
            _cachedTodaySource = source;
          } else {
            _cachedTomorrowPrices = fetchedPrices;
            _cachedTomorrowDate = fetchedDate;
            _cachedTomorrowSource = source;
          }
          _isLoading = false;
        });
      } else if (attempt < 3) {
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) _fetchLiveForecast(attempt: attempt + 1);
      } else {
        setState(() {
          _errorMessage = 'Server returned error ${response.statusCode}. Please try again.';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      if (attempt < 3) {
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) _fetchLiveForecast(attempt: attempt + 1);
      } else {
        setState(() {
          _errorMessage = 'Could not reach server after 3 attempts. Check your connection.';
          _isLoading = false;
        });
      }
    }
  }

  Color _priceColor(double price) {
    if (price < 15.0) return const Color(0xFF10B981);
    if (price < 25.0) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  BoxDecoration _cardDeco(ThemeData theme, bool isDark) => BoxDecoration(
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
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(themeNotifier: widget.themeNotifier, title: 'EnergyTwin'),
      body: Column(
        children: [
          _buildHeroBanner(theme, isDark),
          Expanded(
            child: _isLoading
                ? _buildLoadingState(theme, isDark)
                : _errorMessage.isNotEmpty
                    ? _buildErrorState(theme, isDark)
                    : _buildDashboard(theme, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(ThemeData theme, bool isDark) {
    final isLive = _dataSource.contains('EPEX');
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0C4A6E), const Color(0xFF075985)]
              : [const Color(0xFF0284C7), const Color(0xFF0369A1)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'German Electricity Market',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'EPEX SPOT DE-LU · Retail prices incl. grid & VAT',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.white.withAlpha(180)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SegmentedButton<String>(
                style: SegmentedButton.styleFrom(
                  foregroundColor: Colors.white,
                  selectedForegroundColor: const Color(0xFF0284C7),
                  selectedBackgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                ),
                segments: const [
                  ButtonSegment(value: 'today', label: Text('Today')),
                  ButtonSegment(value: 'tomorrow', label: Text('Tomorrow')),
                ],
                selected: {_selectedDay},
                onSelectionChanged: (Set<String> s) {
                  setState(() => _selectedDay = s.first);
                  _fetchLiveForecast();
                },
              ),
              const SizedBox(height: 8),
              if (!_isLoading && _errorMessage.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLive
                        ? const Color(0xFF10B981).withAlpha(40)
                        : const Color(0xFFF59E0B).withAlpha(40),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isLive
                          ? const Color(0xFF10B981).withAlpha(120)
                          : const Color(0xFFF59E0B).withAlpha(120),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isLive
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isLive ? 'Live Data' : 'AI Forecast',
                        style: TextStyle(
                          color: isLive
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.secondary),
          const SizedBox(height: 20),
          Text(
            _loadingMessage,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withAlpha(150),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 64, color: Colors.redAccent.withAlpha(150)),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent, fontSize: 15),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchLiveForecast,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry Connection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(ThemeData theme, bool isDark) {
    final currentHour = DateTime.now().hour;
    final searchStart = _selectedDay == 'today'
        ? (currentHour + 1 > 23 ? 23 : currentHour + 1)
        : 0;
    final futurePrices =
        _hourlyPrices.isNotEmpty ? _hourlyPrices.sublist(searchStart) : <double>[];

    final minPrice =
        futurePrices.isNotEmpty ? futurePrices.reduce((a, b) => a < b ? a : b) : 0.0;
    final maxPrice = _hourlyPrices.isNotEmpty
        ? _hourlyPrices.reduce((a, b) => a > b ? a : b)
        : 0.0;
    final avgPrice = _hourlyPrices.isNotEmpty
        ? _hourlyPrices.reduce((a, b) => a + b) / _hourlyPrices.length
        : 0.0;
    final currentPrice =
        _hourlyPrices.isNotEmpty ? _hourlyPrices[_selectedDay == 'today' ? currentHour : 0] : 0.0;
    final dailyRange = maxPrice - (_hourlyPrices.isNotEmpty
        ? _hourlyPrices.reduce((a, b) => a < b ? a : b)
        : 0.0);
    final bestHour =
        futurePrices.isNotEmpty ? futurePrices.indexOf(minPrice) + searchStart : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 800;

              final kpiRow = wide
                  ? Row(
                      children: [
                        Expanded(
                          child: _buildKPI(
                            theme, isDark,
                            title: _selectedDay == 'today' ? 'Current Price' : 'Opening Price',
                            value: '${currentPrice.toStringAsFixed(1)} ct',
                            sub: 'per kWh incl. VAT',
                            icon: Icons.bolt,
                            color: _priceColor(currentPrice),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildKPI(
                            theme, isDark,
                            title: 'Day Average',
                            value: '${avgPrice.toStringAsFixed(1)} ct',
                            sub: 'per kWh incl. VAT',
                            icon: Icons.show_chart,
                            color: _priceColor(avgPrice),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildKPI(
                            theme, isDark,
                            title: _selectedDay == 'today'
                                ? 'Next Best Hour'
                                : 'Best Hour',
                            value:
                                '${bestHour.toString().padLeft(2, '0')}:00',
                            sub: '${minPrice.toStringAsFixed(1)} ct/kWh',
                            icon: Icons.schedule,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildKPI(
                            theme, isDark,
                            title: 'Daily Range',
                            value: '${dailyRange.toStringAsFixed(1)} ct',
                            sub: 'peak minus off-peak',
                            icon: Icons.swap_vert,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildKPI(
                                theme, isDark,
                                title: _selectedDay == 'today'
                                    ? 'Current Price'
                                    : 'Opening Price',
                                value: '${currentPrice.toStringAsFixed(1)} ct',
                                sub: 'per kWh incl. VAT',
                                icon: Icons.bolt,
                                color: _priceColor(currentPrice),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildKPI(
                                theme, isDark,
                                title: 'Day Average',
                                value: '${avgPrice.toStringAsFixed(1)} ct',
                                sub: 'per kWh',
                                icon: Icons.show_chart,
                                color: _priceColor(avgPrice),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildKPI(
                                theme, isDark,
                                title: 'Next Best Hour',
                                value:
                                    '${bestHour.toString().padLeft(2, '0')}:00',
                                sub: '${minPrice.toStringAsFixed(1)} ct/kWh',
                                icon: Icons.schedule,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildKPI(
                                theme, isDark,
                                title: 'Daily Range',
                                value: '${dailyRange.toStringAsFixed(1)} ct',
                                sub: 'peak minus off-peak',
                                icon: Icons.swap_vert,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );

              final bottomSection = wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildChartCard(theme, isDark, currentHour)),
                        const SizedBox(width: 24),
                        Expanded(flex: 2, child: _buildPriceGuideCard(theme, isDark)),
                      ],
                    )
                  : Column(
                      children: [
                        _buildChartCard(theme, isDark, currentHour),
                        const SizedBox(height: 24),
                        _buildPriceGuideCard(theme, isDark),
                      ],
                    );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  kpiRow,
                  const SizedBox(height: 24),
                  bottomSection,
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildKPI(
    ThemeData theme,
    bool isDark, {
    required String title,
    required String value,
    required String sub,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDeco(theme, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: isDark ? Colors.white38 : Colors.black38),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(ThemeData theme, bool isDark, int currentHour) {
    if (_hourlyPrices.isEmpty) return const SizedBox.shrink();

    final minY = (_hourlyPrices.reduce((a, b) => a < b ? a : b) - 4).floorToDouble();
    final maxY = (_hourlyPrices.reduce((a, b) => a > b ? a : b) + 4).ceilToDouble();
    final interval = ((maxY - minY) / 5).ceilToDouble().clamp(1, double.infinity);

    final spots = _hourlyPrices
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDeco(theme, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hourly Price Curve',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _targetDate,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _legendDot(const Color(0xFF10B981), 'Cheap'),
                  const SizedBox(width: 12),
                  _legendDot(const Color(0xFFF59E0B), 'Mid'),
                  const SizedBox(width: 12),
                  _legendDot(const Color(0xFFEF4444), 'Peak'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 320,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                minX: 0,
                maxX: 23,
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 15,
                      color: const Color(0xFF10B981).withAlpha(180),
                      strokeWidth: 1.2,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        labelResolver: (_) => '15 ct  ',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    HorizontalLine(
                      y: 25,
                      color: const Color(0xFFF59E0B).withAlpha(180),
                      strokeWidth: 1.2,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        labelResolver: (_) => '25 ct  ',
                        style: const TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  verticalLines: _selectedDay == 'today'
                      ? [
                          VerticalLine(
                            x: currentHour.toDouble(),
                            color: Colors.redAccent.withAlpha(180),
                            strokeWidth: 1.5,
                            dashArray: [5, 5],
                          ),
                        ]
                      : [],
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: isDark ? Colors.white10 : Colors.black.withAlpha(20),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 4,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${v.toInt()}h',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: interval.toDouble(),
                      getTitlesWidget: (v, meta) {
                        if (v == meta.min || v == meta.max) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          '${v.toInt()}ct',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: theme.colorScheme.secondary,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, _) =>
                          _selectedDay == 'today' && spot.x.toInt() == currentHour,
                      getDotPainter: (a, b, c, d) => FlDotCirclePainter(
                        radius: 6,
                        color: Colors.redAccent,
                        strokeWidth: 3,
                        strokeColor: theme.colorScheme.surface,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.colorScheme.secondary.withAlpha(50),
                          theme.colorScheme.secondary.withAlpha(5),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => isDark
                        ? const Color(0xFF1E293B)
                        : Colors.white,
                    tooltipBorder: BorderSide(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                    getTooltipItems: (spots) => spots.map((s) {
                      final c = _priceColor(s.y);
                      return LineTooltipItem(
                        '${s.x.toInt()}:00\n',
                        TextStyle(
                          color: isDark ? Colors.white54 : Colors.black45,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text: '${s.y.toStringAsFixed(1)} ct/kWh',
                            style: TextStyle(
                              color: c,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildPriceGuideCard(ThemeData theme, bool isDark) {
    final sorted = _hourlyPrices.isEmpty
        ? <MapEntry<int, double>>[]
        : _hourlyPrices
            .asMap()
            .entries
            .toList()
          ..sort((a, b) => a.value.compareTo(b.value));
    final cheapest = sorted.take(5).toList();
    final maxVal = _hourlyPrices.isEmpty
        ? 1.0
        : _hourlyPrices.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDeco(theme, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price Guide',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Retail price = wholesale + 15 ct grid/tax + 19% VAT',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: isDark ? Colors.white38 : Colors.black38),
          ),
          const SizedBox(height: 20),
          _buildPriceZone(
            theme, isDark,
            dot: const Color(0xFF10B981),
            label: 'Cheap  < 15 ct/kWh',
            desc: 'Run heat pump, charge EV, do laundry',
          ),
          const SizedBox(height: 12),
          _buildPriceZone(
            theme, isDark,
            dot: const Color(0xFFF59E0B),
            label: 'Mid   15 – 25 ct/kWh',
            desc: 'Normal household use, monitor closely',
          ),
          const SizedBox(height: 12),
          _buildPriceZone(
            theme, isDark,
            dot: const Color(0xFFEF4444),
            label: 'Peak  > 25 ct/kWh',
            desc: 'Avoid big loads, discharge battery',
          ),
          const SizedBox(height: 24),
          Text(
            '5 Cheapest Hours',
            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...cheapest.map((e) {
            final frac = maxVal > 0 ? (e.value / maxVal).clamp(0.0, 1.0) : 0.0;
            final c = _priceColor(e.value);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: Text(
                      '${e.key.toString().padLeft(2, '0')}:00',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: c,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: frac,
                        minHeight: 8,
                        backgroundColor: isDark ? Colors.white10 : Colors.black.withAlpha(20),
                        valueColor: AlwaysStoppedAnimation<Color>(c),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${e.value.toStringAsFixed(1)} ct',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: c,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          Divider(color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _dataSource.contains('EPEX')
                      ? 'Source: EPEX SPOT DE-LU via Fraunhofer ISE'
                      : 'Source: XGBoost model trained on ENTSO-E data',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceZone(
    ThemeData theme,
    bool isDark, {
    required Color dot,
    required String label,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w700, color: dot),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
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
