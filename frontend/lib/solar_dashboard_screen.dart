import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend/custom_app_bar.dart';

class SolarDashboardScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;
  const SolarDashboardScreen({super.key, required this.themeNotifier});

  @override
  State<SolarDashboardScreen> createState() => _SolarDashboardScreenState();
}

class _SolarDashboardScreenState extends State<SolarDashboardScreen> {
  // ==========================================
  // STATE & CONTROLLERS
  // ==========================================
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _billController = TextEditingController(text: '150');
  final TextEditingController _householdController = TextEditingController(text: '4');
  final TextEditingController _gridPriceController = TextEditingController(text: '35.0');
  String _energyRating = 'D';

  int _currentStep = 0; // 0 = Form, 1 = Tap Roof, 2 = Dashboard
  bool _isLoading = false;
  String _errorMessage = '';
  
  String? _rawImageBase64;
  double? _lat, _lon;
  List<Offset> _roofPoints = [];

  Map<String, dynamic>? _analysisData;

  String get _baseUrl {
    // 🔥 Updated from local IP to Render URL
    return 'https://energy-twin-de.onrender.com'; 
  }

  @override
  void dispose() {
    _addressController.dispose();
    _billController.dispose();
    _householdController.dispose();
    _gridPriceController.dispose();
    super.dispose();
  }

  // ==========================================
  // API CALLS
  // ==========================================
  Future<void> _fetchRoofImage() async {
    if (_addressController.text.isEmpty) return;
    setState(() { _isLoading = true; _errorMessage = ''; });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/get_roof'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'address': _addressController.text}),
      );

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
      } else {
        setState(() { _errorMessage = 'Could not find address.'; _isLoading = false; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _errorMessage = 'Server error.'; _isLoading = false; });
    }
  }

  Future<void> _runSimulation() async {
    if (_roofPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tap at least 3 corners on the roof!")));
      return;
    }
    setState(() { _isLoading = true; _errorMessage = ''; });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/simulate_solar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'lat': _lat,
          'lon': _lon,
          'monthly_bill_eur': double.tryParse(_billController.text) ?? 150.0,
          'energy_rating': _energyRating,
          'household_size': int.tryParse(_householdController.text) ?? 4,
          'grid_price_ct_kwh': double.tryParse(_gridPriceController.text) ?? 35.0,
          'roof_points': _roofPoints.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _analysisData = jsonDecode(response.body);
          _currentStep = 2; 
          _isLoading = false;
        });
      } else {
        setState(() { _errorMessage = 'Simulation failed: ${response.body}'; _isLoading = false; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _errorMessage = 'Failed to connect to backend.'; _isLoading = false; });
    }
  }

  // ==========================================
  // MAIN BUILDER
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(themeNotifier: widget.themeNotifier, title: 'Energy-Twin: AI Solar Strategy'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() { _errorMessage = ''; _currentStep = 0; }),
                        child: const Text('Go Back'),
                      )
                    ],
                  ),
                )
              : _buildCurrentStep(theme, isDark),
    );
  }

  Widget _buildCurrentStep(ThemeData theme, bool isDark) {
    if (_currentStep == 0) return _buildFormStep(theme, isDark);
    if (_currentStep == 1) return _buildRoofSelectionStep(theme, isDark);
    return _buildDashboardStep(theme, isDark);
  }

  // ==========================================
  // STEP 0: FORM
  // ==========================================
  Widget _buildFormStep(ThemeData theme, bool isDark) {
    return Center(
      child: Container(
        width: 600, 
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Locate Your Property', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                hintText: 'e.g. Adenauerallee 1, Bonn',
                prefixIcon: const Icon(Icons.location_on, color: Colors.blueAccent),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _energyRating,
                    decoration: InputDecoration(
                      labelText: 'Energy Rating',
                      prefixIcon: const Icon(Icons.home_work, color: Colors.blueAccent),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['A', 'B', 'C', 'D', 'E', 'F', 'G'].map((String rating) {
                      return DropdownMenuItem(value: rating, child: Text('Class $rating'));
                    }).toList(),
                    onChanged: (val) => setState(() => _energyRating = val!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _gridPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Grid Price (ct/kWh)',
                      prefixIcon: const Icon(Icons.bolt, color: Colors.blueAccent),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _billController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Monthly Bill (€)', 
                      prefixIcon: const Icon(Icons.euro, color: Colors.blueAccent), 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _householdController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'People in Home', 
                      prefixIcon: const Icon(Icons.people, color: Colors.blueAccent), 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _fetchRoofImage,
                icon: const Icon(Icons.satellite_alt),
                label: const Text('Fetch Satellite Feed'),
              ),
            )
          ],
        ),
      ),
    );
  }

  // ==========================================
  // STEP 1: INTERACTIVE ROOF MAP
  // ==========================================
  Widget _buildRoofSelectionStep(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Tap the corners of your roof to define the bounds', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          Container(
            width: 400, height: 400, 
            decoration: BoxDecoration(border: Border.all(color: Colors.blueAccent, width: 3)),
            child: GestureDetector(
              onTapDown: (details) {
                setState(() => _roofPoints.add(details.localPosition));
              },
              child: Stack(
                children: [
                  Image.memory(base64Decode(_rawImageBase64!), width: 400, height: 400, fit: BoxFit.cover),
                  CustomPaint(painter: PolygonPainter(_roofPoints), size: const Size(400, 400)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _roofPoints.clear()),
                icon: const Icon(Icons.undo), label: const Text('Clear'),
              ),
              const SizedBox(width: 24),
              FilledButton.icon(
                onPressed: _runSimulation,
                icon: const Icon(Icons.memory), label: const Text('Run AI Analysis'),
              ),
            ],
          )
        ],
      ),
    );
  }

  // ==========================================
  // STEP 2: THEME-RESPONSIVE DASHBOARD
  // ==========================================
  Widget _buildDashboardStep(ThemeData theme, bool isDark) {
    final fin = _analysisData!['financials'] ?? {};
    final strat = _analysisData!['strategy'] ?? {};
    final env = _analysisData!['environment'] ?? {};
    final imageBase64 = _analysisData!['analyzed_image_base64'];
    final roofArea = _analysisData!['roof_area'] ?? 0;
    
    // 🔥 THEME LOGIC: Switches colors instantly based on Light/Dark mode
    final bgColor = isDark ? const Color(0xFF080808) : theme.scaffoldBackgroundColor;
    final boxColor = isDark ? const Color.fromRGBO(25, 25, 25, 0.75) : theme.cardColor;
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedColor = isDark ? const Color(0xFF888888) : Colors.black54;
    final dividerColor = isDark ? Colors.white10 : Colors.black12;

    // Accents: Neons for dark mode, darker readable variants for light mode
    final accentGreen = isDark ? const Color(0xFF00FF88) : Colors.green.shade700;
    final accentYellow = isDark ? const Color(0xFFD4FF00) : Colors.orange.shade700; 
    final accentCyan = isDark ? const Color(0xFF00D4FF) : Colors.blue.shade700;
    final accentPink = isDark ? const Color(0xFFFF00D4) : Colors.purple.shade700;

    return Container(
      color: bgColor, 
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ENERGY-TWIN: AI SOLAR STRATEGY', style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 3, fontWeight: FontWeight.w900, color: textColor)),
            const SizedBox(height: 4),
            Text('Real-time Solar Simulation & Economic Audit | Bonn Region v2.0', style: TextStyle(color: mutedColor)),
            const SizedBox(height: 32),

            LayoutBuilder(
              builder: (context, constraints) {
                Row kpis = Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Box 1
                    Expanded(child: _buildDashBox(' FINANCIAL FREEDOM', Icons.account_balance_wallet, accentGreen, mutedColor, boxColor, [
                      Text('20-YEAR NET PROFIT', style: TextStyle(color: mutedColor, fontSize: 12, letterSpacing: 1)),
                      Text('${fin['twenty_year_profit'] ?? 0}€', style: TextStyle(color: accentGreen, fontSize: 36, fontWeight: FontWeight.w900, shadows: isDark ? [const Shadow(color: Color(0x6600FF88), blurRadius: 15)] : [])),
                      const SizedBox(height: 16),
                      Text('Annual Savings: ${fin['annual_savings'] ?? 0}€', style: TextStyle(color: textColor, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Monthly Relief: ${fin['monthly_relief'] ?? 0}€', style: TextStyle(color: mutedColor, fontSize: 12)),
                      Divider(height: 32, color: dividerColor),
                      Text('ROI: ${fin['payback'] ?? 0} Years', style: TextStyle(color: accentGreen, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ])),
                    const SizedBox(width: 24),

                    // Box 2
                    Expanded(child: _buildDashBox(' SYSTEM BLUEPRINT', Icons.home_repair_service, accentYellow, mutedColor, boxColor, [
                      Text('${_analysisData!['num_panels'] ?? 0} High-Efficiency Panels', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(height: 4),
                      Text('Capacity: ${_analysisData!['capacity_kwp'] ?? 0} kWp', style: TextStyle(color: accentYellow, fontSize: 14)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMiniDonut('Independence', (strat['autarky_rate'] ?? 0).toDouble(), accentYellow, textColor, isDark),
                          _buildMiniDonut('Sun Stability', (strat['location_score'] ?? 0).toDouble(), accentCyan, textColor, isDark),
                          _buildMiniDonut('Battery Flow', (strat['battery_impact'] ?? 0).toDouble(), accentPink, textColor, isDark),
                        ],
                      )
                    ], borderColor: accentYellow)),
                    const SizedBox(width: 24),

                    // Box 3
                    Expanded(child: _buildDashBox(' ENVIRONMENTAL IMPACT', Icons.park, accentCyan, mutedColor, boxColor, [
                      Text('${env['co2_saved'] ?? 0} Tons CO2', style: TextStyle(color: accentCyan, fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('♻️ Equivalent to ${env['tree_count'] ?? 0} trees/year', style: TextStyle(fontSize: 16, color: textColor)),
                      Divider(height: 32, color: dividerColor),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: accentCyan, borderRadius: BorderRadius.circular(4)),
                        child: Text('Status: ${env['eco_grade'] ?? "N/A"}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      )
                    ])),
                  ],
                );
                
                if (constraints.maxWidth < 900) {
                  return Column(children: [kpis.children[0], const SizedBox(height:24), kpis.children[2], const SizedBox(height:24), kpis.children[4]]);
                }
                return kpis;
              },
            ),
            
            const SizedBox(height: 32),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: _buildDashBox('', null, Colors.transparent, mutedColor, Colors.transparent, [
                    Text('🛰️ ANALYZED ROOF BLUEPRINT', style: TextStyle(color: mutedColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (imageBase64 != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          decoration: BoxDecoration(border: Border.all(color: dividerColor)),
                          child: Image.memory(base64Decode(imageBase64), fit: BoxFit.contain, width: double.infinity),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(4)),
                        child: Text('Total Area: $roofArea m²', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    )
                  ], shadow: false),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 7,
                  child: _buildDashBox('', null, Colors.transparent, mutedColor, boxColor, [
                    Row(
                      children: [
                        Icon(Icons.smart_toy, color: accentYellow),
                        const SizedBox(width: 8),
                        Text('AI STRATEGIC ADVISORY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                      ],
                    ),
                    Divider(height: 32, color: dividerColor),
                    ...List<String>.from(_analysisData!['strategic_advice'] ?? []).map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.shield_outlined, color: accentYellow, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text(tip, style: TextStyle(fontSize: 15, height: 1.5, color: isDark ? const Color(0xFFDDDDDD) : Colors.black87))),
                        ],
                      ),
                    )),
                  ]),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDashBox(String title, IconData? icon, Color accent, Color mutedColor, Color boxColor, List<Widget> children, {Color? borderColor, bool shadow = true}) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? (shadow ? Colors.transparent : Colors.black12), width: 1),
        boxShadow: shadow ? [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 32, offset: const Offset(0, 8))] : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Row(
              children: [
                if (icon != null) Icon(icon, color: accent, size: 24),
                Text(title, style: TextStyle(color: mutedColor, letterSpacing: 1, fontSize: 14)),
              ],
            ),
          if (title.isNotEmpty) const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMiniDonut(String label, double percentage, Color accentColor, Color textColor, bool isDark) {
    return Column(
      children: [
        SizedBox(
          width: 85, height: 85,
          child: Stack(
            children: [
              PieChart(PieChartData(
                sectionsSpace: 0, centerSpaceRadius: 32,
                sections: [
                  PieChartSectionData(value: percentage, color: accentColor, radius: 10, showTitle: false),
                  PieChartSectionData(value: 100 - percentage, color: isDark ? Colors.white.withAlpha(12) : Colors.black12, radius: 10, showTitle: false),
                ],
              )),
              Center(child: Text('${percentage.toInt()}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor))),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 11, color: accentColor, fontWeight: isDark ? FontWeight.normal : FontWeight.bold)),
      ],
    );
  }
}

// ==========================================
// ROOF PAINTER
// ==========================================
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
      for (var p in points) canvas.drawCircle(p, 5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}