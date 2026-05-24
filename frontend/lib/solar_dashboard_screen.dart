import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend/custom_app_bar.dart';
import 'package:frontend/main.dart' show serverWarmup, kBackendUrl;

class SolarDashboardScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;
  const SolarDashboardScreen({super.key, required this.themeNotifier});

  @override
  State<SolarDashboardScreen> createState() => _SolarDashboardScreenState();
}

class _SolarDashboardScreenState extends State<SolarDashboardScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _billController = TextEditingController(text: '150');
  final TextEditingController _householdController = TextEditingController(text: '4');
  final TextEditingController _gridPriceController = TextEditingController(text: '35.0');
  String _energyRating = 'D';

  int _currentStep = 0;
  bool _isLoading = false;
  String _errorMessage = '';

  String? _rawImageBase64;
  double? _lat, _lon;
  final List<Offset> _roofPoints = [];

  Map<String, dynamic>? _analysisData;
  String _loadingMessage = 'Connecting...';

  @override
  void dispose() {
    _addressController.dispose();
    _billController.dispose();
    _householdController.dispose();
    _gridPriceController.dispose();
    super.dispose();
  }

  void _startLoadingMessages() {
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted && _isLoading) setState(() => _loadingMessage = 'Server is warming up...');
    });
    Future.delayed(const Duration(seconds: 35), () {
      if (mounted && _isLoading) setState(() => _loadingMessage = 'Almost there...');
    });
  }

  Future<void> _fetchRoofImage({int attempt = 1}) async {
    if (_addressController.text.isEmpty) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _loadingMessage = attempt == 1 ? 'Finding your roof...' : 'Retrying... (attempt $attempt of 3)';
    });
    _startLoadingMessages();
    await serverWarmup;
    if (!mounted) return;
    try {
      final response = await http
          .post(Uri.parse('$kBackendUrl/get_roof'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'address': _addressController.text}))
          .timeout(const Duration(seconds: 30));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _rawImageBase64 = data['image_base64'];
          _lat = data['lat'];
          _lon = data['lon'];
          _roofPoints.clear();
          _currentStep = 1;
          _isLoading = false;
        });
      } else if (attempt < 3) {
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) _fetchRoofImage(attempt: attempt + 1);
      } else {
        setState(() { _errorMessage = 'Could not find address.'; _isLoading = false; });
      }
    } catch (_) {
      if (!mounted) return;
      if (attempt < 3) {
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) _fetchRoofImage(attempt: attempt + 1);
      } else {
        setState(() { _errorMessage = 'Server error. Please try again.'; _isLoading = false; });
      }
    }
  }

  Future<void> _runSimulation({int attempt = 1}) async {
    if (_roofPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tap at least 3 corners on the roof!')));
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _loadingMessage = attempt == 1 ? 'Running solar simulation...' : 'Retrying... (attempt $attempt of 3)';
    });
    _startLoadingMessages();
    await serverWarmup;
    if (!mounted) return;
    try {
      final response = await http
          .post(Uri.parse('$kBackendUrl/simulate_solar'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'lat': _lat, 'lon': _lon,
                'monthly_bill_eur': double.tryParse(_billController.text) ?? 150.0,
                'energy_rating': _energyRating,
                'household_size': int.tryParse(_householdController.text) ?? 4,
                'grid_price_ct_kwh': double.tryParse(_gridPriceController.text) ?? 35.0,
                'roof_points': _roofPoints.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
              }))
          .timeout(const Duration(seconds: 60));
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() { _analysisData = jsonDecode(response.body); _currentStep = 2; _isLoading = false; });
      } else if (attempt < 3) {
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) _runSimulation(attempt: attempt + 1);
      } else {
        setState(() { _errorMessage = 'Simulation failed. Please try again.'; _isLoading = false; });
      }
    } catch (_) {
      if (!mounted) return;
      if (attempt < 3) {
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) _runSimulation(attempt: attempt + 1);
      } else {
        setState(() { _errorMessage = 'Failed to connect to backend.'; _isLoading = false; });
      }
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: CustomAppBar(themeNotifier: widget.themeNotifier, title: 'Solar AI Analyzer'),
      body: _isLoading
          ? _buildLoadingView(theme, isDark)
          : _errorMessage.isNotEmpty
              ? _buildErrorView(theme)
              : _buildCurrentStep(theme, isDark),
    );
  }

  Widget _buildLoadingView(ThemeData theme, bool isDark) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      CircularProgressIndicator(color: theme.colorScheme.primary),
      const SizedBox(height: 20),
      Text(_loadingMessage, style: theme.textTheme.bodyMedium?.copyWith(color: isDark ? Colors.white54 : Colors.black54)),
      const SizedBox(height: 4),
      Text(_currentStep == 0 ? 'Fetching satellite image...' : 'Running solar analysis...',
          style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white30 : Colors.black38)),
    ]));
  }

  Widget _buildErrorView(ThemeData theme) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.error_outline, size: 52, color: Colors.redAccent.withAlpha(180)),
      const SizedBox(height: 16),
      Text(_errorMessage, style: const TextStyle(color: Colors.redAccent, fontSize: 15), textAlign: TextAlign.center),
      const SizedBox(height: 20),
      OutlinedButton.icon(
        onPressed: () => setState(() { _errorMessage = ''; _currentStep = 0; }),
        icon: const Icon(Icons.arrow_back),
        label: const Text('Start Over'),
      ),
    ]));
  }

  Widget _buildCurrentStep(ThemeData theme, bool isDark) {
    if (_currentStep == 0) return _buildFormStep(theme, isDark);
    if (_currentStep == 1) return _buildRoofStep(theme, isDark);
    return _buildDashboardStep(theme, isDark);
  }

  // ── STEP 0: FORM ──────────────────────────────────────────────────────────

  Widget _buildFormStep(ThemeData theme, bool isDark) {
    final amberDark = Colors.amber.shade600;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 60),
      children: [
        Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(children: [
            // Hero banner
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF451A03), const Color(0xFF78350F)]
                      : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: amberDark.withAlpha(isDark ? 80 : 120)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _pill(Icons.wb_sunny, 'Solar irradiance via Open-Meteo · Satellite imagery', amberDark),
                  const SizedBox(height: 12),
                  Text('Solar AI Roof Analyzer',
                      style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF78350F))),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your property address and energy details. We fetch a satellite image, you trace your roof outline, and our AI calculates your exact solar potential and financial return.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.white70 : const Color(0xFF92400E), height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Wrap(spacing: 16, runSpacing: 8, children: [
                    _heroBullet(theme, isDark, Icons.wb_sunny, '3-step analysis', amberDark),
                    _heroBullet(theme, isDark, Icons.euro, 'ROI & payback calc', amberDark),
                    _heroBullet(theme, isDark, Icons.eco, 'CO₂ impact report', amberDark),
                  ]),
                ])),
                const SizedBox(width: 20),
                Icon(Icons.solar_power, size: 72, color: amberDark.withAlpha(isDark ? 200 : 160)),
              ]),
            ),
            const SizedBox(height: 16),

            // Step indicator
            _buildStepIndicator(theme, isDark, 0),
            const SizedBox(height: 16),

            // Form card
            Container(
              padding: const EdgeInsets.all(28),
              decoration: _cardDeco(theme, isDark),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.location_on_outlined, color: theme.colorScheme.primary, size: 22),
                  const SizedBox(width: 10),
                  Text('Property Details', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 4),
                Text('Enter your address to fetch a satellite image of your roof.',
                    style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white38 : Colors.black38)),
                const Divider(height: 28),

                // Address
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Property Address',
                    helperText: 'e.g. Adenauerallee 1, 53113 Bonn',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: isDark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(4),
                  ),
                ),
                const SizedBox(height: 20),

                // Energy rating + grid price
                LayoutBuilder(builder: (ctx, c) {
                  final row = c.maxWidth > 560;
                  final fields = [
                    DropdownButtonFormField<String>(
                      initialValue: _energyRating,
                      decoration: InputDecoration(
                        labelText: 'Energy Efficiency Class',
                        helperText: 'EU energy label A (best) – G (worst)',
                        prefixIcon: const Icon(Icons.home_work_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: isDark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(4),
                      ),
                      items: [
                        ('A', Colors.green.shade600), ('B', Colors.lightGreen.shade600),
                        ('C', Colors.lime.shade700), ('D', Colors.yellow.shade700),
                        ('E', Colors.orange.shade600), ('F', Colors.deepOrange.shade600), ('G', Colors.red.shade700),
                      ].map((r) => DropdownMenuItem(value: r.$1, child: Row(children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: r.$2, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text('Class ${r.$1}'),
                      ]))).toList(),
                      onChanged: (v) => setState(() => _energyRating = v!),
                    ),
                    TextField(
                      controller: _gridPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Grid Electricity Price',
                        helperText: 'Your current tariff in ct/kWh',
                        prefixIcon: const Icon(Icons.bolt_outlined),
                        suffixText: 'ct/kWh',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: isDark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(4),
                      ),
                    ),
                  ];
                  return row
                      ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(child: fields[0]), const SizedBox(width: 16), Expanded(child: fields[1]),
                        ])
                      : Column(children: [fields[0], const SizedBox(height: 16), fields[1]]);
                }),
                const SizedBox(height: 16),

                // Monthly bill + household
                LayoutBuilder(builder: (ctx, c) {
                  final row = c.maxWidth > 560;
                  final fields = [
                    TextField(
                      controller: _billController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Monthly Electricity Bill',
                        helperText: 'Average monthly bill in euros',
                        prefixIcon: const Icon(Icons.euro_outlined),
                        suffixText: '€/mo',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: isDark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(4),
                      ),
                    ),
                    TextField(
                      controller: _householdController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Household Size',
                        helperText: 'Number of people living there',
                        prefixIcon: const Icon(Icons.people_outline),
                        suffixText: 'people',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: isDark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(4),
                      ),
                    ),
                  ];
                  return row
                      ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(child: fields[0]), const SizedBox(width: 16), Expanded(child: fields[1]),
                        ])
                      : Column(children: [fields[0], const SizedBox(height: 16), fields[1]]);
                }),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity, height: 52,
                  child: FilledButton.icon(
                    onPressed: _fetchRoofImage,
                    icon: const Icon(Icons.satellite_alt),
                    label: const Text('Fetch Satellite Image', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  ),
                ),
              ]),
            ),
          ]),
        )),
      ],
    );
  }

  // ── STEP 1: ROOF SELECTION ────────────────────────────────────────────────

  Widget _buildRoofStep(ThemeData theme, bool isDark) {
    return Column(children: [
      _buildStepIndicatorBar(theme, isDark, 1),
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDeco(theme, isDark),
          child: Row(children: [
            Icon(Icons.touch_app_outlined, color: theme.colorScheme.secondary, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Trace Your Roof', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              Text('Tap the corners of your roof polygon in order — at least 3 points.',
                  style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white54 : Colors.black54)),
            ])),
            if (_roofPoints.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.primary.withAlpha(80)),
                ),
                child: Text('${_roofPoints.length} pts', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
          ]),
        ),
      ),
      Expanded(child: Center(child: LayoutBuilder(builder: (ctx, c) {
        final size = math.min(c.maxWidth - 48, math.min(c.maxHeight - 120.0, 560.0));
        return Padding(
          padding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: size, height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.primary, width: 2),
              ),
              child: GestureDetector(
                onTapDown: (d) => setState(() => _roofPoints.add(d.localPosition)),
                child: Stack(children: [
                  Image.memory(base64Decode(_rawImageBase64!), width: size, height: size, fit: BoxFit.cover),
                  CustomPaint(painter: PolygonPainter(_roofPoints), size: Size(size, size)),
                  if (_roofPoints.isEmpty)
                    Center(child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(color: Colors.black.withAlpha(140), borderRadius: BorderRadius.circular(10)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: const [
                        Icon(Icons.touch_app, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Tap corners of your roof', style: TextStyle(color: Colors.white, fontSize: 13)),
                      ]),
                    )),
                ]),
              ),
            ),
          ),
        );
      }))),
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          OutlinedButton.icon(
            onPressed: () => setState(() => _roofPoints.clear()),
            icon: const Icon(Icons.undo, size: 18),
            label: Text('Clear (${_roofPoints.length})'),
          ),
          const SizedBox(width: 24),
          FilledButton.icon(
            onPressed: _roofPoints.length >= 3 ? _runSimulation : null,
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('Run AI Analysis', style: TextStyle(fontWeight: FontWeight.bold)),
            style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ]),
      ),
    ]);
  }

  // ── STEP 2: DASHBOARD ─────────────────────────────────────────────────────

  Widget _buildDashboardStep(ThemeData theme, bool isDark) {
    final fin    = (_analysisData!['financials']  as Map?)?.cast<String, dynamic>() ?? {};
    final strat  = (_analysisData!['strategy']    as Map?)?.cast<String, dynamic>() ?? {};
    final env    = (_analysisData!['environment'] as Map?)?.cast<String, dynamic>() ?? {};
    final imgB64 = _analysisData!['analyzed_image_base64'] as String?;
    final roofArea    = (_analysisData!['roof_area']    as num?)?.toDouble() ?? 0;
    final numPanels   = (_analysisData!['num_panels']   as num?)?.toInt()    ?? 0;
    final capacityKwp = (_analysisData!['capacity_kwp'] as num?)?.toDouble() ?? 0;
    final advice      = List<String>.from(_analysisData!['strategic_advice'] ?? []);
    final profit20    = (fin['twenty_year_profit'] as num?)?.toDouble() ?? 0;
    final annualSav   = (fin['annual_savings']     as num?)?.toDouble() ?? 0;
    final monthlyRel  = (fin['monthly_relief']     as num?)?.toDouble() ?? 0;
    final payback     = (fin['payback']            as num?)?.toDouble() ?? 0;
    final autarky     = (strat['autarky_rate']     as num?)?.toDouble() ?? 0;
    final locScore    = (strat['location_score']   as num?)?.toDouble() ?? 0;
    final batImpact   = (strat['battery_impact']   as num?)?.toDouble() ?? 0;
    final co2Saved    = (env['co2_saved']          as num?)?.toDouble() ?? 0;
    final treeCount   = (env['tree_count']         as num?)?.toInt()    ?? 0;
    final ecoGrade    = env['eco_grade']           as String?           ?? 'N/A';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 60),
      child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: LayoutBuilder(builder: (ctx, c) {
          final isWide = c.maxWidth > 860;
          return Column(children: [
            _buildStepIndicatorBar(theme, isDark, 2),
            const SizedBox(height: 20),

            // 4 KPI cards
            isWide
                ? Row(children: [
                    Expanded(child: _kpiCard(theme, isDark, Icons.solar_power, Colors.amber.shade600, '$numPanels Panels', '${capacityKwp.toStringAsFixed(1)} kWp installed capacity')),
                    const SizedBox(width: 16),
                    Expanded(child: _kpiCard(theme, isDark, Icons.euro_outlined, theme.colorScheme.primary, '€${annualSav.toStringAsFixed(0)}', 'Annual electricity savings')),
                    const SizedBox(width: 16),
                    Expanded(child: _kpiCard(theme, isDark, Icons.replay, theme.colorScheme.secondary, '${payback.toStringAsFixed(1)} yrs', 'Investment payback period')),
                    const SizedBox(width: 16),
                    Expanded(child: _kpiCard(theme, isDark, Icons.eco_outlined, Colors.green.shade600, '${co2Saved.toStringAsFixed(1)} t', 'CO₂ saved per year')),
                  ])
                : Column(children: [
                    Row(children: [
                      Expanded(child: _kpiCard(theme, isDark, Icons.solar_power, Colors.amber.shade600, '$numPanels Panels', '${capacityKwp.toStringAsFixed(1)} kWp')),
                      const SizedBox(width: 12),
                      Expanded(child: _kpiCard(theme, isDark, Icons.euro_outlined, theme.colorScheme.primary, '€${annualSav.toStringAsFixed(0)}', 'Annual savings')),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _kpiCard(theme, isDark, Icons.replay, theme.colorScheme.secondary, '${payback.toStringAsFixed(1)} yrs', 'Payback period')),
                      const SizedBox(width: 12),
                      Expanded(child: _kpiCard(theme, isDark, Icons.eco_outlined, Colors.green.shade600, '${co2Saved.toStringAsFixed(1)} t', 'CO₂ / year')),
                    ]),
                  ]),
            const SizedBox(height: 20),

            // Satellite image + advisory
            isWide
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 2, child: _buildImageCard(theme, isDark, imgB64, roofArea, numPanels)),
                    const SizedBox(width: 20),
                    Expanded(flex: 3, child: _buildAdvisoryCard(theme, isDark, advice)),
                  ])
                : Column(children: [
                    _buildImageCard(theme, isDark, imgB64, roofArea, numPanels),
                    const SizedBox(height: 16),
                    _buildAdvisoryCard(theme, isDark, advice),
                  ]),
            const SizedBox(height: 20),

            // Three metric cards
            isWide
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _buildFinancialCard(theme, isDark, profit20, annualSav, monthlyRel, payback)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildSystemCard(theme, isDark, autarky, locScore, batImpact, isWide)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildEnvironmentCard(theme, isDark, co2Saved, treeCount, ecoGrade)),
                  ])
                : Column(children: [
                    _buildFinancialCard(theme, isDark, profit20, annualSav, monthlyRel, payback),
                    const SizedBox(height: 16),
                    _buildSystemCard(theme, isDark, autarky, locScore, batImpact, false),
                    const SizedBox(height: 16),
                    _buildEnvironmentCard(theme, isDark, co2Saved, treeCount, ecoGrade),
                  ]),
            const SizedBox(height: 24),

            Center(child: TextButton.icon(
              onPressed: () => setState(() {
                _currentStep = 0; _analysisData = null; _rawImageBase64 = null; _roofPoints.clear();
              }),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Analyze Another Property'),
            )),
          ]);
        }),
      )),
    );
  }

  Widget _buildImageCard(ThemeData theme, bool isDark, String? imgB64, double roofArea, int numPanels) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDeco(theme, isDark),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.satellite_alt_outlined, color: theme.colorScheme.secondary, size: 20),
          const SizedBox(width: 8),
          Text('Analyzed Roof', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 4),
        Text('AI panel placement overlay — $numPanels panels on ${roofArea.toStringAsFixed(0)} m²',
            style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white38 : Colors.black38)),
        const SizedBox(height: 16),
        if (imgB64 != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(base64Decode(imgB64), fit: BoxFit.contain, width: double.infinity),
          ),
        const SizedBox(height: 12),
        Center(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.amber.shade600.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.shade600.withAlpha(80)),
          ),
          child: Text('Roof Area: ${roofArea.toStringAsFixed(0)} m²',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade700)),
        )),
      ]),
    );
  }

  Widget _buildAdvisoryCard(ThemeData theme, bool isDark, List<String> advice) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDeco(theme, isDark),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.auto_awesome, color: Colors.amber.shade600, size: 20),
          const SizedBox(width: 8),
          Text('AI Strategic Advisory', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 4),
        Text('Personalized recommendations from EnergyTwin\'s solar analysis engine',
            style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white38 : Colors.black38)),
        const Divider(height: 24),
        ...advice.map((tip) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: Colors.amber.shade600.withAlpha(25), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.lightbulb_outline, color: Colors.amber.shade600, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(tip, style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : Colors.black87, height: 1.5))),
          ]),
        )),
      ]),
    );
  }

  Widget _buildFinancialCard(ThemeData theme, bool isDark, double profit20, double annualSav, double monthlyRel, double payback) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDeco(theme, isDark),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.account_balance_wallet_outlined, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Text('Financial Overview', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ]),
        const Divider(height: 24),
        _metricRow(theme, isDark, '20-Year Net Profit', '€${profit20.toStringAsFixed(0)}', 'Total earnings after installation cost', theme.colorScheme.primary),
        _metricRow(theme, isDark, 'Annual Savings', '€${annualSav.toStringAsFixed(0)}', 'Yearly reduction in electricity bill', Colors.green.shade600),
        _metricRow(theme, isDark, 'Monthly Relief', '€${monthlyRel.toStringAsFixed(0)}', 'Average monthly bill reduction', theme.colorScheme.secondary),
        _metricRow(theme, isDark, 'Payback Period', '${payback.toStringAsFixed(1)} years', 'Time to recoup installation investment', Colors.orange.shade600),
      ]),
    );
  }

  Widget _buildSystemCard(ThemeData theme, bool isDark, double autarky, double locScore, double batImpact, bool isWide) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDeco(theme, isDark),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.donut_large_outlined, color: theme.colorScheme.secondary, size: 20),
          const SizedBox(width: 8),
          Text('System Metrics', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ]),
        const Divider(height: 24),
        isWide
            ? Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _donutMeter(theme, isDark, 'Independence', autarky, Colors.amber.shade600),
                _donutMeter(theme, isDark, 'Sun Score', locScore, Colors.blue.shade500),
                _donutMeter(theme, isDark, 'Battery Value', batImpact, Colors.purple.shade500),
              ])
            : Column(children: [
                _donutMeter(theme, isDark, 'Independence', autarky, Colors.amber.shade600),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _donutMeter(theme, isDark, 'Sun Score', locScore, Colors.blue.shade500),
                  _donutMeter(theme, isDark, 'Battery Value', batImpact, Colors.purple.shade500),
                ]),
              ]),
        const SizedBox(height: 16),
        Text('Independence: % of electricity self-produced. Sun Score: location quality. Battery Value: estimated benefit of adding a home battery.',
            style: theme.textTheme.labelSmall?.copyWith(color: isDark ? Colors.white30 : Colors.black38, height: 1.4)),
      ]),
    );
  }

  Widget _buildEnvironmentCard(ThemeData theme, bool isDark, double co2Saved, int treeCount, String ecoGrade) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDeco(theme, isDark),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.eco_outlined, color: Colors.green.shade600, size: 20),
          const SizedBox(width: 8),
          Text('Environmental Impact', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ]),
        const Divider(height: 24),
        _metricRow(theme, isDark, 'CO₂ Eliminated', '${co2Saved.toStringAsFixed(1)} t/yr', 'Annual carbon emissions prevented', Colors.green.shade600),
        _metricRow(theme, isDark, 'Tree Equivalent', '~$treeCount trees/yr', 'Annual CO₂ absorption equivalent', Colors.teal.shade500),
        _metricRow(theme, isDark, 'EnergyTwin Eco Grade', ecoGrade, 'Sustainability rating for this system', Colors.greenAccent.shade700),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade600.withAlpha(15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.green.shade600.withAlpha(40)),
          ),
          child: Row(children: [
            Icon(Icons.verified_outlined, color: Colors.green.shade600, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text('BAFA-eligible system — qualifies for German state subsidy',
                style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white70 : Colors.black87, height: 1.3))),
          ]),
        ),
      ]),
    );
  }

  // ── SHARED WIDGETS ────────────────────────────────────────────────────────

  Widget _buildStepIndicator(ThemeData theme, bool isDark, int active) {
    final steps = ['Enter Details', 'Trace Roof', 'View Results'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: _cardDeco(theme, isDark),
      child: Row(children: [
        for (int i = 0; i < steps.length; i++) ...[
          if (i > 0) Expanded(child: Container(height: 2, color: i <= active ? theme.colorScheme.primary.withAlpha(80) : (isDark ? Colors.white12 : Colors.black12))),
          _stepDot(theme, isDark, i, active, steps[i]),
        ],
      ]),
    );
  }

  Widget _buildStepIndicatorBar(ThemeData theme, bool isDark, int active) {
    final steps = ['Enter Details', 'Trace Roof', 'View Results'];
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(children: [
        for (int i = 0; i < steps.length; i++) ...[
          if (i > 0) Expanded(child: Container(height: 2, color: i <= active ? theme.colorScheme.primary.withAlpha(80) : (isDark ? Colors.white12 : Colors.black12))),
          _stepDot(theme, isDark, i, active, steps[i]),
        ],
      ]),
    );
  }

  Widget _stepDot(ThemeData theme, bool isDark, int step, int active, String label) {
    final done = step < active;
    final curr = step == active;
    final color = done || curr ? theme.colorScheme.primary : (isDark ? Colors.white24 : Colors.black26);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done || curr ? theme.colorScheme.primary : Colors.transparent,
          border: Border.all(color: color, width: 2),
        ),
        child: Center(child: done
            ? const Icon(Icons.check, color: Colors.white, size: 14)
            : Text('${step + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: curr ? Colors.white : color))),
      ),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 10, fontWeight: curr ? FontWeight.bold : FontWeight.normal,
          color: curr ? theme.colorScheme.primary : (isDark ? Colors.white38 : Colors.black38))),
    ]);
  }

  Widget _kpiCard(ThemeData theme, bool isDark, IconData icon, Color color, String value, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDeco(theme, isDark),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(subtitle, style: theme.textTheme.titleSmall?.copyWith(color: isDark ? Colors.white54 : Colors.black54))),
          Icon(icon, color: color, size: 22),
        ]),
        const SizedBox(height: 12),
        Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }

  Widget _metricRow(ThemeData theme, bool isDark, String label, String value, String hint, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.white54 : Colors.black54))),
          const SizedBox(width: 8),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
        ]),
        const SizedBox(height: 2),
        Text(hint, style: theme.textTheme.labelSmall?.copyWith(color: isDark ? Colors.white30 : Colors.black38, height: 1.3)),
      ]),
    );
  }

  Widget _donutMeter(ThemeData theme, bool isDark, String label, double pct, Color color) {
    final clamped = pct.clamp(0.0, 100.0);
    return Column(children: [
      SizedBox(width: 90, height: 90,
        child: Stack(children: [
          PieChart(PieChartData(
            sectionsSpace: 0,
            centerSpaceRadius: 30,
            sections: [
              PieChartSectionData(value: clamped, color: color, radius: 14, showTitle: false),
              PieChartSectionData(value: 100 - clamped, color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(15), radius: 14, showTitle: false),
            ],
          )),
          Center(child: Text('${clamped.toInt()}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color))),
        ]),
      ),
      const SizedBox(height: 6),
      Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _pill(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  Widget _heroBullet(ThemeData theme, bool isDark, IconData icon, String text, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 5),
      Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? Colors.white60 : const Color(0xFF92400E))),
    ]);
  }

  BoxDecoration _cardDeco(ThemeData theme, bool isDark) => BoxDecoration(
    color: theme.colorScheme.surface,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
    boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 25 : 8), blurRadius: 14, offset: const Offset(0, 5))],
  );
}

// ── POLYGON PAINTER ───────────────────────────────────────────────────────────

class PolygonPainter extends CustomPainter {
  final List<Offset> points;
  PolygonPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.redAccent..strokeWidth = 3..style = PaintingStyle.stroke;
    final dotPaint = Paint()..color = Colors.yellowAccent..style = PaintingStyle.fill;
    if (points.isNotEmpty) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      if (points.length > 2) path.close();
      canvas.drawPath(path, paint);
      for (var p in points) {
        canvas.drawCircle(p, 5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
