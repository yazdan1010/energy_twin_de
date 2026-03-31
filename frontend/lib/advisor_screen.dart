import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/custom_app_bar.dart';
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

  String get _apiUrl {
    // 🔥 Updated from local IP to Render URL
    return 'https://energy-twin-de.onrender.com/simulate_investment';
  }

  // 🔥 PRESENTATION MAGIC: Auto-calculates the gas bill based on size and insulation
  void _updateEstimatedBill() {
    double multiplier = 1.5; // Average insulation baseline
    if (_insulationLevel == 'poor') multiplier = 2.0; // Needs more heating
    if (_insulationLevel == 'good') multiplier = 1.0; // Highly efficient

    // Instantly update the text field
    _gasBillController.text = (_houseSize * multiplier).toStringAsFixed(0);
  }

  Future<void> _calculateROI() async {
    final inputString = _gasBillController.text.trim();
    final double? userBill = double.tryParse(inputString);
    if (userBill == null || userBill <= 0) {
      setState(() => _errorMessage = 'Please enter a valid monthly bill.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _roiData = null;
    });

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'monthly_gas_bill_eur': userBill,
          'house_size_sqm': _houseSize,
          'insulation_level': _insulationLevel,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() => _roiData = jsonDecode(response.body));
      } else {
        setState(() => _errorMessage = 'API Error: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Connection failed. Is Flask running?');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
      appBar: CustomAppBar(themeNotifier: widget.themeNotifier, title: 'Home Energy Audit'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(24.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildInputSection(theme, isDark),
                    const SizedBox(height: 32),
                    if (_errorMessage.isNotEmpty) _buildErrorCard(theme),
                    if (_roiData != null) _buildRichResults(theme, isDark),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 10),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Property Details',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Row 1: Gas Bill & Insulation
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _gasBillController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Monthly Gas Bill (€)',
                    prefixIcon: const Icon(Icons.euro),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _insulationLevel,
                  decoration: InputDecoration(
                    labelText: 'Insulation Quality',
                    prefixIcon: const Icon(Icons.home_work),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'poor', child: Text('Poor (Old Windows)')),
                    DropdownMenuItem(value: 'average', child: Text('Average (Standard)')),
                    DropdownMenuItem(value: 'good', child: Text('Good (Modern/Renovated)')),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _insulationLevel = val!;
                      _updateEstimatedBill(); // 🔥 Instantly updates the bill based on insulation
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Row 2: House Size Slider
          Text('House Size: ${_houseSize.toInt()} m²', style: theme.textTheme.titleMedium),
          Slider(
            value: _houseSize,
            min: 50,
            max: 300,
            divisions: 25,
            activeColor: theme.colorScheme.primary,
            onChanged: (val) {
              setState(() {
                _houseSize = val;
                _updateEstimatedBill(); // 🔥 Instantly updates the bill while dragging
              });
            },
          ),
          const SizedBox(height: 32),

          // Calculate Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _calculateROI,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: const Text(
                'Run Digital Twin Simulation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRichResults(ThemeData theme, bool isDark) {
    return Column(
      children: [
        // BIG Savings Highlight
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.primary.withAlpha(75)),
          ),
          child: Column(
            children: [
              Text(
                'AI-Optimized Annual Savings',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '€${_roiData!['ai_annual_savings_eur']}',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'System pays for itself in ${_roiData!['estimated_roi_years']} Years',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Data Cards Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildDataCard(theme, isDark, Icons.thermostat, 'System Specs', [
                'Thermal Demand: ${_roiData!['heat_demand_kwh']} kWh',
                'Est. Efficiency (COP): ${_roiData!['cop_estimated']}',
                'Electricity Used: ${_roiData!['hp_electricity_kwh']} kWh',
              ]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDataCard(theme, isDark, Icons.euro, 'Financial Breakdown', [
                'Old Gas Cost: €${_roiData!['current_yearly_gas_cost_eur']} / yr',
                'New Elec Cost: €${_roiData!['smart_heatpump_cost_eur']} / yr',
                'EnergyTwin AI shifted usage to off-peak hours.',
              ]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDataCard(theme, isDark, Icons.eco, 'Environmental Impact', [
                'CO2 Eliminated:',
                '${_roiData!['co2_saved_kg']} kg / yr',
                'Equivalent to planting ~${(_roiData!['co2_saved_kg'] / 21).toInt()} trees annually.',
              ]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDataCard(
    ThemeData theme,
    bool isDark,
    IconData icon,
    String title,
    List<String> lines,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.secondary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                line,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white70 : Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent)),
    );
  }
}