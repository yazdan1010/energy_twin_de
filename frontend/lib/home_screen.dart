import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:frontend/main.dart' show serverWarmup, kBackendUrl;
import 'package:frontend/ui/kit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

// ----------------------------------------------------------------------
// Home Screen
// ----------------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.themeNotifier, required this.onNavigate});
  final ValueNotifier<ThemeMode> themeNotifier;

  /// Switches the app shell to the tab at [index].
  final ValueChanged<int> onNavigate;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..forward();
  late final AnimationController _ambient = AnimationController(vsync: this, duration: const Duration(seconds: 24))..repeat();
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  final ScrollController _scroll = ScrollController();

  static List<double>? _cachedPrices;
  List<double>? _prices = _cachedPrices;
  bool _priceError = false;

  @override
  void initState() {
    super.initState();
    if (_prices == null) _fetchPrices();
  }

  Future<void> _fetchPrices({int attempt = 1}) async {
    if (attempt == 1 && _priceError) setState(() => _priceError = false);
    await serverWarmup;
    if (!mounted) return;
    try {
      final res = await http.get(Uri.parse('$kBackendUrl/predict_prices?target=today')).timeout(const Duration(seconds: 30));
      if (!mounted) return;
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final data = jsonDecode(res.body);
      // Same wholesale → retail conversion as the Prices screen (grid fees + 19% VAT).
      final prices = List<double>.from(data['hourly_prices'].map((x) => (x.toDouble() / 10.0 + 15.0) * 1.19));
      _cachedPrices = prices;
      setState(() => _prices = prices);
    } catch (_) {
      if (!mounted) return;
      if (attempt < 3) {
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) _fetchPrices(attempt: attempt + 1);
      } else {
        setState(() => _priceError = true);
      }
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
    _pulse.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette(Theme.of(context).brightness == Brightness.dark);
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 960;
    final gutter = width < 600 ? 20.0 : 40.0;

    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _ambient,
                builder: (_, _) => CustomPaint(painter: AuroraPainter(_ambient.value, p)),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              controller: _scroll,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: gutter),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Reveal(controller: _intro, start: 0, end: 0.4, child: _buildTopBar(p)),
                        SizedBox(height: wide ? 56 : 28),
                        _buildHero(p, wide),
                        SizedBox(height: wide ? 72 : 48),
                        Reveal(controller: _intro, start: 0.55, end: 1, child: _buildStats(p, wide)),
                        SizedBox(height: wide ? 112 : 72),
                        _buildFeatures(p, wide),
                        SizedBox(height: wide ? 112 : 72),
                        _buildHowItWorks(p, wide),
                        SizedBox(height: wide ? 112 : 72),
                        ScrollReveal(controller: _scroll, child: _buildCta(p, wide)),
                        const SizedBox(height: 48),
                        _buildFooter(p),
                        const SizedBox(height: kNavClearance),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- top bar
  Widget _buildTopBar(AppPalette p) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              gradient: const LinearGradient(
                colors: [AppColors.emerald, AppColors.sky],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [BoxShadow(color: AppColors.emerald.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            'EnergyTwin',
            style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: p.text, letterSpacing: -0.5),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: p.border),
              color: p.glass,
            ),
            child: Text(
              'DE',
              style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w700, color: p.muted),
            ),
          ),
          const Spacer(),
          GlassIconButton(
            icon: p.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            tooltip: p.isDark ? 'Light mode' : 'Dark mode',
            onTap: () => widget.themeNotifier.value = p.isDark ? ThemeMode.light : ThemeMode.dark,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- hero
  Widget _buildHero(AppPalette p, bool wide) {
    final copy = _buildHeroCopy(p, wide);
    final card = Reveal(
      controller: _intro,
      start: 0.3,
      end: 0.85,
      offset: 40,
      child: _LivePriceCard(
        palette: p,
        prices: _prices,
        error: _priceError,
        pulse: _pulse,
        onRetry: _fetchPrices,
        onOpen: () => widget.onNavigate(1),
      ),
    );
    if (!wide) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [copy, const SizedBox(height: 36), card]);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 11, child: copy),
        const SizedBox(width: 56),
        Expanded(flex: 9, child: card),
      ],
    );
  }

  Widget _buildHeroCopy(AppPalette p, bool wide) {
    final headlineSize = wide ? 64.0 : 40.0;
    final headlineStyle = GoogleFonts.plusJakartaSans(
      fontSize: headlineSize,
      fontWeight: FontWeight.w800,
      height: 1.04,
      letterSpacing: wide ? -2.4 : -1.4,
      color: p.text,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Reveal(
          controller: _intro,
          start: 0.05,
          end: 0.45,
          child: LiveBadge(pulse: _pulse, label: 'Live forecast · EPEX SPOT DE-LU'),
        ),
        const SizedBox(height: 24),
        Reveal(
          controller: _intro,
          start: 0.1,
          end: 0.5,
          child: Text('Power your home\nat the', style: headlineStyle),
        ),
        Reveal(
          controller: _intro,
          start: 0.15,
          end: 0.55,
          child: AnimatedBuilder(
            animation: _ambient,
            builder: (_, child) => ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) {
                final shift = _ambient.value * 2;
                return LinearGradient(
                  colors: const [AppColors.emerald, AppColors.sky, AppColors.indigo, AppColors.emerald],
                  stops: const [0, 0.35, 0.7, 1],
                  begin: Alignment(-1 - shift, 0),
                  end: Alignment(3 - shift, 0),
                  tileMode: TileMode.repeated,
                ).createShader(bounds);
              },
              child: child,
            ),
            child: Text('smartest hour.', style: headlineStyle),
          ),
        ),
        const SizedBox(height: 24),
        Reveal(
          controller: _intro,
          start: 0.2,
          end: 0.6,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Text(
              'EnergyTwin forecasts German electricity prices with machine learning and turns them into '
              'real savings for your heat pump, solar roof and everyday appliances.',
              style: GoogleFonts.inter(fontSize: wide ? 18 : 16, height: 1.6, color: p.muted),
            ),
          ),
        ),
        const SizedBox(height: 36),
        Reveal(
          controller: _intro,
          start: 0.28,
          end: 0.68,
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              PrimaryButton(label: 'Explore live prices', icon: Icons.arrow_forward_rounded, onTap: () => widget.onNavigate(1)),
              SecondaryButton(label: 'Calculate my savings', icon: Icons.savings_outlined, onTap: () => widget.onNavigate(2)),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Reveal(
          controller: _intro,
          start: 0.35,
          end: 0.75,
          child: Wrap(
            spacing: 22,
            runSpacing: 10,
            children: [
              for (final t in const ['XGBoost forecasting', 'Retail prices incl. VAT', 'Built for German homes'])
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.emerald),
                    const SizedBox(width: 6),
                    Text(
                      t,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: p.muted),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- stats
  Widget _buildStats(AppPalette p, bool wide) {
    final stats = [
      const _Stat(value: 17.56, decimals: 2, prefix: '€', suffix: '', label: 'Forecast MAE per MWh'),
      const _Stat(value: 24, decimals: 0, prefix: '', suffix: 'h', label: 'Day-ahead horizon'),
      const _Stat(value: 3, decimals: 0, prefix: '', suffix: '', label: 'AI-powered tools'),
      const _Stat(value: 19, decimals: 0, prefix: '', suffix: '%', label: 'VAT included in prices'),
    ];
    return Glass(
      radius: 24,
      padding: EdgeInsets.symmetric(vertical: wide ? 28 : 20, horizontal: wide ? 12 : 8),
      child: LayoutBuilder(
        builder: (context, c) {
          final perRow = c.maxWidth > 640 ? 4 : 2;
          final itemWidth = c.maxWidth / perRow;
          return Wrap(
            runSpacing: 20,
            children: [
              for (var i = 0; i < stats.length; i++)
                SizedBox(
                  width: itemWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      border: (i % perRow != 0) ? Border(left: BorderSide(color: p.border)) : null,
                    ),
                    child: _StatTile(stat: stats[i], palette: p, wide: wide),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------- features
  Widget _buildFeatures(AppPalette p, bool wide) {
    final features = [
      _Feature(
        icon: Icons.insights_rounded,
        colors: const [AppColors.sky, AppColors.indigo],
        title: 'Price Forecast',
        body:
            'Day-ahead prices for today and tomorrow, converted into what you actually pay per kWh — with the cheapest hours highlighted.',
        tags: const ['EPEX SPOT', 'XGBoost'],
        tab: 1,
      ),
      _Feature(
        icon: Icons.heat_pump_rounded,
        colors: const [AppColors.emerald, AppColors.teal],
        title: 'Heat Pump Advisor',
        body: 'Find out what replacing your gas boiler really saves, and how AI scheduling around cheap windows adds even more.',
        tags: const ['ROI', 'Smart scheduling'],
        tab: 2,
      ),
      _Feature(
        icon: Icons.solar_power_rounded,
        colors: const [AppColors.amber, AppColors.orange],
        title: 'Solar AI',
        body: 'Trace your roof on satellite imagery and get AI panel placement, yearly yield and payback estimates in seconds.',
        tags: const ['Satellite', 'Computer vision'],
        tab: 3,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScrollReveal(
          controller: _scroll,
          child: SectionHeader(
            wide: wide,
            eyebrow: 'PLATFORM',
            title: 'Three tools. One goal:\na cheaper, greener home.',
            subtitle:
                'Every tool runs on the same live market forecast, so your decisions stay consistent from today\'s laundry to a 20-year solar investment.',
          ),
        ),
        const SizedBox(height: 48),
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth >= 900 ? 3 : (c.maxWidth >= 600 ? 2 : 1);
            const gap = 20.0;
            final w = (c.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var i = 0; i < features.length; i++)
                  SizedBox(
                    width: w,
                    child: ScrollReveal(
                      controller: _scroll,
                      delay: Duration(milliseconds: 120 * (cols == 1 ? 0 : i)),
                      child: _FeatureCard(feature: features[i], palette: p, onTap: () => widget.onNavigate(features[i].tab)),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- how it works
  Widget _buildHowItWorks(AppPalette p, bool wide) {
    const steps = [
      (
        Icons.cloud_download_rounded,
        'Collect',
        'Generation, load and spot-price data stream in from SMARD and the EPEX SPOT day-ahead auction.',
      ),
      (
        Icons.auto_graph_rounded,
        'Predict',
        'A gradient-boosted model forecasts every hour of the coming day, accounting for wind, solar and demand.',
      ),
      (Icons.tune_rounded, 'Optimize', 'Your heat pump, solar and appliances are planned around the cheapest, greenest windows.'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScrollReveal(
          controller: _scroll,
          child: SectionHeader(wide: wide, eyebrow: 'HOW IT WORKS', title: 'From market data\nto money saved.'),
        ),
        const SizedBox(height: 48),
        LayoutBuilder(
          builder: (context, c) {
            final horizontal = c.maxWidth >= 800;
            final children = [
              for (var i = 0; i < steps.length; i++)
                ScrollReveal(
                  controller: _scroll,
                  delay: Duration(milliseconds: horizontal ? 150 * i : 0),
                  child: _StepTile(
                    palette: p,
                    index: i + 1,
                    icon: steps[i].$1,
                    title: steps[i].$2,
                    body: steps[i].$3,
                    showConnector: horizontal && i < steps.length - 1,
                  ),
                ),
            ];
            if (!horizontal) {
              return Column(
                children: [for (final child in children) Padding(padding: const EdgeInsets.only(bottom: 28), child: child)],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (final child in children) Expanded(child: child)],
            );
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- CTA
  Widget _buildCta(AppPalette p, bool wide) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: AnimatedBuilder(
        animation: _ambient,
        builder: (_, child) {
          final t = _ambient.value * 2 * math.pi;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(math.cos(t), math.sin(t)),
                end: Alignment(-math.cos(t), -math.sin(t)),
                colors: const [Color(0xFF047857), Color(0xFF0E7490), Color(0xFF4338CA)],
              ),
            ),
            child: child,
          );
        },
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: GridPainter(Colors.white.withValues(alpha: 0.07), 28))),
            Padding(
              padding: EdgeInsets.all(wide ? 56 : 28),
              child: Flex(
                direction: wide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: wide ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                children: [
                  Flexible(
                    fit: wide ? FlexFit.tight : FlexFit.loose,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ready to see what you could save?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: wide ? 36 : 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -1,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Enter a few details about your home and get a personalised savings estimate in under a minute.',
                          style: GoogleFonts.inter(fontSize: 16, height: 1.55, color: Colors.white.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: wide ? 40 : 0, height: wide ? 0 : 28),
                  HoverScale(
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => widget.onNavigate(2),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Start with the Advisor',
                                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF065F46)),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.arrow_forward_rounded, size: 18, color: Color(0xFF065F46)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- footer
  Widget _buildFooter(AppPalette p) {
    final style = GoogleFonts.inter(fontSize: 12.5, color: p.muted, height: 1.6);
    return Column(
      children: [
        Divider(color: p.border, height: 1),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 24,
          runSpacing: 8,
          children: [
            Text('© ${DateTime.now().year} EnergyTwin DE', style: style.copyWith(fontWeight: FontWeight.w600)),
            Text('Market data: SMARD.de · EPEX SPOT. Prices shown are forecasts, not tariffs.', style: style),
          ],
        ),
      ],
    );
  }
}

// ======================================================================
// Live price card
// ======================================================================
class _LivePriceCard extends StatelessWidget {
  const _LivePriceCard({
    required this.palette,
    required this.prices,
    required this.error,
    required this.pulse,
    required this.onRetry,
    required this.onOpen,
  });

  final AppPalette palette;
  final List<double>? prices;
  final bool error;
  final Animation<double> pulse;
  final VoidCallback onRetry;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: p.shadow, blurRadius: 60, offset: const Offset(0, 30)),
          BoxShadow(color: AppColors.emerald.withValues(alpha: p.isDark ? 0.12 : 0.08), blurRadius: 80, spreadRadius: -10),
        ],
      ),
      child: Glass(
        strong: true,
        radius: 28,
        padding: const EdgeInsets.all(26),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.easeOutCubic,
          child: prices != null
              ? _buildLoaded(context, prices!)
              : error
              ? _buildError()
              : _buildLoading(),
        ),
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, List<double> prices) {
    final p = palette;
    final hour = DateTime.now().hour.clamp(0, prices.length - 1);
    final now = prices[hour];
    final avg = prices.reduce((a, b) => a + b) / prices.length;
    final minI = prices.indexOf(prices.reduce(math.min));
    final maxI = prices.indexOf(prices.reduce(math.max));
    final diffPct = (now - avg) / avg * 100;

    final (statusLabel, statusColor, statusIcon) = diffPct <= -8
        ? ('Cheap hour', AppColors.emerald, Icons.eco_rounded)
        : diffPct >= 8
        ? ('Peak hour', AppColors.rose, Icons.warning_amber_rounded)
        : ('Average', AppColors.amber, Icons.horizontal_rule_rounded);

    String hh(int h) => '${h.toString().padLeft(2, '0')}:00';

    return Column(
      key: const ValueKey('loaded'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              'RIGHT NOW',
              style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: p.muted),
            ),
            const SizedBox(width: 8),
            Text('${hh(hour)}–${hh((hour + 1) % 24)}', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: p.muted)),
            const Spacer(),
            Pill(color: statusColor, icon: statusIcon, label: statusLabel),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CountUp(
              value: now,
              decimals: 1,
              style: GoogleFonts.plusJakartaSans(fontSize: 56, fontWeight: FontWeight.w800, height: 1, color: p.text, letterSpacing: -2),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'ct/kWh',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: p.muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              diffPct >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              size: 16,
              color: diffPct >= 0 ? AppColors.rose : AppColors.emerald,
            ),
            const SizedBox(width: 6),
            Text(
              '${diffPct.abs().toStringAsFixed(0)}% ${diffPct >= 0 ? 'above' : 'below'} today\'s average of ${avg.toStringAsFixed(1)} ct',
              style: GoogleFonts.inter(fontSize: 13, color: p.muted),
            ),
          ],
        ),
        const SizedBox(height: 22),
        SizedBox(
          height: 130,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1800),
            curve: Curves.easeInOutCubic,
            builder: (_, progress, _) => AnimatedBuilder(
              animation: pulse,
              builder: (_, _) => CustomPaint(
                size: Size.infinite,
                painter: _SparklinePainter(
                  values: prices,
                  progress: progress,
                  current: hour,
                  cheapest: minI,
                  pulse: pulse.value,
                  palette: p,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final l in const ['00', '06', '12', '18', '24'])
              Text(l, style: GoogleFonts.jetBrainsMono(fontSize: 10, color: p.muted.withValues(alpha: 0.8))),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _MiniTile(
                palette: p,
                color: AppColors.emerald,
                label: 'Cheapest',
                value: hh(minI),
                sub: '${prices[minI].toStringAsFixed(1)} ct',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniTile(
                palette: p,
                color: AppColors.rose,
                label: 'Peak',
                value: hh(maxI),
                sub: '${prices[maxI].toStringAsFixed(1)} ct',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextLink(label: 'Full forecast for today & tomorrow', color: AppColors.emerald, onTap: onOpen),
      ],
    );
  }

  Widget _buildLoading() {
    final p = palette;
    return Column(
      key: const ValueKey('loading'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              'RIGHT NOW',
              style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: p.muted),
            ),
            const Spacer(),
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.emerald.withValues(alpha: 0.8)),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Shimmer(width: 180, height: 50),
        const SizedBox(height: 12),
        Shimmer(width: 240, height: 14),
        const SizedBox(height: 26),
        Shimmer(height: 130),
        const SizedBox(height: 26),
        Row(
          children: [
            Expanded(child: Shimmer(height: 64)),
            const SizedBox(width: 12),
            Expanded(child: Shimmer(height: 64)),
          ],
        ),
        const SizedBox(height: 18),
        Text('Waking up the forecast engine…', style: GoogleFonts.inter(fontSize: 13, color: p.muted)),
      ],
    );
  }

  Widget _buildError() {
    final p = palette;
    return SizedBox(
      key: const ValueKey('error'),
      height: 300,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 40, color: p.muted),
          const SizedBox(height: 14),
          Text(
            'Live prices are unavailable',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: p.text),
          ),
          const SizedBox(height: 6),
          Text('The forecast server didn\'t respond.', style: GoogleFonts.inter(fontSize: 13, color: p.muted)),
          const SizedBox(height: 18),
          SecondaryButton(label: 'Try again', icon: Icons.refresh_rounded, onTap: onRetry),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.progress,
    required this.current,
    required this.cheapest,
    required this.pulse,
    required this.palette,
  });

  final List<double> values;
  final double progress;
  final int current;
  final int cheapest;
  final double pulse;
  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final lo = values.reduce(math.min);
    final hi = values.reduce(math.max);
    final range = (hi - lo).abs() < 0.01 ? 1.0 : hi - lo;
    final n = values.length;

    Offset pt(int i) => Offset(i / (n - 1) * size.width, size.height * 0.08 + (1 - (values[i] - lo) / range) * size.height * 0.84);

    // Subtle horizontal guides.
    final guide = Paint()
      ..color = palette.border
      ..strokeWidth = 1;
    for (var g = 0; g <= 3; g++) {
      final y = size.height * g / 3;
      _dashedLine(canvas, Offset(0, y), Offset(size.width, y), guide);
    }

    final line = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 0; i < n - 1; i++) {
      final a = pt(i), b = pt(i + 1);
      final mx = (a.dx + b.dx) / 2;
      line.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
    }
    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final rect = Offset.zero & size;
    // Vertical colour ramp: expensive = red at the top, cheap = green at the bottom.
    const ramp = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.rose, AppColors.amber, AppColors.emerald],
    );

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, -20, size.width * progress, size.height + 40));
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.emerald.withValues(alpha: palette.isDark ? 0.28 : 0.2),
            AppColors.emerald.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
    canvas.drawPath(
      line,
      Paint()
        ..shader = ramp.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();

    final reveal = size.width * progress;

    // Cheapest-hour marker.
    final c = pt(cheapest);
    if (c.dx <= reveal) {
      canvas.drawCircle(c, 4.5, Paint()..color = AppColors.emerald);
      canvas.drawCircle(
        c,
        4.5,
        Paint()
          ..color = palette.bg
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Current-hour marker with pulsing halo.
    final cur = pt(current);
    if (cur.dx <= reveal) {
      _dashedLine(
        canvas,
        Offset(cur.dx, 0),
        Offset(cur.dx, size.height),
        Paint()
          ..color = palette.text.withValues(alpha: 0.25)
          ..strokeWidth = 1,
      );
      canvas.drawCircle(cur, 6 + pulse * 12, Paint()..color = AppColors.sky.withValues(alpha: 0.35 * (1 - pulse)));
      canvas.drawCircle(cur, 6, Paint()..color = Colors.white);
      canvas.drawCircle(cur, 4, Paint()..color = AppColors.sky);
    }
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 4.0, gap = 4.0;
    final total = (b - a).distance;
    final dir = (b - a) / total;
    for (double d = 0; d < total; d += dash + gap) {
      canvas.drawLine(a + dir * d, a + dir * math.min(d + dash, total), paint);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.progress != progress || old.pulse != pulse || old.values != values || old.palette.isDark != palette.isDark;
}

// ======================================================================
// Background
// ======================================================================
// ======================================================================
// Sections & tiles
// ======================================================================
class _Stat {
  const _Stat({required this.value, required this.decimals, required this.prefix, required this.suffix, required this.label});
  final double value;
  final int decimals;
  final String prefix;
  final String suffix;
  final String label;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.stat, required this.palette, required this.wide});
  final _Stat stat;
  final AppPalette palette;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CountUp(
          value: stat.value,
          decimals: stat.decimals,
          prefix: stat.prefix,
          suffix: stat.suffix,
          duration: const Duration(milliseconds: 2000),
          style: GoogleFonts.plusJakartaSans(fontSize: wide ? 34 : 26, fontWeight: FontWeight.w800, color: palette.text, letterSpacing: -1),
        ),
        const SizedBox(height: 4),
        Text(
          stat.label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 12.5, color: palette.muted),
        ),
      ],
    );
  }
}

class _Feature {
  const _Feature({
    required this.icon,
    required this.colors,
    required this.title,
    required this.body,
    required this.tags,
    required this.tab,
  });
  final IconData icon;
  final List<Color> colors;
  final String title;
  final String body;
  final List<String> tags;
  final int tab;
}

class _FeatureCard extends StatefulWidget {
  const _FeatureCard({required this.feature, required this.palette, required this.onTap});
  final _Feature feature;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final f = widget.feature;
    final accent = f.colors.first;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _hover ? -8 : 0, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _hover ? accent.withValues(alpha: p.isDark ? 0.25 : 0.18) : p.shadow,
                blurRadius: _hover ? 50 : 30,
                offset: Offset(0, _hover ? 24 : 14),
                spreadRadius: -8,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: _hover ? p.glassStrong : p.glass,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _hover ? accent.withValues(alpha: 0.5) : p.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedRotation(
                      turns: _hover ? -0.02 : 0,
                      duration: const Duration(milliseconds: 280),
                      child: AnimatedScale(
                        scale: _hover ? 1.08 : 1,
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutBack,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            gradient: LinearGradient(colors: f.colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                            boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.4), blurRadius: 18, offset: const Offset(0, 6))],
                          ),
                          child: Icon(f.icon, color: Colors.white, size: 26),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      f.title,
                      style: GoogleFonts.plusJakartaSans(fontSize: 21, fontWeight: FontWeight.w800, color: p.text, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 10),
                    Text(f.body, style: GoogleFonts.inter(fontSize: 14.5, height: 1.6, color: p.muted)),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in f.tags)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                            child: Text(
                              t,
                              style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: accent),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Text(
                          'Open tool',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: p.text),
                        ),
                        AnimatedPadding(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          padding: EdgeInsets.only(left: _hover ? 12 : 6),
                          child: Icon(Icons.arrow_forward_rounded, size: 18, color: _hover ? accent : p.text),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.palette,
    required this.index,
    required this.icon,
    required this.title,
    required this.body,
    required this.showConnector,
  });
  final AppPalette palette;
  final int index;
  final IconData icon;
  final String title;
  final String body;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.glassStrong,
                border: Border.all(color: AppColors.emerald.withValues(alpha: 0.4), width: 1.5),
                boxShadow: [BoxShadow(color: AppColors.emerald.withValues(alpha: 0.18), blurRadius: 24)],
              ),
              child: Icon(icon, color: AppColors.emerald, size: 24),
            ),
            if (showConnector)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.emerald.withValues(alpha: 0.5), AppColors.sky.withValues(alpha: 0.05)]),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(right: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '0$index',
                style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.emerald, letterSpacing: 1),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: p.text, letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              Text(body, style: GoogleFonts.inter(fontSize: 14.5, height: 1.6, color: p.muted)),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniTile extends StatelessWidget {
  const _MiniTile({required this.palette, required this.color, required this.label, required this.value, required this.sub});
  final AppPalette palette;
  final Color color;
  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withValues(alpha: palette.isDark ? 0.1 : 0.07),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: palette.muted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: palette.text),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  sub,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 12, color: palette.muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// Primitives
// ======================================================================
