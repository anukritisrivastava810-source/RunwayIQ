import 'package:flutter_test/flutter_test.dart';
import 'package:runway_iq/core/network/api_client.dart';
import 'package:runway_iq/core/network/api_exceptions.dart';
import 'package:runway_iq/features/company/data/repositories/company_repository.dart';
import 'package:runway_iq/features/company/domain/models/company.dart';
import 'package:runway_iq/features/onboarding/domain/models/onboarding_models.dart';

class MockApiClient extends ApiClient {
  dynamic getResponse;
  dynamic postResponse;
  dynamic putResponse;
  dynamic deleteResponse;

  Exception? errorToThrow;

  String? lastPath;
  dynamic lastData;
  Map<String, dynamic>? lastQueryParams;

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    lastPath = path;
    lastQueryParams = queryParameters;
    if (errorToThrow != null) throw errorToThrow!;
    return getResponse;
  }

  @override
  Future<dynamic> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    lastPath = path;
    lastData = data;
    lastQueryParams = queryParameters;
    if (errorToThrow != null) throw errorToThrow!;
    return postResponse;
  }

  @override
  Future<dynamic> put(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    lastPath = path;
    lastData = data;
    lastQueryParams = queryParameters;
    if (errorToThrow != null) throw errorToThrow!;
    return putResponse;
  }

  @override
  Future<dynamic> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    lastPath = path;
    lastData = data;
    lastQueryParams = queryParameters;
    if (errorToThrow != null) throw errorToThrow!;
    return deleteResponse;
  }
}

void main() {
  group('Company Model Unit Tests', () {
    test('fromJson and toJson round-trip', () {
      final json = {
        'id': 'comp-uuid-123',
        'name': 'TechCorp Inc',
        'legalName': 'TechCorp Incorporated',
        'industry': 'SaaS',
        'website': 'https://techcorp.io',
        'logoUrl': 'https://techcorp.io/logo.png',
        'country': 'USA',
        'currency': 'USD',
        'stage': 'SERIES_A',
        'foundedAt': '2024-01-15T00:00:00.000Z',
        'createdAt': '2024-02-01T10:00:00.000Z',
        'updatedAt': '2024-02-02T12:00:00.000Z',
      };

      final company = Company.fromJson(json);

      expect(company.id, 'comp-uuid-123');
      expect(company.name, 'TechCorp Inc');
      expect(company.legalName, 'TechCorp Incorporated');
      expect(company.industry, 'SaaS');
      expect(company.website, 'https://techcorp.io');
      expect(company.logoUrl, 'https://techcorp.io/logo.png');
      expect(company.country, 'USA');
      expect(company.currency, 'USD');
      expect(company.stage, 'SERIES_A');
      expect(company.foundedAt, DateTime.parse('2024-01-15T00:00:00.000Z'));

      final outputJson = company.toJson();
      expect(outputJson['id'], 'comp-uuid-123');
      expect(outputJson['name'], 'TechCorp Inc');
      expect(outputJson['currency'], 'USD');
      expect(outputJson['stage'], 'SERIES_A');
    });

    test('copyWith updates fields properly', () {
      const company = Company(
        id: '1',
        name: 'Alpha Ltd',
        industry: 'FinTech',
      );

      final updated = company.copyWith(name: 'Alpha AI', stage: 'SEED');

      expect(updated.id, '1');
      expect(updated.name, 'Alpha AI');
      expect(updated.industry, 'FinTech');
      expect(updated.stage, 'SEED');
    });

    test('Company to CompanyDetails and back interop', () {
      final companyDetails = CompanyDetails(
        name: 'Beta Software',
        legalName: 'Beta Software LLC',
        industry: 'AI',
        stage: 'SEED',
        country: 'India',
        currency: 'INR',
        foundedDate: DateTime(2023, 5, 10),
      );

      final company = Company.fromCompanyDetails(companyDetails, id: 'beta-123');
      expect(company.id, 'beta-123');
      expect(company.name, 'Beta Software');
      expect(company.currency, 'INR');

      final backToDetails = company.toCompanyDetails();
      expect(backToDetails.name, 'Beta Software');
      expect(backToDetails.industry, 'AI');
      expect(backToDetails.currency, 'INR');
    });
  });

  group('CompanyRepository Unit Tests', () {
    late MockApiClient mockApiClient;
    late CompanyRepository repository;

    setUp(() {
      mockApiClient = MockApiClient();
      repository = CompanyRepository(apiClient: mockApiClient);
    });

    test('createCompany sends POST request to /company and parses result', () async {
      mockApiClient.postResponse = {
        'id': 'comp-999',
        'name': 'Nova Labs',
        'currency': 'USD',
        'stage': 'PRE_SEED',
      };

      const inputCompany = Company(name: 'Nova Labs');
      final result = await repository.createCompany(inputCompany);

      expect(mockApiClient.lastPath, '/company');
      expect(mockApiClient.lastData['name'], 'Nova Labs');
      expect(result.id, 'comp-999');
      expect(result.name, 'Nova Labs');
    });

    test('getCompanies sends GET request to /company and parses list', () async {
      mockApiClient.getResponse = [
        {'id': '1', 'name': 'Comp 1'},
        {'id': '2', 'name': 'Comp 2'},
      ];

      final results = await repository.getCompanies();

      expect(mockApiClient.lastPath, '/company');
      expect(results.length, 2);
      expect(results[0].name, 'Comp 1');
      expect(results[1].name, 'Comp 2');
    });

    test('getCompanyById sends GET request to /company/:id', () async {
      mockApiClient.getResponse = {'id': 'comp-123', 'name': 'Found Company'};

      final result = await repository.getCompanyById('comp-123');

      expect(mockApiClient.lastPath, '/company/comp-123');
      expect(result.id, 'comp-123');
      expect(result.name, 'Found Company');
    });

    test('getCompanyByName sends GET request to /company/name/:name with URL encoding', () async {
      mockApiClient.getResponse = {'id': 'comp-456', 'name': 'Acme & Co'};

      final result = await repository.getCompanyByName('Acme & Co');

      expect(mockApiClient.lastPath, '/company/name/Acme%20%26%20Co');
      expect(result.name, 'Acme & Co');
    });

    test('updateCompany sends PUT request to /company/:id', () async {
      mockApiClient.putResponse = {'id': 'comp-789', 'name': 'Updated Corp'};

      const company = Company(name: 'Updated Corp');
      final result = await repository.updateCompany('comp-789', company);

      expect(mockApiClient.lastPath, '/company/comp-789');
      expect(result.name, 'Updated Corp');
    });

    test('deleteCompany sends DELETE request to /company/:id', () async {
      mockApiClient.deleteResponse = {'success': true, 'message': 'Company deleted successfully'};

      await repository.deleteCompany('comp-789');

      expect(mockApiClient.lastPath, '/company/comp-789');
    });

    test('handles NotFoundException gracefully', () async {
      mockApiClient.errorToThrow = NotFoundException('Company not found');

      expect(
        () => repository.getCompanyById('non-existent'),
        throwsA(isA<NotFoundException>().having((e) => e.message, 'message', contains('not found'))),
      );
    });

    test('handles NetworkException when internet fails', () async {
      mockApiClient.errorToThrow = NetworkException('No internet connection');

      expect(
        () => repository.getCompanies(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('handles ServerException when server error or conflict occurs', () async {
      mockApiClient.errorToThrow = ServerException('Company with this name already exists');

      expect(
        () => repository.createCompany(const Company(name: 'Existing')),
        throwsA(isA<ServerException>().having((e) => e.message, 'message', contains('already exists'))),
      );
    });

    test('handles ValidationException for 400/422 requests', () async {
      mockApiClient.errorToThrow = ValidationException('Company name is required');

      expect(
        () => repository.createCompany(const Company(name: '')),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
