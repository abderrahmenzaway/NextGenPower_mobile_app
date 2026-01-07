import 'dart:convert';
import 'package:http/http.dart' as http;

/// Configuration for API service
class ApiConfig {
  /// Base URL for the API - configure based on environment
  /// For development: http://localhost:3000
  /// For production/ngrok: Use --dart-define=API_BASE_URL=https://your-ngrok-url.ngrok-free.dev
  static String baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// Base URL for the NILM Model API
  /// For development: http://localhost:3001 (Express gateway to Flask)
  static String nilmApiBaseUrl = const String.fromEnvironment(
    'NILM_API_BASE_URL',
    defaultValue: 'http://localhost:3001',
  );

  /// Base URL for the Predictive Maintenance Model 2 API
  /// For development: http://localhost:3002 (Express gateway to Flask at 5002)
  static String model2ApiBaseUrl = const String.fromEnvironment(
    'MODEL2_API_BASE_URL',
    defaultValue: 'http://localhost:3002',
  );

  /// Placeholder for open trades (no specific buyer/seller)
  static const String openTradeMarker = 'OPEN';
}

/// API Service for connecting to the Energy Trading Network backend
class ApiService {
  /// Generate a unique trade ID
  static String generateTradeId() {
    return 'TRADE-${DateTime.now().millisecondsSinceEpoch}-${DateTime.now().microsecond}';
  }

  /// Health check endpoint
  /// GET /api/health
  static Future<Map<String, dynamic>> healthCheck() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/health'),
    );
    return _handleResponse(response);
  }

  /// Get system configuration including TEC token ID
  /// GET /api/config
  static Future<Map<String, dynamic>> getConfig() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/config'),
    );
    return _handleResponse(response);
  }

  /// Register a new factory
  /// POST /api/factory/register
  /// Body: { factoryId, name, password, initialBalance, energyType, currencyBalance, dailyConsumption, availableEnergy }
  static Future<Map<String, dynamic>> registerFactory({
    required String factoryId,
    required String name,
    required String password,
    required double initialBalance,
    required String energyType,
    double currencyBalance = 0,
    double dailyConsumption = 0,
    double? availableEnergy,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/factory/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'factoryId': factoryId,
        'name': name,
        'password': password,
        'initialBalance': initialBalance,
        'energyType': energyType,
        'currencyBalance': currencyBalance,
        'dailyConsumption': dailyConsumption,
        'availableEnergy': availableEnergy ?? initialBalance,
      }),
    );
    return _handleResponse(response);
  }

  /// Login factory
  /// POST /api/factory/login
  /// Body: { factoryId, password }
  static Future<Map<String, dynamic>> loginFactory({
    required String factoryId,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/factory/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'factoryId': factoryId, 'password': password}),
    );
    return _handleResponse(response);
  }

  /// Create a new energy trade
  /// POST /api/trade/create
  /// Body: { tradeId, sellerId, buyerId, amount, pricePerUnit }
  static Future<Map<String, dynamic>> createTrade({
    required String tradeId,
    required String sellerId,
    required String buyerId,
    required double amount,
    required double pricePerUnit,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/trade/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'tradeId': tradeId,
        'sellerId': sellerId,
        'buyerId': buyerId,
        'amount': amount,
        'pricePerUnit': pricePerUnit,
      }),
    );
    return _handleResponse(response);
  }

  /// Execute a pending energy trade (accept trade)
  /// POST /api/trade/execute
  /// Body: { tradeId }
  static Future<Map<String, dynamic>> executeTrade({
    required String tradeId,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/trade/execute'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'tradeId': tradeId}),
    );
    return _handleResponse(response);
  }

  /// Get factory information
  /// GET /api/factory/:factoryId
  static Future<Map<String, dynamic>> getFactory(String factoryId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/factory/$factoryId'),
    );
    return _handleResponse(response);
  }

  /// Get all factories in the industrial zone
  /// GET /api/factories
  static Future<Map<String, dynamic>> getAllFactories() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/factories'),
    );
    return _handleResponse(response);
  }

  /// Get factory energy balance
  /// GET /api/factory/:factoryId/balance
  static Future<Map<String, dynamic>> getFactoryBalance(
    String factoryId,
  ) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/factory/$factoryId/balance'),
    );
    return _handleResponse(response);
  }

  /// Get factory available energy
  /// GET /api/factory/:factoryId/available-energy
  static Future<Map<String, dynamic>> getAvailableEnergy(
    String factoryId,
  ) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/factory/$factoryId/available-energy'),
    );
    return _handleResponse(response);
  }

  /// Get factory energy status (surplus/deficit)
  /// GET /api/factory/:factoryId/energy-status
  static Future<Map<String, dynamic>> getEnergyStatus(String factoryId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/factory/$factoryId/energy-status'),
    );
    return _handleResponse(response);
  }

  /// Get trade information
  /// GET /api/trade/:tradeId
  static Future<Map<String, dynamic>> getTrade(String tradeId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/trade/$tradeId'),
    );
    return _handleResponse(response);
  }

  /// Get factory transaction history
  /// GET /api/factory/:factoryId/history
  static Future<Map<String, dynamic>> getFactoryHistory(
    String factoryId,
  ) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/factory/$factoryId/history'),
    );
    return _handleResponse(response);
  }

  /// Get factory trades (as buyer or seller)
  /// GET /api/factory/:factoryId/trades
  static Future<Map<String, dynamic>> getFactoryTrades(
    String factoryId,
  ) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/factory/$factoryId/trades'),
    );
    return _handleResponse(response);
  }

  /// Mint energy tokens
  /// POST /api/energy/mint
  static Future<Map<String, dynamic>> mintEnergy({
    required String factoryId,
    required double amount,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/energy/mint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'factoryId': factoryId, 'amount': amount}),
    );
    return _handleResponse(response);
  }

  /// Transfer energy tokens between factories
  /// POST /api/energy/transfer
  static Future<Map<String, dynamic>> transferEnergy({
    required String fromFactoryId,
    required String toFactoryId,
    required double amount,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/energy/transfer'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fromFactoryId': fromFactoryId,
        'toFactoryId': toFactoryId,
        'amount': amount,
      }),
    );
    return _handleResponse(response);
  }

  /// Update available energy of a factory
  /// PUT /api/factory/:factoryId/available-energy
  static Future<Map<String, dynamic>> updateAvailableEnergy({
    required String factoryId,
    required double availableEnergy,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/factory/$factoryId/available-energy'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'availableEnergy': availableEnergy}),
    );
    return _handleResponse(response);
  }

  /// Update daily consumption of a factory
  /// PUT /api/factory/:factoryId/daily-consumption
  static Future<Map<String, dynamic>> updateDailyConsumption({
    required String factoryId,
    required double dailyConsumption,
  }) async {
    final response = await http.put(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/factory/$factoryId/daily-consumption',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'dailyConsumption': dailyConsumption}),
    );
    return _handleResponse(response);
  }

  /// Change factory password
  /// PUT /api/factory/:factoryId/password
  /// Body: { currentPassword, newPassword }
  static Future<Map<String, dynamic>> changePassword({
    required String factoryId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/factory/$factoryId/password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );
    return _handleResponse(response);
  }

  /// Get NILM model predictions for machine consumption
  /// POST /api/predict
  /// Body: { aggregate_sequence: [288 numbers] }
  /// Returns predictions for: BA, CHP, CS, EVSE, PV
  static Future<Map<String, dynamic>> getNilmPredictions({
    required List<double> aggregateSequence,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.nilmApiBaseUrl}/api/predict'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'aggregate_sequence': aggregateSequence}),
    );
    return _handleResponse(response);
  }

  /// Get Model 2 (Predictive Maintenance) predictions for a machine
  /// POST /api/predict
  /// Body: { air_temperature, process_temperature, rotational_speed, torque, tool_wear, type_H, type_L, type_M }
  /// Returns: { predicted_failure_type, confidence, probability, reconstruction_error, is_anomaly }
  static Future<Map<String, dynamic>> getModel2Prediction({
    required double airTemperature,
    required double processTemperature,
    required double rotationalSpeed,
    required double torque,
    required double toolWear,
    required int typeH,
    required int typeL,
    required int typeM,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.model2ApiBaseUrl}/api/predict'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'air_temperature': airTemperature,
        'process_temperature': processTemperature,
        'rotational_speed': rotationalSpeed,
        'torque': torque,
        'tool_wear': toolWear,
        'type_H': typeH,
        'type_L': typeL,
        'type_M': typeM,
      }),
    );
    return _handleResponse(response);
  }

  /// Get treasury account transactions from Hedera testnet
  /// GET /api/treasury/transactions
  /// Query params: limit (optional, default: 20)
  static Future<Map<String, dynamic>> getTreasuryTransactions({
    int limit = 20,
  }) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/treasury/transactions?limit=$limit'),
    );
    return _handleResponse(response);
  }

  /// Get latest block information from Hedera testnet
  /// GET /api/blockchain/latest-block
  static Future<Map<String, dynamic>> getLatestBlockInfo() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/blockchain/latest-block'),
    );
    return _handleResponse(response);
  }

  /// Get treasury account balance from Hedera testnet
  /// GET /api/treasury/balance
  static Future<Map<String, dynamic>> getTreasuryBalance() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/treasury/balance'),
    );
    return _handleResponse(response);
  }

  /// Handle HTTP response and parse JSON
  static Map<String, dynamic> _handleResponse(http.Response response) {
    Map<String, dynamic> body;

    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      // Handle malformed JSON response
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Invalid response from server: ${response.body}',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: body['error'] ?? 'Unknown error',
      );
    }
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException: $statusCode - $message';
}
