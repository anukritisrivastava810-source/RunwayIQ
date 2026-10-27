import '../models/treasury_investment.dart';
import '../models/market_quote.dart';

abstract class ITreasuryRepository {
  Future<TreasuryInvestment> createTreasuryInvestment(TreasuryInvestment investment);
  Future<List<TreasuryInvestment>> getAllTreasuryInvestments();
  Future<TreasuryInvestment> getTreasuryInvestmentById(String id);
  Future<List<TreasuryInvestment>> getTreasuryInvestmentsByCompany(String companyId);
  Future<TreasuryInvestment> updateTreasuryInvestment(String id, TreasuryInvestment investment);
  Future<void> deleteTreasuryInvestment(String id);
  Future<MarketQuote> getInvestmentQuote(String id, {bool? forceRefresh});
}
