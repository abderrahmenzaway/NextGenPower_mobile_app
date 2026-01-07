import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/energy_data.dart';
import '../models/factory.dart';
import '../models/energy_offer.dart';
import '../models/trade.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class EnergyDataProvider extends ChangeNotifier {
  // Current factory information
  String _currentFactoryId = '';
  String _currentFactoryName = '';
  
  // Notification service reference
  NotificationService? _notificationService;
  
  // Daily consumption and available energy for alerts
  double? _dailyConsumption;
  double? _availableEnergy;
  
  // Energy alert state tracking to prevent spam
  DateTime? _lastLowEnergyAlert;
  DateTime? _lastSurplusAlert;
  static const Duration _alertCooldown = Duration(hours: 1);
  
  CurrentEnergyData _currentData = CurrentEnergyData(
    generation: 245,
    consumption: 198,
    balance: 47,
    todayGenerated: 1834,
    todayConsumed: 1567,
    todayTraded: 423,
    costSavings: 1247,
    batteryLevel: 78,
  );

  List<EnergyData> _history = [];
  List<EnergyFactory> _factories = [];
  List<EnergyOffer> _offers = [];
  List<Trade> _trades = [];

  Timer? _timer;

  EnergyDataProvider() {
    _initializeData();
    _startUpdates();
  }

  // Getters
  String get currentFactoryId => _currentFactoryId;
  String get currentFactoryName => _currentFactoryName;
  CurrentEnergyData get currentData => _currentData;
  List<EnergyData> get history => _history;
  List<EnergyFactory> get factories => _factories;
  List<EnergyOffer> get offers => _offers;
  List<Trade> get trades => _trades;

  /// Set notification service reference
  void setNotificationService(NotificationService service) {
    _notificationService = service;
  }

  /// Set the current factory after login/registration
  void setCurrentFactory(String factoryId, String factoryName) {
    _currentFactoryId = factoryId;
    _currentFactoryName = factoryName;
    notifyListeners();
    
    // Try to fetch data from API
    _fetchFactoryData();
  }

  /// Fetch factory data from API
  Future<void> _fetchFactoryData() async {
    try {
      // Try to fetch current factory data to get dailyConsumption and availableEnergy
      final factoryResult = await ApiService.getFactory(_currentFactoryId);
      if (factoryResult['success'] == true && factoryResult['data'] != null) {
        final factoryData = factoryResult['data'] as Map<String, dynamic>;
        _dailyConsumption = (factoryData['dailyConsumption'] as num?)?.toDouble();
        _availableEnergy = (factoryData['availableEnergy'] as num?)?.toDouble();
        
        // Check energy status and trigger alerts if needed
        _checkEnergyStatus();
      }
      
      // Try to fetch all factories
      final result = await ApiService.getAllFactories();
      if (result['success'] == true && result['data'] != null) {
        final factoriesData = result['data'] as List;
        _factories = factoriesData
            .map((f) => EnergyFactory.fromJson(f as Map<String, dynamic>))
            .where((f) => f.id != _currentFactoryId) // Exclude current factory
            .toList();
        notifyListeners();
      }
    } catch (e) {
      // API might not be available, use mock data
      debugPrint('API not available, using mock data: $e');
    }
  }

  /// Check energy status and send alerts
  void _checkEnergyStatus() {
    if (_notificationService == null || 
        _dailyConsumption == null || 
        _availableEnergy == null) {
      return;
    }

    final now = DateTime.now();

    if (_availableEnergy! < _dailyConsumption!) {
      // Low energy alert with cooldown
      if (_lastLowEnergyAlert == null || 
          now.difference(_lastLowEnergyAlert!) > _alertCooldown) {
        _notificationService!.notifyEnergyLow(
          currentEnergy: _availableEnergy!,
          dailyConsumption: _dailyConsumption!,
        );
        _lastLowEnergyAlert = now;
      }
    } else if (_availableEnergy! > _dailyConsumption! * 1.5) {
      // Surplus alert (50% more than daily consumption) with cooldown
      if (_lastSurplusAlert == null || 
          now.difference(_lastSurplusAlert!) > _alertCooldown) {
        final surplus = _availableEnergy! - _dailyConsumption!;
        _notificationService!.notifyEnergySurplus(
          currentEnergy: _availableEnergy!,
          dailyConsumption: _dailyConsumption!,
          surplus: surplus,
        );
        _lastSurplusAlert = now;
      }
    }
  }

  /// Fetch offers/trades from API
  Future<void> fetchOffers() async {
    // Note: The backend doesn't have a "list all trades" endpoint
    // In a real implementation, you would add this endpoint
    // For now, we keep the mock data
    notifyListeners();
  }

  /// Get factory name by ID (from local cache)
  String _getFactoryNameById(String factoryId) {
    final factory = _factories.where((f) => f.id == factoryId).firstOrNull;
    return factory?.name ?? factoryId;
  }

  /// Create a new trade offer via API
  Future<Map<String, dynamic>> createTradeOffer({
    required String sellerId,
    required String buyerId,
    required double amount,
    required double pricePerUnit,
    String? sellerName,
  }) async {
    final tradeId = ApiService.generateTradeId();
    
    final result = await ApiService.createTrade(
      tradeId: tradeId,
      sellerId: sellerId,
      buyerId: buyerId,
      amount: amount,
      pricePerUnit: pricePerUnit,
    );

    if (result['success'] == true) {
      // Add to local offers list
      final factoryName = sellerName ?? _getFactoryNameById(sellerId);
      _offers.add(EnergyOffer(
        id: tradeId,
        factoryId: sellerId,
        factoryName: factoryName,
        type: OfferType.sell,
        kWh: amount,
        pricePerKWh: pricePerUnit,
        distance: 0,
        timestamp: DateTime.now(),
        sellerId: sellerId,
        buyerId: buyerId,
      ));
      
      // Send notification
      if (_notificationService != null) {
        final isSeller = sellerId == _currentFactoryId;
        final otherFactoryName = isSeller 
            ? _getFactoryNameById(buyerId) 
            : factoryName;
        final tradeType = isSeller ? 'sell' : 'buy';
        
        _notificationService!.notifyTradeCreated(
          tradeId: tradeId,
          factoryName: otherFactoryName,
          amount: amount,
          pricePerUnit: pricePerUnit,
          tradeType: tradeType,
        );
      }
      
      notifyListeners();
    }

    return result;
  }

  /// Execute/accept a trade via API
  Future<Map<String, dynamic>> executeTrade(String tradeId) async {
    final result = await ApiService.executeTrade(tradeId: tradeId);

    if (result['success'] == true) {
      // Update local state - remove from offers, add to completed trades
      final offerIndex = _offers.indexWhere((o) => o.id == tradeId);
      if (offerIndex >= 0) {
        final offer = _offers[offerIndex];
        _trades.add(Trade(
          id: tradeId,
          type: offer.type == OfferType.sell ? TradeType.buy : TradeType.sell,
          factoryName: offer.factoryName,
          kWh: offer.kWh,
          pricePerKWh: offer.pricePerKWh,
          totalPrice: offer.totalPrice,
          status: TradeStatus.completed,
          timestamp: DateTime.now(),
        ));
        
        // Send notification
        if (_notificationService != null) {
          final tradeType = offer.type == OfferType.sell ? 'sell' : 'buy';
          _notificationService!.notifyTradeExecuted(
            tradeId: tradeId,
            factoryName: offer.factoryName,
            amount: offer.kWh,
            totalPrice: offer.totalPrice,
            tradeType: tradeType,
          );
        }
        
        _offers.removeAt(offerIndex);
      }
      notifyListeners();
    }

    return result;
  }

  /// Get trade details from API
  Future<Trade?> getTradeDetails(String tradeId) async {
    try {
      final result = await ApiService.getTrade(tradeId);
      if (result['success'] == true && result['data'] != null) {
        return Trade.fromJson(result['data'] as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Error fetching trade details: $e');
    }
    return null;
  }

  void _initializeData() {
    // Initialize history data
    final now = DateTime.now();
    for (int i = 23; i >= 0; i--) {
      final hour = now.subtract(Duration(hours: i));
      final baseGen = 150 + sin(i / 24 * 2 * pi) * 100;
      _history.add(EnergyData(
        timestamp: hour,
        generation: baseGen + Random().nextDouble() * 50,
        consumption: 120 + Random().nextDouble() * 80,
        solar: baseGen * 0.6,
        wind: baseGen * 0.3,
        battery: baseGen * 0.1,
      ));
    }

    // Initialize factories - empty by default, will be populated from API
    _factories = [];

    // Initialize offers - empty by default, user must create offers manually
    _offers = [];

    // Initialize trades - empty by default, will be populated when trades are executed
    _trades = [];
  }

  void _startUpdates() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      final random = Random();
      _currentData = CurrentEnergyData(
        generation: max(0, _currentData.generation + (random.nextDouble() - 0.5) * 20),
        consumption: max(0, _currentData.consumption + (random.nextDouble() - 0.5) * 15),
        balance: _currentData.generation - _currentData.consumption,
        todayGenerated: _currentData.todayGenerated,
        todayConsumed: _currentData.todayConsumed,
        todayTraded: _currentData.todayTraded,
        costSavings: _currentData.costSavings,
        batteryLevel: min(100, max(0, _currentData.batteryLevel + (random.nextDouble() - 0.5) * 5)),
      );
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
