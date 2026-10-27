class BurnTrendPoint {
  final String month;
  final double expenseBurn;
  final double payrollBurn;
  final double totalBurn;

  const BurnTrendPoint({
    required this.month,
    required this.expenseBurn,
    required this.payrollBurn,
    required this.totalBurn,
  });

  factory BurnTrendPoint.fromJson(Map<String, dynamic> json) {
    return BurnTrendPoint(
      month: json['month']?.toString() ?? '',
      expenseBurn: _toDouble(json['expenseBurn']),
      payrollBurn: _toDouble(json['payrollBurn']),
      totalBurn: _toDouble(json['totalBurn']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'expenseBurn': expenseBurn,
      'payrollBurn': payrollBurn,
      'totalBurn': totalBurn,
    };
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  /// Formatted month label: "2026-05" -> "May"
  String get displayMonth {
    final parts = month.split('-');
    if (parts.length >= 2) {
      final monthIndex = int.tryParse(parts[1]);
      if (monthIndex != null && monthIndex >= 1 && monthIndex <= 12) {
        const monthNames = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        return monthNames[monthIndex - 1];
      }
    }
    return month;
  }
}

class BurnTrendResponse {
  final String companyId;
  final String currency;
  final List<BurnTrendPoint> points;

  const BurnTrendResponse({
    required this.companyId,
    required this.currency,
    required this.points,
  });

  factory BurnTrendResponse.fromJson(Map<String, dynamic> json) {
    final payload =
        (json.containsKey('data') && json['data'] is Map<String, dynamic>)
            ? json['data'] as Map<String, dynamic>
            : json;

    final companyId = payload['companyId']?.toString() ?? '';
    final currency = payload['currency']?.toString() ?? 'USD';

    final rawPoints = payload['data'];
    final List<BurnTrendPoint> points = [];
    if (rawPoints is List) {
      for (final item in rawPoints) {
        if (item is Map<String, dynamic>) {
          points.add(BurnTrendPoint.fromJson(item));
        }
      }
    }

    return BurnTrendResponse(
      companyId: companyId,
      currency: currency,
      points: points,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyId': companyId,
      'currency': currency,
      'data': points.map((p) => p.toJson()).toList(),
    };
  }

  /// Whether there is any non-zero burn data in the points.
  bool get hasBurnData =>
      points.any((p) => p.totalBurn > 0 || p.expenseBurn > 0 || p.payrollBurn > 0);

  String get currencySymbol {
    switch (currency.toUpperCase()) {
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'INR':
        return '₹';
      case 'USD':
      default:
        return '\$';
    }
  }
}
