import 'package:flutter/material.dart';

enum AssetType {
  bond('BOND', 'Bonds / T-Bills', Icons.account_balance, Colors.blue),
  fixedDeposit('FIXED_DEPOSIT', 'Fixed Deposit', Icons.savings, Colors.orange),
  cash('CASH', 'Cash Reserve', Icons.attach_money, Colors.teal),
  stock('STOCK', 'Stocks', Icons.trending_up, Colors.green),
  etf('ETF', 'ETF', Icons.pie_chart, Colors.purple),
  mutualFund('MUTUAL_FUND', 'Mutual Funds', Icons.bar_chart, Colors.indigo),
  crypto('CRYPTO', 'Crypto', Icons.currency_bitcoin, Colors.amber);

  final String value;
  final String displayName;
  final IconData icon;
  final Color color;

  const AssetType(this.value, this.displayName, this.icon, this.color);

  static AssetType fromJson(String? value) {
    if (value == null) return AssetType.bond;
    return AssetType.values.firstWhere(
      (e) => e.value.toUpperCase() == value.toUpperCase(),
      orElse: () => AssetType.bond,
    );
  }

  static AssetType fromDisplayName(String name) {
    return AssetType.values.firstWhere(
      (e) => e.displayName.toLowerCase() == name.toLowerCase() ||
             e.value.toLowerCase() == name.toLowerCase(),
      orElse: () => AssetType.bond,
    );
  }

  String toJson() => value;
}

enum TreasuryCurrency {
  usd('USD'),
  inr('INR'),
  eur('EUR'),
  gbp('GBP'),
  sgd('SGD'),
  aed('AED');

  final String value;
  const TreasuryCurrency(this.value);

  static TreasuryCurrency fromJson(String? value) {
    if (value == null) return TreasuryCurrency.usd;
    return TreasuryCurrency.values.firstWhere(
      (e) => e.value.toUpperCase() == value.toUpperCase(),
      orElse: () => TreasuryCurrency.usd,
    );
  }

  String toJson() => value;
}

class TreasuryInvestment {
  final String? id;
  final String companyId;
  final AssetType assetType;
  final String name;
  final String? ticker;
  final double? units;
  final double purchasePrice;
  final double? currentPrice;
  final double totalInvested;
  final double? currentValue;
  final TreasuryCurrency currency;
  final DateTime investmentDate;
  final DateTime? maturityDate;
  final double? interestRate; // e.g. 0.052 for 5.2%
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TreasuryInvestment({
    this.id,
    required this.companyId,
    required this.assetType,
    required this.name,
    this.ticker,
    this.units,
    required this.purchasePrice,
    this.currentPrice,
    required this.totalInvested,
    this.currentValue,
    this.currency = TreasuryCurrency.usd,
    required this.investmentDate,
    this.maturityDate,
    this.interestRate,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory TreasuryInvestment.fromJson(Map<String, dynamic> json) {
    return TreasuryInvestment(
      id: json['id'] as String?,
      companyId: json['companyId'] as String? ?? '',
      assetType: AssetType.fromJson(json['assetType'] as String?),
      name: json['name'] as String? ?? '',
      ticker: json['ticker'] as String?,
      units: json['units'] != null
          ? double.tryParse(json['units'].toString())
          : null,
      purchasePrice: (json['purchasePrice'] is num)
          ? (json['purchasePrice'] as num).toDouble()
          : double.tryParse(json['purchasePrice']?.toString() ?? '0') ?? 0.0,
      currentPrice: json['currentPrice'] != null
          ? double.tryParse(json['currentPrice'].toString())
          : null,
      totalInvested: (json['totalInvested'] is num)
          ? (json['totalInvested'] as num).toDouble()
          : double.tryParse(json['totalInvested']?.toString() ?? '0') ?? 0.0,
      currentValue: json['currentValue'] != null
          ? double.tryParse(json['currentValue'].toString())
          : null,
      currency: TreasuryCurrency.fromJson(json['currency'] as String?),
      investmentDate: json['investmentDate'] != null
          ? DateTime.tryParse(json['investmentDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      maturityDate: json['maturityDate'] != null
          ? DateTime.tryParse(json['maturityDate'].toString())
          : null,
      interestRate: json['interestRate'] != null
          ? double.tryParse(json['interestRate'].toString())
          : null,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'companyId': companyId,
      'assetType': assetType.toJson(),
      'name': name,
      'purchasePrice': purchasePrice,
      'totalInvested': totalInvested,
      'currency': currency.toJson(),
      'investmentDate': investmentDate.toIso8601String(),
    };
    if (id != null) map['id'] = id;
    if (ticker != null && ticker!.isNotEmpty) map['ticker'] = ticker;
    if (units != null) map['units'] = units;
    if (currentPrice != null) map['currentPrice'] = currentPrice;
    if (currentValue != null) map['currentValue'] = currentValue;
    if (maturityDate != null) {
      map['maturityDate'] = maturityDate!.toIso8601String();
    }
    if (interestRate != null) map['interestRate'] = interestRate;
    if (notes != null && notes!.isNotEmpty) map['notes'] = notes;
    return map;
  }

  @override
  String toString() =>
      'TreasuryInvestment(id: $id, name: $name, type: ${assetType.value}, totalInvested: $totalInvested)';
}
