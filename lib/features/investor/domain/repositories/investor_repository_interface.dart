import '../models/investor.dart';

abstract class IInvestorRepository {
  /// Create a new investor via POST /investor
  Future<Investor> createInvestor(Investor investor);

  /// Fetch all investors for a company via GET /investor?companyId=...
  Future<List<Investor>> getInvestorsByCompany(String companyId);

  /// Fetch a single investor by ID via GET /investor/:id
  Future<Investor> getInvestorById(String id);
}
