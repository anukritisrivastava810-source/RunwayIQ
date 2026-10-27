import '../../../department/domain/models/department.dart';

/// Matches the Prisma EmploymentStatus enum: ACTIVE | INACTIVE | NOTICE | RESIGNED
/// Also includes aliases for UI backwards compatibility.
enum EmploymentStatus {
  active('ACTIVE'),
  inactive('INACTIVE'),
  notice('NOTICE'),
  resigned('RESIGNED'),
  probation('PROBATION'),
  noticePeriod('NOTICE_PERIOD'),
  terminated('TERMINATED');

  final String value;
  const EmploymentStatus(this.value);

  /// Parses the backend string (e.g. 'ACTIVE') into this enum.
  /// Unknown values fall back to [active].
  static EmploymentStatus fromJson(String? value) {
    if (value == null) return EmploymentStatus.active;
    final upper = value.toUpperCase();
    for (final s in EmploymentStatus.values) {
      if (s.value == upper) return s;
    }
    if (upper == 'NOTICE') return EmploymentStatus.notice;
    if (upper == 'INACTIVE') return EmploymentStatus.inactive;
    return EmploymentStatus.active;
  }

  /// Returns valid Prisma EmploymentStatus enum string for backend persistence.
  String toJson() {
    switch (this) {
      case EmploymentStatus.active:
        return 'ACTIVE';
      case EmploymentStatus.inactive:
      case EmploymentStatus.probation:
      case EmploymentStatus.terminated:
        return 'INACTIVE';
      case EmploymentStatus.notice:
      case EmploymentStatus.noticePeriod:
        return 'NOTICE';
      case EmploymentStatus.resigned:
        return 'RESIGNED';
    }
  }

  String get displayName {
    switch (this) {
      case EmploymentStatus.active:
        return 'Active';
      case EmploymentStatus.inactive:
        return 'Inactive';
      case EmploymentStatus.notice:
      case EmploymentStatus.noticePeriod:
        return 'Notice Period';
      case EmploymentStatus.resigned:
        return 'Resigned';
      case EmploymentStatus.probation:
        return 'Probation';
      case EmploymentStatus.terminated:
        return 'Terminated';
    }
  }
}

enum EmployeeCurrency {
  usd('USD'),
  inr('INR'),
  eur('EUR'),
  gbp('GBP'),
  sgd('SGD'),
  aed('AED');

  final String value;
  const EmployeeCurrency(this.value);

  static EmployeeCurrency fromJson(String? value) {
    if (value == null) return EmployeeCurrency.usd;
    return EmployeeCurrency.values.firstWhere(
      (e) => e.value.toUpperCase() == value.toUpperCase(),
      orElse: () => EmployeeCurrency.usd,
    );
  }

  String toJson() => value;
}

class Employee {
  final String? id;
  final String companyId;
  final String departmentId;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final double annualSalary;
  final EmployeeCurrency currency;
  final EmploymentStatus status;
  final DateTime joinedAt;
  final DateTime? exitedAt;
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Department? department;

  const Employee({
    this.id,
    required this.companyId,
    required this.departmentId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.annualSalary,
    this.currency = EmployeeCurrency.usd,
    this.status = EmploymentStatus.active,
    required this.joinedAt,
    this.exitedAt,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
    this.department,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get departmentName => department?.name ?? '';

  /// Safely parses a value that may arrive from the backend as a [num] or as a
  /// decimal [String] (e.g. Prisma Decimal serialisation of annualSalary).
  static double _parseDecimal(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String?,
      companyId: json['companyId'] as String? ?? '',
      departmentId: json['departmentId'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      annualSalary: _parseDecimal(json['annualSalary']),
      currency: EmployeeCurrency.fromJson(json['currency'] as String?),
      status: EmploymentStatus.fromJson(json['status'] as String?),
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      exitedAt: json['exitedAt'] != null
          ? DateTime.tryParse(json['exitedAt'].toString())
          : null,
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      department: json['department'] is Map<String, dynamic>
          ? Department.fromJson(json['department'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'companyId': companyId,
      'departmentId': departmentId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role,
      'annualSalary': annualSalary,
      'currency': currency.toJson(),
      'status': status.toJson(),
      'joinedAt': joinedAt.toUtc().toIso8601String(),
    };
    if (id != null) map['id'] = id;
    if (exitedAt != null) map['exitedAt'] = exitedAt!.toUtc().toIso8601String();
    if (avatarUrl != null) map['avatarUrl'] = avatarUrl;
    return map;
  }

  Employee copyWith({
    String? id,
    String? companyId,
    String? departmentId,
    String? firstName,
    String? lastName,
    String? email,
    String? role,
    double? annualSalary,
    EmployeeCurrency? currency,
    EmploymentStatus? status,
    DateTime? joinedAt,
    DateTime? exitedAt,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    Department? department,
  }) {
    return Employee(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      departmentId: departmentId ?? this.departmentId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      role: role ?? this.role,
      annualSalary: annualSalary ?? this.annualSalary,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      exitedAt: exitedAt ?? this.exitedAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      department: department ?? this.department,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Employee &&
        other.id == id &&
        other.companyId == companyId &&
        other.departmentId == departmentId &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.email == email &&
        other.role == role &&
        other.annualSalary == annualSalary &&
        other.currency == currency &&
        other.status == status &&
        other.joinedAt == joinedAt &&
        other.exitedAt == exitedAt &&
        other.avatarUrl == avatarUrl;
  }

  @override
  int get hashCode => Object.hash(
        id,
        companyId,
        departmentId,
        firstName,
        lastName,
        email,
        role,
        annualSalary,
        currency,
        status,
        joinedAt,
        exitedAt,
        avatarUrl,
      );

  @override
  String toString() =>
      'Employee(id: $id, name: $fullName, role: $role, '
      'salary: $annualSalary, status: ${status.toJson()}, '
      'companyId: $companyId)';
}
