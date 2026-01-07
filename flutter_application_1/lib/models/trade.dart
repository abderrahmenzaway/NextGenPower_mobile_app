enum TradeType { buy, sell }

enum TradeStatus { pending, active, completed, cancelled }

class Trade {
  final String id;
  final TradeType type;
  final String factoryName;
  final double kWh;
  final double pricePerKWh;
  final double totalPrice;
  final TradeStatus status;
  final DateTime timestamp;
  final double? profitLoss;
  final String? sellerId;
  final String? buyerId;

  Trade({
    required this.id,
    required this.type,
    required this.factoryName,
    required this.kWh,
    required this.pricePerKWh,
    required this.totalPrice,
    required this.status,
    required this.timestamp,
    this.profitLoss,
    this.sellerId,
    this.buyerId,
  });

  /// Create trade from API JSON response
  factory Trade.fromJson(Map<String, dynamic> json) {
    // Parse status from string
    TradeStatus status;
    switch (json['status']?.toString().toLowerCase()) {
      case 'pending':
        status = TradeStatus.pending;
        break;
      case 'active':
        status = TradeStatus.active;
        break;
      case 'completed':
      case 'executed':
        status = TradeStatus.completed;
        break;
      case 'cancelled':
        status = TradeStatus.cancelled;
        break;
      default:
        status = TradeStatus.pending;
    }

    double amount = (json['amount'] ?? json['kWh'] ?? 0).toDouble();
    double pricePerUnit = (json['pricePerUnit'] ?? json['pricePerKWh'] ?? 0).toDouble();

    return Trade(
      id: json['tradeId'] ?? json['id'] ?? '',
      type: json['type'] == 'sell' ? TradeType.sell : TradeType.buy,
      factoryName: json['factoryName'] ?? json['sellerId'] ?? '',
      kWh: amount,
      pricePerKWh: pricePerUnit,
      totalPrice: json['totalPrice'] ?? (amount * pricePerUnit),
      status: status,
      timestamp: json['timestamp'] != null 
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      profitLoss: json['profitLoss']?.toDouble(),
      sellerId: json['sellerId'],
      buyerId: json['buyerId'],
    );
  }

  /// Convert trade to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'tradeId': id,
      'sellerId': sellerId ?? factoryName,
      'buyerId': buyerId ?? '',
      'amount': kWh,
      'pricePerUnit': pricePerKWh,
    };
  }
}
