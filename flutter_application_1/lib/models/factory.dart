class EnergyFactory {
  final String id;
  final String name;
  final Location location;
  final double distance;
  final FactoryStatus status;
  final Capacity capacity;
  final double currentGeneration;
  final double currentConsumption;
  final double balance;
  final String? energyType;
  final double? currencyBalance;
  final double? dailyConsumption;
  final double? availableEnergy;

  EnergyFactory({
    required this.id,
    required this.name,
    required this.location,
    required this.distance,
    required this.status,
    required this.capacity,
    required this.currentGeneration,
    required this.currentConsumption,
    required this.balance,
    this.energyType,
    this.currencyBalance,
    this.dailyConsumption,
    this.availableEnergy,
  });

  /// Create factory from API JSON response
  factory EnergyFactory.fromJson(Map<String, dynamic> json) {
    // Determine status based on balance
    double balance = (json['balance'] ?? json['initialBalance'] ?? 0).toDouble();
    double availableEnergy = (json['availableEnergy'] ?? balance).toDouble();
    double dailyConsumption = (json['dailyConsumption'] ?? 0).toDouble();
    
    FactoryStatus status;
    if (availableEnergy > dailyConsumption) {
      status = FactoryStatus.surplus;
    } else if (availableEnergy < dailyConsumption) {
      status = FactoryStatus.deficit;
    } else {
      status = FactoryStatus.storage;
    }

    return EnergyFactory(
      id: json['factoryId'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      location: Location(
        lat: (json['location']?['lat'] ?? 0).toDouble(),
        lng: (json['location']?['lng'] ?? 0).toDouble(),
      ),
      distance: (json['distance'] ?? 0).toDouble(),
      status: status,
      capacity: Capacity(
        solar: (json['capacity']?['solar'] ?? 500).toDouble(),
        wind: (json['capacity']?['wind'] ?? 300).toDouble(),
        battery: (json['capacity']?['battery'] ?? 200).toDouble(),
      ),
      currentGeneration: availableEnergy,
      currentConsumption: dailyConsumption,
      balance: availableEnergy - dailyConsumption,
      energyType: json['energyType'],
      currencyBalance: (json['currencyBalance'] ?? 0).toDouble(),
      dailyConsumption: dailyConsumption,
      availableEnergy: availableEnergy,
    );
  }

  /// Convert factory to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'factoryId': id,
      'name': name,
      'initialBalance': balance,
      'energyType': energyType ?? 'Solar',
      'currencyBalance': currencyBalance ?? 0,
      'dailyConsumption': dailyConsumption ?? currentConsumption,
      'availableEnergy': availableEnergy ?? currentGeneration,
    };
  }
}

class Location {
  final double lat;
  final double lng;

  Location({required this.lat, required this.lng});
}

class Capacity {
  final double solar;
  final double wind;
  final double battery;

  Capacity({
    required this.solar,
    required this.wind,
    required this.battery,
  });
}

enum FactoryStatus { surplus, deficit, storage }
