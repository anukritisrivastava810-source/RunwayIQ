import '../models/company.dart';

abstract class ICompanyRepository {
  /// Create a new company via POST /company
  Future<Company> createCompany(Company company);

  /// Fetch all companies via GET /company
  Future<List<Company>> getCompanies();

  /// Fetch a single company by ID via GET /company/:id
  Future<Company> getCompanyById(String id);

  /// Fetch a single company by name via GET /company/name/:name
  Future<Company> getCompanyByName(String name);

  /// Update an existing company via PUT /company/:id
  Future<Company> updateCompany(String id, Company company);

  /// Delete a company by ID via DELETE /company/:id
  Future<void> deleteCompany(String id);
}
