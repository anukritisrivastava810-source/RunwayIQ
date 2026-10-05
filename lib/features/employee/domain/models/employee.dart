import '../../../department/domain/models/department.dart';

enum EmploymentStatus {
  active('ACTIVE'),
  probation('PROBATION'),
  noticePeriod('NOTICE_PERIOD'),
  terminated('TERMINATED'),
  resigned('RESIGNED');

  final String value;
  const EmploymentStatus(this.value);

  static EmploymentStatus fromJson(String? value) {
    if (value == null) return EmploymentStatus.active;
    return EmploymentStatus.values.firstWhere(
      (e) => e.value.toUpperCase() == value.toUpperCase(),
      orElse: () => EmploymentStatus.active,
    );
  }

  String toJson() => value;
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

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String?,
      companyId: json['companyId'] as String? ?? '',
      departmentId: json['departmentId'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      annualSalary: (json['annualSalary'] is num)
          ? (json['annualSalary'] as num).toDouble()
          : double.tryParse(json['annualSalary']?.toString() ?? '0') ?? 0.0,
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
      'joinedAt': joinedAt.toIso8601String(),
    };
    if (id != null) map['id'] = id;
    if (exitedAt != null) map['exitedAt'] = exitedAt!.toIso8601String();
    if (avatarUrl != null) map['avatarUrl'] = avatarUrl;
    return map;
  }

  @override
  String toString() =>
      'Employee(id: $id, name: $fullName, role: $role, salary: $annualSalary)';
}
