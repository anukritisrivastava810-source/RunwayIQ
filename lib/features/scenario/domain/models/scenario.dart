// Scenario domain model — matches the Prisma Scenario schema and backend
// POST /api/v1/scenarios/simulate response structure.

class Scenario {
  final String? id;
  final String companyId;
  final String name;
  final String? description;

  // Baseline snapshot
  final double baseCash;
  final double baseMonthlyBurn;
  final double baseMonthlyRevenue;
  final double baseRunwayMonths;

  // Adjustments
  final double additionalBurn;
  final double additionalRevenue;
  final double additionalCash;

  // Computed (stored for dashboard speed)
  final double? simulatedRunway;

  final String currency;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Scenario({
    this.id,
    required this.companyId,
    required this.name,
    this.description,
    this.baseCash = 0.0,
    this.baseMonthlyBurn = 0.0,
    this.baseMonthlyRevenue = 0.0,
    this.baseRunwayMonths = 0.0,
    this.additionalBurn = 0.0,
    this.additionalRevenue = 0.0,
    this.additionalCash = 0.0,
    this.simulatedRunway,
    this.currency = 'USD',
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  static double _parseDecimal(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  factory Scenario.fromJson(Map<String, dynamic> json) {
    return Scenario(
      id: json['id'] as String?,
      companyId: json['companyId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      baseCash: _parseDecimal(json['baseCash']),
      baseMonthlyBurn: _parseDecimal(json['baseMonthlyBurn']),
      baseMonthlyRevenue: _parseDecimal(json['baseMonthlyRevenue']),
      baseRunwayMonths: _parseDecimal(json['baseRunwayMonths']),
      additionalBurn: _parseDecimal(json['additionalBurn']),
      additionalRevenue: _parseDecimal(json['additionalRevenue']),
      additionalCash: _parseDecimal(json['additionalCash']),
      simulatedRunway: json['simulatedRunway'] != null
          ? _parseDecimal(json['simulatedRunway'])
          : null,
      currency: json['currency'] as String? ?? 'USD',
      isActive: json['isActive'] as bool? ?? true,
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
      'name': name,
      'baseCash': baseCash,
      'baseMonthlyBurn': baseMonthlyBurn,
      'baseMonthlyRevenue': baseMonthlyRevenue,
      'baseRunwayMonths': baseRunwayMonths,
      'additionalBurn': additionalBurn,
      'additionalRevenue': additionalRevenue,
      'additionalCash': additionalCash,
      'currency': currency,
      'isActive': isActive,
    };
    if (id != null) map['id'] = id;
    if (description != null && description!.isNotEmpty) {
      map['description'] = description;
    }
    if (simulatedRunway != null) map['simulatedRunway'] = simulatedRunway;
    return map;
  }

  Scenario copyWith({
    String? id,
    String? companyId,
    String? name,
    String? description,
    double? baseCash,
    double? baseMonthlyBurn,
    double? baseMonthlyRevenue,
    double? baseRunwayMonths,
    double? additionalBurn,
    double? additionalRevenue,
    double? additionalCash,
    double? simulatedRunway,
    String? currency,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Scenario(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      description: description ?? this.description,
      baseCash: baseCash ?? this.baseCash,
      baseMonthlyBurn: baseMonthlyBurn ?? this.baseMonthlyBurn,
      baseMonthlyRevenue: baseMonthlyRevenue ?? this.baseMonthlyRevenue,
      baseRunwayMonths: baseRunwayMonths ?? this.baseRunwayMonths,
      additionalBurn: additionalBurn ?? this.additionalBurn,
      additionalRevenue: additionalRevenue ?? this.additionalRevenue,
      additionalCash: additionalCash ?? this.additionalCash,
      simulatedRunway: simulatedRunway ?? this.simulatedRunway,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'Scenario(id: $id, name: $name, companyId: $companyId, '
      'additionalBurn: $additionalBurn, additionalRevenue: $additionalRevenue, '
      'additionalCash: $additionalCash)';
}

/// Matches the POST /api/v1/scenarios/simulate response JSON structure.
///
/// Backend response:
/// {
///   "statusCode": 200,
///   "success": true,
///   "data": {
///     "companyId": "...",
///     "scenarioId": "...",   // optional
///     "scenarioName": "...", // optional
///     "baseline": { "cash": ..., "burn": ..., "runway": ... },
///     "simulated": { "cash": ..., "burn": ..., "runway": ... },
///     "adjustments": { "additionalBurn": ..., "additionalRevenue": ..., "additionalCash": ... }
///   }
/// }
///
/// Note: `runway` is `null` in JSON when the backend returns Infinity
/// (JavaScript `Infinity` cannot be serialized to JSON; the backend lets it
/// serialize to `null`). Flutter interprets `null` runway as "unlimited runway".
class SimulationResult {
  final String companyId;
  final String? scenarioId;
  final String? scenarioName;
  final SimulationFinancials baseline;
  final SimulationFinancials simulated;
  final SimulationAdjustments adjustments;

  const SimulationResult({
    required this.companyId,
    this.scenarioId,
    this.scenarioName,
    required this.baseline,
    required this.simulated,
    required this.adjustments,
  });

  factory SimulationResult.fromJson(Map<String, dynamic> json) {
    return SimulationResult(
      companyId: json['companyId'] as String? ?? '',
      scenarioId: json['scenarioId'] as String?,
      scenarioName: json['scenarioName'] as String?,
      baseline: SimulationFinancials.fromJson(
        json['baseline'] as Map<String, dynamic>? ?? {},
      ),
      simulated: SimulationFinancials.fromJson(
        json['simulated'] as Map<String, dynamic>? ?? {},
      ),
      adjustments: SimulationAdjustments.fromJson(
        json['adjustments'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class SimulationFinancials {
  /// Cash remaining. May be negative if the company is over-extended.
  final double cash;

  /// Monthly burn. May be zero (break-even) or negative (cash-flow positive).
  final double burn;

  /// Runway in months, or null when the backend serializes Infinity as null.
  /// null  → unlimited runway (burn ≤ 0 and cash > 0)
  /// 0.0   → depleted (cash ≤ 0)
  /// >0.0  → finite runway
  final double? runway;

  const SimulationFinancials({
    required this.cash,
    required this.burn,
    this.runway,
  });

  static double _parseDecimal(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  factory SimulationFinancials.fromJson(Map<String, dynamic> json) {
    return SimulationFinancials(
      cash: _parseDecimal(json['cash']),
      burn: _parseDecimal(json['burn']),
      // null ← Infinity serialized by backend; keep null to let UI format it.
      runway: json['runway'] != null ? _parseDecimal(json['runway']) : null,
    );
  }
}

class SimulationAdjustments {
  final double additionalBurn;
  final double additionalRevenue;
  final double additionalCash;

  const SimulationAdjustments({
    required this.additionalBurn,
    required this.additionalRevenue,
    required this.additionalCash,
  });

  static double _parseDecimal(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  factory SimulationAdjustments.fromJson(Map<String, dynamic> json) {
    return SimulationAdjustments(
      additionalBurn: _parseDecimal(json['additionalBurn']),
      additionalRevenue: _parseDecimal(json['additionalRevenue']),
      additionalCash: _parseDecimal(json['additionalCash']),
    );
  }
}
