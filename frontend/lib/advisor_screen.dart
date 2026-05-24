import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/custom_app_bar.dart';
import 'package:frontend/main.dart' show serverWarmup, kBackendUrl;
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

  void _updateEstimatedBill() {
    double multiplier = 1.5;
    if (_insulationLevel == 'poor') multiplier = 2.0;
    if (_insulationLevel == 'good') multiplier = 1.0;
    _gasBillController.text = (_houseSize * multiplier).toStringAsFixed(0);
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
        setState(() { _roiData = jsonDecode(response.body); _isLoading = false; });
      } else if (attempt < 3) {
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) _calculateROI(attempt: attempt + 1);
      } else {
        setState(() { _errorMessage = 'Server error ${response.statusCode}.'; _isLoading = false; });
      }
    } catch (_) {
      if (!mounted) return;
      if (attempt < 3) {
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) _calculateROI(attempt: attempt + 1);
      } else {
        setState(() { _errorMessage = 'Could not reach server after 3 attempts.'; _isLoading = false; });
      }
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
      appBar: CustomAppBar(themeNotifier: widget.themeNotifier, title: 'Heat Pump Advisor'),
      body: LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth > 860;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 60),
              children: [
                _buildHero(theme, isDark),
                const SizedBox(height: 20),
                _buildHowItWorks(theme, isDark, isWide),
                const SizedBox(height: 20),
                if (isWide)
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 3, child: _buildInputCard(theme, isDark)),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: _buildAssumptionsCard(theme, isDark)),
                  ])
                else ...[
                  _buildInputCard(theme, isDark),
                  const SizedBox(height: 20),
                  _buildAssumptionsCard(theme, isDark),
                ],
                if (_isLoading) ...[const SizedBox(height: 20), _buildLoadingCard(theme, isDark)],
                if (_errorMessage.isNotEmpty) ...[const SizedBox(height: 20), _buildErrorCard()],
                if (_roiData != null) ...[const SizedBox(height: 20), _buildResults(theme, isDark, isWide)],
              ],
            ),
          ),
        );
      }),
    );
  }

  // ── HERO ──────────────────────────────────────────────────────────────────

  Widget _buildHero(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF064E3B), const Color(0xFF065F46)]
              : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withAlpha(isDark ? 60 : 100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _pill(theme, Icons.bolt, 'Powered by live EPEX SPOT market data'),
                const SizedBox(height: 12),
                Text(
                  'Heat Pump ROI Advisor',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF064E3B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Replace your gas boiler with a smart heat pump and let EnergyTwin\'s AI schedule heating around cheap electricity windows. Enter your property details to see your exact savings.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white70 : const Color(0xFF065F46),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _heroBullet(theme, isDark, Icons.eco, '3–4× more efficient than gas'),
                    _heroBullet(theme, isDark, Icons.schedule, 'AI off-peak scheduling'),
                    _heroBullet(theme, isDark, Icons.co2, 'Up to 80% less CO₂'),
                    _heroBullet(theme, isDark, Icons.euro, '€15k install, BAFA subsidy eligible'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Icon(Icons.heat_pump, size: 72, color: theme.colorScheme.primary.withAlpha(isDark ? 200 : 160)),
        ],
      ),
    );
  }

  Widget _pill(ThemeData theme, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withAlpha(80)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: theme.colorScheme.primary),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
      ]),
    );
  }

  Widget _heroBullet(ThemeData theme, bool isDark, IconData icon, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: theme.colorScheme.primary),
      const SizedBox(width: 5),
      Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? Colors.white60 : const Color(0xFF065F46))),
    ]);
  }

  // ── HOW IT WORKS ──────────────────────────────────────────────────────────

  Widget _buildHowItWorks(ThemeData theme, bool isDark, bool isWide) {
    final steps = [
      (Icons.local_fire_department, Colors.orange.shade600, 'Your Gas Boiler Today',
          'Burns natural gas at ~85% efficiency. German gas costs ~€0.10/kWh. Heating a typical home produces 1,200–2,400 kg of CO₂ every year.'),
      (Icons.heat_pump, Colors.blue.shade500, 'The Heat Pump Upgrade',
          'Moves heat from outdoor air using a small amount of electricity. A COP of 3.5 means 1 kWh in → 3.5 kWh of heat out — far more efficient than any combustion boiler.'),
      (Icons.auto_awesome, theme.colorScheme.primary, 'EnergyTwin AI Scheduling',
          'Our AI monitors German EPEX SPOT prices and pre-heats your home during cheap windows (overnight wind surplus, midday solar dip) — saving an extra 40% on electricity.'),
    ];

    final cards = steps.map((s) => _stepCard(theme, isDark, s.$1, s.$2, s.$3, s.$4)).toList();

    return isWide
        ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: cards[0]), const SizedBox(width: 16),
            Expanded(child: cards[1]), const SizedBox(width: 16),
            Expanded(child: cards[2]),
          ])
        : Column(children: [cards[0], const SizedBox(height: 12), cards[1], const SizedBox(height: 12), cards[2]]);
  }

  Widget _stepCard(ThemeData theme, bool isDark, IconData icon, Color color, String title, String body) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(theme, isDark),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 12),
        Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(body, style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white60 : Colors.black54, height: 1.5)),
      ]),
    );
  }

  // ── INPUT CARD ────────────────────────────────────────────────────────────

  Widget _buildInputCard(ThemeData theme, bool isDark) {
    final copHints = {'poor': 'COP ≈ 2.8  ·  needs higher water temps', 'average': 'COP ≈ 3.5  ·  typical German installation', 'good': 'COP ≈ 4.2  ·  excellent with underfloor heating'};
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: _cardDecoration(theme, isDark),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.home_outlined, color: theme.colorScheme.primary, size: 22),
          const SizedBox(width: 10),
          Text('Your Property', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 4),
        Text(
          'The bill auto-estimates as you adjust size and insulation.',
          style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white38 : Colors.black38),
        ),
        const Divider(height: 28),

        // Gas bill
        TextField(
          controller: _gasBillController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Monthly Heating / Gas Bill',
            helperText: 'Your average monthly gas or district heating bill',
            prefixIcon: const Icon(Icons.euro_outlined),
            suffixText: '€ / month',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: isDark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(4),
          ),
        ),
        const SizedBox(height: 24),

        // Insulation
        DropdownButtonFormField<String>(
          initialValue: _insulationLevel,
          decoration: InputDecoration(
            labelText: 'Building Insulation',
            prefixIcon: const Icon(Icons.home_work_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: isDark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(4),
          ),
          items: [
            DropdownMenuItem(value: 'poor', child: Row(children: [Icon(Icons.thermostat, color: Colors.red.shade400, size: 18), const SizedBox(width: 8), const Text('Poor — pre-1980, minimal insulation')])),
            DropdownMenuItem(value: 'average', child: Row(children: [Icon(Icons.thermostat, color: Colors.orange.shade400, size: 18), const SizedBox(width: 8), const Text('Average — standard German construction')])),
            DropdownMenuItem(value: 'good', child: Row(children: [Icon(Icons.thermostat, color: Colors.green.shade400, size: 18), const SizedBox(width: 8), const Text('Good — modern, renovated, or passive')])),
          ],
          onChanged: (val) => setState(() { _insulationLevel = val!; _updateEstimatedBill(); }),
        ),
        const SizedBox(height: 8),
        // COP hint chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.info_outline, size: 13, color: theme.colorScheme.secondary),
            const SizedBox(width: 6),
            Text(copHints[_insulationLevel]!, style: TextStyle(fontSize: 12, color: theme.colorScheme.secondary, fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(height: 24),

        // House size slider
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Icon(Icons.square_foot_outlined, size: 18, color: theme.colorScheme.secondary),
            const SizedBox(width: 6),
            Text('House Size', style: theme.textTheme.titleSmall),
          ]),
          Text('${_houseSize.toInt()} m²',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
        ]),
        Slider(
          value: _houseSize,
          min: 50,
          max: 300,
          divisions: 25,
          activeColor: theme.colorScheme.secondary,
          onChanged: (val) => setState(() { _houseSize = val; _updateEstimatedBill(); }),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('50 m²', style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white38 : Colors.black38)),
          Text(_houseSizeLabel(), style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white54 : Colors.black54)),
          Text('300 m²', style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white38 : Colors.black38)),
        ]),
        const SizedBox(height: 28),

        // CTA button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _calculateROI,
            icon: _isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.calculate_outlined),
            label: Text(
              _isLoading ? _loadingMessage : 'Calculate My Savings',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
      ]),
    );
  }

  String _houseSizeLabel() {
    if (_houseSize < 80) return 'Small apartment';
    if (_houseSize < 120) return 'Medium apartment';
    if (_houseSize < 160) return 'Semi-detached';
    if (_houseSize < 220) return 'Detached house';
    return 'Large property';
  }

  // ── ASSUMPTIONS CARD ──────────────────────────────────────────────────────

  Widget _buildAssumptionsCard(ThemeData theme, bool isDark) {
    final rows = [
      ('Gas price', '€0.10 / kWh', 'Current German residential tariff'),
      ('Gas boiler efficiency', '85%', 'Typical old condensing boiler'),
      ('Standard electricity', '€0.30 / kWh', 'Average German household rate'),
      ('Smart rate (EnergyTwin)', '€0.18 / kWh', 'Off-peak EPEX SPOT average'),
      ('Installation cost', '€15,000', 'Net after BAFA subsidy (up to €18,750)'),
      ('Grid CO₂ intensity', '0.35 kg / kWh', 'German electricity mix, 2024'),
      ('Gas CO₂ intensity', '0.20 kg / kWh', 'Direct natural gas emissions'),
    ];
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(theme, isDark),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.rule_folder_outlined, color: theme.colorScheme.secondary, size: 20),
          const SizedBox(width: 8),
          Text('Model Assumptions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 4),
        Text('Transparent methodology — Germany 2024 data.',
            style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white38 : Colors.black38)),
        const Divider(height: 24),
        ...rows.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 5, height: 5, margin: const EdgeInsets.only(top: 6, right: 10),
                decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.secondary)),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(r.$1, style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white54 : Colors.black54)),
                Text(r.$2, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
              ]),
              Text(r.$3, style: theme.textTheme.labelSmall?.copyWith(color: isDark ? Colors.white30 : Colors.black38)),
            ])),
          ]),
        )),
      ]),
    );
  }

  // ── LOADING / ERROR ───────────────────────────────────────────────────────

  Widget _buildLoadingCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: _cardDecoration(theme, isDark),
      child: Column(children: [
        CircularProgressIndicator(color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(_loadingMessage, style: theme.textTheme.bodyMedium?.copyWith(color: isDark ? Colors.white54 : Colors.black54)),
        const SizedBox(height: 4),
        Text('Running Digital Twin simulation...', style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white30 : Colors.black38)),
      ]),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.redAccent.withAlpha(20), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.redAccent.withAlpha(60))),
      child: Row(children: [
        const Icon(Icons.error_outline, color: Colors.redAccent),
        const SizedBox(width: 12),
        Expanded(child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent))),
      ]),
    );
  }

  // ── RESULTS ───────────────────────────────────────────────────────────────

  Widget _buildResults(ThemeData theme, bool isDark, bool isWide) {
    final d = _roiData!;
    final gasCost    = (d['current_yearly_gas_cost_eur'] as num).toDouble();
    final smartCost  = (d['smart_heatpump_cost_eur']     as num).toDouble();
    final savings    = (d['ai_annual_savings_eur']        as num).toDouble();
    final roi        = (d['estimated_roi_years']          as num).toDouble();
    final heatKwh   = (d['heat_demand_kwh']              as num).toDouble();
    final elecKwh   = (d['hp_electricity_kwh']           as num).toDouble();
    final cop        = (d['cop_estimated']               as num).toDouble();
    final co2Saved   = (d['co2_saved_kg']               as num).toDouble();
    final standardCost = elecKwh * 0.30;

    return Column(children: [
      _buildSavingsHero(theme, isDark, savings, roi, savings * 20, co2Saved, isWide),
      const SizedBox(height: 16),
      _buildCostComparison(theme, isDark, gasCost, standardCost, smartCost),
      const SizedBox(height: 16),
      isWide
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _buildSystemSpecs(theme, isDark, cop, heatKwh, elecKwh)),
              const SizedBox(width: 16),
              Expanded(child: _buildEnvironmentCard(theme, isDark, co2Saved, heatKwh)),
            ])
          : Column(children: [
              _buildSystemSpecs(theme, isDark, cop, heatKwh, elecKwh),
              const SizedBox(height: 16),
              _buildEnvironmentCard(theme, isDark, co2Saved, heatKwh),
            ]),
      const SizedBox(height: 16),
      _buildSmartSchedulingCard(theme, isDark, standardCost, smartCost),
    ]);
  }

  // ── SAVINGS HERO ──────────────────────────────────────────────────────────

  Widget _buildSavingsHero(ThemeData theme, bool isDark, double savings, double roi, double lifetime, double co2, bool isWide) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? [const Color(0xFF064E3B), const Color(0xFF065F46)] : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withAlpha(80)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Text('Your Digital Twin Results', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF064E3B))),
        ]),
        const SizedBox(height: 20),
        isWide
            ? Row(children: [
                Expanded(child: _statBlock(theme, isDark, '€${savings.toStringAsFixed(0)}', 'Saved per year', theme.colorScheme.primary, true)),
                _vDivider(isDark),
                Expanded(child: _statBlock(theme, isDark, '${roi.toStringAsFixed(1)} yrs', 'Break-even payback', theme.colorScheme.secondary, false)),
                _vDivider(isDark),
                Expanded(child: _statBlock(theme, isDark, '€${lifetime.toStringAsFixed(0)}', 'Total over 20 years', Colors.teal.shade400, false)),
                _vDivider(isDark),
                Expanded(child: _statBlock(theme, isDark, '${co2.toStringAsFixed(0)} kg', 'CO₂ eliminated / yr', Colors.green.shade500, false)),
              ])
            : Column(children: [
                Row(children: [
                  Expanded(child: _statBlock(theme, isDark, '€${savings.toStringAsFixed(0)}', 'Saved / year', theme.colorScheme.primary, true)),
                  Expanded(child: _statBlock(theme, isDark, '${roi.toStringAsFixed(1)} yrs', 'Break-even', theme.colorScheme.secondary, false)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _statBlock(theme, isDark, '€${lifetime.toStringAsFixed(0)}', '20-year total', Colors.teal.shade400, false)),
                  Expanded(child: _statBlock(theme, isDark, '${co2.toStringAsFixed(0)} kg', 'CO₂ / yr saved', Colors.green.shade500, false)),
                ]),
              ]),
      ]),
    );
  }

  Widget _statBlock(ThemeData theme, bool isDark, String value, String label, Color color, bool large) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(children: [
        Text(value,
            textAlign: TextAlign.center,
            style: (large ? theme.textTheme.displaySmall : theme.textTheme.headlineMedium)
                ?.copyWith(fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white60 : Colors.black54)),
      ]),
    );
  }

  Widget _vDivider(bool isDark) => Container(
    width: 1, height: 64, margin: const EdgeInsets.symmetric(horizontal: 4),
    color: isDark ? Colors.white12 : Colors.black12,
  );

  // ── COST COMPARISON ───────────────────────────────────────────────────────

  Widget _buildCostComparison(ThemeData theme, bool isDark, double gasCost, double standardCost, double smartCost) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(theme, isDark),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.compare_arrows_rounded, color: theme.colorScheme.primary, size: 22),
          const SizedBox(width: 8),
          Text('Annual Cost Comparison', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 4),
        Text('Same warmth — three very different heating strategies.',
            style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white54 : Colors.black54)),
        const SizedBox(height: 20),
        _costBar(theme, isDark, 'Gas Boiler', 'Your current system — gas burned at 85% efficiency', gasCost, gasCost, Colors.orange.shade700, false),
        const SizedBox(height: 16),
        _costBar(theme, isDark, 'Standard Heat Pump', 'Off-the-shelf install, billed at flat €0.30/kWh tariff', standardCost, gasCost, Colors.blue.shade500, false),
        const SizedBox(height: 16),
        _costBar(theme, isDark, 'EnergyTwin Smart Heat Pump', 'AI shifts load to off-peak windows — avg €0.18/kWh', smartCost, gasCost, theme.colorScheme.primary, true),
      ]),
    );
  }

  Widget _costBar(ThemeData theme, bool isDark, String title, String subtitle, double cost, double maxCost, Color color, bool isBest) {
    final fraction = (cost / maxCost).clamp(0.0, 1.0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (isBest) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withAlpha(100))),
                child: Text('BEST', style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(child: Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
          ]),
          Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white38 : Colors.black38)),
        ])),
        const SizedBox(width: 12),
        Text('€${cost.toStringAsFixed(0)}/yr',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
      ]),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: fraction,
          minHeight: 10,
          backgroundColor: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(12),
          color: color,
        ),
      ),
    ]);
  }

  // ── SYSTEM SPECS ──────────────────────────────────────────────────────────

  Widget _buildSystemSpecs(ThemeData theme, bool isDark, double cop, double heatKwh, double elecKwh) {
    final copLabel = cop >= 4.0 ? 'Excellent' : (cop >= 3.3 ? 'Good' : 'Acceptable');
    final copColor = cop >= 4.0 ? Colors.green.shade600 : (cop >= 3.3 ? Colors.orange.shade600 : Colors.blue.shade500);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(theme, isDark),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.settings_suggest_outlined, color: theme.colorScheme.secondary, size: 20),
          const SizedBox(width: 8),
          Text('System Specifications', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ]),
        const Divider(height: 24),
        _specRow(theme, isDark, 'Annual Heat Demand', '${heatKwh.toStringAsFixed(0)} kWh',
            'Total thermal energy your home needs for heating — derived from gas consumption × 85% boiler efficiency'),
        _specRow(theme, isDark, 'Heat Pump Electricity', '${elecKwh.toStringAsFixed(0)} kWh / yr',
            'Electricity the heat pump consumes to deliver the heat demand above'),
        _specRow(theme, isDark, 'Coefficient of Performance', 'COP $cop  ·  $copLabel',
            '1 kWh electricity → ${cop}x kWh of heat. Depends on insulation quality and system design.',
            valueColor: copColor),
        _specRow(theme, isDark, 'Insulation Class', '${_insulationLevel[0].toUpperCase()}${_insulationLevel.substring(1)}',
            'Determines achievable COP and heat distribution type (radiators vs. underfloor heating)'),
      ]),
    );
  }

  Widget _specRow(ThemeData theme, bool isDark, String label, String value, String hint, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white54 : Colors.black54))),
          const SizedBox(width: 8),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: valueColor)),
        ]),
        const SizedBox(height: 2),
        Text(hint, style: theme.textTheme.labelSmall?.copyWith(color: isDark ? Colors.white30 : Colors.black38, height: 1.4)),
      ]),
    );
  }

  // ── ENVIRONMENT ───────────────────────────────────────────────────────────

  Widget _buildEnvironmentCard(ThemeData theme, bool isDark, double co2Saved, double heatKwh) {
    final trees = (co2Saved / 21).toInt();
    final gasCo2 = (heatKwh / 0.85) * 0.20;
    final reductionPct = gasCo2 > 0 ? ((co2Saved / gasCo2) * 100).clamp(0, 100).toInt() : 0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(theme, isDark),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.eco_outlined, color: Colors.green.shade500, size: 20),
          const SizedBox(width: 8),
          Text('Environmental Impact', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ]),
        const Divider(height: 24),
        _envRow(theme, isDark, Icons.co2, Colors.green.shade600, '${co2Saved.toStringAsFixed(0)} kg', 'CO₂ eliminated per year'),
        _envRow(theme, isDark, Icons.park_outlined, Colors.teal.shade500, '~$trees trees', 'Equivalent annual CO₂ absorption'),
        _envRow(theme, isDark, Icons.directions_car_outlined, Colors.blue.shade500, '${(co2Saved / 2300).toStringAsFixed(1)} cars', 'Taken off the road equivalent'),
        const SizedBox(height: 16),
        Text('CO₂ reduction vs. your current gas boiler',
            style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white54 : Colors.black54)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: reductionPct / 100,
            minHeight: 14,
            backgroundColor: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(12),
            color: Colors.green.shade500,
          ),
        ),
        const SizedBox(height: 6),
        Text('$reductionPct% less CO₂ than gas',
            style: theme.textTheme.labelSmall?.copyWith(color: Colors.green.shade500, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _envRow(ThemeData theme, bool isDark, IconData icon, Color color, String value, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white54 : Colors.black54)),
        ]),
      ]),
    );
  }

  // ── SMART SCHEDULING ──────────────────────────────────────────────────────

  Widget _buildSmartSchedulingCard(ThemeData theme, bool isDark, double standardCost, double smartCost) {
    final extra = (standardCost - smartCost).abs();
    final pct = standardCost > 0 ? ((extra / standardCost) * 100).toInt() : 0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(theme, isDark),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.bolt, color: Colors.amber.shade600, size: 22),
          const SizedBox(width: 8),
          Expanded(child: Text(
            'How EnergyTwin Saves an Extra €${extra.toStringAsFixed(0)}/yr ($pct%)',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          )),
        ]),
        const SizedBox(height: 4),
        Text(
          'The AI shifts your heat pump runtime to the three cheapest daily windows on the German EPEX SPOT market — the same prices shown on your Prices screen.',
          style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white54 : Colors.black54, height: 1.5),
        ),
        const Divider(height: 24),
        _scheduleRow(theme, isDark, Icons.nightlight_round, Colors.indigo.shade400, '00:00 – 06:00  ·  Overnight Wind Valley',
            'Wind turbines run all night but demand is minimal. EPEX prices fall to 5–15 ct/kWh. EnergyTwin pre-charges your home\'s thermal mass silently while you sleep.'),
        _scheduleRow(theme, isDark, Icons.wb_sunny, Colors.amber.shade600, '11:00 – 14:00  ·  Solar Surplus Midday',
            'Germany\'s solar fleet peaks and prices can hit 0 or even go negative. EnergyTwin maximises heat pump runtime in this window — essentially free heat.'),
        _scheduleRow(theme, isDark, Icons.trending_down, Colors.red.shade400, '17:00 – 20:00  ·  Avoid Evening Peak',
            'Evening demand spikes push EPEX to 30–60 ct/kWh. EnergyTwin pauses the heat pump. Stored heat keeps your home comfortable without paying peak rates.'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.primary.withAlpha(40)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.lightbulb_outline, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'A well-insulated home retains heat for 3–6 hours, making schedule shifting painless and invisible to occupants.',
              style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white70 : Colors.black87, height: 1.4),
            )),
          ]),
        ),
      ]),
    );
  }

  Widget _scheduleRow(ThemeData theme, bool isDark, IconData icon, Color color, String timeLabel, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(timeLabel, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 3),
          Text(description, style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white60 : Colors.black54, height: 1.4)),
        ])),
      ]),
    );
  }

  // ── SHARED HELPERS ────────────────────────────────────────────────────────

  BoxDecoration _cardDecoration(ThemeData theme, bool isDark) => BoxDecoration(
    color: theme.colorScheme.surface,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
    boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 25 : 8), blurRadius: 14, offset: const Offset(0, 5))],
  );
}
