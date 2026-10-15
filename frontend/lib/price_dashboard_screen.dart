import 'dart:async';
import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:frontend/custom_app_bar.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/main.dart' show serverWarmup, kBackendUrl;
import 'package:frontend/ui/kit.dart';
import 'package:http/http.dart' as http;

class PriceDashboardScreen extends StatefulWidget {
  const PriceDashboardScreen({super.key, required this.themeNotifier});
  final ValueNotifier<ThemeMode> themeNotifier;

  @override
  State<PriceDashboardScreen> createState() => _PriceDashboardScreenState();
}

class _PriceDashboardScreenState extends State<PriceDashboardScreen> with SingleTickerProviderStateMixin {
  List<double> _hourlyPrices = [];
  bool _isLoading = true;
  // Resolved at build time so a language switch mid-load updates the text.
  String Function(AppLocalizations)? _error;
  String _targetDate = '';
  String Function(AppLocalizations) _loadingMessage = (l) => l.loadingPrices;
  String _dataSource = '';

  String _selectedDay = 'today';
  static List<double>? _cachedTodayPrices;
  static String? _cachedTodayDate;
  static String? _cachedTodaySource;
  static List<double>? _cachedTomorrowPrices;
  static String? _cachedTomorrowDate;
  static String? _cachedTomorrowSource;

  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  static const _accent = [AppColors.sky, AppColors.indigo];

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

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveForecast({int attempt = 1}) async {
    if (_selectedDay == 'today' && _cachedTodayPrices != null) {
      setState(() {
        _hourlyPrices = _cachedTodayPrices!;
        _targetDate = _cachedTodayDate!;
        _dataSource = _cachedTodaySource ?? '';
        _isLoading = false;
        _error = null;
      });
      return;
    }
    if (_selectedDay == 'tomorrow' && _cachedTomorrowPrices != null) {
      setState(() {
        _hourlyPrices = _cachedTomorrowPrices!;
        _targetDate = _cachedTomorrowDate!;
        _dataSource = _cachedTomorrowSource ?? '';
        _isLoading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _loadingMessage = attempt == 1 ? (l) => l.loadingConnecting : (l) => l.loadingRetry(attempt);
    });

    Future.delayed(const Duration(seconds: 6), () {
      if (mounted && _isLoading) setState(() => _loadingMessage = (l) => l.loadingWarmingUp);
    });
    Future.delayed(const Duration(seconds: 35), () {
      if (mounted && _isLoading) setState(() => _loadingMessage = (l) => l.loadingAlmost);
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
          final code = response.statusCode;
          _error = (l) => l.errorServerCode(code);
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
          _error = (l) => l.errorUnreachable;
          _isLoading = false;
        });
      }
    }
  }

  static String _hh(int h) => '${h.toString().padLeft(2, '0')}:00';

  // ---------------------------------------------------------------- build
  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        themeNotifier: widget.themeNotifier,
        title: context.l10n.pricesTitle,
        subtitle: context.l10n.pricesSubtitle,
        icon: Icons.insights_rounded,
        colors: _accent,
      ),
      body: AuroraBackground(
        colors: const [AppColors.sky, AppColors.indigo, AppColors.emerald, AppColors.blue],
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 32, bottom: kNavClearance),
            child: PageBody(
              child: LayoutBuilder(
                builder: (context, c) {
                  final wide = c.maxWidth > 860;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FadeSlideIn(child: _buildIntro(p, wide)),
                      const SizedBox(height: 32),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 450),
                        switchInCurve: Curves.easeOutCubic,
                        transitionBuilder: (child, a) => FadeTransition(
                          opacity: a,
                          child: SlideTransition(position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(a), child: child),
                        ),
                        child: _isLoading
                            ? KeyedSubtree(key: const ValueKey('loading'), child: _buildLoading(p, wide))
                            : _error != null
                                ? KeyedSubtree(key: const ValueKey('error'), child: _buildError())
                                : KeyedSubtree(key: ValueKey('data-$_selectedDay-$_targetDate'), child: _buildDashboard(p, wide)),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- intro
  Widget _buildIntro(AppPalette p, bool wide) {
    final isLive = _dataSource.contains('EPEX');
    final l = context.l10n;
    final ready = !_isLoading && _error == null;
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          eyebrow: l.pricesEyebrow,
          title: l.pricesHeadline,
          subtitle: l.pricesIntro,
          wide: wide,
          accent: AppColors.sky,
          compact: true,
        ),
        const SizedBox(height: 18),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 400),
          opacity: ready ? 1 : 0,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              LiveBadge(
                pulse: _pulse,
                label: isLive ? l.pricesLiveData : l.pricesAiForecast,
                color: isLive ? AppColors.emerald : AppColors.amber,
              ),
              if (_targetDate.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: p.glass,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: p.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 13, color: p.muted),
                      const SizedBox(width: 7),
                      Text(context.date(_targetDate), style: AppType.mono(12, p.muted)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
    final toggle = SegmentedToggle<String>(
      options: [('today', l.today), ('tomorrow', l.tomorrow)],
      value: _selectedDay,
      colors: _accent,
      onChanged: (v) {
        setState(() => _selectedDay = v);
        _fetchLiveForecast();
      },
    );
    if (!wide) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [copy, const SizedBox(height: 22), toggle]);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [Expanded(child: copy), const SizedBox(width: 24), toggle],
    );
  }

  // ---------------------------------------------------------------- states
  Widget _buildLoading(AppPalette p, bool wide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoadingPanel(
          message: _loadingMessage(context.l10n),
          sub: _selectedDay == 'today' ? context.l10n.pricesFetchingToday : context.l10n.pricesFetchingTomorrow,
          icon: Icons.insights_rounded,
          colors: _accent,
        ),
        const SizedBox(height: 20),
        ResponsiveGrid(
          minItemWidth: 220,
          children: [for (var i = 0; i < 4; i++) const Glass(radius: 22, padding: EdgeInsets.all(20), child: Shimmer(height: 92))],
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ErrorPanel(
          title: context.l10n.pricesLoadError,
          message: _error!(context.l10n),
          actionLabel: context.l10n.retryConnection,
          onAction: _fetchLiveForecast,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- dashboard
  Widget _buildDashboard(AppPalette p, bool wide) {
    final currentHour = DateTime.now().hour;
    final isToday = _selectedDay == 'today';
    final searchStart = isToday ? (currentHour + 1 > 23 ? 23 : currentHour + 1) : 0;
    final futurePrices = _hourlyPrices.isNotEmpty ? _hourlyPrices.sublist(searchStart) : <double>[];

    final minPrice = futurePrices.isNotEmpty ? futurePrices.reduce((a, b) => a < b ? a : b) : 0.0;
    final maxPrice = _hourlyPrices.isNotEmpty ? _hourlyPrices.reduce((a, b) => a > b ? a : b) : 0.0;
    final avgPrice = _hourlyPrices.isNotEmpty ? _hourlyPrices.reduce((a, b) => a + b) / _hourlyPrices.length : 0.0;
    final currentPrice = _hourlyPrices.isNotEmpty ? _hourlyPrices[isToday ? currentHour : 0] : 0.0;
    final dailyRange = maxPrice - (_hourlyPrices.isNotEmpty ? _hourlyPrices.reduce((a, b) => a < b ? a : b) : 0.0);
    final bestHour = futurePrices.isNotEmpty ? futurePrices.indexOf(minPrice) + searchStart : 0;

    final l = context.l10n;
    final kpis = ResponsiveGrid(
      minItemWidth: 220,
      children: [
        FadeSlideIn(
          child: KpiTile(
            icon: Icons.bolt_rounded,
            colors: [AppColors.forPrice(currentPrice), Color.lerp(AppColors.forPrice(currentPrice), AppColors.indigo, 0.35)!],
            label: isToday ? l.kpiCurrentPrice : l.kpiOpeningPrice,
            number: currentPrice,
            decimals: 1,
            suffix: ' ct',
            sub: l.perKwhInclVat,
            valueColor: AppColors.forPrice(currentPrice),
          ),
        ),
        FadeSlideIn(
          delay: const Duration(milliseconds: 80),
          child: KpiTile(
            icon: Icons.show_chart_rounded,
            colors: const [AppColors.indigo, AppColors.violet],
            label: l.kpiDayAverage,
            number: avgPrice,
            decimals: 1,
            suffix: ' ct',
            sub: l.perKwhInclVat,
          ),
        ),
        FadeSlideIn(
          delay: const Duration(milliseconds: 160),
          child: KpiTile(
            icon: Icons.schedule_rounded,
            colors: const [AppColors.emerald, AppColors.teal],
            label: isToday ? l.kpiNextBestHour : l.kpiBestHour,
            text: _hh(bestHour),
            sub: l.ctPerKwhValue(context.fmt(minPrice, 1)),
            valueColor: AppColors.emerald,
          ),
        ),
        FadeSlideIn(
          delay: const Duration(milliseconds: 240),
          child: KpiTile(
            icon: Icons.swap_vert_rounded,
            colors: _accent,
            label: l.kpiDailyRange,
            number: dailyRange,
            decimals: 1,
            suffix: ' ct',
            sub: l.kpiPeakMinusOffPeak,
          ),
        ),
      ],
    );

    final chart = _buildChartCard(p, currentHour);
    final guide = _buildPriceGuideCard(p);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        kpis,
        const SizedBox(height: 20),
        FadeSlideIn(delay: const Duration(milliseconds: 280), child: _buildInsight(p, bestHour, minPrice, avgPrice, isToday)),
        const SizedBox(height: 20),
        FadeSlideIn(
          delay: const Duration(milliseconds: 340),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Expanded(flex: 3, child: chart), const SizedBox(width: 20), Expanded(flex: 2, child: guide)],
                )
              : Column(children: [chart, const SizedBox(height: 20), guide]),
        ),
      ],
    );
  }

  Widget _buildInsight(AppPalette p, int bestHour, double minPrice, double avgPrice, bool isToday) {
    final savePct = avgPrice > 0 ? ((avgPrice - minPrice) / avgPrice * 100).clamp(0, 100).round() : 0;
    return Glass(
      radius: 20,
      borderColor: AppColors.emerald.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const IconTile(icon: Icons.tips_and_updates_rounded, colors: [AppColors.emerald, AppColors.teal], size: 42),
          const SizedBox(width: 16),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: AppType.body(14.5, p.muted, height: 1.5),
                children: [
                  TextSpan(
                    text: isToday ? context.l10n.insightSmart : context.l10n.insightPlan,
                    style: AppType.body(14.5, p.text, weight: FontWeight.w700),
                  ),
                  TextSpan(text: context.l10n.insightBefore),
                  TextSpan(text: _hh(bestHour), style: AppType.body(14.5, AppColors.emerald, weight: FontWeight.w700)),
                  TextSpan(text: context.l10n.insightAfter(context.fmt(savePct))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- chart
  Widget _buildChartCard(AppPalette p, int currentHour) {
    if (_hourlyPrices.isEmpty) return const SizedBox.shrink();
    final isToday = _selectedDay == 'today';

    final lo = _hourlyPrices.reduce((a, b) => a < b ? a : b);
    final hi = _hourlyPrices.reduce((a, b) => a > b ? a : b);
    final minY = (lo - 4).floorToDouble();
    final maxY = (hi + 4).ceilToDouble();
    final interval = ((maxY - minY) / 5).ceilToDouble().clamp(1, double.infinity).toDouble();
    final tooltipBg = p.isDark ? const Color(0xFF0F172A) : Colors.white;

    LineChartData data(double t) {
      final spots = [
        for (var i = 0; i < _hourlyPrices.length; i++) FlSpot(i.toDouble(), minY + (_hourlyPrices[i] - minY) * t),
      ];
      return LineChartData(
        minY: minY,
        maxY: maxY,
        minX: 0,
        maxX: 23,
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            for (final (y, c) in const [(15.0, AppColors.emerald), (25.0, AppColors.amber)])
              if (y > minY && y < maxY)
                HorizontalLine(
                  y: y,
                  color: c.withValues(alpha: 0.6),
                  strokeWidth: 1.2,
                  dashArray: [6, 4],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    labelResolver: (_) => '${y.toInt()} ct  ',
                    style: AppType.mono(10.5, c, weight: FontWeight.w700),
                  ),
                ),
          ],
          verticalLines: isToday
              ? [
                  VerticalLine(
                    x: currentHour.toDouble(),
                    color: p.text.withValues(alpha: 0.3),
                    strokeWidth: 1.2,
                    dashArray: [4, 4],
                    label: VerticalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      labelResolver: (_) => ' ${context.l10n.now}',
                      style: AppType.mono(10, p.muted, weight: FontWeight.w700),
                    ),
                  ),
                ]
              : [],
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) => FlLine(color: p.border, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 4,
              getTitlesWidget: (v, _) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(v.toInt().toString().padLeft(2, '0'), style: AppType.mono(10.5, p.faint)),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: interval,
              getTitlesWidget: (v, meta) {
                if (v == meta.min || v == meta.max) return const SizedBox.shrink();
                return Text('${v.toInt()}ct', style: AppType.mono(10.5, p.faint));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            preventCurveOverShooting: true,
            barWidth: 3,
            isStrokeCapRound: true,
            // Colour follows the price band at the top, middle and bottom of the visible range.
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.forPrice(hi), AppColors.forPrice((hi + lo) / 2), AppColors.forPrice(lo)],
            ),
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, _) => isToday && spot.x.toInt() == currentHour,
              getDotPainter: (a, b, c, d) => FlDotCirclePainter(
                radius: 6,
                color: AppColors.sky,
                strokeWidth: 3,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.sky.withValues(alpha: p.isDark ? 0.28 : 0.22), AppColors.sky.withValues(alpha: 0)],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          getTouchedSpotIndicator: (bar, indexes) => indexes
              .map((i) => TouchedSpotIndicatorData(
                    FlLine(color: AppColors.sky.withValues(alpha: 0.5), strokeWidth: 1.5, dashArray: [4, 4]),
                    FlDotData(
                      getDotPainter: (spot, a, b, c) => FlDotCirclePainter(
                        radius: 6,
                        color: AppColors.forPrice(spot.y),
                        strokeWidth: 3,
                        strokeColor: Colors.white,
                      ),
                    ),
                  ))
              .toList(),
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => tooltipBg,
            tooltipBorder: BorderSide(color: p.border),
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      '${_hh(s.x.toInt())}\n',
                      AppType.mono(11, p.muted),
                      children: [
                        TextSpan(
                          text: context.l10n.ctPerKwhValue(context.fmt(_hourlyPrices[s.x.toInt()], 1)),
                          style: AppType.body(14, AppColors.forPrice(_hourlyPrices[s.x.toInt()]), weight: FontWeight.w800),
                        ),
                      ],
                    ))
                .toList(),
          ),
        ),
      );
    }

    return GlassCard(
      title: context.l10n.chartTitle,
      subtitle: context.l10n.chartSubtitle,
      icon: Icons.show_chart_rounded,
      colors: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _legendDot(p, AppColors.emerald, context.l10n.legendCheap),
              _legendDot(p, AppColors.amber, context.l10n.legendMid),
              _legendDot(p, AppColors.rose, context.l10n.legendPeak),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1300),
              curve: Curves.easeOutCubic,
              builder: (_, t, _) => LineChart(data(t), duration: Duration.zero),
            ),
          ),
          const SizedBox(height: 24),
          Text(context.l10n.hourlyHeatmap, style: AppType.eyebrow(p.faint)),
          const SizedBox(height: 10),
          _HeatStrip(prices: _hourlyPrices, current: isToday ? currentHour : null),
        ],
      ),
    );
  }

  Widget _legendDot(AppPalette p, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6)]),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppType.body(12, p.muted, weight: FontWeight.w600, height: 1.2)),
      ],
    );
  }

  // ---------------------------------------------------------------- guide
  Widget _buildPriceGuideCard(AppPalette p) {
    final sorted = _hourlyPrices.isEmpty ? <MapEntry<int, double>>[] : _hourlyPrices.asMap().entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final cheapest = sorted.take(5).toList();
    final maxVal = _hourlyPrices.isEmpty ? 1.0 : _hourlyPrices.reduce((a, b) => a > b ? a : b);

    return GlassCard(
      title: context.l10n.guideTitle,
      subtitle: context.l10n.guideSubtitle,
      icon: Icons.tune_rounded,
      colors: const [AppColors.emerald, AppColors.teal],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPriceZone(p, color: AppColors.emerald, range: '< 15 ct/kWh', label: context.l10n.zoneCheap, desc: context.l10n.zoneCheapDesc),
          const SizedBox(height: 10),
          _buildPriceZone(p, color: AppColors.amber, range: '15 – 25 ct/kWh', label: context.l10n.zoneMid, desc: context.l10n.zoneMidDesc),
          const SizedBox(height: 10),
          _buildPriceZone(p, color: AppColors.rose, range: '> 25 ct/kWh', label: context.l10n.zonePeak, desc: context.l10n.zonePeakDesc),
          const SizedBox(height: 26),
          Text(context.l10n.fiveCheapestHours, style: AppType.eyebrow(p.faint)),
          const SizedBox(height: 14),
          for (var i = 0; i < cheapest.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == 0 ? AppColors.emerald : p.track,
                    ),
                    child: Text('${i + 1}', style: AppType.mono(10.5, i == 0 ? Colors.white : p.muted, weight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(width: 48, child: Text(_hh(cheapest[i].key), style: AppType.mono(12.5, p.text, weight: FontWeight.w700))),
                  Expanded(
                    child: AnimatedBar(
                      fraction: maxVal > 0 ? cheapest[i].value / maxVal : 0,
                      colors: [AppColors.forPrice(cheapest[i].value), Color.lerp(AppColors.forPrice(cheapest[i].value), Colors.white, 0.2)!],
                      height: 8,
                      duration: Duration(milliseconds: 900 + i * 120),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 54,
                    child: Text(
                      context.l10n.ctValue(context.fmt(cheapest[i].value, 1)),
                      textAlign: TextAlign.right,
                      style: AppType.mono(12, AppColors.forPrice(cheapest[i].value), weight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Divider(color: p.border, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 15, color: p.faint),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _dataSource.contains('EPEX') ? context.l10n.sourceEpex : context.l10n.sourceModel,
                  style: AppType.body(12, p.faint, height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceZone(AppPalette p, {required Color color, required String range, required String label, required String desc}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withValues(alpha: p.isDark ? 0.07 : 0.06),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: AppType.body(13.5, color, weight: FontWeight.w800, height: 1.2)),
              const Spacer(),
              Text(range, style: AppType.mono(11.5, color, weight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Text(desc, style: AppType.body(12.5, p.muted, height: 1.4)),
        ],
      ),
    );
  }
}

/// 24 cells coloured relative to the day's cheapest and priciest hour.
class _HeatStrip extends StatelessWidget {
  const _HeatStrip({required this.prices, this.current});
  final List<double> prices;
  final int? current;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final lo = prices.reduce((a, b) => a < b ? a : b);
    final hi = prices.reduce((a, b) => a > b ? a : b);
    final range = (hi - lo).abs() < 0.01 ? 1.0 : hi - lo;

    Color heat(double v) {
      final t = (v - lo) / range;
      return t < 0.5
          ? Color.lerp(AppColors.emerald, AppColors.amber, t * 2)!
          : Color.lerp(AppColors.amber, AppColors.rose, (t - 0.5) * 2)!;
    }

    return Column(
      children: [
        SizedBox(
          height: 38,
          child: Row(
            children: [
              for (var i = 0; i < prices.length; i++)
                Expanded(
                  child: Tooltip(
                    message: '${i.toString().padLeft(2, '0')}:00 · ${context.l10n.ctPerKwhValue(context.fmt(prices[i], 1))}',
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 400 + i * 35),
                      curve: Curves.easeOut,
                      builder: (_, t, _) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          color: heat(prices[i]).withValues(alpha: (i == current ? 1.0 : 0.75) * t),
                          borderRadius: BorderRadius.circular(6),
                          border: i == current ? Border.all(color: p.text, width: 2) : null,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final l in const ['00', '06', '12', '18', '23']) Text(l, style: AppType.mono(10, p.faint)),
          ],
        ),
      ],
    );
  }
}
