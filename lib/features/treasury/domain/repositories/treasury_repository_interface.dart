import '../models/treasury_investment.dart';

abstract class ITreasuryRepository {
  Future<TreasuryInvestment> createTreasuryInvestment(TreasuryInvestment investment);
  Future<List<TreasuryInvestment>> getAllTreasuryInvestments();
  Future<TreasuryInvestment> getTreasuryInvestmentById(String id);
  Future<List<TreasuryInvestment>> getTreasuryInvestmentsByCompany(String companyId);
  Future<TreasuryInvestment> updateTreasuryInvestment(String id, TreasuryInvestment investment);
  Future<void> deleteTreasuryInvestment(String id);
}
