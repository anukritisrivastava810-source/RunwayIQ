/// Domain model for Department, matching Prisma Department schema.
class Department {
  final String? id;
  final String companyId;
  final String name;
  final int headCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Department({
    this.id,
    required this.companyId,
    required this.name,
    this.headCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] as String?,
      companyId: json['companyId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      headCount: json['headCount'] as int? ?? 0,
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
      'headCount': headCount,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  @override
  String toString() => 'Department(id: $id, name: $name, headCount: $headCount)';
}
