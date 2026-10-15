import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/custom_app_bar.dart';
import 'package:frontend/main.dart' show serverWarmup, kBackendUrl;
import 'package:frontend/ui/kit.dart';
import 'package:http/http.dart' as http;

class AdvisorScreen extends StatefulWidget {
  const AdvisorScreen({super.key, required this.themeNotifier});
  final ValueNotifier<ThemeMode> themeNotifier;

  @override
  State<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends State<AdvisorScreen> {
  final TextEditingController _gasBillController = TextEditingController(text: '180');
  double _houseSize = 120.0;
  String _insulationLevel = 'average';

  bool _isLoading = false;
  Map<String, dynamic>? _roiData;
  String _errorMessage = '';
  String _loadingMessage = 'Calculating...';

  final GlobalKey _resultsKey = GlobalKey();
  final GlobalKey _statusKey = GlobalKey();

  static const _accent = [AppColors.emerald, AppColors.teal];

  void _updateEstimatedBill() {
    double multiplier = 1.5;
    if (_insulationLevel == 'poor') multiplier = 2.0;
    if (_insulationLevel == 'good') multiplier = 1.0;
    _gasBillController.text = (_houseSize * multiplier).toStringAsFixed(0);
  }

  void _scrollTo(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 700), curve: Curves.easeOutCubic, alignment: 0.05);
      }
    });
  }

  Future<void> _calculateROI({int attempt = 1}) async {
    final double? userBill = double.tryParse(_gasBillController.text.trim());
    if (userBill == null || userBill <= 0) {
      setState(() => _errorMessage = 'Please enter a valid monthly bill.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _roiData = null;
      _loadingMessage = attempt == 1 ? 'Connecting to server...' : 'Retrying... (attempt $attempt of 3)';
    });
    if (attempt == 1) _scrollTo(_statusKey);
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
          .post(
            Uri.parse('$kBackendUrl/simulate_investment'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'monthly_gas_bill_eur': userBill,
              'house_size_sqm': _houseSize,
              'insulation_level': _insulationLevel,
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          _roiData = jsonDecode(response.body);
          _isLoading = false;
        });
        _scrollTo(_resultsKey);
      } else if (attempt < 3) {
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) _calculateROI(attempt: attempt + 1);
      } else {
        setState(() {
          _errorMessage = 'Server error ${response.statusCode}.';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      if (attempt < 3) {
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) _calculateROI(attempt: attempt + 1);
      } else {
        setState(() {
          _errorMessage = 'Could not reach server after 3 attempts.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _gasBillController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- build
  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        themeNotifier: widget.themeNotifier,
        title: 'Heat Pump Advisor',
        subtitle: 'ROI simulation · AI off-peak scheduling',
        icon: Icons.heat_pump_rounded,
        colors: _accent,
      ),
      body: AuroraBackground(
        colors: const [AppColors.emerald, AppColors.teal, AppColors.sky, AppColors.indigo],
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 32, bottom: kNavClearance),
            child: PageBody(
              maxWidth: 1140,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 860;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FadeSlideIn(child: _buildHero(p, isWide)),
                      SizedBox(height: isWide ? 72 : 48),
                      FadeSlideIn(delay: const Duration(milliseconds: 150), child: _buildHowItWorks(p, isWide)),
                      SizedBox(height: isWide ? 72 : 48),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 250),
                        child: SectionHeader(
                          eyebrow: 'YOUR SIMULATION',
                          title: 'Tell us about your home.',
                          subtitle: 'Three inputs are all the Digital Twin needs to model your heating demand.',
                          wide: isWide,
                          compact: true,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 300),
                        child: isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 3, child: _buildInputCard(p)),
                                  const SizedBox(width: 20),
                                  Expanded(flex: 2, child: _buildAssumptionsCard(p)),
                                ],
                              )
                            : Column(children: [_buildInputCard(p), const SizedBox(height: 20), _buildAssumptionsCard(p)]),
                      ),
                      KeyedSubtree(
                        key: _statusKey,
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_isLoading) ...[
                                const SizedBox(height: 24),
                                FadeSlideIn(
                                  child: LoadingPanel(
                                    message: _loadingMessage,
                                    sub: 'Running Digital Twin simulation...',
                                    icon: Icons.heat_pump_rounded,
                                    colors: _accent,
                                  ),
                                ),
                              ],
                              if (_errorMessage.isNotEmpty) ...[const SizedBox(height: 24), FadeSlideIn(child: _buildErrorCard(p))],
                            ],
                          ),
                        ),
                      ),
                      if (_roiData != null) ...[
                        const SizedBox(height: 56),
                        KeyedSubtree(key: _resultsKey, child: _buildResults(p, isWide)),
                      ],
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

  // ---------------------------------------------------------------- hero
  Widget _buildHero(AppPalette p, bool isWide) {
    final titleStyle = AppType.display(isWide ? 48 : 34, p.text, height: 1.06);
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Pill(color: AppColors.emerald, icon: Icons.bolt_rounded, label: 'Powered by live EPEX SPOT market data'),
        const SizedBox(height: 20),
        Text('Swap your gas boiler\nfor a', style: titleStyle),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (b) => const LinearGradient(colors: [AppColors.emerald, AppColors.teal, AppColors.sky]).createShader(b),
          child: Text('smart heat pump.', style: titleStyle),
        ),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            'Replace your gas boiler with a smart heat pump and let EnergyTwin\'s AI schedule heating around cheap electricity windows. Enter your property details to see your exact savings.',
            style: AppType.body(isWide ? 17 : 15.5, p.muted, height: 1.6),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _heroChip(p, Icons.eco_rounded, '3–4× more efficient than gas'),
            _heroChip(p, Icons.schedule_rounded, 'AI off-peak scheduling'),
            _heroChip(p, Icons.co2_rounded, 'Up to 80% less CO₂'),
            _heroChip(p, Icons.euro_rounded, '€15k install, BAFA subsidy eligible'),
          ],
        ),
      ],
    );
    if (!isWide) return copy;
    return Row(
      children: [
        Expanded(child: copy),
        const SizedBox(width: 40),
        const HeroOrb(icon: Icons.heat_pump_rounded, colors: _accent, size: 240),
      ],
    );
  }

  Widget _heroChip(AppPalette p, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: p.glass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.emerald),
          const SizedBox(width: 7),
          Text(text, style: AppType.body(12.5, p.text, weight: FontWeight.w600, height: 1.2)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- how it works
  Widget _buildHowItWorks(AppPalette p, bool isWide) {
    const steps = [
      (
        Icons.local_fire_department_rounded,
        [AppColors.orange, AppColors.rose],
        'Your gas boiler today',
        'Burns natural gas at ~85% efficiency. German gas costs ~€0.10/kWh. Heating a typical home produces 1,200–2,400 kg of CO₂ every year.',
      ),
      (
        Icons.heat_pump_rounded,
        [AppColors.sky, AppColors.blue],
        'The heat pump upgrade',
        'Moves heat from outdoor air using a small amount of electricity. A COP of 3.5 means 1 kWh in → 3.5 kWh of heat out — far more efficient than any combustion boiler.',
      ),
      (
        Icons.auto_awesome_rounded,
        [AppColors.emerald, AppColors.teal],
        'EnergyTwin AI scheduling',
        'Our AI monitors German EPEX SPOT prices and pre-heats your home during cheap windows (overnight wind surplus, midday solar dip) — saving an extra 40% on electricity.',
      ),
    ];

    final cards = [
      for (var i = 0; i < steps.length; i++) _stepCard(p, i + 1, steps[i].$1, steps[i].$2, steps[i].$3, steps[i].$4),
    ];

    Widget connector(IconData icon) => Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(shape: BoxShape.circle, color: p.glassStrong, border: Border.all(color: p.border)),
            child: Icon(icon, size: 16, color: p.muted),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          eyebrow: 'WHY IT PAYS OFF',
          title: 'From burning gas to\nsmart, scheduled heat.',
          wide: isWide,
          compact: true,
        ),
        const SizedBox(height: 28),
        if (isWide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[0]),
                Center(child: connector(Icons.arrow_forward_rounded)),
                Expanded(child: cards[1]),
                Center(child: connector(Icons.arrow_forward_rounded)),
                Expanded(child: cards[2]),
              ],
            ),
          )
        else
          Column(
            children: [cards[0], connector(Icons.arrow_downward_rounded), cards[1], connector(Icons.arrow_downward_rounded), cards[2]],
          ),
      ],
    );
  }

  Widget _stepCard(AppPalette p, int n, IconData icon, List<Color> colors, String title, String body) {
    return Glass(
      radius: 22,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon: icon, colors: colors, size: 46),
              const Spacer(),
              Text('0$n', style: AppType.mono(13, colors.first, weight: FontWeight.w700, spacing: 1)),
            ],
          ),
          const SizedBox(height: 18),
          Text(title, style: AppType.display(17, p.text)),
          const SizedBox(height: 8),
          Text(body, style: AppType.body(13.5, p.muted, height: 1.6)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- input
  Widget _buildInputCard(AppPalette p) {
    final copHints = {
      'poor': 'COP ≈ 2.8  ·  needs higher water temps',
      'average': 'COP ≈ 3.5  ·  typical German installation',
      'good': 'COP ≈ 4.2  ·  excellent with underfloor heating',
    };
    const levels = [
      ('poor', 'Poor', 'Pre-1980, minimal insulation', AppColors.rose),
      ('average', 'Average', 'Standard German construction', AppColors.amber),
      ('good', 'Good', 'Modern, renovated or passive', AppColors.emerald),
    ];

    return GlassCard(
      title: 'Your property',
      subtitle: 'The bill auto-estimates as you adjust size and insulation.',
      icon: Icons.home_rounded,
      colors: _accent,
      strong: true,
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _gasBillController,
            label: 'Monthly heating / gas bill',
            helper: 'Your average monthly gas or district heating bill',
            icon: Icons.euro_rounded,
            suffix: '€ / month',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onSubmitted: (_) => _isLoading ? null : _calculateROI(),
          ),
          const SizedBox(height: 24),
          Text('Building insulation', style: AppType.body(13, p.text, weight: FontWeight.w600, height: 1.2)),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, c) {
              final tiles = [
                for (final l in levels)
                  _InsulationTile(
                    title: l.$2,
                    sub: l.$3,
                    color: l.$4,
                    selected: _insulationLevel == l.$1,
                    onTap: () => setState(() {
                      _insulationLevel = l.$1;
                      _updateEstimatedBill();
                    }),
                  ),
              ];
              if (c.maxWidth < 440) {
                return Column(children: [for (final t in tiles) Padding(padding: const EdgeInsets.only(bottom: 8), child: t)]);
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < tiles.length; i++) ...[if (i > 0) const SizedBox(width: 10), Expanded(child: tiles[i])],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SizeTransition(sizeFactor: a, axisAlignment: -1, child: child),
            ),
            child: Align(
              key: ValueKey(_insulationLevel),
              alignment: Alignment.centerLeft,
              child: Pill(color: AppColors.sky, icon: Icons.info_outline_rounded, label: copHints[_insulationLevel]!),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('House size', style: AppType.body(13, p.text, weight: FontWeight.w600, height: 1.2)),
              const Spacer(),
              Text('${_houseSize.toInt()}', style: AppType.display(26, AppColors.emerald, height: 1)),
              const SizedBox(width: 4),
              Text('m²', style: AppType.body(14, p.muted, weight: FontWeight.w600, height: 1.2)),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              activeTrackColor: AppColors.emerald,
              inactiveTrackColor: p.track,
              thumbColor: Colors.white,
              overlayColor: AppColors.emerald.withValues(alpha: 0.15),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11, elevation: 4),
              tickMarkShape: SliderTickMarkShape.noTickMark,
              trackShape: const RoundedRectSliderTrackShape(),
            ),
            child: Slider(
              value: _houseSize,
              min: 50,
              max: 300,
              divisions: 25,
              onChanged: (val) => setState(() {
                _houseSize = val;
                _updateEstimatedBill();
              }),
            ),
          ),
          Row(
            children: [
              Text('50 m²', style: AppType.mono(11, p.faint)),
              const Spacer(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Pill(key: ValueKey(_houseSizeLabel()), color: AppColors.emerald, icon: Icons.home_work_rounded, label: _houseSizeLabel()),
              ),
              const Spacer(),
              Text('300 m²', style: AppType.mono(11, p.faint)),
            ],
          ),
          const SizedBox(height: 30),
          PrimaryButton(
            label: _isLoading ? _loadingMessage : 'Calculate my savings',
            icon: Icons.arrow_forward_rounded,
            loading: _isLoading,
            expand: true,
            colors: _accent,
            onTap: _calculateROI,
          ),
        ],
      ),
    );
  }

  String _houseSizeLabel() {
    if (_houseSize < 80) return 'Small apartment';
    if (_houseSize < 120) return 'Medium apartment';
    if (_houseSize < 160) return 'Semi-detached';
    if (_houseSize < 220) return 'Detached house';
    return 'Large property';
  }

  // ---------------------------------------------------------------- assumptions
  Widget _buildAssumptionsCard(AppPalette p) {
    final rows = [
      ('Gas price', '€0.10 / kWh', 'Current German residential tariff'),
      ('Gas boiler efficiency', '85%', 'Typical old condensing boiler'),
      ('Standard electricity', '€0.30 / kWh', 'Average German household rate'),
      ('Smart rate (EnergyTwin)', '€0.18 / kWh', 'Off-peak EPEX SPOT average'),
      ('Installation cost', '€15,000', 'Net after BAFA subsidy (up to €18,750)'),
      ('Grid CO₂ intensity', '0.35 kg / kWh', 'German electricity mix, 2024'),
      ('Gas CO₂ intensity', '0.20 kg / kWh', 'Direct natural gas emissions'),
    ];
    return GlassCard(
      title: 'Model assumptions',
      subtitle: 'Transparent methodology — Germany 2024 data.',
      icon: Icons.rule_rounded,
      colors: const [AppColors.sky, AppColors.indigo],
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(color: p.border, height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rows[i].$1, style: AppType.body(13, p.text, weight: FontWeight.w600, height: 1.3)),
                      const SizedBox(height: 2),
                      Text(rows[i].$3, style: AppType.body(11.5, p.faint, height: 1.35)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(rows[i].$2, style: AppType.mono(12.5, AppColors.sky, weight: FontWeight.w700)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorCard(AppPalette p) {
    return Glass(
      radius: 18,
      borderColor: AppColors.rose.withValues(alpha: 0.35),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const IconTile(icon: Icons.error_outline_rounded, colors: [AppColors.rose], size: 40, soft: true),
          const SizedBox(width: 14),
          Expanded(child: Text(_errorMessage, style: AppType.body(14, p.text, weight: FontWeight.w600, height: 1.4))),
          const SizedBox(width: 12),
          TextLink(label: 'Try again', color: AppColors.rose, icon: Icons.refresh_rounded, onTap: _calculateROI),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- results
  Widget _buildResults(AppPalette p, bool isWide) {
    final d = _roiData!;
    final gasCost = (d['current_yearly_gas_cost_eur'] as num).toDouble();
    final smartCost = (d['smart_heatpump_cost_eur'] as num).toDouble();
    final savings = (d['ai_annual_savings_eur'] as num).toDouble();
    final roi = (d['estimated_roi_years'] as num).toDouble();
    final heatKwh = (d['heat_demand_kwh'] as num).toDouble();
    final elecKwh = (d['hp_electricity_kwh'] as num).toDouble();
    final cop = (d['cop_estimated'] as num).toDouble();
    final co2Saved = (d['co2_saved_kg'] as num).toDouble();
    final standardCost = elecKwh * 0.30;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeSlideIn(
          child: SectionHeader(
            eyebrow: 'YOUR DIGITAL TWIN RESULTS',
            title: 'Here\'s what you\'d save.',
            wide: isWide,
            compact: true,
          ),
        ),
        const SizedBox(height: 24),
        FadeSlideIn(delay: const Duration(milliseconds: 100), child: _buildSavingsHero(savings, roi, savings * 20, co2Saved, isWide)),
        const SizedBox(height: 20),
        FadeSlideIn(delay: const Duration(milliseconds: 200), child: _buildCostComparison(p, gasCost, standardCost, smartCost)),
        const SizedBox(height: 20),
        FadeSlideIn(
          delay: const Duration(milliseconds: 300),
          child: isWide
              ? IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _buildSystemSpecs(p, cop, heatKwh, elecKwh)),
                      const SizedBox(width: 20),
                      Expanded(child: _buildEnvironmentCard(p, co2Saved, heatKwh)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildSystemSpecs(p, cop, heatKwh, elecKwh),
                    const SizedBox(height: 20),
                    _buildEnvironmentCard(p, co2Saved, heatKwh),
                  ],
                ),
        ),
        const SizedBox(height: 20),
        FadeSlideIn(delay: const Duration(milliseconds: 400), child: _buildSmartSchedulingCard(p, standardCost, smartCost, isWide)),
      ],
    );
  }

  Widget _buildSavingsHero(double savings, double roi, double lifetime, double co2, bool isWide) {
    final stats = [
      (savings, 0, '€', '', 'Saved per year'),
      (roi, 1, '', ' yrs', 'Break-even payback'),
      (lifetime, 0, '€', '', 'Total over 20 years'),
      (co2, 0, '', ' kg', 'CO₂ eliminated / yr'),
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF047857), Color(0xFF0F766E), Color(0xFF3730A3)],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: GridPainter(Colors.white.withValues(alpha: 0.07), 28))),
            Padding(
              padding: EdgeInsets.all(isWide ? 32 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text('Simulation complete', style: AppType.body(14, Colors.white, weight: FontWeight.w700, height: 1.2)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, c) {
                      final perRow = c.maxWidth > 640 ? 4 : 2;
                      final w = c.maxWidth / perRow;
                      return Wrap(
                        runSpacing: 22,
                        children: [
                          for (var i = 0; i < stats.length; i++)
                            Container(
                              width: w,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: i % perRow != 0 ? Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.2))) : null,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: CountUp(
                                      value: stats[i].$1,
                                      decimals: stats[i].$2,
                                      prefix: stats[i].$3,
                                      suffix: stats[i].$4,
                                      thousands: true,
                                      duration: const Duration(milliseconds: 1800),
                                      style: AppType.display(i == 0 ? (isWide ? 40 : 30) : (isWide ? 32 : 24), Colors.white, height: 1.1),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(stats[i].$5, style: AppType.body(12.5, Colors.white.withValues(alpha: 0.75), height: 1.3)),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostComparison(AppPalette p, double gasCost, double standardCost, double smartCost) {
    return GlassCard(
      title: 'Annual cost comparison',
      subtitle: 'Same warmth — three very different heating strategies.',
      icon: Icons.compare_arrows_rounded,
      colors: _accent,
      child: Column(
        children: [
          _costBar(p, 'Gas Boiler', 'Your current system — gas burned at 85% efficiency', gasCost, gasCost,
              const [AppColors.orange, AppColors.rose], false, 0),
          const SizedBox(height: 20),
          _costBar(p, 'Standard Heat Pump', 'Off-the-shelf install, billed at flat €0.30/kWh tariff', standardCost, gasCost,
              const [AppColors.sky, AppColors.blue], false, 1),
          const SizedBox(height: 20),
          _costBar(p, 'EnergyTwin Smart Heat Pump', 'AI shifts load to off-peak windows — avg €0.18/kWh', smartCost, gasCost, _accent, true, 2),
        ],
      ),
    );
  }

  Widget _costBar(AppPalette p, String title, String subtitle, double cost, double maxCost, List<Color> colors, bool isBest, int i) {
    final fraction = maxCost > 0 ? (cost / maxCost).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isBest) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(gradient: LinearGradient(colors: colors), borderRadius: BorderRadius.circular(6)),
                          child: Text('BEST', style: AppType.mono(9.5, Colors.white, weight: FontWeight.w800, spacing: 0.8)),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(child: Text(title, style: AppType.body(14.5, p.text, weight: FontWeight.w700, height: 1.3))),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppType.body(12, p.faint, height: 1.35)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            CountUp(
              value: cost,
              decimals: 0,
              prefix: '€',
              suffix: '/yr',
              thousands: true,
              style: AppType.display(18, colors.first),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AnimatedBar(fraction: fraction, colors: colors, height: 12, duration: Duration(milliseconds: 1000 + i * 250)),
      ],
    );
  }

  Widget _buildSystemSpecs(AppPalette p, double cop, double heatKwh, double elecKwh) {
    final copLabel = cop >= 4.0 ? 'Excellent' : (cop >= 3.3 ? 'Good' : 'Acceptable');
    final copColor = cop >= 4.0 ? AppColors.emerald : (cop >= 3.3 ? AppColors.amber : AppColors.sky);
    return GlassCard(
      title: 'System specifications',
      icon: Icons.settings_suggest_rounded,
      colors: const [AppColors.sky, AppColors.indigo],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              RingMeter(
                value: cop / 5,
                colors: [copColor, Color.lerp(copColor, AppColors.indigo, 0.4)!],
                label: 'COP · $copLabel',
                centerText: cop.toStringAsFixed(1),
                size: 104,
              ),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bigFact(p, 'Annual heat demand', heatKwh, 'kWh'),
                    const SizedBox(height: 14),
                    _bigFact(p, 'Heat pump electricity', elecKwh, 'kWh / yr'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: p.border, height: 1),
          const SizedBox(height: 16),
          _specRow(p, 'Annual heat demand', 'Total thermal energy your home needs for heating — derived from gas consumption × 85% boiler efficiency'),
          _specRow(p, 'Heat pump electricity', 'Electricity the heat pump consumes to deliver the heat demand above'),
          _specRow(p, 'Coefficient of performance', '1 kWh electricity → ${cop}x kWh of heat. Depends on insulation quality and system design.'),
          _specRow(
            p,
            'Insulation class · ${_insulationLevel[0].toUpperCase()}${_insulationLevel.substring(1)}',
            'Determines achievable COP and heat distribution type (radiators vs. underfloor heating)',
          ),
        ],
      ),
    );
  }

  Widget _bigFact(AppPalette p, String label, double value, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppType.body(12, p.muted, weight: FontWeight.w600, height: 1.3)),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            CountUp(value: value, decimals: 0, thousands: true, style: AppType.display(22, p.text)),
            const SizedBox(width: 5),
            Text(unit, style: AppType.body(12, p.faint, height: 1.2)),
          ],
        ),
      ],
    );
  }

  Widget _specRow(AppPalette p, String label, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 10),
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.sky),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$label  ', style: AppType.body(12.5, p.text, weight: FontWeight.w700, height: 1.45)),
                  TextSpan(text: hint, style: AppType.body(12.5, p.faint, height: 1.45)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentCard(AppPalette p, double co2Saved, double heatKwh) {
    final trees = (co2Saved / 21).toInt();
    final gasCo2 = (heatKwh / 0.85) * 0.20;
    final reductionPct = gasCo2 > 0 ? ((co2Saved / gasCo2) * 100).clamp(0, 100).toInt() : 0;
    return GlassCard(
      title: 'Environmental impact',
      icon: Icons.eco_rounded,
      colors: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _envRow(p, Icons.co2_rounded, AppColors.emerald, '${co2Saved.toStringAsFixed(0)} kg', 'CO₂ eliminated per year'),
          _envRow(p, Icons.park_rounded, AppColors.teal, '~$trees trees', 'Equivalent annual CO₂ absorption'),
          _envRow(p, Icons.directions_car_rounded, AppColors.sky, '${(co2Saved / 2300).toStringAsFixed(1)} cars', 'Taken off the road equivalent'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Text('CO₂ reduction vs. your gas boiler', style: AppType.body(12.5, p.muted, weight: FontWeight.w600, height: 1.3))),
              Text('$reductionPct%', style: AppType.display(18, AppColors.emerald)),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedBar(fraction: reductionPct / 100, colors: const [AppColors.teal, AppColors.emerald], height: 14),
          const SizedBox(height: 8),
          Text('$reductionPct% less CO₂ than gas', style: AppType.body(12, AppColors.emerald, weight: FontWeight.w700, height: 1.3)),
        ],
      ),
    );
  }

  Widget _envRow(AppPalette p, IconData icon, Color color, String value, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          IconTile(icon: icon, colors: [color], size: 44, soft: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AppType.display(18, p.text)),
                Text(label, style: AppType.body(12.5, p.muted, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartSchedulingCard(AppPalette p, double standardCost, double smartCost, bool isWide) {
    final extra = (standardCost - smartCost).abs();
    final pct = standardCost > 0 ? ((extra / standardCost) * 100).toInt() : 0;
    const windows = [
      (
        Icons.nightlight_round,
        AppColors.indigo,
        '00:00 – 06:00',
        'Overnight wind valley',
        'Wind turbines run all night but demand is minimal. EPEX prices fall to 5–15 ct/kWh. EnergyTwin pre-charges your home\'s thermal mass silently while you sleep.',
      ),
      (
        Icons.wb_sunny_rounded,
        AppColors.amber,
        '11:00 – 14:00',
        'Solar surplus midday',
        'Germany\'s solar fleet peaks and prices can hit 0 or even go negative. EnergyTwin maximises heat pump runtime in this window — essentially free heat.',
      ),
      (
        Icons.trending_down_rounded,
        AppColors.rose,
        '17:00 – 20:00',
        'Avoid evening peak',
        'Evening demand spikes push EPEX to 30–60 ct/kWh. EnergyTwin pauses the heat pump. Stored heat keeps your home comfortable without paying peak rates.',
      ),
    ];

    return GlassCard(
      title: 'How EnergyTwin saves an extra €${extra.toStringAsFixed(0)}/yr ($pct%)',
      subtitle:
          'The AI shifts your heat pump runtime to the three cheapest daily windows on the German EPEX SPOT market — the same prices shown on your Prices screen.',
      icon: Icons.bolt_rounded,
      colors: const [AppColors.amber, AppColors.orange],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('A TYPICAL DAY', style: AppType.eyebrow(p.faint)),
          const SizedBox(height: 10),
          const _DayTimeline(),
          const SizedBox(height: 24),
          ResponsiveGrid(
            minItemWidth: 260,
            maxColumns: 3,
            children: [
              for (final w in windows)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: w.$2.withValues(alpha: p.isDark ? 0.07 : 0.05),
                    border: Border.all(color: w.$2.withValues(alpha: 0.22)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconTile(icon: w.$1, colors: [w.$2], size: 36, soft: true),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(w.$3, style: AppType.mono(12, w.$2, weight: FontWeight.w700)),
                                Text(w.$4, style: AppType.body(13.5, p.text, weight: FontWeight.w700, height: 1.3)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(w.$5, style: AppType.body(12.5, p.muted, height: 1.5)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.emerald.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_rounded, size: 18, color: AppColors.emerald),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'A well-insulated home retains heat for 3–6 hours, making schedule shifting painless and invisible to occupants.',
                    style: AppType.body(13, p.text, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsulationTile extends StatefulWidget {
  const _InsulationTile({required this.title, required this.sub, required this.color, required this.selected, required this.onTap});
  final String title;
  final String sub;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_InsulationTile> createState() => _InsulationTileState();
}

class _InsulationTileState extends State<_InsulationTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final sel = widget.selected;
    final c = widget.color;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: sel ? c.withValues(alpha: p.isDark ? 0.14 : 0.1) : (_hover ? p.glassStrong : p.field),
            border: Border.all(color: sel ? c : p.border, width: sel ? 1.6 : 1),
            boxShadow: sel ? [BoxShadow(color: c.withValues(alpha: 0.25), blurRadius: 18, offset: const Offset(0, 6))] : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.thermostat_rounded, size: 18, color: c),
                  const Spacer(),
                  AnimatedScale(
                    scale: sel ? 1 : 0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                    child: Icon(Icons.check_circle_rounded, size: 18, color: c),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(widget.title, style: AppType.body(14, p.text, weight: FontWeight.w700, height: 1.2)),
              const SizedBox(height: 2),
              Text(widget.sub, style: AppType.body(11.5, p.muted, height: 1.35)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 24-hour strip highlighting when the smart heat pump runs and pauses.
class _DayTimeline extends StatelessWidget {
  const _DayTimeline();

  static Color? _windowColor(int h) {
    if (h < 6) return AppColors.indigo;
    if (h >= 11 && h < 14) return AppColors.amber;
    if (h >= 17 && h < 20) return AppColors.rose;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Column(
      children: [
        SizedBox(
          height: 30,
          child: Row(
            children: [
              for (var h = 0; h < 24; h++)
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 400 + h * 40),
                    curve: Curves.easeOut,
                    builder: (_, t, _) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1.2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: _windowColor(h)?.withValues(alpha: 0.85 * t) ?? p.track,
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
          children: [for (final l in const ['00', '06', '12', '18', '24']) Text(l, style: AppType.mono(10, p.faint))],
        ),
      ],
    );
  }
}
