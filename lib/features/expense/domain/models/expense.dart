import 'package:flutter/material.dart';

enum ExpenseCategory {
  payroll('PAYROLL', 'Payroll', Icons.people, Colors.indigo),
  cloud('CLOUD', 'Cloud Services', Icons.cloud, Colors.blue),
  marketing('MARKETING', 'Marketing', Icons.campaign, Colors.orange),
  officeRent('OFFICE_RENT', 'Office Rent', Icons.business, Colors.purple),
  utilities('UTILITIES', 'Utilities', Icons.power, Colors.amber),
  legal('LEGAL', 'Legal & Professional', Icons.gavel, Colors.brown),
  software('SOFTWARE', 'Software Licenses', Icons.code, Colors.teal),
  travel('TRAVEL', 'Travel & Meals', Icons.flight, Colors.green),
  hardware('HARDWARE', 'Hardware', Icons.computer, Colors.cyan),
  other('OTHER', 'Other Operational', Icons.receipt_long, Colors.grey);

  final String value;
  final String displayName;
  final IconData icon;
  final Color color;

  const ExpenseCategory(this.value, this.displayName, this.icon, this.color);

  static ExpenseCategory fromJson(String? value) {
    if (value == null) return ExpenseCategory.other;
    return ExpenseCategory.values.firstWhere(
      (e) => e.value.toUpperCase() == value.toUpperCase(),
      orElse: () => ExpenseCategory.other,
    );
  }

  static ExpenseCategory fromDisplayName(String name) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.displayName.toLowerCase() == name.toLowerCase(),
      orElse: () => ExpenseCategory.other,
    );
  }

  String toJson() => value;
}

enum ExpenseRecurrence {
  oneTime('ONE_TIME', 'One-Time'),
  weekly('WEEKLY', 'Weekly'),
  monthly('MONTHLY', 'Monthly'),
  quarterly('QUARTERLY', 'Quarterly'),
  yearly('YEARLY', 'Yearly');

  final String value;
  final String displayName;

  const ExpenseRecurrence(this.value, this.displayName);

  static ExpenseRecurrence fromJson(String? value) {
    if (value == null) return ExpenseRecurrence.monthly;
    return ExpenseRecurrence.values.firstWhere(
      (e) => e.value.toUpperCase() == value.toUpperCase(),
      orElse: () => ExpenseRecurrence.monthly,
    );
  }

  static ExpenseRecurrence fromDisplayName(String name) {
    return ExpenseRecurrence.values.firstWhere(
      (e) => e.displayName.toLowerCase() == name.toLowerCase(),
      orElse: () => ExpenseRecurrence.monthly,
    );
  }

  String toJson() => value;
}

enum ExpenseCurrency {
  usd('USD'),
  inr('INR'),
  eur('EUR'),
  gbp('GBP'),
  sgd('SGD'),
  aed('AED');

  final String value;
  const ExpenseCurrency(this.value);

  static ExpenseCurrency fromJson(String? value) {
    if (value == null) return ExpenseCurrency.usd;
    return ExpenseCurrency.values.firstWhere(
      (e) => e.value.toUpperCase() == value.toUpperCase(),
      orElse: () => ExpenseCurrency.usd,
    );
  }

  String toJson() => value;
}

class Expense {
  final String? id;
  final String companyId;
  final String? departmentId;
  final String title;
  final String? description;
  final ExpenseCategory category;
  final double amount;
  final ExpenseCurrency currency;
  final ExpenseRecurrence recurrence;
  final DateTime expenseDate;
  final String? receiptUrl;
  final String? vendor;
  final bool isPaid;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Expense({
    this.id,
    required this.companyId,
    this.departmentId,
    required this.title,
    this.description,
    this.category = ExpenseCategory.other,
    required this.amount,
    this.currency = ExpenseCurrency.usd,
    this.recurrence = ExpenseRecurrence.monthly,
    required this.expenseDate,
    this.receiptUrl,
    this.vendor,
    this.isPaid = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String?,
      companyId: json['companyId'] as String? ?? '',
      departmentId: json['departmentId'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      category: ExpenseCategory.fromJson(json['category'] as String?),
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      currency: ExpenseCurrency.fromJson(json['currency'] as String?),
      recurrence: ExpenseRecurrence.fromJson(json['recurrence'] as String?),
      expenseDate: json['expenseDate'] != null
          ? DateTime.tryParse(json['expenseDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      receiptUrl: json['receiptUrl'] as String?,
      vendor: json['vendor'] as String?,
      isPaid: json['isPaid'] as bool? ?? false,
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
      'title': title,
      'category': category.toJson(),
      'amount': amount,
      'currency': currency.toJson(),
      'recurrence': recurrence.toJson(),
      'expenseDate': expenseDate.toIso8601String(),
      'isPaid': isPaid,
    };
    if (id != null) map['id'] = id;
    if (departmentId != null) map['departmentId'] = departmentId;
    if (description != null && description!.isNotEmpty) {
      map['description'] = description;
    }
    if (vendor != null && vendor!.isNotEmpty) map['vendor'] = vendor;
    if (receiptUrl != null && receiptUrl!.isNotEmpty) {
      map['receiptUrl'] = receiptUrl;
    }
    return map;
  }

  @override
  String toString() =>
      'Expense(id: $id, title: $title, category: ${category.value}, amount: $amount)';
}
