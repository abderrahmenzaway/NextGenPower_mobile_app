import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onSignOut;
  final VoidCallback onBack;
  final String factoryId;
  final String factoryName;
  final double? currencyBalance;
  final double? availableEnergy;
  final double? dailyConsumption;

  const ProfileScreen({
    super.key,
    required this.onSignOut,
    required this.onBack,
    required this.factoryId,
    required this.factoryName,
    this.currencyBalance,
    this.availableEnergy,
    this.dailyConsumption,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _hederaAccountId;
  double? _tecBalance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFactoryData();
  }

  Future<void> _fetchFactoryData() async {
    try {
      final result = await ApiService.getFactory(widget.factoryId);
      final factoryData = result['data'] as Map<String, dynamic>;
      
      setState(() {
        _hederaAccountId = factoryData['hederaAccountId'] as String?;
        _tecBalance = (factoryData['currencyBalance'] as num?)?.toDouble();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900.withOpacity(0.5),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: widget.onBack,
        ),
        title: Row(
          children: [
            const Icon(Icons.bolt, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Next Gen Power',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  Text(
                    'Account Settings',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Header
          Card(
            color: Colors.grey.shade900.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade600,
                          Colors.purple.shade600,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.factory, size: 32, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.factoryName.isNotEmpty ? widget.factoryName : widget.factoryId,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Factory ID: ${widget.factoryId}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        if (_hederaAccountId != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.verified, color: Colors.blue, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Hedera ID: $_hederaAccountId',
                                  style: const TextStyle(color: Colors.blueAccent, fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Energy Details
          Card(
            color: Colors.grey.shade900.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bolt, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Energy Details',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfrastructureRow(
                    Icons.flash_on,
                    Colors.green,
                    'Available Energy',
                    '${widget.availableEnergy?.toStringAsFixed(1) ?? '0.0'} kWh',
                  ),
                  const Divider(color: Colors.grey, height: 24),
                  _buildInfrastructureRow(
                    Icons.power,
                    Colors.orange,
                    'Daily Consumption',
                    '${widget.dailyConsumption?.toStringAsFixed(1) ?? '0.0'} kWh',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Wallet Details
          Card(
            color: Colors.grey.shade900.withOpacity(0.5),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade600.withOpacity(0.2),
                    Colors.purple.shade600.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.shade600.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.account_balance_wallet, color: Colors.blueAccent, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Wallet Details',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'TEC Coin',
                          style: TextStyle(color: Colors.blueAccent, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Currency Balance',
                              style: TextStyle(
                                color: Colors.blue.shade300,
                                fontSize: 12,
                              ),
                            ),
                            _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    '${_tecBalance?.toStringAsFixed(2) ?? widget.currencyBalance?.toStringAsFixed(2) ?? '0.00'} TEC',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_hederaAccountId != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance, color: Colors.blueAccent, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Hedera Account',
                                  style: TextStyle(color: Colors.grey, fontSize: 10),
                                ),
                                Text(
                                  _hederaAccountId!,
                                  style: const TextStyle(
                                    color: Colors.blueAccent,
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Notification Preferences
          Card(
            color: Colors.grey.shade900.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notifications, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Notification Preferences',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSwitchRow(
                    'Energy Alerts',
                    'Low energy and surplus notifications',
                    true,
                  ),
                  const SizedBox(height: 12),
                  _buildSwitchRow(
                    'Trade Offers',
                    'New trading opportunities',
                    true,
                  ),
                  const SizedBox(height: 12),
                  _buildSwitchRow(
                    'Price Alerts',
                    'Below/above threshold notifications',
                    false,
                  ),
                  const SizedBox(height: 12),
                  _buildSwitchRow(
                    'Contract Executions',
                    'Smart contract activity',
                    true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Auto-Trading Rules
          Card(
            color: Colors.grey.shade900.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.settings, color: Colors.purple, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Auto-Trading Rules',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                      Switch(
                        value: true,
                        onChanged: (val) {},
                        activeThumbColor: Colors.blue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto-Sell Surplus',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Automatically sell when surplus exceeds 50 kWh at min 0.10 TEC/kWh',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto-Buy Deficit',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Automatically buy when deficit exceeds 20 kWh at max 0.15 TEC/kWh',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                    ),
                    child: const Center(
                      child: Text(
                        'Configure Rules',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Security Settings
          Card(
            color: Colors.grey.shade900.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Security Settings',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSwitchRow(
                    'Two-Factor Authentication',
                    'Extra security for your account',
                    true,
                  ),
                  const SizedBox(height: 12),
                  _buildSwitchRow(
                    'Biometric Login',
                    'Use fingerprint or face ID',
                    true,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                    ),
                    child: const Center(
                      child: Text(
                        'Change Password',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Account Statistics
          Card(
            color: Colors.grey.shade900.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account Statistics',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Member Since',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const Text(
                              'Jan 2024',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Trades',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const Text(
                              '342',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Energy Traded',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const Text(
                              '12,847 kWh',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Savings',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const Text(
                              '4,283 TEC',
                              style: TextStyle(color: Colors.greenAccent),
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
          const SizedBox(height: 16),

          // Action Buttons
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.grey),
            ),
            child: const Center(
              child: Text(
                'Export Report',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.grey),
            ),
            child: const Center(
              child: Text(
                'Help & Support',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: widget.onSignOut,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
            ),
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Sign Out',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfrastructureRow(
    IconData icon,
    Color color,
    String label,
    String value,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildSwitchRow(String title, String subtitle, bool value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: (val) {},
          activeThumbColor: Colors.blue,
        ),
      ],
    );
  }
}
