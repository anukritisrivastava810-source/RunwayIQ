import '../models/funding_round.dart';

abstract class IFundingRoundRepository {
  /// Create a new funding round via POST /funding
  Future<FundingRound> createFundingRound(FundingRound fundingRound);

  /// Fetch all funding rounds via GET /funding
  Future<List<FundingRound>> getAllFundingRounds();

  /// Fetch a single funding round by ID via GET /funding/:id
  Future<FundingRound> getFundingRoundById(String id);

  /// Fetch all funding rounds for a company via GET /funding/company/:companyId
  Future<List<FundingRound>> getFundingRoundsByCompany(String companyId);

  /// Update an existing funding round via PUT /funding/:id
  Future<FundingRound> updateFundingRound(String id, FundingRound fundingRound);

  /// Delete a funding round by ID via DELETE /funding/:id
  Future<void> deleteFundingRound(String id);
}
