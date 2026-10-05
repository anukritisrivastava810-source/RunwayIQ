/// Matches the Prisma FundingRoundType enum exactly.
/// These string values are what the backend sends and expects.
enum FundingRoundType {
  preSeed,
  seed,
  seriesA,
  seriesB,
  seriesC,
  bridge,
  debt,
  grant,
  ipo;

  /// Converts this enum value to the exact Prisma backend string (e.g. 'PRE_SEED').
  String toJson() {
    switch (this) {
      case FundingRoundType.preSeed:
        return 'PRE_SEED';
      case FundingRoundType.seed:
        return 'SEED';
      case FundingRoundType.seriesA:
        return 'SERIES_A';
      case FundingRoundType.seriesB:
        return 'SERIES_B';
      case FundingRoundType.seriesC:
        return 'SERIES_C';
      case FundingRoundType.bridge:
        return 'BRIDGE';
      case FundingRoundType.debt:
        return 'DEBT';
      case FundingRoundType.grant:
        return 'GRANT';
      case FundingRoundType.ipo:
        return 'IPO';
    }
  }

  /// UI-friendly display label.
  String get displayName {
    switch (this) {
      case FundingRoundType.preSeed:
        return 'Pre-Seed';
      case FundingRoundType.seed:
        return 'Seed';
      case FundingRoundType.seriesA:
        return 'Series A';
      case FundingRoundType.seriesB:
        return 'Series B';
      case FundingRoundType.seriesC:
        return 'Series C';
      case FundingRoundType.bridge:
        return 'Bridge';
      case FundingRoundType.debt:
        return 'Debt';
      case FundingRoundType.grant:
        return 'Grant';
      case FundingRoundType.ipo:
        return 'IPO';
    }
  }

  /// Parses a Prisma backend string (e.g. 'PRE_SEED') into this enum.
  static FundingRoundType fromJson(String? value) {
    switch (value) {
      case 'PRE_SEED':
        return FundingRoundType.preSeed;
      case 'SEED':
        return FundingRoundType.seed;
      case 'SERIES_A':
        return FundingRoundType.seriesA;
      case 'SERIES_B':
        return FundingRoundType.seriesB;
      case 'SERIES_C':
        return FundingRoundType.seriesC;
      case 'BRIDGE':
        return FundingRoundType.bridge;
      case 'DEBT':
        return FundingRoundType.debt;
      case 'GRANT':
        return FundingRoundType.grant;
      case 'IPO':
        return FundingRoundType.ipo;
      default:
        return FundingRoundType.seed;
    }
  }

  /// Parses a UI-friendly display name (e.g. 'Pre-seed', 'Series A') into this enum.
  static FundingRoundType fromDisplayName(String? value) {
    if (value == null) return FundingRoundType.seed;
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'pre-seed':
      case 'pre seed':
      case 'preseed':
        return FundingRoundType.preSeed;
      case 'seed':
        return FundingRoundType.seed;
      case 'series a':
        return FundingRoundType.seriesA;
      case 'series b':
        return FundingRoundType.seriesB;
      case 'series c':
      case 'series c+':
        return FundingRoundType.seriesC;
      case 'bridge':
        return FundingRoundType.bridge;
      case 'debt':
        return FundingRoundType.debt;
      case 'grant':
        return FundingRoundType.grant;
      case 'ipo':
        return FundingRoundType.ipo;
      default:
        return FundingRoundType.seed;
    }
  }
}

/// Matches the Prisma Currency enum exactly.
enum FundingCurrency {
  usd,
  inr,
  eur,
  gbp,
  sgd,
  aed;

  /// Converts to the exact Prisma backend string.
  String toJson() {
    switch (this) {
      case FundingCurrency.usd:
        return 'USD';
      case FundingCurrency.inr:
        return 'INR';
      case FundingCurrency.eur:
        return 'EUR';
      case FundingCurrency.gbp:
        return 'GBP';
      case FundingCurrency.sgd:
        return 'SGD';
      case FundingCurrency.aed:
        return 'AED';
    }
  }

  static FundingCurrency fromJson(String? value) {
    switch (value) {
      case 'INR':
        return FundingCurrency.inr;
      case 'EUR':
        return FundingCurrency.eur;
      case 'GBP':
        return FundingCurrency.gbp;
      case 'SGD':
        return FundingCurrency.sgd;
      case 'AED':
        return FundingCurrency.aed;
      case 'USD':
      default:
        return FundingCurrency.usd;
    }
  }
}

/// Domain model for a FundingRound, matching the Prisma FundingRound schema.
///
/// Prisma stores monetary values as Decimal (arbitrary precision). The backend
/// serialises them as JSON numbers or strings depending on the value. [_parseDecimal]
/// handles both transparently and converts to [double].
class FundingRound {
  final String? id;
  final String companyId;
  final String investorId;
  final FundingRoundType roundType;
  final double amountRaised;
  final FundingCurrency currency;
  final double? equityPercent;
  final double? preMoneyVal;
  final double? postMoneyVal;
  final DateTime closedAt;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FundingRound({
    this.id,
    required this.companyId,
    required this.investorId,
    required this.roundType,
    required this.amountRaised,
    this.currency = FundingCurrency.usd,
    this.equityPercent,
    this.preMoneyVal,
    this.postMoneyVal,
    required this.closedAt,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  /// Safely parses a value that may arrive from the backend as a [num] or as a
  /// decimal [String] (e.g. Prisma Decimal serialisation).
  static double? _parseDecimal(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  factory FundingRound.fromJson(Map<String, dynamic> json) {
    return FundingRound(
      id: json['id'] as String?,
      companyId: json['companyId'] as String? ?? '',
      investorId: json['investorId'] as String? ?? '',
      roundType: FundingRoundType.fromJson(json['roundType'] as String?),
      amountRaised: _parseDecimal(json['amountRaised']) ?? 0.0,
      currency: FundingCurrency.fromJson(json['currency'] as String?),
      equityPercent: _parseDecimal(json['equityPercent']),
      preMoneyVal: _parseDecimal(json['preMoneyVal']),
      postMoneyVal: _parseDecimal(json['postMoneyVal']),
      closedAt: json['closedAt'] != null
          ? DateTime.tryParse(json['closedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
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
      'investorId': investorId,
      'roundType': roundType.toJson(),
      'amountRaised': amountRaised,
      'currency': currency.toJson(),
      'closedAt': closedAt.toUtc().toIso8601String(),
    };

    if (id != null) map['id'] = id;
    if (equityPercent != null) map['equityPercent'] = equityPercent;
    if (preMoneyVal != null) map['preMoneyVal'] = preMoneyVal;
    if (postMoneyVal != null) map['postMoneyVal'] = postMoneyVal;
    if (notes != null) map['notes'] = notes;
    if (createdAt != null) map['createdAt'] = createdAt!.toUtc().toIso8601String();
    if (updatedAt != null) map['updatedAt'] = updatedAt!.toUtc().toIso8601String();

    return map;
  }

  FundingRound copyWith({
    String? id,
    String? companyId,
    String? investorId,
    FundingRoundType? roundType,
    double? amountRaised,
    FundingCurrency? currency,
    double? equityPercent,
    double? preMoneyVal,
    double? postMoneyVal,
    DateTime? closedAt,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FundingRound(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      investorId: investorId ?? this.investorId,
      roundType: roundType ?? this.roundType,
      amountRaised: amountRaised ?? this.amountRaised,
      currency: currency ?? this.currency,
      equityPercent: equityPercent ?? this.equityPercent,
      preMoneyVal: preMoneyVal ?? this.preMoneyVal,
      postMoneyVal: postMoneyVal ?? this.postMoneyVal,
      closedAt: closedAt ?? this.closedAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FundingRound &&
        other.id == id &&
        other.companyId == companyId &&
        other.investorId == investorId &&
        other.roundType == roundType &&
        other.amountRaised == amountRaised &&
        other.currency == currency &&
        other.equityPercent == equityPercent &&
        other.preMoneyVal == preMoneyVal &&
        other.postMoneyVal == postMoneyVal &&
        other.closedAt == closedAt &&
        other.notes == notes &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        companyId,
        investorId,
        roundType,
        amountRaised,
        currency,
        equityPercent,
        preMoneyVal,
        postMoneyVal,
        closedAt,
        notes,
        createdAt,
        updatedAt,
      );

  @override
  String toString() {
    return 'FundingRound(id: $id, companyId: $companyId, investorId: $investorId, '
        'roundType: ${roundType.toJson()}, amountRaised: $amountRaised, '
        'currency: ${currency.toJson()}, closedAt: $closedAt)';
  }
}
