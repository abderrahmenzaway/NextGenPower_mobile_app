import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class BlockchainScreen extends StatefulWidget {
  final VoidCallback onBack;
  final String factoryId;
  final String factoryName;

  const BlockchainScreen({
    super.key,
    required this.onBack,
    required this.factoryId,
    required this.factoryName,
  });

  @override
  State<BlockchainScreen> createState() => _BlockchainScreenState();
}

class _BlockchainScreenState extends State<BlockchainScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  String? _hederaAccountId;
  double? _tecBalance;
  bool _isLoading = true;
  
  // Hedera blockchain data
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _factoryTrades = [];
  int? _blockHeight;
  String? _latestBlockHash;
  DateTime? _latestBlockTime;
  int? _transactionCount;
  bool _loadingBlockchainData = true;
  bool _loadingFactoryTrades = true;

  // Threshold to distinguish seconds from milliseconds timestamps
  static const int _timestampThresholdMs = 10000000000;

  // Helper to get value from map with both camelCase and lowercase keys
  T? _getValue<T>(Map<String, dynamic> map, String camelKey, String lowerKey) {
    return (map[lowerKey] ?? map[camelKey]) as T?;
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _fetchFactoryData();
    _fetchBlockchainData();
    _fetchFactoryTrades();
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

  Future<void> _fetchBlockchainData() async {
    try {
      // Fetch treasury transactions and latest block info in parallel
      final results = await Future.wait([
        ApiService.getTreasuryTransactions(limit: 10),
        ApiService.getLatestBlockInfo(),
      ]);

      final transactionsResult = results[0] as Map<String, dynamic>;
      final blockInfoResult = results[1] as Map<String, dynamic>;

      final transactionsData = transactionsResult['data'] as List;
      final blockData = blockInfoResult['data'] as Map<String, dynamic>;

      setState(() {
        _transactions = transactionsData.map((tx) => tx as Map<String, dynamic>).toList();
        _blockHeight = blockData['blockNumber'] as int?;
        _latestBlockHash = blockData['hash'] as String?;
        _transactionCount = blockData['transactionCount'] as int?;
        
        // Parse timestamp
        final timestampStr = blockData['timestamp'] as String?;
        if (timestampStr != null) {
          _latestBlockTime = DateTime.parse(timestampStr);
        }
        
        _loadingBlockchainData = false;
      });
    } catch (e) {
      print('Error fetching blockchain data: $e');
      setState(() {
        _loadingBlockchainData = false;
      });
    }
  }

  Future<void> _fetchFactoryTrades() async {
    try {
      final result = await ApiService.getFactoryTrades(widget.factoryId);
      
      if (result['success'] == true) {
        final tradesData = result['data'] as List;
        
        setState(() {
          _factoryTrades = tradesData.map((trade) => trade as Map<String, dynamic>).toList();
          _loadingFactoryTrades = false;
        });
      }
    } catch (e) {
      print('Error fetching factory trades: $e');
      setState(() {
        _loadingFactoryTrades = false;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _truncateHash(String hash) {
    return '${hash.substring(0, 10)}...${hash.substring(hash.length - 8)}';
  }

  String _formatAccountId(String accountId) {
    // For Hedera account IDs like 0.0.12345, keep them short
    // For transaction IDs, show a shortened version
    if (accountId.startsWith('0.0.')) {
      return accountId; // Keep account IDs as is
    }
    // Truncate long strings
    if (accountId.length > 20) {
      return '${accountId.substring(0, 10)}...';
    }
    return accountId;
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Next Gen Power',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  Text(
                    'Blockchain Explorer',
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
          // Wallet Summary Card
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
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Token Balance',
                            style: TextStyle(
                              color: Colors.blue.shade300,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _isLoading
                              ? const SizedBox(
                                  height: 32,
                                  width: 32,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  '${_tecBalance?.toStringAsFixed(2) ?? '0.00'} TEC',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          Text(
                            'TEC Coin Balance',
                            style: TextStyle(
                              color: Colors.blue.shade300,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                          ),
                          child: const Text('Send', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                          ),
                          child: const Text('Receive', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Block Height
          Card(
            color: Colors.grey.shade900.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Block Height',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  _loadingBlockchainData
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _blockHeight != null
                              ? _blockHeight.toString().replaceAllMapped(
                                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                    (Match m) => '${m[1]},',
                                  )
                              : 'N/A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Live Transactions Feed
          Card(
            color: Colors.grey.shade900.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Live Transactions',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      Row(
                        children: [
                          FadeTransition(
                            opacity: _pulseController,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Live',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_loadingBlockchainData)
                    const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    )
                  else if (_transactions.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          'No transactions available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ..._transactions.take(5).map((tx) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildTransactionItemFromHedera(tx),
                      );
                    }).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // My Factory Transactions
          Card(
            color: Colors.grey.shade900.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'My Factory Transactions',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_loadingFactoryTrades)
                    const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    )
                  else if (_factoryTrades.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          'No factory transactions yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ..._factoryTrades.map((trade) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildFactoryTradeItem(trade),
                      );
                    }).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Latest Block
          Card(
            color: Colors.grey.shade900.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Latest Block',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  if (_loadingBlockchainData)
                    const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    )
                  else ...[
                    _buildStatRow('Block Number', _blockHeight?.toString() ?? 'N/A'),
                    _buildStatRow(
                      'Timestamp',
                      _latestBlockTime != null
                          ? '${_latestBlockTime!.hour.toString().padLeft(2, '0')}:${_latestBlockTime!.minute.toString().padLeft(2, '0')}:${_latestBlockTime!.second.toString().padLeft(2, '0')}'
                          : 'N/A',
                    ),
                    _buildStatRow('Transactions', _transactionCount?.toString() ?? 'N/A'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Block Hash',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Row(
                          children: [
                            Text(
                              _latestBlockHash != null && _latestBlockHash!.length > 20
                                  ? '${_latestBlockHash!.substring(0, 10)}...${_latestBlockHash!.substring(_latestBlockHash!.length - 8)}'
                                  : _latestBlockHash ?? 'N/A',
                              style: TextStyle(
                                color: Colors.purple.shade400,
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.open_in_new, size: 12, color: Colors.grey),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Live Transactions Feed
        ],
      ),
    );
  }

  Widget _buildTransactionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String type,
    required Color typeColor,
    required String amount,
    required DateTime time,
    required String hash,
  }) {
    return Card(
      color: Colors.grey.shade800.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade700.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            color: typeColor,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade900.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _truncateHash(hash),
                              style: TextStyle(
                                color: Colors.purple.shade400,
                                fontSize: 10,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _copyToClipboard(hash),
                            child: const Icon(Icons.copy, size: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      Text(
                        amount,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItemFromHedera(Map<String, dynamic> tx) {
    // Parse transaction data
    final transactionId = tx['transactionId'] as String? ?? '';
    final timestamp = tx['consensusTimestamp'] as String? ?? '';
    final type = tx['type'] as String? ?? 'UNKNOWN';
    final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
    final result = tx['result'] as String? ?? '';
    final initiator = tx['initiator'] as String? ?? 'Anonymous';
    final counterParty = tx['counterParty'] as String?;
    
    // Parse timestamp
    DateTime? txTime;
    try {
      if (timestamp.isNotEmpty) {
        txTime = DateTime.parse(timestamp);
      }
    } catch (e) {
      txTime = DateTime.now();
    }
    
    // Format account IDs for display
    final formattedInitiator = _formatAccountId(initiator);
    final formattedCounterParty = counterParty != null ? _formatAccountId(counterParty) : null;
    
    // Determine icon and color based on transaction type
    IconData icon = Icons.swap_horiz;
    Color iconColor = Colors.blue;
    String title = type;
    Color typeColor = Colors.blue;
    
    if (type == 'ACCOUNT CREATED') {
      icon = Icons.person_add;
      iconColor = Colors.green;
      typeColor = Colors.green;
      title = 'Account Created';
      if (formattedCounterParty != null) {
        title = '$formattedInitiator created account';
      }
    } else if (type == 'TOKEN TRANSFER') {
      icon = Icons.swap_horiz;
      iconColor = Colors.blue;
      typeColor = Colors.blue;
      title = 'Token Transfer';
      if (formattedCounterParty != null) {
        title = '$formattedInitiator → $formattedCounterParty';
      } else {
        title = '$formattedInitiator transferred tokens';
      }
    } else if (type == 'TOKEN ASSOCIATION') {
      icon = Icons.link;
      iconColor = Colors.purple;
      typeColor = Colors.purple;
      title = '$formattedInitiator associated token';
    } else if (type == 'TOKEN MINT') {
      icon = Icons.add_circle;
      iconColor = Colors.amber;
      typeColor = Colors.amber;
      title = '$formattedInitiator minted tokens';
    } else if (type == 'TOKEN CREATION') {
      icon = Icons.create;
      iconColor = Colors.green;
      typeColor = Colors.green;
      title = '$formattedInitiator created token';
    } else {
      // Generic handling for other types
      title = '$formattedInitiator: $type';
    }
    
    // Format amount
    final amountStr = amount > 0 ? '${amount.toStringAsFixed(2)} TEC' : 'N/A';
    
    return _buildTransactionItem(
      icon: icon,
      iconColor: iconColor,
      title: title,
      type: type,
      typeColor: typeColor,
      amount: amountStr,
      time: txTime ?? DateTime.now(),
      hash: transactionId,
    );
  }

  Widget _buildFactoryTradeItem(Map<String, dynamic> trade) {
    // Parse trade data - handle both camelCase and lowercase from PostgreSQL
    final tradeId = _getValue<String>(trade, 'tradeId', 'tradeid') ?? '';
    final sellerId = _getValue<String>(trade, 'sellerId', 'sellerid') ?? '';
    final buyerId = _getValue<String>(trade, 'buyerId', 'buyerid') ?? '';
    final sellerName = _getValue<String>(trade, 'sellerName', 'sellername') ?? sellerId;
    final buyerName = _getValue<String>(trade, 'buyerName', 'buyername') ?? buyerId;
    final amount = (_getValue<num>(trade, 'amount', 'amount')?.toDouble()) ?? 0.0;
    final pricePerUnit = (_getValue<num>(trade, 'pricePerUnit', 'priceperunit')?.toDouble()) ?? 0.0;
    final totalPrice = (_getValue<num>(trade, 'totalPrice', 'totalprice')?.toDouble()) ?? 0.0;
    final status = _getValue<String>(trade, 'status', 'status') ?? 'pending';
    final timestamp = trade['timestamp'];
    
    // Parse timestamp
    DateTime? txTime;
    try {
      if (timestamp != null) {
        // Handle both seconds (PostgreSQL EPOCH) and milliseconds
        final epoch = timestamp is int ? timestamp : (timestamp as num).toInt();
        txTime = DateTime.fromMillisecondsSinceEpoch(
          epoch < _timestampThresholdMs ? epoch * 1000 : epoch,
        );
      }
    } catch (e) {
      txTime = DateTime.now();
    }
    
    // Determine if this factory is the buyer or seller
    final isSeller = sellerId == widget.factoryId;
    final counterParty = isSeller ? buyerName : sellerName;
    final direction = isSeller ? 'to' : 'from';
    
    // Determine icon and color
    IconData icon = isSeller ? Icons.arrow_upward : Icons.arrow_downward;
    Color iconColor = isSeller ? Colors.red : Colors.green;
    String title = '$direction $counterParty';
    Color typeColor = status == 'completed' ? Colors.green : Colors.orange;
    
    // Format amount - show energy amount and TEC amount
    final amountStr = '${amount.toStringAsFixed(2)} kWh (${totalPrice.toStringAsFixed(2)} TEC)';
    
    return Card(
      color: Colors.grey.shade800.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade700.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isSeller ? 'Sold $title' : 'Bought $title',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: typeColor,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (txTime != null)
                    Text(
                      '${txTime.year}-${txTime.month.toString().padLeft(2, '0')}-${txTime.day.toString().padLeft(2, '0')} ${txTime.hour.toString().padLeft(2, '0')}:${txTime.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade900.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tradeId.length > 20
                                  ? '${tradeId.substring(0, 10)}...${tradeId.substring(tradeId.length - 8)}'
                                  : tradeId,
                              style: TextStyle(
                                color: Colors.purple.shade400,
                                fontSize: 10,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _copyToClipboard(tradeId),
                            child: const Icon(Icons.copy, size: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      Text(
                        amountStr,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
