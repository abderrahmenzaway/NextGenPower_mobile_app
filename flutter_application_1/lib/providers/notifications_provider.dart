import 'package:flutter/material.dart';
import '../models/notification.dart' as notif_model;
import '../services/websocket_service.dart';
import 'energy_data_provider.dart';

class NotificationsProvider extends ChangeNotifier {
  late List<notif_model.Notification> _notifications;
  String? _currentFactoryId;
  EnergyDataProvider? _energyDataProvider;

  NotificationsProvider() {
    _notifications = [
      notif_model.Notification(
        id: '1',
        icon: Icons.bolt,
        color: Colors.green,
        title: 'Low Energy Alert',
        message: 'Your surplus has dropped below 50 kWh',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      notif_model.Notification(
        id: '2',
        icon: Icons.local_offer,
        color: Colors.blue,
        title: 'New Trade Offer',
        message: 'Factory 3 wants to buy 100 kWh at 0.12 TEC/kWh',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      notif_model.Notification(
        id: '3',
        icon: Icons.check_circle,
        color: Colors.purple,
        title: 'Contract Executed',
        message: 'Successfully sold 150 kWh to Factory 2',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];

    // Listen to WebSocket messages
    WebSocketService.addListener(_handleWebSocketMessage);
  }

  /// Set the energy data provider to sync offers
  void setEnergyDataProvider(EnergyDataProvider provider) {
    _energyDataProvider = provider;
  }

  void _handleWebSocketMessage(Map<String, dynamic> data) {
    debugPrint('📨 Handling WebSocket message: $data');
    
    // Handle different notification types from WebSocket
    if (data['type'] == 'new_trade_offer') {
      debugPrint('🔥 Processing new_trade_offer');
      debugPrint('   tradeId: ${data['tradeId']}');
      debugPrint('   sellerId: ${data['sellerId']}');
      debugPrint('   amount: ${data['amount']}');
      debugPrint('   pricePerUnit: ${data['pricePerUnit']}');
      debugPrint('   energyDataProvider: $_energyDataProvider');
      
      // Add notification
      addNotification(
        notif_model.Notification(
          id: data['tradeId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          icon: Icons.local_offer,
          color: Colors.blue,
          title: 'New Energy Offer',
          message: data['message'] ?? 'New energy offer available',
          timestamp: DateTime.now(),
        ),
      );

      // Add offer to the offers list
      if (_energyDataProvider != null && data['tradeId'] != null) {
        debugPrint('✅ Adding offer to EnergyDataProvider');
        _energyDataProvider!.addOfferFromNotification(
          tradeId: data['tradeId'].toString(),
          sellerId: data['sellerId']?.toString() ?? '',
          sellerName: 'Factory ${data['sellerId']?.toString() ?? 'Unknown'}',
          amount: double.tryParse(data['amount'].toString()) ?? 0.0,
          pricePerUnit: double.tryParse(data['pricePerUnit'].toString()) ?? 0.0,
        );
        debugPrint('✅ Offer added successfully');
      } else {
        debugPrint('❌ Cannot add offer: energyDataProvider=$_energyDataProvider, tradeId=${data['tradeId']}');
      }
    } else if (data['type'] == 'new_offer') {
      addNotification(
        notif_model.Notification(
          id: data['tradeId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          icon: Icons.local_offer,
          color: Colors.blue,
          title: 'New Energy Offer',
          message: data['message'] ?? 'New energy offer available',
          timestamp: DateTime.now(),
        ),
      );
    } else if (data['type'] == 'trade_executed') {
      addNotification(
        notif_model.Notification(
          id: data['tradeId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          icon: Icons.check_circle,
          color: Colors.purple,
          title: 'Contract Executed',
          message: data['message'] ?? 'Trade executed successfully',
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Connect to WebSocket for a factory
  void connectToFactory(String factoryId) {
    if (_currentFactoryId != factoryId) {
      _currentFactoryId = factoryId;
      WebSocketService.connect(factoryId);
    }
  }

  @override
  void dispose() {
    WebSocketService.removeListener(_handleWebSocketMessage);
    super.dispose();
  }

  List<notif_model.Notification> get notifications =>
      _notifications.toList();

  void addNotification(notif_model.Notification notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  void removeNotification(String id) {
    _notifications.removeWhere((notif) => notif.id == id);
    notifyListeners();
  }

  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  void addTradeNotification({
    required String tradeId,
    required String sellerFactoryId,
    required String sellerFactoryName,
    required String buyerFactoryId,
    required String buyerFactoryName,
    required double amount,
    required double pricePerUnit,
  }) {
    final totalPrice = amount * pricePerUnit;
    addNotification(
      notif_model.Notification(
        id: tradeId,
        icon: Icons.local_offer,
        color: Colors.blue,
        title: 'New Energy Offer',
        message: '$sellerFactoryName offers ${amount.toStringAsFixed(0)} kWh at ${pricePerUnit.toStringAsFixed(2)} TEC/kWh',
        timestamp: DateTime.now(),
      ),
    );
  }

  void addEnergyAlertNotification({
    required String message,
  }) {
    addNotification(
      notif_model.Notification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        icon: Icons.bolt,
        color: Colors.green,
        title: 'Energy Alert',
        message: message,
        timestamp: DateTime.now(),
      ),
    );
  }

  void addContractNotification({
    required String contractId,
    required String message,
  }) {
    addNotification(
      notif_model.Notification(
        id: contractId,
        icon: Icons.check_circle,
        color: Colors.purple,
        title: 'Contract Executed',
        message: message,
        timestamp: DateTime.now(),
      ),
    );
  }
}
