import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/custom_app_bar.dart';
import 'package:frontend/l10n/app_localizations.dart';
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
  // Resolved at build time so a language switch mid-load updates the text.
  String Function(AppLocalizations)? _error;
  String Function(AppLocalizations) _loadingMessage = (l) => l.advisorCalculating;

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
      setState(() => _error = (l) => l.advisorInvalidBill);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _error = null;
      _roiData = null;
      _loadingMessage = attempt == 1 ? (l) => l.loadingConnecting : (l) => l.loadingRetry(attempt);
    });
    if (attempt == 1) _scrollTo(_statusKey);
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
          final code = response.statusCode;
          _error = (l) => l.advisorServerError(code);
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
          _error = (l) => l.advisorUnreachable;
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
        title: context.l10n.advisorTitle,
        subtitle: context.l10n.advisorSubtitle,
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
                          eyebrow: context.l10n.advisorSimEyebrow,
                          title: context.l10n.advisorSimTitle,
                          subtitle: context.l10n.advisorSimSubtitle,
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
                                    message: _loadingMessage(context.l10n),
                                    sub: context.l10n.advisorRunningTwin,
                                    icon: Icons.heat_pump_rounded,
                                    colors: _accent,
                                  ),
                                ),
                              ],
                              if (_error != null) ...[const SizedBox(height: 24), FadeSlideIn(child: _buildErrorCard(p))],
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
    final l = context.l10n;
    final titleStyle = AppType.display(isWide ? 48 : 34, p.text, height: 1.06);
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Pill(color: AppColors.emerald, icon: Icons.bolt_rounded, label: l.advisorPill),
        const SizedBox(height: 20),
        Text(l.advisorHeadline1, style: titleStyle),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (b) => const LinearGradient(colors: [AppColors.emerald, AppColors.teal, AppColors.sky]).createShader(b),
          child: Text(l.advisorHeadline2, style: titleStyle),
        ),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            l.advisorIntro,
            style: AppType.body(isWide ? 17 : 15.5, p.muted, height: 1.6),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _heroChip(p, Icons.eco_rounded, l.advisorChip1),
            _heroChip(p, Icons.schedule_rounded, l.advisorChip2),
            _heroChip(p, Icons.co2_rounded, l.advisorChip3),
            _heroChip(p, Icons.euro_rounded, l.advisorChip4),
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
    final l = context.l10n;
    final steps = [
      (Icons.local_fire_department_rounded, const [AppColors.orange, AppColors.rose], l.advisorStep1Title, l.advisorStep1Body),
      (Icons.heat_pump_rounded, const [AppColors.sky, AppColors.blue], l.advisorStep2Title, l.advisorStep2Body),
      (Icons.auto_awesome_rounded, const [AppColors.emerald, AppColors.teal], l.advisorStep3Title, l.advisorStep3Body),
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
          eyebrow: l.advisorWhyEyebrow,
          title: l.advisorWhyTitle,
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
    final l = context.l10n;
    final copHints = {'poor': l.copHintPoor, 'average': l.copHintAverage, 'good': l.copHintGood};
    final levels = [
      ('poor', l.insulationPoor, l.insulationPoorDesc, AppColors.rose),
      ('average', l.insulationAverage, l.insulationAverageDesc, AppColors.amber),
      ('good', l.insulationGood, l.insulationGoodDesc, AppColors.emerald),
    ];

    return GlassCard(
      title: l.propertyTitle,
      subtitle: l.propertySubtitle,
      icon: Icons.home_rounded,
      colors: _accent,
      strong: true,
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _gasBillController,
            label: l.gasBillLabel,
            helper: l.gasBillHelper,
            icon: Icons.euro_rounded,
            suffix: l.perMonthSuffix,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onSubmitted: (_) => _isLoading ? null : _calculateROI(),
          ),
          const SizedBox(height: 24),
          Text(l.buildingInsulation, style: AppType.body(13, p.text, weight: FontWeight.w600, height: 1.2)),
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
              Text(l.houseSize, style: AppType.body(13, p.text, weight: FontWeight.w600, height: 1.2)),
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
            label: _isLoading ? _loadingMessage(l) : l.calculateSavings,
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
    final l = context.l10n;
    if (_houseSize < 80) return l.sizeSmallApartment;
    if (_houseSize < 120) return l.sizeMediumApartment;
    if (_houseSize < 160) return l.sizeSemiDetached;
    if (_houseSize < 220) return l.sizeDetached;
    return l.sizeLarge;
  }

  // ---------------------------------------------------------------- assumptions
  Widget _buildAssumptionsCard(AppPalette p) {
    final l = context.l10n;
    final rows = [
      (l.asmGasPrice, l.asmGasPriceValue, l.asmGasPriceHint),
      (l.asmBoiler, l.asmBoilerValue, l.asmBoilerHint),
      (l.asmStdElec, l.asmStdElecValue, l.asmStdElecHint),
      (l.asmSmartRate, l.asmSmartRateValue, l.asmSmartRateHint),
      (l.asmInstall, l.asmInstallValue, l.asmInstallHint),
      (l.asmGridCo2, l.asmGridCo2Value, l.asmGridCo2Hint),
      (l.asmGasCo2, l.asmGasCo2Value, l.asmGasCo2Hint),
    ];
    return GlassCard(
      title: l.assumptionsTitle,
      subtitle: l.assumptionsSubtitle,
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
          Expanded(child: Text(_error!(context.l10n), style: AppType.body(14, p.text, weight: FontWeight.w600, height: 1.4))),
          const SizedBox(width: 12),
          TextLink(label: context.l10n.tryAgain, color: AppColors.rose, icon: Icons.refresh_rounded, onTap: _calculateROI),
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
            eyebrow: context.l10n.resultsEyebrow,
            title: context.l10n.resultsTitle,
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
    final l = context.l10n;
    // (value, decimals, is euro amount, suffix, label)
    final stats = [
      (savings, 0, true, '', l.statSavedPerYear),
      (roi, 1, false, l.yearsSuffix, l.statBreakEven),
      (lifetime, 0, true, '', l.statTwentyYears),
      (co2, 0, false, ' kg', l.statCo2PerYear),
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
                      Text(l.simulationComplete, style: AppType.body(14, Colors.white, weight: FontWeight.w700, height: 1.2)),
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
                                      currency: stats[i].$3,
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
      title: context.l10n.costTitle,
      subtitle: context.l10n.costSubtitle,
      icon: Icons.compare_arrows_rounded,
      colors: _accent,
      child: Column(
        children: [
          _costBar(p, context.l10n.costGas, context.l10n.costGasDesc, gasCost, gasCost,
              const [AppColors.orange, AppColors.rose], false, 0),
          const SizedBox(height: 20),
          _costBar(p, context.l10n.costStdHp, context.l10n.costStdHpDesc, standardCost, gasCost,
              const [AppColors.sky, AppColors.blue], false, 1),
          const SizedBox(height: 20),
          _costBar(p, context.l10n.costSmartHp, context.l10n.costSmartHpDesc, smartCost, gasCost, _accent, true, 2),
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
                          child: Text(context.l10n.best, style: AppType.mono(9.5, Colors.white, weight: FontWeight.w800, spacing: 0.8)),
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
              currency: true,
              suffix: context.l10n.perYearShort,
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
    final l = context.l10n;
    final copLabel = cop >= 4.0 ? l.copExcellent : (cop >= 3.3 ? l.copGood : l.copAcceptable);
    final copColor = cop >= 4.0 ? AppColors.emerald : (cop >= 3.3 ? AppColors.amber : AppColors.sky);
    return GlassCard(
      title: l.specsTitle,
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
                label: l.copLabel(copLabel),
                centerText: context.fmt(cop, 1),
                size: 104,
              ),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bigFact(p, l.annualHeatDemand, heatKwh, 'kWh'),
                    const SizedBox(height: 14),
                    _bigFact(p, l.hpElectricity, elecKwh, l.kwhPerYear),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: p.border, height: 1),
          const SizedBox(height: 16),
          _specRow(p, l.annualHeatDemand, l.annualHeatDemandHint),
          _specRow(p, l.hpElectricity, l.hpElectricityHint),
          _specRow(p, l.copFull, l.copFullHint(context.fmt(cop, 1))),
          _specRow(
            p,
            l.insulationClass(switch (_insulationLevel) {
              'poor' => l.insulationPoor,
              'good' => l.insulationGood,
              _ => l.insulationAverage,
            }),
            l.insulationClassHint,
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
    final l = context.l10n;
    return GlassCard(
      title: l.envTitle,
      icon: Icons.eco_rounded,
      colors: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _envRow(p, Icons.co2_rounded, AppColors.emerald, l.kgValue(context.fmt(co2Saved)), l.co2PerYear),
          _envRow(p, Icons.park_rounded, AppColors.teal, l.treesApprox(context.fmt(trees)), l.treesHint),
          _envRow(p, Icons.directions_car_rounded, AppColors.sky, l.carsValue(context.fmt(co2Saved / 2300, 1)), l.carsHint),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Text(l.co2ReductionVsGas, style: AppType.body(12.5, p.muted, weight: FontWeight.w600, height: 1.3))),
              Text('${context.fmt(reductionPct)} %', style: AppType.display(18, AppColors.emerald)),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedBar(fraction: reductionPct / 100, colors: const [AppColors.teal, AppColors.emerald], height: 14),
          const SizedBox(height: 8),
          Text(l.co2LessThanGas(context.fmt(reductionPct)), style: AppType.body(12, AppColors.emerald, weight: FontWeight.w700, height: 1.3)),
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
    final l = context.l10n;
    final windows = [
      (Icons.nightlight_round, AppColors.indigo, '00:00 – 06:00', l.windowNightTitle, l.windowNightBody),
      (Icons.wb_sunny_rounded, AppColors.amber, '11:00 – 14:00', l.windowMiddayTitle, l.windowMiddayBody),
      (Icons.trending_down_rounded, AppColors.rose, '17:00 – 20:00', l.windowEveningTitle, l.windowEveningBody),
    ];

    return GlassCard(
      title: l.schedulingTitle(context.eur(extra), context.fmt(pct)),
      subtitle: l.schedulingSubtitle,
      icon: Icons.bolt_rounded,
      colors: const [AppColors.amber, AppColors.orange],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.typicalDay, style: AppType.eyebrow(p.faint)),
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
                    l.schedulingTip,
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
