import '../../../onboarding/domain/models/onboarding_models.dart';

class Company {
  final String? id;
  final String name;
  final String? legalName;
  final String? industry;
  final String? website;
  final String? logoUrl;
  final String? country;
  final String currency;
  final String stage;
  final DateTime? foundedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Company({
    this.id,
    required this.name,
    this.legalName,
    this.industry,
    this.website,
    this.logoUrl,
    this.country,
    this.currency = 'USD',
    this.stage = 'Pre-seed',
    this.foundedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      legalName: json['legalName'] as String?,
      industry: json['industry'] as String?,
      website: json['website'] as String?,
      logoUrl: json['logoUrl'] as String?,
      country: json['country'] as String?,
      currency: json['currency'] as String? ?? 'USD',
      stage: _enumToStage(json['stage'] as String?),
      foundedAt: json['foundedAt'] != null ? DateTime.tryParse(json['foundedAt'].toString()) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
    };
    if (id != null) map['id'] = id;
    if (legalName != null) map['legalName'] = legalName;
    if (industry != null) map['industry'] = industry;
    if (website != null) map['website'] = website;
    if (logoUrl != null) map['logoUrl'] = logoUrl;
    if (country != null) map['country'] = country;
    map['currency'] = currency;
    map['stage'] = _stageToEnum(stage);
    if (foundedAt != null) map['foundedAt'] = foundedAt!.toIso8601String();
    if (createdAt != null) map['createdAt'] = createdAt!.toIso8601String();
    if (updatedAt != null) map['updatedAt'] = updatedAt!.toIso8601String();
    return map;
  }

  Company copyWith({
    String? id,
    String? name,
    String? legalName,
    String? industry,
    String? website,
    String? logoUrl,
    String? country,
    String? currency,
    String? stage,
    DateTime? foundedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      legalName: legalName ?? this.legalName,
      industry: industry ?? this.industry,
      website: website ?? this.website,
      logoUrl: logoUrl ?? this.logoUrl,
      country: country ?? this.country,
      currency: currency ?? this.currency,
      stage: stage ?? this.stage,
      foundedAt: foundedAt ?? this.foundedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converts this [Company] domain model into [CompanyDetails] used by onboarding step
  CompanyDetails toCompanyDetails() {
    return CompanyDetails(
      name: name,
      legalName: legalName,
      industry: industry ?? '',
      stage: stage,
      country: country ?? '',
      currency: currency,
      foundedDate: foundedAt ?? DateTime.now(),
    );
  }

  /// Creates a [Company] domain model from onboarding [CompanyDetails]
  factory Company.fromCompanyDetails(CompanyDetails details, {String? id}) {
    return Company(
      id: id,
      name: details.name,
      legalName: details.legalName,
      industry: details.industry,
      stage: details.stage,
      country: details.country,
      currency: details.currency,
      foundedAt: details.foundedDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Company &&
        other.id == id &&
        other.name == name &&
        other.legalName == legalName &&
        other.industry == industry &&
        other.website == website &&
        other.logoUrl == logoUrl &&
        other.country == country &&
        other.currency == currency &&
        other.stage == stage &&
        other.foundedAt == foundedAt &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        legalName,
        industry,
        website,
        logoUrl,
        country,
        currency,
        stage,
        foundedAt,
        createdAt,
        updatedAt,
      );

  @override
  String toString() {
    return 'Company(id: $id, name: $name, legalName: $legalName, industry: $industry, stage: $stage, currency: $currency)';
  }
}

String _stageToEnum(String uiStage) {
  switch (uiStage) {
    case 'Idea': return 'IDEA';
    case 'Pre-seed': return 'PRE_SEED';
    case 'Seed': return 'SEED';
    case 'Series A': return 'SERIES_A';
    case 'Series B': return 'SERIES_B';
    case 'Series C':
    case 'Series C+': return 'SERIES_C';
    case 'Growth': return 'GROWTH';
    case 'IPO': return 'IPO';
    case 'Bootstrapped': return 'IDEA';
    default: return 'PRE_SEED';
  }
}

String _enumToStage(String? backendStage) {
  switch (backendStage) {
    case 'IDEA': return 'Idea';
    case 'PRE_SEED': return 'Pre-seed';
    case 'SEED': return 'Seed';
    case 'SERIES_A': return 'Series A';
    case 'SERIES_B': return 'Series B';
    case 'SERIES_C': return 'Series C+';
    case 'GROWTH': return 'Growth';
    case 'IPO': return 'IPO';
    default: return 'Pre-seed';
  }
}
