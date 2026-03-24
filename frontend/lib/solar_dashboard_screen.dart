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
  // Step 0: User Inputs
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _billController = TextEditingController(text: '150');
  final TextEditingController _householdController = TextEditingController(text: '4');
  String _energyRating = 'D';

  // State Trackers
  int _currentStep = 0; // 0 = Form, 1 = Tap Roof, 2 = Dashboard
  bool _isLoading = false;
  String _errorMessage = '';
  
  // Roof Selection Data
  String? _rawImageBase64;
  double? _lat, _lon;
  List<Offset> _roofPoints = [];

  // Final Dashboard Data
  Map<String, dynamic>? _analysisData;

  String get _baseUrl {
    return 'https://energy-twin-de.onrender.com'; 
  }

  // --- API 1: Fetch Image ---
  Future<void> _fetchRoofImage() async {
    if (_addressController.text.isEmpty) return;
    setState(() { _isLoading = true; _errorMessage = ''; });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/get_roof'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'address': _addressController.text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _rawImageBase64 = data['image_base64'];
          _lat = data['lat'];
          _lon = data['lon'];
          _roofPoints.clear();
          _currentStep = 1; // Move to roof selection
          _isLoading = false;
        });
      } else {
        setState(() { _errorMessage = 'Could not find address.'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _errorMessage = 'Server error.'; _isLoading = false; });
    }
  }

  // --- API 2: Run Simulation ---
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
          'roof_points': _roofPoints.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _analysisData = jsonDecode(response.body);
          _currentStep = 2; // Move to dashboard
          _isLoading = false;
        });
      } else {
        setState(() { _errorMessage = 'Simulation failed: ${response.body}'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _errorMessage = 'Failed to connect to backend.'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(themeNotifier: widget.themeNotifier, title: 'Energy-Twin: AI Solar Strategy'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
              : _buildCurrentStep(theme, isDark),
    );
  }

  Widget _buildCurrentStep(ThemeData theme, bool isDark) {
    if (_currentStep == 0) return _buildFormStep(theme, isDark);
    if (_currentStep == 1) return _buildRoofSelectionStep(theme, isDark);
    return _buildDashboardStep(theme, isDark);
  }

  // ==========================================
  // STEP 0: INPUT FORM
  // ==========================================
  Widget _buildFormStep(ThemeData theme, bool isDark) {
    return Center(
      child: Container(
        width: 400,
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
                  child: TextField(
                    controller: _billController,
                    decoration: InputDecoration(hintText: 'Bill (€)', prefixIcon: const Icon(Icons.euro), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _householdController,
                    decoration: InputDecoration(hintText: 'People', prefixIcon: const Icon(Icons.people), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
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
  // STEP 1: INTERACTIVE ROOF SELECTION
  // ==========================================
  Widget _buildRoofSelectionStep(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Tap the corners of your roof to define the bounds', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          // Interactive Canvas
          Container(
            width: 400, height: 400, // Fixed size for coordinate scaling
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
  // STEP 2: TEAMMATE'S 3-BOX DASHBOARD
  // ==========================================
  Widget _buildDashboardStep(ThemeData theme, bool isDark) {
    final fin = _analysisData!['financials'];
    final strat = _analysisData!['strategy'];
    final env = _analysisData!['environment'];
    final imageBase64 = _analysisData!['analyzed_image_base64'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Real-time Solar Simulation & Economic Audit', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey)),
          const SizedBox(height: 32),

          // TOP ROW: THE 3 STRATEGIC KPI BOXES
          LayoutBuilder(
            builder: (context, constraints) {
              Row kpis = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Box 1: Financial Freedom
                  Expanded(child: _buildDashBox(theme, isDark, 'FINANCIAL FREEDOM', Icons.account_balance_wallet, Colors.greenAccent, [
                    Text('20-YEAR NET PROFIT', style: TextStyle(color: Colors.grey.shade400, fontSize: 12, letterSpacing: 1)),
                    Text('€${fin['twenty_year_profit']}', style: const TextStyle(color: Colors.greenAccent, fontSize: 36, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Text('Annual Savings: €${fin['annual_savings']}', style: const TextStyle(color: Colors.white70)),
                    const Divider(height: 32),
                    Text('ROI: ${fin['payback']} Years', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                  ])),
                  const SizedBox(width: 24),

                  // Box 2: System Blueprint
                  Expanded(child: _buildDashBox(theme, isDark, 'SYSTEM BLUEPRINT', Icons.solar_power, Colors.yellowAccent, [
                    Text('${_analysisData!['num_panels']} High-Efficiency Panels', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Capacity: ${_analysisData!['capacity_kwp']} kWp', style: const TextStyle(color: Colors.yellowAccent)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMiniDonut('Autarky', strat['autarky_rate'].toDouble(), Colors.yellowAccent),
                        _buildMiniDonut('Sun Score', strat['location_score'].toDouble(), Colors.orangeAccent),
                      ],
                    )
                  ])),
                  const SizedBox(width: 24),

                  // Box 3: Environmental Legacy
                  Expanded(child: _buildDashBox(theme, isDark, 'ENVIRONMENTAL IMPACT', Icons.eco, Colors.lightBlueAccent, [
                    Text('${env['co2_saved']} Tons CO2', style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('♻️ Equivalent to ${env['tree_count']} trees/year', style: const TextStyle(color: Colors.white70)),
                    const Divider(height: 32),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.lightBlueAccent.withAlpha(40), borderRadius: BorderRadius.circular(12)),
                      child: Text('Status: ${env['eco_grade']}', style: const TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold)),
                    )
                  ])),
                ],
              );
              
              if (constraints.maxWidth < 800) {
                // If on mobile, wrap them vertically
                return Column(children: [kpis.children[0], const SizedBox(height:16), kpis.children[2], const SizedBox(height:16), kpis.children[4]]);
              }
              return kpis;
            },
          ),
          
          const SizedBox(height: 32),

          // BOTTOM ROW: AI Blueprint & Strategic Advice
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Image
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    children: [
                      Text('🛰️ ANALYZED ROOF BLUEPRINT', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(base64Decode(imageBase64), fit: BoxFit.contain),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Right: Advice List
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.memory, color: Colors.purpleAccent),
                          const SizedBox(width: 8),
                          Text('AI STRATEGIC ADVISORY', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(height: 32),
                      ...List<String>.from(_analysisData!['strategic_advice']).map((tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.shield_outlined, color: Colors.purpleAccent, size: 20),
                            const SizedBox(width: 12),
                            Expanded(child: Text(tip, style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.white70))),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDashBox(ThemeData theme, bool isDark, String title, IconData icon, Color accent, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF191919), // Deep dark matching teammate's dash
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withAlpha(50), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(80), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: Colors.grey.shade400, letterSpacing: 1.2, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMiniDonut(String label, double percentage, Color color) {
    return Column(
      children: [
        SizedBox(
          width: 60, height: 60,
          child: Stack(
            children: [
              PieChart(PieChartData(
                sectionsSpace: 0, centerSpaceRadius: 20,
                sections: [
                  PieChartSectionData(value: percentage, color: color, radius: 10, showTitle: false),
                  PieChartSectionData(value: 100 - percentage, color: Colors.white10, radius: 10, showTitle: false),
                ],
              )),
              Center(child: Text('${percentage.toInt()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 10, color: color)),
      ],
    );
  }
}

// Canvas Painter to draw the red polygon lines over the image
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
      if (points.length > 2) path.close(); // Close the loop
      
      canvas.drawPath(path, paint);
      for (var p in points) canvas.drawCircle(p, 5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}