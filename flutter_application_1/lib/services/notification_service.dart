import 'package:flutter/material.dart';
import '../models/notification.dart';

class NotificationService extends ChangeNotifier {
  final List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  List<AppNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  int get unreadCount => unreadNotifications.length;

  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    notifyListeners();
  }

  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  void removeNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  // Create trade notification
  void notifyTradeCreated({
    required String tradeId,
    required String factoryName,
    required double amount,
    required double pricePerUnit,
    required String tradeType,
  }) {
    final notification = AppNotification(
      id: '${tradeId}-created-${DateTime.now().microsecondsSinceEpoch}',
      type: NotificationType.tradeCreated,
      title: 'Trade Created',
      message: 'New $tradeType trade created with $factoryName: ${amount.toStringAsFixed(1)} kWh at ${pricePerUnit.toStringAsFixed(2)} TEC/kWh',
      timestamp: DateTime.now(),
      metadata: {
        'tradeId': tradeId,
        'factoryName': factoryName,
        'amount': amount,
        'pricePerUnit': pricePerUnit,
        'tradeType': tradeType,
      },
    );
    addNotification(notification);
  }

  // Create trade execution notification
  void notifyTradeExecuted({
    required String tradeId,
    required String factoryName,
    required double amount,
    required double totalPrice,
    required String tradeType,
  }) {
    final notification = AppNotification(
      id: '${tradeId}-executed-${DateTime.now().microsecondsSinceEpoch}',
      type: NotificationType.tradeExecuted,
      title: 'Trade Executed',
      message: 'Trade executed with $factoryName: ${amount.toStringAsFixed(1)} kWh for ${totalPrice.toStringAsFixed(2)} TEC',
      timestamp: DateTime.now(),
      metadata: {
        'tradeId': tradeId,
        'factoryName': factoryName,
        'amount': amount,
        'totalPrice': totalPrice,
        'tradeType': tradeType,
      },
    );
    addNotification(notification);
  }

  // Energy low alert
  void notifyEnergyLow({
    required double currentEnergy,
    required double dailyConsumption,
  }) {
    final notification = AppNotification(
      id: 'energy-low-${DateTime.now().microsecondsSinceEpoch}',
      type: NotificationType.energyLow,
      title: 'Low Energy Alert',
      message: '⚠️ Your energy (${currentEnergy.toStringAsFixed(1)} kWh) is below daily consumption (${dailyConsumption.toStringAsFixed(1)} kWh). Consider buying energy instead of trading.',
      timestamp: DateTime.now(),
      metadata: {
        'currentEnergy': currentEnergy,
        'dailyConsumption': dailyConsumption,
      },
    );
    addNotification(notification);
  }

  // Energy high alert (surplus)
  void notifyEnergySurplus({
    required double currentEnergy,
    required double dailyConsumption,
    required double surplus,
  }) {
    final notification = AppNotification(
      id: 'energy-high-${DateTime.now().microsecondsSinceEpoch}',
      type: NotificationType.energyHigh,
      title: 'Energy Surplus',
      message: '✅ You have surplus energy: ${surplus.toStringAsFixed(1)} kWh above daily consumption. Good time to sell!',
      timestamp: DateTime.now(),
      metadata: {
        'currentEnergy': currentEnergy,
        'dailyConsumption': dailyConsumption,
        'surplus': surplus,
      },
    );
    addNotification(notification);
  }

  // Generic info notification
  void notifyInfo({
    required String title,
    required String message,
  }) {
    final notification = AppNotification(
      id: 'info-${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.info,
      title: title,
      message: message,
      timestamp: DateTime.now(),
    );
    addNotification(notification);
  }
}
