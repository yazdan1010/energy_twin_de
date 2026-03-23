import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend/custom_app_bar.dart'; // Ensure this matches your project structure

class SolarDashboardScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;
  const SolarDashboardScreen({super.key, required this.themeNotifier});

  @override
  State<SolarDashboardScreen> createState() => _SolarDashboardScreenState();
}

class _SolarDashboardScreenState extends State<SolarDashboardScreen> {
  // Input Controllers
  final TextEditingController _panelsController = TextEditingController(text: '20');
  final TextEditingController _billController = TextEditingController(text: '150');
  final TextEditingController _householdController = TextEditingController(text: '4');
  String _energyRating = 'D';

  // State Management
  bool _isLoading = false;
  Map<String, dynamic>? _analysisData;
  String _errorMessage = '';

  String get _apiUrl {
    const port = '5001';
    const endpoint = '/simulate_solar';
    if (kIsWeb) return 'http://127.0.0.1:$port$endpoint';
    if (Platform.isAndroid) return 'http://10.0.2.2:$port$endpoint';
    return 'http://127.0.0.1:$port$endpoint';
  }

  Future<void> _runSimulation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _analysisData = null;
    });

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'num_panels': int.tryParse(_panelsController.text) ?? 20,
          'monthly_bill_eur': double.tryParse(_billController.text) ?? 150.0,
          'energy_rating': _energyRating,
          'household_size': int.tryParse(_householdController.text) ?? 4,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _analysisData = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'API Error: ${response.statusCode} - ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to connect to AI Engine. Check if Flask is running.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(themeNotifier: widget.themeNotifier, title: 'AI Solar Architect'),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT PANEL: Configuration
          Container(
            width: 350,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(right: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Parameters',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                _buildInputField(
                  theme,
                  isDark,
                  'Usable Roof Panels',
                  'e.g. 20',
                  _panelsController,
                  Icons.grid_on,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  theme,
                  isDark,
                  'Monthly Bill (€)',
                  'e.g. 150',
                  _billController,
                  Icons.euro,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  theme,
                  isDark,
                  'Household Size',
                  'e.g. 4',
                  _householdController,
                  Icons.people,
                ),
                const SizedBox(height: 16),

                Text('Energy Rating', style: theme.textTheme.bodySmall),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _energyRating,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: ['A', 'B', 'C', 'D', 'E', 'F', 'G'].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text('Class $value'));
                  }).toList(),
                  onChanged: (newValue) => setState(() => _energyRating = newValue!),
                ),

                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _runSimulation,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.memory),
                    label: Text(
                      _isLoading ? 'Simulating...' : 'Run AI Analysis',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // RIGHT PANEL: The Dashboard
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                ? Center(
                    child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                  )
                : _analysisData == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.solar_power,
                          size: 80,
                          color: theme.colorScheme.primary.withAlpha(100),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Enter your home parameters and click "Run AI Analysis"',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildResultsDashboard(theme, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsDashboard(ThemeData theme, bool isDark) {
    // Extracting the data safely from the JSON payload
    final specs = _analysisData!['system_specs'];
    final financials = _analysisData!['financials'];
    final noBat = financials['no_battery'];
    final withBat = financials['with_battery'];
    final adviceList = List<String>.from(_analysisData!['strategic_advice']);
    final metrics = _analysisData!['ai_metrics'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER: AI Confidence
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Solar Strategy Report',
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.purple.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.memory, color: Colors.purple, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'AI Confidence: ${metrics['accuracy_percent']}%',
                      style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ROW 1: System Hardware & Eco Specs
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  theme,
                  isDark,
                  'System Size',
                  '${specs['capacity_kwp']} kWp',
                  '${specs['num_panels']} Panels',
                  Icons.solar_power,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildInfoCard(
                  theme,
                  isDark,
                  'Annual Yield',
                  '${specs['yield_kwh'].toStringAsFixed(0)} kWh',
                  'AI Predicted Output',
                  Icons.bolt,
                  Colors.yellow.shade700,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildInfoCard(
                  theme,
                  isDark,
                  'Eco Impact',
                  '${specs['co2_saved_tons']} Tons',
                  'CO2 Offset / Year',
                  Icons.eco,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ROW 2: Financial Strategy Comparison
          Text(
            'Financial Strategy (Standard vs. Battery)',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Standard System Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Standard Setup',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ROI: ${noBat['payback']} Years',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Invest: €${noBat['invest'].toStringAsFixed(0)} | Save: €${noBat['savings'].toStringAsFixed(0)}/yr',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const Divider(height: 32),
                      _buildDonutChart(
                        (noBat['sc_rate'] as num).toDouble(),
                        theme,
                        'Self-Consumption',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Battery System Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(20), // Highlighted color
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.colorScheme.primary.withAlpha(50), width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.battery_charging_full, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'With Smart Storage',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ROI: ${withBat['payback']} Years',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Invest: €${withBat['invest'].toStringAsFixed(0)} | Save: €${withBat['savings'].toStringAsFixed(0)}/yr',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const Divider(height: 32),
                      _buildDonutChart(
                        (withBat['sc_rate'] as num).toDouble(),
                        theme,
                        'Self-Consumption',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ROW 3: AI Acquisition Roadmap
          Text(
            'AI Acquisition Roadmap',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: adviceList
                  .map(
                    (advice) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 24),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              advice,
                              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    ThemeData theme,
    bool isDark,
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChart(double scRate, ThemeData theme, String title) {
    return SizedBox(
      height: 160,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 35,
                sections: [
                  PieChartSectionData(
                    value: scRate,
                    color: Colors.greenAccent.shade400,
                    title: '${scRate.toStringAsFixed(0)}%',
                    radius: 25,
                    titleStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 12,
                    ),
                  ),
                  PieChartSectionData(
                    value: 100 - scRate,
                    color: Colors.grey.withAlpha(100),
                    title: '',
                    radius: 20,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 12, height: 12, color: Colors.greenAccent.shade400),
                    const SizedBox(width: 8),
                    const Text('Used Internally'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(width: 12, height: 12, color: Colors.grey.withAlpha(100)),
                    const SizedBox(width: 8),
                    const Text('Export to Grid'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    ThemeData theme,
    bool isDark,
    String label,
    String hint,
    TextEditingController controller,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: theme.colorScheme.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
