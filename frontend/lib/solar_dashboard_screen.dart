import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:frontend/custom_app_bar.dart';
import 'package:frontend/main.dart' show serverWarmup, kBackendUrl;
import 'package:frontend/ui/kit.dart';
import 'package:http/http.dart' as http;

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

  // Nullable so hot reload on an open screen can't leave them undefined.
  Size? _imageSize; // pixel size of the satellite image
  double? _canvasSize; // on-screen size the roof was traced at
  String? _fetchedAddress;

  // Decoding base64 on every tap would re-decode the image and make it flicker.
  // Nullable (not initialised) so hot reload on an open screen can't leave it undefined.
  Map<String, Uint8List>? _decoded;
  Uint8List _bytes(String b64) => (_decoded ??= {}).putIfAbsent(b64, () => base64Decode(b64));

  static const _accent = [AppColors.amber, AppColors.orange];
  static const _steps = ['Enter details', 'Trace roof', 'View results'];

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
              headers: {'Content-Type': 'application/json'}, body: jsonEncode({'address': _addressController.text}))
          .timeout(const Duration(seconds: 30));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final b64 = data['image_base64'] as String;
        final decoded = await decodeImageFromList(_bytes(b64));
        final imageSize = Size(decoded.width.toDouble(), decoded.height.toDouble());
        decoded.dispose();
        if (!mounted) return;
        setState(() {
          _rawImageBase64 = b64;
          _imageSize = imageSize;
          _fetchedAddress = _addressController.text.trim();
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
        setState(() {
          _errorMessage = 'Could not find address.';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      if (attempt < 3) {
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) _fetchRoofImage(attempt: attempt + 1);
      } else {
        setState(() {
          _errorMessage = 'Server error. Please try again.';
          _isLoading = false;
        });
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
    final pxPoints = _roofPoints.map(_toImagePx).toList();
    try {
      final response = await http
          .post(Uri.parse('$kBackendUrl/simulate_solar'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'address': _fetchedAddress ?? _addressController.text.trim(),
                'lat': _lat,
                'lon': _lon,
                'monthly_bill_eur': double.tryParse(_billController.text) ?? 150.0,
                'energy_rating': _energyRating,
                'household_size': int.tryParse(_householdController.text) ?? 4,
                'grid_price_ct_kwh': double.tryParse(_gridPriceController.text) ?? 35.0,
                // Panels are drawn on this exact image, using outline points in its pixel space.
                'image_base64': _rawImageBase64,
                'roof_points_px': pxPoints.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
                // Older backends double these values, so halve them to land on the same pixels.
                'roof_points': pxPoints.map((p) => {'x': p.dx / 2, 'y': p.dy / 2}).toList(),
              }))
          .timeout(const Duration(seconds: 60));
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          _analysisData = jsonDecode(response.body);
          _currentStep = 2;
          _isLoading = false;
        });
      } else if (response.statusCode == 422) {
        // The outline was understood but no panels fit — retrying won't help.
        String message = 'No solar panels fit inside the traced outline.';
        try {
          message = (jsonDecode(response.body)['error'] as String?) ?? message;
        } catch (_) {}
        setState(() {
          _errorMessage = message;
          _isLoading = false;
        });
      } else if (attempt < 3) {
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) _runSimulation(attempt: attempt + 1);
      } else {
        setState(() {
          _errorMessage = 'Simulation failed. Please try again.';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      if (attempt < 3) {
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) _runSimulation(attempt: attempt + 1);
      } else {
        setState(() {
          _errorMessage = 'Failed to connect to backend.';
          _isLoading = false;
        });
      }
    }
  }

  void _resetAll() => setState(() {
        _currentStep = 0;
        _analysisData = null;
        _rawImageBase64 = null;
        _imageSize = null;
        _fetchedAddress = null;
        _roofPoints.clear();
      });

  /// Maps a tap on the square canvas (image shown with BoxFit.cover) to satellite-image pixels.
  Offset _toImagePx(Offset local) {
    final canvas = _canvasSize ?? 560;
    final img = _imageSize ?? const Size(800, 800);
    final scale = math.max(canvas / img.width, canvas / img.height);
    final dx = (canvas - img.width * scale) / 2;
    final dy = (canvas - img.height * scale) / 2;
    return Offset(
      ((local.dx - dx) / scale).clamp(0, img.width),
      ((local.dy - dy) / scale).clamp(0, img.height),
    );
  }

  // ---------------------------------------------------------------- build
  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final Widget content;
    final String key;
    if (_isLoading) {
      key = 'loading';
      content = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: LoadingPanel(
            message: _loadingMessage,
            sub: _currentStep == 0 ? 'Fetching satellite image...' : 'Running solar analysis...',
            icon: _currentStep == 0 ? Icons.satellite_alt_rounded : Icons.auto_awesome_rounded,
            colors: _accent,
          ),
        ),
      );
    } else if (_errorMessage.isNotEmpty) {
      key = 'error';
      content = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ErrorPanel(
            message: _errorMessage,
            actionLabel: _currentStep == 1 && _rawImageBase64 != null ? 'Back to tracing' : 'Start over',
            actionIcon: Icons.arrow_back_rounded,
            onAction: () => setState(() {
              _errorMessage = '';
              if (!(_currentStep == 1 && _rawImageBase64 != null)) _currentStep = 0;
            }),
          ),
        ),
      );
    } else {
      key = 'step-$_currentStep';
      content = _currentStep == 0 ? _buildFormStep(p) : (_currentStep == 1 ? _buildRoofStep(p) : _buildDashboardStep(p));
    }

    return Scaffold(
      backgroundColor: p.bg,
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        themeNotifier: widget.themeNotifier,
        title: 'Solar AI',
        subtitle: 'Satellite roof analysis · yield & payback',
        icon: Icons.solar_power_rounded,
        colors: _accent,
      ),
      body: AuroraBackground(
        colors: const [AppColors.amber, AppColors.orange, AppColors.sky, AppColors.rose],
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 28, bottom: kNavClearance),
            child: PageBody(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: FadeSlideIn(child: StepIndicator(steps: _steps, active: _currentStep, colors: _accent)),
                    ),
                  ),
                  const SizedBox(height: 36),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(position: Tween(begin: const Offset(0.03, 0), end: Offset.zero).animate(a), child: child),
                    ),
                    child: KeyedSubtree(key: ValueKey(key), child: content),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- step 0
  Widget _buildFormStep(AppPalette p) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth > 860;
        final titleStyle = AppType.display(wide ? 48 : 34, p.text, height: 1.06);
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Pill(color: AppColors.amber, icon: Icons.wb_sunny_rounded, label: 'Solar irradiance via Open-Meteo · Satellite imagery'),
            const SizedBox(height: 20),
            Text('See what your roof\ncould', style: titleStyle),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (b) => const LinearGradient(colors: [AppColors.amber, AppColors.orange, AppColors.rose]).createShader(b),
              child: Text('earn you.', style: titleStyle),
            ),
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Text(
                'Enter your property address and energy details. We fetch a satellite image, you trace your roof outline, and our AI calculates your exact solar potential and financial return.',
                style: AppType.body(wide ? 17 : 15.5, p.muted, height: 1.6),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _heroChip(p, Icons.route_rounded, '3-step analysis'),
                _heroChip(p, Icons.euro_rounded, 'ROI & payback calc'),
                _heroChip(p, Icons.eco_rounded, 'CO₂ impact report'),
              ],
            ),
          ],
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FadeSlideIn(
              child: wide
                  ? Row(
                      children: [
                        Expanded(child: copy),
                        const SizedBox(width: 40),
                        const HeroOrb(icon: Icons.wb_sunny_rounded, colors: _accent, size: 240),
                      ],
                    )
                  : copy,
            ),
            SizedBox(height: wide ? 56 : 40),
            FadeSlideIn(
              delay: const Duration(milliseconds: 150),
              child: Center(
                child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: _buildFormCard(p)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _heroChip(AppPalette p, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: p.glass, borderRadius: BorderRadius.circular(12), border: Border.all(color: p.border)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.amber),
          const SizedBox(width: 7),
          Text(text, style: AppType.body(12.5, p.text, weight: FontWeight.w600, height: 1.2)),
        ],
      ),
    );
  }

  Widget _buildFormCard(AppPalette p) {
    return GlassCard(
      title: 'Property details',
      subtitle: 'Enter your address to fetch a satellite image of your roof.',
      icon: Icons.location_on_rounded,
      colors: _accent,
      strong: true,
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _addressController,
            label: 'Property address',
            hint: 'Street, number, postcode, city',
            helper: 'e.g. Musterstraße 12, 10115 Berlin',
            icon: Icons.location_on_outlined,
            accent: AppColors.amber,
            onSubmitted: (_) => _fetchRoofImage(),
          ),
          const SizedBox(height: 24),
          Text('Energy efficiency class', style: AppType.body(13, p.text, weight: FontWeight.w600, height: 1.2)),
          const SizedBox(height: 10),
          _EnergyClassPicker(value: _energyRating, onChanged: (v) => setState(() => _energyRating = v)),
          const SizedBox(height: 8),
          Text('EU energy label A (best) – G (worst)', style: AppType.body(12, p.muted, height: 1.3)),
          const SizedBox(height: 24),
          ResponsiveGrid(
            minItemWidth: 230,
            maxColumns: 3,
            children: [
              AppTextField(
                controller: _gridPriceController,
                label: 'Grid electricity price',
                helper: 'Your current tariff in ct/kWh',
                icon: Icons.bolt_outlined,
                suffix: 'ct/kWh',
                accent: AppColors.amber,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              AppTextField(
                controller: _billController,
                label: 'Monthly electricity bill',
                helper: 'Average monthly bill in euros',
                icon: Icons.euro_outlined,
                suffix: '€/mo',
                accent: AppColors.amber,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              AppTextField(
                controller: _householdController,
                label: 'Household size',
                helper: 'Number of people living there',
                icon: Icons.people_outline_rounded,
                suffix: 'people',
                accent: AppColors.amber,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          const SizedBox(height: 30),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _addressController,
            builder: (_, v, _) => PrimaryButton(
              label: 'Fetch satellite image',
              icon: Icons.satellite_alt_rounded,
              expand: true,
              colors: _accent,
              onTap: v.text.isEmpty ? null : _fetchRoofImage,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- step 1
  Widget _buildRoofStep(AppPalette p) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth > 900;
        final canvas = FadeSlideIn(child: LayoutBuilder(builder: (context, cc) => _buildRoofCanvas(p, cc.maxWidth - 6)));
        final panel = FadeSlideIn(delay: const Duration(milliseconds: 120), child: _buildTracePanel(p));
        if (!wide) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [panel, const SizedBox(height: 20), canvas]);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Expanded(flex: 7, child: canvas), const SizedBox(width: 24), Expanded(flex: 5, child: panel)],
        );
      },
    );
  }

  Widget _buildRoofCanvas(AppPalette p, double available) {
    final size = math.min(available, 560.0);
    // Points are stored in canvas space; remember the size so they can be mapped to image pixels.
    if (_canvasSize != null && _canvasSize != size && _roofPoints.isNotEmpty) {
      final k = size / _canvasSize!;
      for (var i = 0; i < _roofPoints.length; i++) {
        _roofPoints[i] = _roofPoints[i] * k;
      }
    }
    _canvasSize = size;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(colors: [AppColors.amber, AppColors.orange, AppColors.rose]),
          boxShadow: [BoxShadow(color: AppColors.orange.withValues(alpha: 0.35), blurRadius: 40, offset: const Offset(0, 16))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: SizedBox(
            width: size,
            height: size,
            child: MouseRegion(
              cursor: SystemMouseCursors.precise,
              child: GestureDetector(
                onTapDown: (d) => setState(() => _roofPoints.add(d.localPosition)),
                child: Stack(
                  children: [
                    Image.memory(_bytes(_rawImageBase64!), width: size, height: size, fit: BoxFit.cover, gaplessPlayback: true),
                    CustomPaint(painter: PolygonPainter(_roofPoints), size: Size(size, size)),
                    if (_roofPoints.isEmpty)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.touch_app_rounded, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text('Tap corners of your roof', style: AppType.body(13, Colors.white, weight: FontWeight.w600, height: 1.2)),
                            ],
                          ),
                        ),
                      ),
                    if (_lat != null && _lon != null)
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            '${_lat!.toStringAsFixed(5)}, ${_lon!.toStringAsFixed(5)}',
                            style: AppType.mono(10.5, Colors.white.withValues(alpha: 0.9)),
                          ),
                        ),
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

  Widget _buildTracePanel(AppPalette p) {
    final n = _roofPoints.length;
    final ready = n >= 3;
    const tips = [
      'Tap each corner of the roof surface you want to cover.',
      'Go around the outline in order — clockwise or counter-clockwise.',
      'Run the AI analysis once the shape looks right.',
    ];
    return GlassCard(
      title: 'Trace your roof',
      subtitle: 'Tap the corners of your roof polygon in order — at least 3 points.',
      icon: Icons.touch_app_rounded,
      colors: _accent,
      strong: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tips.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.amber.withValues(alpha: 0.15)),
                    child: Text('${i + 1}', style: AppType.mono(11, AppColors.amber, weight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(tips[i], style: AppType.body(13.5, p.muted, height: 1.45))),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: p.field,
              border: Border.all(color: ready ? AppColors.emerald.withValues(alpha: 0.4) : p.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                      child: Text('$n', key: ValueKey(n), style: AppType.display(34, ready ? AppColors.emerald : p.text, height: 1)),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(n == 1 ? 'corner placed' : 'corners placed', style: AppType.body(13, p.muted, height: 1.2)),
                    ),
                    const Spacer(),
                    Pill(
                      color: ready ? AppColors.emerald : AppColors.amber,
                      icon: ready ? Icons.check_rounded : Icons.more_horiz_rounded,
                      label: ready ? 'Ready' : '${3 - n} more needed',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AnimatedBar(
                  fraction: n / 3,
                  colors: ready ? const [AppColors.teal, AppColors.emerald] : _accent,
                  height: 6,
                  duration: const Duration(milliseconds: 400),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Undo',
                  icon: Icons.undo_rounded,
                  accent: AppColors.amber,
                  onTap: n == 0 ? null : () => setState(() => _roofPoints.removeLast()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SecondaryButton(
                  label: 'Clear ($n)',
                  icon: Icons.delete_sweep_rounded,
                  accent: AppColors.amber,
                  onTap: n == 0 ? null : () => setState(() => _roofPoints.clear()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Run AI analysis',
            icon: Icons.auto_awesome_rounded,
            expand: true,
            colors: _accent,
            onTap: ready ? _runSimulation : null,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextLink(
              label: 'Change address',
              color: p.muted,
              icon: Icons.edit_location_alt_rounded,
              onTap: () => setState(() => _currentStep = 0),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- step 2
  Widget _buildDashboardStep(AppPalette p) {
    final fin = (_analysisData!['financials'] as Map?)?.cast<String, dynamic>() ?? {};
    final strat = (_analysisData!['strategy'] as Map?)?.cast<String, dynamic>() ?? {};
    final env = (_analysisData!['environment'] as Map?)?.cast<String, dynamic>() ?? {};
    final imgB64 = _analysisData!['analyzed_image_base64'] as String?;
    final roofArea = (_analysisData!['roof_area'] as num?)?.toDouble() ?? 0;
    final numPanels = (_analysisData!['num_panels'] as num?)?.toInt() ?? 0;
    final capacityKwp = (_analysisData!['capacity_kwp'] as num?)?.toDouble() ?? 0;
    final advice = List<String>.from(_analysisData!['strategic_advice'] ?? []);
    final profit20 = (fin['twenty_year_profit'] as num?)?.toDouble() ?? 0;
    final annualSav = (fin['annual_savings'] as num?)?.toDouble() ?? 0;
    final monthlyRel = (fin['monthly_relief'] as num?)?.toDouble() ?? 0;
    final payback = (fin['payback'] as num?)?.toDouble() ?? 0;
    final autarky = (strat['autarky_rate'] as num?)?.toDouble() ?? 0;
    final locScore = (strat['location_score'] as num?)?.toDouble() ?? 0;
    final batImpact = (strat['battery_impact'] as num?)?.toDouble() ?? 0;
    final co2Saved = (env['co2_saved'] as num?)?.toDouble() ?? 0;
    final treeCount = (env['tree_count'] as num?)?.toInt() ?? 0;
    final ecoGrade = env['eco_grade'] as String? ?? 'N/A';

    return LayoutBuilder(
      builder: (context, c) {
        final isWide = c.maxWidth > 860;
        final restart = SecondaryButton(label: 'Analyze another property', icon: Icons.refresh_rounded, accent: AppColors.amber, onTap: _resetAll);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FadeSlideIn(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: SectionHeader(
                      eyebrow: 'ANALYSIS COMPLETE',
                      title: 'Your roof\'s solar potential.',
                      wide: isWide,
                      accent: AppColors.amber,
                      compact: true,
                    ),
                  ),
                  if (isWide) ...[const SizedBox(width: 20), restart],
                ],
              ),
            ),
            const SizedBox(height: 24),
            FadeSlideIn(delay: const Duration(milliseconds: 60), child: _buildLocationBar(p)),
            const SizedBox(height: 20),
            ResponsiveGrid(
              minItemWidth: 220,
              children: [
                FadeSlideIn(
                  child: KpiTile(
                    icon: Icons.solar_power_rounded,
                    colors: _accent,
                    label: 'Panels on your roof',
                    number: numPanels.toDouble(),
                    suffix: ' panels',
                    sub: '${capacityKwp.toStringAsFixed(1)} kWp installed capacity',
                  ),
                ),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: KpiTile(
                    icon: Icons.euro_rounded,
                    colors: const [AppColors.emerald, AppColors.teal],
                    label: 'Annual savings',
                    number: annualSav,
                    prefix: '€',
                    thousands: true,
                    sub: 'Annual electricity savings',
                    valueColor: AppColors.emerald,
                  ),
                ),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 160),
                  child: KpiTile(
                    icon: Icons.replay_rounded,
                    colors: const [AppColors.sky, AppColors.indigo],
                    label: 'Payback period',
                    number: payback,
                    decimals: 1,
                    suffix: ' yrs',
                    sub: 'Investment payback period',
                  ),
                ),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 240),
                  child: KpiTile(
                    icon: Icons.eco_rounded,
                    colors: const [AppColors.teal, AppColors.emerald],
                    label: 'CO₂ avoided',
                    number: co2Saved,
                    decimals: 1,
                    suffix: ' t',
                    sub: 'CO₂ saved per year',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FadeSlideIn(
              delay: const Duration(milliseconds: 300),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildImageCard(p, imgB64, roofArea, numPanels)),
                        const SizedBox(width: 20),
                        Expanded(flex: 3, child: _buildAdvisoryCard(p, advice)),
                      ],
                    )
                  : Column(
                      children: [
                        _buildImageCard(p, imgB64, roofArea, numPanels),
                        const SizedBox(height: 20),
                        _buildAdvisoryCard(p, advice),
                      ],
                    ),
            ),
            const SizedBox(height: 20),
            FadeSlideIn(
              delay: const Duration(milliseconds: 400),
              child: isWide
                  ? IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _buildFinancialCard(p, profit20, annualSav, monthlyRel, payback)),
                          const SizedBox(width: 20),
                          Expanded(child: _buildSystemCard(p, autarky, locScore, batImpact)),
                          const SizedBox(width: 20),
                          Expanded(child: _buildEnvironmentCard(p, co2Saved, treeCount, ecoGrade)),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        _buildFinancialCard(p, profit20, annualSav, monthlyRel, payback),
                        const SizedBox(height: 20),
                        _buildSystemCard(p, autarky, locScore, batImpact),
                        const SizedBox(height: 20),
                        _buildEnvironmentCard(p, co2Saved, treeCount, ecoGrade),
                      ],
                    ),
            ),
            const SizedBox(height: 32),
            Center(child: restart),
          ],
        );
      },
    );
  }

  Widget _buildLocationBar(AppPalette p) {
    final address = (_fetchedAddress?.isNotEmpty ?? false) ? _fetchedAddress! : 'Selected property';
    return Glass(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const IconTile(icon: Icons.home_rounded, colors: _accent, size: 46),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ANALYZED PROPERTY', style: AppType.eyebrow(AppColors.amber)),
                const SizedBox(height: 4),
                Text(address, style: AppType.display(18, p.text, height: 1.25)),
                if (_lat != null && _lon != null) ...[
                  const SizedBox(height: 2),
                  Text('${_lat!.toStringAsFixed(5)}° N, ${_lon!.toStringAsFixed(5)}° E', style: AppType.mono(11.5, p.muted)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(AppPalette p, String? imgB64, double roofArea, int numPanels) {
    return GlassCard(
      title: 'Analyzed roof',
      subtitle: 'AI panel placement overlay — $numPanels panels on ${roofArea.toStringAsFixed(0)} m²',
      icon: Icons.satellite_alt_rounded,
      colors: const [AppColors.sky, AppColors.indigo],
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (imgB64 != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(_bytes(imgB64), fit: BoxFit.contain, width: double.infinity, gaplessPlayback: true),
            ),
          const SizedBox(height: 14),
          Center(child: Pill(color: AppColors.amber, icon: Icons.square_foot_rounded, label: 'Roof area: ${roofArea.toStringAsFixed(0)} m²')),
        ],
      ),
    );
  }

  Widget _buildAdvisoryCard(AppPalette p, List<String> advice) {
    return GlassCard(
      title: 'AI strategic advisory',
      subtitle: 'Personalized recommendations from EnergyTwin\'s solar analysis engine',
      icon: Icons.auto_awesome_rounded,
      colors: _accent,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < advice.length; i++)
            FadeSlideIn(
              delay: Duration(milliseconds: 450 + i * 90),
              offset: 12,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: p.field,
                  border: Border.all(color: p.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(colors: _accent),
                      ),
                      child: Text('${i + 1}', style: AppType.mono(11.5, Colors.white, weight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(advice[i], style: AppType.body(14, p.text, height: 1.55))),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFinancialCard(AppPalette p, double profit20, double annualSav, double monthlyRel, double payback) {
    return GlassCard(
      title: 'Financial overview',
      icon: Icons.account_balance_wallet_rounded,
      colors: const [AppColors.emerald, AppColors.teal],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('20-year net profit', style: AppType.body(12.5, p.muted, weight: FontWeight.w600, height: 1.3)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: CountUp(
              value: profit20,
              decimals: 0,
              prefix: '€',
              thousands: true,
              duration: const Duration(milliseconds: 1800),
              style: AppType.display(34, AppColors.emerald, height: 1.1),
            ),
          ),
          Text('Total earnings after installation cost', style: AppType.body(12, p.faint, height: 1.3)),
          const SizedBox(height: 18),
          Divider(color: p.border, height: 1),
          const SizedBox(height: 16),
          _metricRow(p, 'Annual savings', '€${annualSav.toStringAsFixed(0)}', 'Yearly reduction in electricity bill', AppColors.emerald),
          _metricRow(p, 'Monthly relief', '€${monthlyRel.toStringAsFixed(0)}', 'Average monthly bill reduction', AppColors.sky),
          _metricRow(p, 'Payback period', '${payback.toStringAsFixed(1)} years', 'Time to recoup installation investment', AppColors.orange),
        ],
      ),
    );
  }

  Widget _buildSystemCard(AppPalette p, double autarky, double locScore, double batImpact) {
    return GlassCard(
      title: 'System metrics',
      icon: Icons.donut_large_rounded,
      colors: const [AppColors.sky, AppColors.indigo],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: RingMeter(value: autarky / 100, colors: _accent, label: 'Independence', size: 84, stroke: 9)),
              Expanded(
                child: RingMeter(value: locScore / 100, colors: const [AppColors.sky, AppColors.blue], label: 'Sun score', size: 84, stroke: 9),
              ),
              Expanded(
                child: RingMeter(
                  value: batImpact / 100,
                  colors: const [AppColors.violet, AppColors.indigo],
                  label: 'Battery value',
                  size: 84,
                  stroke: 9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: p.field, border: Border.all(color: p.border)),
            child: Text(
              'Independence: % of electricity self-produced. Sun Score: location quality. Battery Value: estimated benefit of adding a home battery.',
              style: AppType.body(12, p.muted, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentCard(AppPalette p, double co2Saved, int treeCount, String ecoGrade) {
    return GlassCard(
      title: 'Environmental impact',
      icon: Icons.eco_rounded,
      colors: const [AppColors.teal, AppColors.emerald],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(colors: [AppColors.emerald, AppColors.teal]),
                  boxShadow: [BoxShadow(color: AppColors.emerald.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 6))],
                ),
                child: FittedBox(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(ecoGrade, style: AppType.display(26, Colors.white)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('EnergyTwin eco grade', style: AppType.body(14, p.text, weight: FontWeight.w700, height: 1.3)),
                    Text('Sustainability rating for this system', style: AppType.body(12, p.faint, height: 1.3)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Divider(color: p.border, height: 1),
          const SizedBox(height: 16),
          _metricRow(p, 'CO₂ eliminated', '${co2Saved.toStringAsFixed(1)} t/yr', 'Annual carbon emissions prevented', AppColors.emerald),
          _metricRow(p, 'Tree equivalent', '~$treeCount trees/yr', 'Annual CO₂ absorption equivalent', AppColors.teal),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.emerald.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, color: AppColors.emerald, size: 17),
                const SizedBox(width: 9),
                Expanded(
                  child: Text('BAFA-eligible system — qualifies for German state subsidy', style: AppType.body(12.5, p.text, height: 1.35)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricRow(AppPalette p, String label, String value, String hint, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppType.body(13, p.text, weight: FontWeight.w600, height: 1.3)),
                const SizedBox(height: 2),
                Text(hint, style: AppType.body(11.5, p.faint, height: 1.35)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(value, style: AppType.mono(13, color, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// EU energy-label style selector for classes A–G.
class _EnergyClassPicker extends StatelessWidget {
  const _EnergyClassPicker({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  static final _classes = [
    ('A', Colors.green.shade600),
    ('B', Colors.lightGreen.shade600),
    ('C', Colors.lime.shade700),
    ('D', Colors.yellow.shade700),
    ('E', Colors.orange.shade600),
    ('F', Colors.deepOrange.shade600),
    ('G', Colors.red.shade700),
  ];

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return SizedBox(
      height: 54,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < _classes.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => onChanged(_classes[i].$1),
                  child: Semantics(
                    button: true,
                    selected: value == _classes[i].$1,
                    label: 'Energy class ${_classes[i].$1}',
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutBack,
                      height: value == _classes[i].$1 ? 54 : 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: value == _classes[i].$1 ? _classes[i].$2 : _classes[i].$2.withValues(alpha: p.isDark ? 0.16 : 0.14),
                        border: Border.all(color: _classes[i].$2.withValues(alpha: value == _classes[i].$1 ? 1 : 0.35)),
                        boxShadow: value == _classes[i].$1
                            ? [BoxShadow(color: _classes[i].$2.withValues(alpha: 0.45), blurRadius: 16, offset: const Offset(0, 6))]
                            : null,
                      ),
                      child: Text(
                        _classes[i].$1,
                        style: AppType.display(value == _classes[i].$1 ? 20 : 16, value == _classes[i].$1 ? Colors.white : _classes[i].$2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── POLYGON PAINTER ───────────────────────────────────────────────────────────

class PolygonPainter extends CustomPainter {
  final List<Offset> points;
  PolygonPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    if (points.length > 2) {
      path.close();
      canvas.drawPath(path, Paint()..color = AppColors.amber.withValues(alpha: 0.28));
    }
    // Soft glow under a crisp outline.
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.orange.withValues(alpha: 0.6)
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.amber
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );

    for (var i = 0; i < points.length; i++) {
      final pt = points[i];
      final first = i == 0;
      canvas.drawCircle(pt, 10, Paint()..color = Colors.black.withValues(alpha: 0.25));
      canvas.drawCircle(pt, 9, Paint()..color = Colors.white);
      canvas.drawCircle(
        pt,
        9,
        Paint()
          ..color = first && points.length > 2 ? AppColors.emerald : AppColors.orange
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(color: Color(0xFF0B1220), fontSize: 9.5, fontWeight: FontWeight.w800),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pt - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
