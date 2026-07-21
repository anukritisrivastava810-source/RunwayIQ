class CompanyDetails {
  final String name;
  final String? legalName;
  final String industry;
  final String stage;
  final String country;
  final String currency;
  final DateTime foundedDate;
  final String? registrationNumber;

  CompanyDetails({
    required this.name,
    this.legalName,
    required this.industry,
    required this.stage,
    required this.country,
    required this.currency,
    required this.foundedDate,
    this.registrationNumber,
  });
}

class FinancialSetup {
  final double currentCash;
  final double monthlyRevenue;
  final double monthlyExpenses;
  final double payroll;
  final String burnFrequency;
  final String currency;

  FinancialSetup({
    required this.currentCash,
    required this.monthlyRevenue,
    required this.monthlyExpenses,
    required this.payroll,
    required this.burnFrequency,
    required this.currency,
  });
}

class TeamSetup {
  final int teamSize;
  final List<String> departments;

  TeamSetup({
    required this.teamSize,
    required this.departments,
  });
}

class FundingDetails {
  final bool hasRaised;
  final String? round;
  final String? investorName;
  final double? amount;
  final double? equityPercentage;
  final DateTime? investmentDate;

  FundingDetails({
    required this.hasRaised,
    this.round,
    this.investorName,
    this.amount,
    this.equityPercentage,
    this.investmentDate,
  });
}

class TreasuryDetails {
  final bool hasInvestments;
  final List<String> investmentTypes;

  TreasuryDetails({
    required this.hasInvestments,
    required this.investmentTypes,
  });
}

class OnboardingData {
  CompanyDetails? company;
  FinancialSetup? financials;
  TeamSetup? team;
  FundingDetails? funding;
  TreasuryDetails? treasury;

  OnboardingData({
    this.company,
    this.financials,
    this.team,
    this.funding,
    this.treasury,
  });
}
