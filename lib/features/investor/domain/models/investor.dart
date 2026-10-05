/// Minimal domain model for an Investor, matching the Prisma Investor schema.
///
/// Prisma schema:
///   model Investor {
///     id          String   @id @default(uuid())
///     companyId   String
///     name        String
///     firmName    String?
///     email       String?
///     logoUrl     String?
///     linkedinUrl String?
///     createdAt   DateTime @default(now())
///     updatedAt   DateTime @updatedAt
///   }
class Investor {
  final String? id;
  final String companyId;
  final String name;
  final String? firmName;
  final String? email;
  final String? logoUrl;
  final String? linkedinUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Investor({
    this.id,
    required this.companyId,
    required this.name,
    this.firmName,
    this.email,
    this.logoUrl,
    this.linkedinUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory Investor.fromJson(Map<String, dynamic> json) {
    return Investor(
      id: json['id'] as String?,
      companyId: json['companyId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      firmName: json['firmName'] as String?,
      email: json['email'] as String?,
      logoUrl: json['logoUrl'] as String?,
      linkedinUrl: json['linkedinUrl'] as String?,
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
    };
    if (id != null) map['id'] = id;
    if (firmName != null) map['firmName'] = firmName;
    if (email != null) map['email'] = email;
    if (logoUrl != null) map['logoUrl'] = logoUrl;
    if (linkedinUrl != null) map['linkedinUrl'] = linkedinUrl;
    return map;
  }

  @override
  String toString() =>
      'Investor(id: $id, companyId: $companyId, name: $name)';
}
