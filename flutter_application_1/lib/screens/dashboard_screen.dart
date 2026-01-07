import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../providers/energy_data_provider.dart';
import '../providers/notifications_provider.dart';
import '../models/factory.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  final Function(String) onNavigate;
  final String currentFactoryId;

  const DashboardScreen({
    super.key,
    required this.onNavigate,
    required this.currentFactoryId,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const double _chartYAxisInterval = 50.0;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<EnergyDataProvider>(
      builder: (context, energyData, child) {
        final factories = energyData.factories
            .where((f) =>
                f.name.toLowerCase().contains(_searchQuery.toLowerCase()) &&
                f.status != FactoryStatus.storage)
            .toList();

        return Scaffold(
          backgroundColor: const Color(0xFF0a0a0a),
          body: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.grey.shade900.withOpacity(0.5),
                title: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'lib/screens/assets/logo.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Next Gen Power',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        Text(
                          'Factory: ${energyData.currentFactoryName.isNotEmpty ? energyData.currentFactoryName : widget.currentFactoryId}',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: Stack(
                      children: [
                        const Icon(Icons.notifications),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 8,
                              minHeight: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    color: Colors.grey,
                    onPressed: () {
                      _showNotificationPanel(context);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.blur_on),
                    color: Colors.grey,
                    onPressed: () => widget.onNavigate('blockchain'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person),
                    color: Colors.grey,
                    onPressed: () => widget.onNavigate('profile'),
                  ),
                ],
              ),

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search for factories...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade800,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
              ),

              // Today's Energy Balance Chart
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    color: Colors.grey.shade900.withOpacity(0.5),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Today's Energy Balance",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Factory 1 (My Factory)',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () => widget.onNavigate('myFactory'),
                                child: const Text(
                                  'View My Factory',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Green = Surplus | Red = Deficit',
                            style: TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                          const SizedBox(height: 16),
                          // Line chart for generation and consumption
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: _buildEnergyLineChart(energyData),
                          ),
                          const SizedBox(height: 12),
                          // Legend
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Generation',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Consumption',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Available Factories',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              // Factory List
              if (factories.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.factory_outlined,
                            size: 64,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No factories available',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Other factories will appear here once they register on the network',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final factory = factories[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Card(
                        color: Colors.grey.shade900.withOpacity(0.5),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          factory.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.wb_sunny,
                                              size: 16,
                                              color: Colors.yellow,
                                            ),
                                            const SizedBox(width: 4),
                                            const Text(
                                              'Solar Energy',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${factory.distance} km away',
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(factory.status)
                                          .withOpacity(0.2),
                                      border: Border.all(
                                        color: _getStatusColor(factory.status),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getStatusLabel(factory.status),
                                      style: TextStyle(
                                        color: _getStatusColor(factory.status),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade800.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Available',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            '${factory.balance.abs()} kWh',
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Price/kWh',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            '${(0.08 + (index * 0.02)).toStringAsFixed(2)} TEC',
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Capacity',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            '${factory.capacity.solar} kW',
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (factory.status == FactoryStatus.surplus)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      _showBuyEnergyDialog(context, factory);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade600,
                                    ),
                                    icon: const Icon(Icons.shopping_cart,
                                        color: Colors.white),
                                    label: const Text(
                                      'Buy Energy',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              if (factory.status == FactoryStatus.deficit)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      _showSellEnergyDialog(context, factory);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade600,
                                    ),
                                    icon: const Icon(Icons.sell,
                                        color: Colors.white),
                                    label: const Text(
                                      'Sell Energy',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: factories.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(FactoryStatus status) {
    switch (status) {
      case FactoryStatus.surplus:
        return Colors.green;
      case FactoryStatus.deficit:
        return Colors.red;
      case FactoryStatus.storage:
        return Colors.purple;
    }
  }

  String _getStatusLabel(FactoryStatus status) {
    return status.name[0].toUpperCase() + status.name.substring(1);
  }

  Widget _buildEnergyLineChart(EnergyDataProvider energyData) {
    final history = energyData.history;
    
    if (history.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Prepare data points for generation and consumption lines
    final generationSpots = <FlSpot>[];
    final consumptionSpots = <FlSpot>[];
    
    for (int i = 0; i < history.length; i++) {
      generationSpots.add(FlSpot(i.toDouble(), history[i].generation));
      consumptionSpots.add(FlSpot(i.toDouble(), history[i].consumption));
    }

    // Calculate max Y value for the chart using fold for better readability
    final maxDataValue = history.fold<double>(
      0.0,
      (maxVal, data) => math.max(maxVal, math.max(data.generation, data.consumption)),
    );
    // Round up to nearest interval for clean axis labels
    final maxY = ((maxDataValue / _chartYAxisInterval).ceil() * _chartYAxisInterval);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: _chartYAxisInterval,
          verticalInterval: 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade700,
              strokeWidth: 0.5,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.shade700,
              strokeWidth: 0.5,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text(
              'Time (hours ago)',
              style: TextStyle(color: Colors.grey, fontSize: 10),
            ),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 4,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < history.length) {
                  // Calculate hours from most recent: index 0 is oldest data, 
                  // so we reverse to show most recent (0h) on the right side
                  final hoursFromMostRecent = history.length - 1 - index;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      '${hoursFromMostRecent}h',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: const Text(
              'kWh',
              style: TextStyle(color: Colors.grey, fontSize: 10),
            ),
            sideTitles: SideTitles(
              showTitles: true,
              interval: _chartYAxisInterval,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade700),
        ),
        minX: 0,
        maxX: (history.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          // Generation line (green)
          LineChartBarData(
            spots: generationSpots,
            isCurved: true,
            color: Colors.green,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.1),
            ),
          ),
          // Consumption line (orange)
          LineChartBarData(
            spots: consumptionSpots,
            isCurved: true,
            color: Colors.orange,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.orange.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (LineBarSpot spot) => Colors.grey.shade800,
            tooltipRoundedRadius: 8,
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final isGeneration = spot.barIndex == 0;
                return LineTooltipItem(
                  '${isGeneration ? 'Gen' : 'Con'}: ${spot.y.toStringAsFixed(1)} kWh',
                  TextStyle(
                    color: isGeneration ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  void _showNotificationPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: Colors.grey),
            Expanded(
              child: Consumer<NotificationsProvider>(
                builder: (context, notificationsProvider, child) {
                  final notifications = notificationsProvider.notifications;
                  
                  if (notifications.isEmpty) {
                    return Center(
                      child: Text(
                        'No notifications',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return _buildNotificationItem(
                        notification.icon,
                        notification.color,
                        notification.title,
                        notification.message,
                        notification.timeAgo,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    IconData icon,
    Color color,
    String title,
    String message,
    String time,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSellEnergyDialog(BuildContext context, EnergyFactory factory) {
    final factoryNameController = TextEditingController();
    final amountController = TextEditingController();
    final priceController = TextEditingController(text: '0.10');
    String selectedEnergyType = 'Solar';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          double amount = double.tryParse(amountController.text) ?? 0;
          double price = double.tryParse(priceController.text) ?? 0;
          double total = amount * price;

          return AlertDialog(
            backgroundColor: Colors.grey.shade900,
            title: Text(
              'Sell Energy to ${factory.name}',
              style: const TextStyle(color: Colors.white),
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: factoryNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Your Factory Name',
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey.shade800,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Energy Type',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedEnergyType,
                      style: const TextStyle(color: Colors.white),
                      dropdownColor: Colors.grey.shade800,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade800,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: ['Solar', 'Wind', 'Hydro', 'Biomass']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setDialogState(() {
                          selectedEnergyType = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Amount (kWh)',
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey.shade800,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Price per kWh (TEC)',
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey.shade800,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Price:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${total.toStringAsFixed(2)} TEC',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid amount'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  
                  Navigator.pop(context);
                  
                  try {
                    // Create trade via API - current factory sells to the selected factory
                    final tradeId = ApiService.generateTradeId();
                    final result = await ApiService.createTrade(
                      tradeId: tradeId,
                      sellerId: widget.currentFactoryId,
                      buyerId: factory.id,
                      amount: amount,
                      pricePerUnit: price,
                    );
                    
                    if (!context.mounted) return;
                    
                    // Add notification for the buyer factory
                    if (context.mounted) {
                      context.read<NotificationsProvider>().addTradeNotification(
                        tradeId: tradeId,
                        sellerFactoryId: widget.currentFactoryId,
                        sellerFactoryName: factoryNameController.text.isEmpty ? 'Your Factory' : factoryNameController.text,
                        buyerFactoryId: factory.id,
                        buyerFactoryName: factory.name,
                        amount: amount,
                        pricePerUnit: price,
                      );
                    }
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Trade created: ${amount.toStringAsFixed(0)} kWh of $selectedEnergyType at ${price.toStringAsFixed(2)} TEC/kWh to ${factory.name}'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } on ApiException catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.message}'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    // Fallback to local-only mode
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Sell order created (offline): ${amount.toStringAsFixed(0)} kWh of $selectedEnergyType at ${price.toStringAsFixed(2)} TEC/kWh to ${factory.name}'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                ),
                child:
                    const Text('Confirm', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showBuyEnergyDialog(BuildContext context, EnergyFactory factory) {
    final amountController = TextEditingController();
    final priceController = TextEditingController(text: '0.10');
    String selectedDelivery = 'Immediate';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          double amount = double.tryParse(amountController.text) ?? 0;
          double price = double.tryParse(priceController.text) ?? 0;
          double total = amount * price;

          return AlertDialog(
            backgroundColor: Colors.grey.shade900,
            title: Text(
              'Buy Energy from ${factory.name}',
              style: const TextStyle(color: Colors.white),
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: amountController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Amount (kWh)',
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey.shade800,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Price per kWh (TEC)',
                        labelStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey.shade800,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Delivery Time',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedDelivery,
                      style: const TextStyle(color: Colors.white),
                      dropdownColor: Colors.grey.shade800,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade800,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: ['Immediate', 'Within an hour', 'Tomorrow']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setDialogState(() {
                          selectedDelivery = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Price:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${total.toStringAsFixed(2)} TEC',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid amount'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  
                  Navigator.pop(context);
                  
                  try {
                    // Create trade via API - seller factory sells to current factory (buyer)
                    final tradeId = ApiService.generateTradeId();
                    final result = await ApiService.createTrade(
                      tradeId: tradeId,
                      sellerId: factory.id,
                      buyerId: widget.currentFactoryId,
                      amount: amount,
                      pricePerUnit: price,
                    );
                    
                    if (!context.mounted) return;
                    
                    // Add notification for the buyer factory
                    if (context.mounted) {
                      context.read<NotificationsProvider>().addTradeNotification(
                        tradeId: tradeId,
                        sellerFactoryId: factory.id,
                        sellerFactoryName: factory.name,
                        buyerFactoryId: widget.currentFactoryId,
                        buyerFactoryName: 'Your Factory',
                        amount: amount,
                        pricePerUnit: price,
                      );
                    }
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Trade created: Buying ${amount.toStringAsFixed(0)} kWh at ${price.toStringAsFixed(2)} TEC/kWh from ${factory.name}'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } on ApiException catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.message}'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    // Fallback to local-only mode
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Buy order created (offline): ${amount.toStringAsFixed(0)} kWh at ${price.toStringAsFixed(2)} TEC/kWh'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                ),
                child:
                    const Text('Confirm', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }
}
