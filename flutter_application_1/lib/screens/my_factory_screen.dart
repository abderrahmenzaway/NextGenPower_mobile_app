import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/energy_data_provider.dart';
import '../widgets/energy_gauge.dart';
import '../services/api_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class MyFactoryScreen extends StatefulWidget {
  final Function(String) onNavigate;
  final String factoryId;
  final String factoryName;

  const MyFactoryScreen({
    super.key,
    required this.onNavigate,
    required this.factoryId,
    required this.factoryName,
  });

  @override
  State<MyFactoryScreen> createState() => _MyFactoryScreenState();
}

class _MyFactoryScreenState extends State<MyFactoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Configuration constants
  static const double _anomalyProbability = 0.15; // 15% chance of anomaly in mock data
  static const double _lowRiskThreshold = 0.05;   // Reconstruction error threshold for low risk
  static const double _mediumRiskThreshold = 0.1;  // Reconstruction error threshold for medium risk
  
  // NILM prediction state (Model 1)
  Map<String, double>? _nilmPredictions;
  bool _isLoadingPredictions = false;
  String? _predictionError;
  
  // Model 2 (Predictive Maintenance) state
  Map<String, Map<String, dynamic>>? _model2Predictions;
  bool _isLoadingModel2 = false;
  String? _model2Error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchNilmPredictions();
    _fetchModel2Predictions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  /// Generates mock aggregate sequence data (288 values for 24 hours at 5-minute intervals)
List<double> _generateMockAggregateSequence() {
  final random = Random();

  return List.generate(288, (index) {
    // Hour of day
    int hour = ((index * 5) ~/ 60) % 24;

    // Base load slightly different
    double baseLoad = 140.0 + random.nextDouble() * 5.0; // small drift

    // Time-of-day variation (different pattern)
    double timeVariation;
    if (hour >= 7 && hour <= 17) {
      timeVariation = 110 + sin(index / 15) * 10; // daytime peak + wave
    } else if (hour >= 18 && hour <= 22) {
      timeVariation = 60 + sin(index / 20) * 6;  // evening moderate
    } else {
      timeVariation = 20 + sin(index / 25) * 5;  // night low
    }

    // Softer random fluctuation
    double randomVariation = random.nextDouble() * 15;

    // Slight upward trend
    double trend = index * 0.45;

    return baseLoad + timeVariation + randomVariation + trend;
  });
}

  /// Fetches NILM predictions from the backend
  Future<void> _fetchNilmPredictions() async {
    if (_isLoadingPredictions) return;
    
    setState(() {
      _isLoadingPredictions = true;
      _predictionError = null;
    });
    
    try {
      final mockData = _generateMockAggregateSequence();
      final response = await ApiService.getNilmPredictions(
        aggregateSequence: mockData,
      );
      
      if (response['status'] == 'success' && response['predictions'] != null) {
        final predictions = response['predictions'] as Map<String, dynamic>;
        setState(() {
         _nilmPredictions = {
            'BA': ((predictions['BA'] as num?)?.toDouble() ?? 0.0) * 100,
            'CHP': ((predictions['CHP'] as num?)?.toDouble() ?? 0.0) * 100,
            'CS': ((predictions['CS'] as num?)?.toDouble() ?? 0.0) * 100,
            'EVSE': ((predictions['EVSE'] as num?)?.toDouble() ?? 0.0) * 100,
            'PV': ((predictions['PV'] as num?)?.toDouble() ?? 0.0) * 100,
          };
          _isLoadingPredictions = false;
        });
      } else {
        setState(() {
          _predictionError = 'Invalid response from server';
          _isLoadingPredictions = false;
        });
      }
    } catch (e) {
      setState(() {
        _predictionError = e.toString();
        _isLoadingPredictions = false;
      });
    }
  }

  /// Generates mock sensor data for Model 2 (Predictive Maintenance)
  /// Returns sensor values for: air_temperature, process_temperature, rotational_speed, torque, tool_wear
  Map<String, dynamic> _generateMockSensorData(String machineKey) {
    final random = Random();
    
    // Different sensor profiles for each machine type
    switch (machineKey) {
      case 'BA': // Battery Array - moderate temp, low speed
        return {
          'air_temperature': 295.0 + random.nextDouble() * 10,
          'process_temperature': 305.0 + random.nextDouble() * 15,
          'rotational_speed': 1200 + random.nextInt(300),
          'torque': 25.0 + random.nextDouble() * 15,
          'tool_wear': 50 + random.nextInt(100),
          'type_H': 0,
          'type_L': 1,
          'type_M': 0,
        };
      case 'CHP': // Combined Heat & Power - high temp, high torque
        return {
          'air_temperature': 305.0 + random.nextDouble() * 15,
          'process_temperature': 320.0 + random.nextDouble() * 20,
          'rotational_speed': 1800 + random.nextInt(400),
          'torque': 50.0 + random.nextDouble() * 20,
          'tool_wear': 80 + random.nextInt(120),
          'type_H': 1,
          'type_L': 0,
          'type_M': 0,
        };
      case 'CS': // Charging Station - moderate profile
        return {
          'air_temperature': 298.0 + random.nextDouble() * 8,
          'process_temperature': 308.0 + random.nextDouble() * 12,
          'rotational_speed': 1400 + random.nextInt(300),
          'torque': 35.0 + random.nextDouble() * 15,
          'tool_wear': 40 + random.nextInt(80),
          'type_H': 0,
          'type_L': 0,
          'type_M': 1,
        };
      case 'EVSE': // Electric Vehicle Supply - variable load
        return {
          'air_temperature': 300.0 + random.nextDouble() * 12,
          'process_temperature': 312.0 + random.nextDouble() * 15,
          'rotational_speed': 1500 + random.nextInt(500),
          'torque': 40.0 + random.nextDouble() * 20,
          'tool_wear': 60 + random.nextInt(100),
          'type_H': 0,
          'type_L': 0,
          'type_M': 1,
        };
      case 'PV': // Photovoltaic System - low stress profile
        return {
          'air_temperature': 292.0 + random.nextDouble() * 6,
          'process_temperature': 302.0 + random.nextDouble() * 10,
          'rotational_speed': 1000 + random.nextInt(200),
          'torque': 20.0 + random.nextDouble() * 10,
          'tool_wear': 30 + random.nextInt(60),
          'type_H': 0,
          'type_L': 1,
          'type_M': 0,
        };
      default:
        return {
          'air_temperature': 300.0,
          'process_temperature': 310.0,
          'rotational_speed': 1500,
          'torque': 40.0,
          'tool_wear': 100,
          'type_H': 0,
          'type_L': 1,
          'type_M': 0,
        };
    }
  }

  /// Fetches Model 2 (Predictive Maintenance) predictions for all machines
  Future<void> _fetchModel2Predictions() async {
    if (_isLoadingModel2) return;
    
    setState(() {
      _isLoadingModel2 = true;
      _model2Error = null;
    });
    
    final machines = ['BA', 'CHP', 'CS', 'EVSE', 'PV'];
    final Map<String, Map<String, dynamic>> predictions = {};
    
    try {
      for (final machine in machines) {
        final sensorData = _generateMockSensorData(machine);
        
        try {
          final response = await ApiService.getModel2Prediction(
            airTemperature: sensorData['air_temperature'] as double,
            processTemperature: sensorData['process_temperature'] as double,
            rotationalSpeed: (sensorData['rotational_speed'] as int).toDouble(),
            torque: sensorData['torque'] as double,
            toolWear: (sensorData['tool_wear'] as int).toDouble(),
            typeH: sensorData['type_H'] as int,
            typeL: sensorData['type_L'] as int,
            typeM: sensorData['type_M'] as int,
          );
          
          if (response['success'] == true && response['data'] != null) {
            final data = response['data'] as Map<String, dynamic>;
            predictions[machine] = {
              'isAnomaly': data['is_anomaly'] ?? false,
              'failureType': data['predicted_failure_type'] ?? 'Unknown',
              'confidence': data['confidence'] ?? '0%',
              'probability': data['probability'] ?? 0.0,
              'reconstructionError': data['reconstruction_error'] ?? 0.0,
            };
          }
        } catch (e) {
          // If individual machine fails, use mock data
          predictions[machine] = _generateMockModel2Data(machine);
        }
      }
      
      setState(() {
        _model2Predictions = predictions;
        _isLoadingModel2 = false;
      });
    } catch (e) {
      // If all fails, generate mock data for all machines
      for (final machine in machines) {
        predictions[machine] = _generateMockModel2Data(machine);
      }
      setState(() {
        _model2Predictions = predictions;
        _model2Error = 'Using simulated data (API unavailable)';
        _isLoadingModel2 = false;
      });
    }
  }

  /// Generates mock Model 2 data when API is unavailable
  Map<String, dynamic> _generateMockModel2Data(String machineKey) {
    final random = Random();
    
    // Different failure profiles for each machine
    final failureTypes = [
      'No Failure',
      'Heat Dissipation Failure',
      'Power Failure',
      'Overstrain Failure',
      'Tool Wear Failure',
      'Random Failure',
    ];
    
    // Probability of anomaly (using class constant)
    final isAnomaly = random.nextDouble() < _anomalyProbability;
    
    String failureType;
    double probability;
    double reconstructionError;
    
    if (isAnomaly) {
      // If anomaly, pick a failure type (not "No Failure")
      failureType = failureTypes[1 + random.nextInt(failureTypes.length - 1)];
      probability = 0.5 + random.nextDouble() * 0.4; // 50-90%
      reconstructionError = _mediumRiskThreshold + 0.05 + random.nextDouble() * 0.3; // Above medium threshold
    } else {
      failureType = 'No Failure';
      probability = 0.85 + random.nextDouble() * 0.14; // 85-99%
      reconstructionError = random.nextDouble() * _lowRiskThreshold * 1.5; // Below low threshold mostly
    }
    
    return {
      'isAnomaly': isAnomaly,
      'failureType': failureType,
      'confidence': '${(probability * 100).toStringAsFixed(1)}%',
      'probability': probability,
      'reconstructionError': reconstructionError,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnergyDataProvider>(
      builder: (context, energyData, child) {
        final current = energyData.currentData;

        return Scaffold(
          backgroundColor: const Color(0xFF0a0a0a),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.grey.shade900.withOpacity(0.5),
                title: Row(
                  children: [
                    const Icon(Icons.factory, color: Colors.blue),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.factoryName.isNotEmpty ? widget.factoryName : widget.factoryId,
                          style: const TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        Text(
                          'ID: ${widget.factoryId}',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.blue,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Machines'),
                    Tab(text: 'Impact'),
                  ],
                ),
              ),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(current),
                    _buildMachinesTab(),
                    _buildImpactTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab(dynamic current) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Current Status
        Card(
          color: Colors.grey.shade900.withOpacity(0.5),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Status',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: EnergyGauge(
                        value: current.generation,
                        max: 300,
                        label: 'Generation',
                        color: Colors.green,
                        unit: 'kW',
                      ),
                    ),
                    Expanded(
                      child: EnergyGauge(
                        value: current.consumption,
                        max: 300,
                        label: 'Consumption',
                        color: Colors.orange,
                        unit: 'kW',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.bolt,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Balance',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${current.balance >= 0 ? '+' : ''}${current.balance.round()} kW',
                              style: TextStyle(
                                color: current.balance >= 0
                                    ? Colors.green
                                    : Colors.red,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.battery_charging_full,
                                  color: Colors.purple,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Battery',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${current.batteryLevel.round()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Energy Sources
        Card(
          color: Colors.grey.shade900.withOpacity(0.5),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Energy Sources',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Icon(Icons.wb_sunny, color: Colors.orange, size: 32),
                        const SizedBox(height: 8),
                        const Text(
                          'Solar',
                          style: TextStyle(color: Colors.white),
                        ),
                        const Text(
                          '60%',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(Icons.air, color: Colors.blue, size: 32),
                        const SizedBox(height: 8),
                        const Text(
                          'Wind',
                          style: TextStyle(color: Colors.white),
                        ),
                        const Text(
                          '30%',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(Icons.directions_walk, color: Colors.purple, size: 32),
                        const SizedBox(height: 8),
                        const Text(
                          'Footstep',
                          style: TextStyle(color: Colors.white),
                        ),
                        const Text(
                          '10%',
                          style: TextStyle(
                            color: Colors.purple,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Today's Summary
        Card(
          color: Colors.grey.shade900.withOpacity(0.5),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Summary",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSummaryRow('Total Generated', '${current.todayGenerated} kWh'),
                _buildSummaryRow('Total Consumed', '${current.todayConsumed} kWh'),
                _buildSummaryRow('Energy Traded', '${current.todayTraded} kWh'),
                const Divider(color: Colors.grey),
                _buildSummaryRow(
                  'Cost Savings',
                  '${current.costSavings} TEC',
                  valueColor: Colors.green,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMachinesTab() {
    // Machine configuration with full names and colors for the 5 NILM model outputs
    final machineConfig = {
      'BA': {'fullName': 'Battery Array', 'color': Colors.purple, 'icon': Icons.battery_charging_full},
      'CHP': {'fullName': 'Combined Heat & Power', 'color': Colors.orange, 'icon': Icons.local_fire_department},
      'CS': {'fullName': 'Charging Station', 'color': Colors.blue, 'icon': Icons.ev_station},
      'EVSE': {'fullName': 'Electric Vehicle Supply', 'color': Colors.green, 'icon': Icons.electric_car},
      'PV': {'fullName': 'Photovoltaic System', 'color': Colors.yellow, 'icon': Icons.wb_sunny},
    };
    
    // Handle loading state - show loader if either model is still loading
    if (_isLoadingPredictions || _isLoadingModel2) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Loading machine data from AI models...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    // Handle error state
    if (_predictionError != null && _nilmPredictions == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load predictions',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _predictionError!,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _fetchNilmPredictions();
                _fetchModel2Predictions();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
            ),
          ],
        ),
      );
    }
    
    // Build machine data from NILM predictions
    final List<Map<String, dynamic>> machineData = [];
    if (_nilmPredictions != null) {
      for (final entry in _nilmPredictions!.entries) {
        final config = machineConfig[entry.key];
        if (config != null) {
          // Use absolute value for consumption display
          // Generation (negative values like PV, CHP) are shown as positive generation
          machineData.add({
            'key': entry.key,
            'name': config['fullName'] as String,
            'consumption': entry.value.abs(),
            'isGeneration': entry.value < 0,
            'color': config['color'] as Color,
            'icon': config['icon'] as IconData,
          });
        }
      }
    }
    
    // Calculate total consumption (sum of absolute values)
    final totalConsumption = machineData.fold<double>(
      0.0,
      (sum, m) => sum + (m['consumption'] as double),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header with refresh button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI-Powered Analysis',
                  style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                if (_model2Error != null)
                  Text(
                    _model2Error!,
                    style: const TextStyle(color: Colors.amber, fontSize: 10),
                  ),
              ],
            ),
            IconButton(
              onPressed: () {
                _fetchNilmPredictions();
                _fetchModel2Predictions();
              },
              icon: const Icon(Icons.refresh, color: Colors.blue, size: 20),
              tooltip: 'Refresh predictions',
            ),
          ],
        ),
        Card(
          color: Colors.grey.shade900.withOpacity(0.5),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Machine Consumption Overview',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Power Flow',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        '${totalConsumption.toStringAsFixed(1)} kW',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (machineData.isNotEmpty)
                  SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 0,
                        sections: machineData.map((machine) {
                          final consumption = machine['consumption'] as double;
                          final color = machine['color'] as Color;
                          final percentage = totalConsumption > 0 
                              ? (consumption / totalConsumption * 100) 
                              : 0.0;
                          return PieChartSectionData(
                            value: consumption,
                            title: '${percentage.toStringAsFixed(0)}%',
                            color: color,
                            radius: 100,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Machine Details',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...machineData.map((machine) {
          final key = machine['key'] as String;
          final name = machine['name'] as String;
          final consumption = machine['consumption'] as double;
          final isGeneration = machine['isGeneration'] as bool;
          final color = machine['color'] as Color;
          final icon = machine['icon'] as IconData;
          final percentage = totalConsumption > 0 
              ? (consumption / totalConsumption * 100) 
              : 0.0;
          
          // Get Model 2 data for this machine
          final model2Data = _model2Predictions?[key];
          final isAnomaly = model2Data?['isAnomaly'] as bool? ?? false;
          final failureType = model2Data?['failureType'] as String? ?? 'Loading...';
          final confidence = model2Data?['confidence'] as String? ?? '--';
          final reconstructionError = model2Data?['reconstructionError'] as double? ?? 0.0;
          
          // Calculate risk level based on reconstruction error thresholds
          String riskLevel;
          Color riskColor;
          if (reconstructionError < _lowRiskThreshold) {
            riskLevel = 'Low';
            riskColor = Colors.green;
          } else if (reconstructionError < _mediumRiskThreshold) {
            riskLevel = 'Medium';
            riskColor = Colors.amber;
          } else {
            riskLevel = 'High';
            riskColor = Colors.red;
          }
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              color: Colors.grey.shade900.withOpacity(0.5),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Machine header row with energy info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(icon, color: color, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade800,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        key,
                                        style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      isGeneration ? Icons.arrow_upward : Icons.arrow_downward,
                                      color: isGeneration ? Colors.green : Colors.orange,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isGeneration ? 'Generating' : 'Consuming',
                                      style: TextStyle(
                                        color: isGeneration ? Colors.green : Colors.orange,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${consumption.toStringAsFixed(1)} kW',
                              style: TextStyle(
                                color: isGeneration ? Colors.green : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: const TextStyle(color: Colors.grey, fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Energy progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade700,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    // Model 2: Predictive Maintenance Info
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isAnomaly 
                            ? Colors.red.withOpacity(0.1) 
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isAnomaly 
                              ? Colors.red.withOpacity(0.3) 
                              : Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Status row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isAnomaly ? Icons.warning_amber_rounded : Icons.check_circle,
                                    color: isAnomaly ? Colors.red : Colors.green,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isAnomaly ? 'At Risk' : 'Normal',
                                    style: TextStyle(
                                      color: isAnomaly ? Colors.red : Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: riskColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Risk: $riskLevel',
                                  style: TextStyle(
                                    color: riskColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Failure type and confidence
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Prediction',
                                      style: TextStyle(color: Colors.grey, fontSize: 9),
                                    ),
                                    Text(
                                      failureType,
                                      style: TextStyle(
                                        color: isAnomaly ? Colors.amber : Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Confidence',
                                    style: TextStyle(color: Colors.grey, fontSize: 9),
                                  ),
                                  Text(
                                    confidence,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildImpactTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.grey.shade900.withOpacity(0.5),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade600.withOpacity(0.2),
                  Colors.blue.shade600.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green.shade600.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Environmental Impact This Month',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.eco, color: Colors.green, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'CO₂ Saved',
                                  style: TextStyle(color: Colors.grey, fontSize: 10),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              '12.4 tons',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '≈ 287 trees planted',
                              style: TextStyle(color: Colors.grey, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.water_drop, color: Colors.blue, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Water Saved',
                                  style: TextStyle(color: Colors.grey, fontSize: 10),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              '45k L',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '≈ 180 bathtubs',
                              style: TextStyle(color: Colors.grey, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.factory, color: Colors.grey, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Coal Avoided',
                            style: TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '5,600 kg',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Equivalent to not burning coal',
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: Colors.grey.shade900.withOpacity(0.5),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sustainability Achievements',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🌱', style: TextStyle(fontSize: 32)),
                          SizedBox(height: 4),
                          Text(
                            'Green Champion',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            '30 days clean energy',
                            style: TextStyle(color: Colors.grey, fontSize: 9),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('💧', style: TextStyle(fontSize: 32)),
                          SizedBox(height: 4),
                          Text(
                            'Water Saver',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            '45k liters saved',
                            style: TextStyle(color: Colors.grey, fontSize: 9),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.yellow.withOpacity(0.1),
                        border: Border.all(
                          color: Colors.yellow.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('⚡', style: TextStyle(fontSize: 32)),
                          SizedBox(height: 4),
                          Text(
                            'Energy Trader',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            '100+ trades completed',
                            style: TextStyle(color: Colors.grey, fontSize: 9),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        border: Border.all(
                          color: Colors.purple.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🌍', style: TextStyle(fontSize: 32)),
                          SizedBox(height: 4),
                          Text(
                            'Earth Guardian',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            '12 tons CO₂ reduced',
                            style: TextStyle(color: Colors.grey, fontSize: 9),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
