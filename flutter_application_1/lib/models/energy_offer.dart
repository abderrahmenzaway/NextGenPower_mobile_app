class EnergyOffer {
  final String id;
  final String factoryId;
  final String factoryName;
  final OfferType type;
  final double kWh;
  final double pricePerKWh;
  final double distance;
  final DateTime timestamp;
  final String? sellerId;
  final String? buyerId;
  final String? status;

  EnergyOffer({
    required this.id,
    required this.factoryId,
    required this.factoryName,
    required this.type,
    required this.kWh,
    required this.pricePerKWh,
    required this.distance,
    required this.timestamp,
    this.sellerId,
    this.buyerId,
    this.status,
  });

  double get totalPrice => kWh * pricePerKWh;

  /// Create offer from API trade JSON response
  factory EnergyOffer.fromJson(Map<String, dynamic> json) {
    return EnergyOffer(
      id: json['tradeId'] ?? json['id'] ?? '',
      factoryId: json['sellerId'] ?? json['factoryId'] ?? '',
      factoryName: json['factoryName'] ?? json['sellerId'] ?? '',
      type: json['type'] == 'buy' ? OfferType.buy : OfferType.sell,
      kWh: (json['amount'] ?? json['kWh'] ?? 0).toDouble(),
      pricePerKWh: (json['pricePerUnit'] ?? json['pricePerKWh'] ?? 0).toDouble(),
      distance: (json['distance'] ?? 0).toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      sellerId: json['sellerId'],
      buyerId: json['buyerId'],
      status: json['status'],
    );
  }

  /// Convert offer to JSON for creating a trade
  /// Note: tradeId should be generated externally using ApiService.generateTradeId()
  Map<String, dynamic> toTradeJson({required String buyerId, required String tradeId}) {
    return {
      'tradeId': tradeId,
      'sellerId': sellerId ?? factoryId,
      'buyerId': buyerId,
      'amount': kWh,
      'pricePerUnit': pricePerKWh,
    };
  }
}

enum OfferType { buy, sell }
