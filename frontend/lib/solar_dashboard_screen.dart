import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/custom_app_bar.dart';
import 'package:http/http.dart' as http;

class SolarDashboardScreen extends StatefulWidget {
  const SolarDashboardScreen({super.key, required this.themeNotifier});
  final ValueNotifier<ThemeMode> themeNotifier;

  @override
  State<SolarDashboardScreen> createState() => _SolarDashboardScreenState();
}

class _SolarDashboardScreenState extends State<SolarDashboardScreen> {
  // --- 1. CONTROLLERS & STATE VARIABLES ---
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _gridPriceController = TextEditingController(text: '35.0');

  // 🔥 THE MISSING FIELDS
  final TextEditingController _billController = TextEditingController(text: '120');
  String _residents = '3';
  String _energyRating = 'D';

  bool _isLoading = false;
  Map<String, dynamic>? _solarData;

  bool _isFormValid = false;
  String _formErrorMessage = '';

  // --- 2. CLOUD BACKEND URL ---
  String get _apiUrl {
    return 'https://energy-twin-de.onrender.com/simulate_solar';
  }

  // --- 3. LIFECYCLE & LISTENERS ---
  @override
  void initState() {
    super.initState();
    _addressController.addListener(_onFieldChanged);
    _gridPriceController.addListener(_onFieldChanged);
    _billController.addListener(_onFieldChanged); // Listen to new bill field
  }

  @override
  void dispose() {
    _addressController.dispose();
    _gridPriceController.dispose();
    _billController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (_formErrorMessage.isNotEmpty) {
      setState(() => _formErrorMessage = '');
    }

    // Now requires address, grid price, AND bill to be filled
    final isValid =
        _addressController.text.trim().isNotEmpty &&
        _gridPriceController.text.trim().isNotEmpty &&
        _billController.text.trim().isNotEmpty;

    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  // --- 4. THE API CALL ---
  Future<void> _fetchSatelliteFeed() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _formErrorMessage = '';
      _solarData = null;
    });

    try {
      final double gridPrice = double.tryParse(_gridPriceController.text.trim()) ?? 35.0;
      final double monthlyBill = double.tryParse(_billController.text.trim()) ?? 120.0;
      final int residentsCount = int.tryParse(_residents.replaceAll('+', '')) ?? 3;

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'address': _addressController.text.trim(),
          'energy_rating': _energyRating,
          'grid_price_ct_kwh': gridPrice,
         // 'monthly_bill_eur': monthlyBill, // 🔥 Added to payload
         // 'number_of_residents': residentsCount, // 🔥 Added to payload
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _solarData = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        // 🔥 SMART ERROR LOGGING: Now it will tell you if the Python server crashed!
        print('Server Error: ${response.statusCode} - ${response.body}');

        setState(() {
          // Attempt to show the actual error from the backend, otherwise fallback
          try {
            final errorBody = jsonDecode(response.body);
            _formErrorMessage =
                errorBody['error'] ??
                'Server error (${response.statusCode}). Check address format.';
          } catch (_) {
            _formErrorMessage =
                'Server Error ${response.statusCode}: Your backend might be crashing.';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      print('🔥 CRITICAL NETWORK ERROR: $e');
      setState(() {
        _formErrorMessage = 'Failed to connect to the server. Check your internet.';
        _isLoading = false;
      });
    }
  }

  // --- 5. THE UI BUILDER ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(themeNotifier: widget.themeNotifier, title: 'Solar Rooftop AI'),
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
                    if (_solarData != null) _buildRichResults(theme, isDark),
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
            'Property Scanning',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // --- ROW 1: Address Input ---
          TextField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'Property Address',
              prefixIcon: const Icon(Icons.location_on),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),

          // --- ROW 2: Energy Rating & Grid Price ---
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _energyRating,
                  decoration: InputDecoration(
                    labelText: 'Energy Rating',
                    prefixIcon: const Icon(Icons.home_work),
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
                    prefixIcon: const Icon(Icons.bolt),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // --- ROW 3: Monthly Bill & Residents (THE MISSING FIELDS) ---
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _billController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Monthly Bill (€)',
                    prefixIcon: const Icon(Icons.euro),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _residents,
                  decoration: InputDecoration(
                    labelText: 'Residents',
                    prefixIcon: const Icon(Icons.people),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: ['1', '2', '3', '4', '5', '6+'].map((String val) {
                    return DropdownMenuItem(value: val, child: Text('$val Person(s)'));
                  }).toList(),
                  onChanged: (val) => setState(() => _residents = val!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // --- SMART ERROR MESSAGE ---
          if (_formErrorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                _formErrorMessage,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),

          // --- FETCH BUTTON ---
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: (_isFormValid && !_isLoading) ? _fetchSatelliteFeed : null,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.satellite_alt),
              label: const Text(
                'Fetch Satellite Feed',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                disabledBackgroundColor: theme.colorScheme.onSurface.withAlpha(30),
                disabledForegroundColor: theme.colorScheme.onSurface.withAlpha(100),
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
    final aiConfidence = _solarData!['ai_confidence_score'] ?? 'High';
    final annualGeneration = _solarData!['annual_generation_kwh'] ?? 0;
    final estimatedSavings = _solarData!['estimated_yearly_savings_eur'] ?? 0;
    final recommendedKw = _solarData!['recommended_system_kw'] ?? 0.0;
    final roiYears = _solarData!['roi_years'] ?? 0.0;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.orange.withAlpha(25),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.orange.withAlpha(75)),
          ),
          child: Column(
            children: [
              const Text(
                'Estimated Annual Savings',
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                '€$estimatedSavings',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              Text('System pays for itself in $roiYears Years', style: theme.textTheme.titleMedium),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildDataCard(theme, isDark, Icons.solar_power, 'System Specs', [
                'Recommended Size: $recommendedKw kWp',
                'Est. Generation: $annualGeneration kWh/yr',
                'Energy Rating: Class $_energyRating',
                'Household Size: $_residents Residents',
              ]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDataCard(theme, isDark, Icons.memory, 'AI Analysis', [
                'Confidence Score: $aiConfidence',
                'Grid Price Factored: ${_gridPriceController.text} ct/kWh',
                'Current Bill Factored: €${_billController.text}/mo',
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
              Icon(icon, color: theme.colorScheme.primary, size: 24),
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
}
