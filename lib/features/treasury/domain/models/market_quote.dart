class MarketQuote {
  final String investmentId;
  final String companyId;
  final String name;
  final String assetType;
  final String ticker;
  final double price;
  final String currency;
  final double? units;
  final double? currentValue;
  final double totalInvested;
  final bool persisted;
  final String? persistenceReason;
  final DateTime retrievedAt;
  final bool cached;
  final String cacheStatus; // 'HIT', 'MISS', 'STALE'
  final String source;      // 'LIVE', 'CACHE', 'STALE'
  final int ageSeconds;
  final bool isRealTime;
  final bool isStale;

  const MarketQuote({
    required this.investmentId,
    required this.companyId,
    required this.name,
    required this.assetType,
    required this.ticker,
    required this.price,
    required this.currency,
    this.units,
    this.currentValue,
    required this.totalInvested,
    this.persisted = false,
    this.persistenceReason,
    required this.retrievedAt,
    this.cached = false,
    this.cacheStatus = 'MISS',
    this.source = 'LIVE',
    this.ageSeconds = 0,
    this.isRealTime = false,
    this.isStale = false,
  });

  factory MarketQuote.fromJson(Map<String, dynamic> json) {
    return MarketQuote(
      investmentId: json['investmentId']?.toString() ?? '',
      companyId: json['companyId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      assetType: json['assetType']?.toString() ?? '',
      ticker: json['ticker']?.toString() ?? '',
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      currency: json['currency']?.toString() ?? 'USD',
      units: json['units'] != null
          ? double.tryParse(json['units'].toString())
          : null,
      currentValue: json['currentValue'] != null
          ? double.tryParse(json['currentValue'].toString())
          : null,
      totalInvested: (json['totalInvested'] is num)
          ? (json['totalInvested'] as num).toDouble()
          : double.tryParse(json['totalInvested']?.toString() ?? '0') ?? 0.0,
      persisted: json['persisted'] == true,
      persistenceReason: json['persistenceReason'] as String?,
      retrievedAt: json['retrievedAt'] != null
          ? DateTime.tryParse(json['retrievedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      cached: json['cached'] == true,
      cacheStatus: json['cacheStatus']?.toString() ?? 'MISS',
      source: json['source']?.toString() ?? 'LIVE',
      ageSeconds: (json['ageSeconds'] is num)
          ? (json['ageSeconds'] as num).toInt()
          : int.tryParse(json['ageSeconds']?.toString() ?? '0') ?? 0,
      isRealTime: json['isRealTime'] == true,
      isStale: json['isStale'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'investmentId': investmentId,
      'companyId': companyId,
      'name': name,
      'assetType': assetType,
      'ticker': ticker,
      'price': price,
      'currency': currency,
      if (units != null) 'units': units,
      if (currentValue != null) 'currentValue': currentValue,
      'totalInvested': totalInvested,
      'persisted': persisted,
      if (persistenceReason != null) 'persistenceReason': persistenceReason,
      'retrievedAt': retrievedAt.toIso8601String(),
      'cached': cached,
      'cacheStatus': cacheStatus,
      'source': source,
      'ageSeconds': ageSeconds,
      'isRealTime': isRealTime,
      'isStale': isStale,
    };
  }

  /// Unrealized profit/loss in amount: Current Value - Total Invested
  double? get unrealizedGainLoss {
    if (currentValue != null && totalInvested > 0) {
      return currentValue! - totalInvested;
    }
    return null;
  }

  /// Unrealized profit/loss in percentage: (GainLoss / Total Invested) * 100
  double? get unrealizedGainLossPercent {
    final gl = unrealizedGainLoss;
    if (gl != null && totalInvested > 0) {
      return (gl / totalInvested) * 100;
    }
    return null;
  }

  @override
  String toString() =>
      'MarketQuote(ticker: $ticker, price: $price, currentValue: $currentValue, cached: $cached, isStale: $isStale)';
}
