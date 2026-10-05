import 'package:flutter_test/flutter_test.dart';
import 'package:runway_iq/core/network/api_client.dart';
import 'package:runway_iq/core/network/api_exceptions.dart';
import 'package:runway_iq/features/funding/data/repositories/funding_round_repository.dart';
import 'package:runway_iq/features/funding/domain/models/funding_round.dart';
import 'package:runway_iq/features/investor/data/repositories/investor_repository.dart';
import 'package:runway_iq/features/investor/domain/models/investor.dart';

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
  group('FundingRound Model Unit Tests', () {
    test('fromJson and toJson round-trip with all fields', () {
      final json = {
        'id': 'fr-uuid-123',
        'companyId': 'comp-uuid-456',
        'investorId': 'inv-uuid-789',
        'roundType': 'SERIES_A',
        'amountRaised': '2500000.00',
        'currency': 'USD',
        'equityPercent': '0.15',
        'preMoneyVal': '10000000.00',
        'postMoneyVal': '12500000.00',
        'closedAt': '2025-06-15T00:00:00.000Z',
        'notes': 'Lead by Tier 1 VC',
        'createdAt': '2025-06-15T12:00:00.000Z',
        'updatedAt': '2025-06-15T12:00:00.000Z',
      };

      final round = FundingRound.fromJson(json);

      expect(round.id, 'fr-uuid-123');
      expect(round.companyId, 'comp-uuid-456');
      expect(round.investorId, 'inv-uuid-789');
      expect(round.roundType, FundingRoundType.seriesA);
      expect(round.amountRaised, 2500000.0);
      expect(round.currency, FundingCurrency.usd);
      expect(round.equityPercent, 0.15);
      expect(round.preMoneyVal, 10000000.0);
      expect(round.postMoneyVal, 12500000.0);
      expect(round.closedAt, DateTime.parse('2025-06-15T00:00:00.000Z'));
      expect(round.notes, 'Lead by Tier 1 VC');

      final outputJson = round.toJson();
      expect(outputJson['id'], 'fr-uuid-123');
      expect(outputJson['companyId'], 'comp-uuid-456');
      expect(outputJson['investorId'], 'inv-uuid-789');
      expect(outputJson['roundType'], 'SERIES_A');
      expect(outputJson['amountRaised'], 2500000.0);
      expect(outputJson['currency'], 'USD');
      expect(outputJson['equityPercent'], 0.15);
    });

    test('Parses numeric and string decimal amounts properly', () {
      final jsonWithNum = {
        'companyId': 'c1',
        'investorId': 'i1',
        'roundType': 'SEED',
        'amountRaised': 1500000,
        'equityPercent': 0.10,
        'closedAt': '2025-01-01T00:00:00.000Z',
      };
      final roundFromNum = FundingRound.fromJson(jsonWithNum);
      expect(roundFromNum.amountRaised, 1500000.0);
      expect(roundFromNum.equityPercent, 0.10);

      final jsonWithStr = {
        'companyId': 'c1',
        'investorId': 'i1',
        'roundType': 'SEED',
        'amountRaised': '1500000.50',
        'equityPercent': '0.125',
        'closedAt': '2025-01-01T00:00:00.000Z',
      };
      final roundFromStr = FundingRound.fromJson(jsonWithStr);
      expect(roundFromStr.amountRaised, 1500000.50);
      expect(roundFromStr.equityPercent, 0.125);
    });

    test('Enum conversion and display names work for all types', () {
      expect(FundingRoundType.preSeed.toJson(), 'PRE_SEED');
      expect(FundingRoundType.seed.toJson(), 'SEED');
      expect(FundingRoundType.seriesA.toJson(), 'SERIES_A');
      expect(FundingRoundType.seriesB.toJson(), 'SERIES_B');
      expect(FundingRoundType.seriesC.toJson(), 'SERIES_C');
      expect(FundingRoundType.bridge.toJson(), 'BRIDGE');
      expect(FundingRoundType.debt.toJson(), 'DEBT');
      expect(FundingRoundType.grant.toJson(), 'GRANT');
      expect(FundingRoundType.ipo.toJson(), 'IPO');

      expect(FundingRoundType.preSeed.displayName, 'Pre-Seed');
      expect(FundingRoundType.seed.displayName, 'Seed');
      expect(FundingRoundType.seriesA.displayName, 'Series A');
      expect(FundingRoundType.seriesB.displayName, 'Series B');
      expect(FundingRoundType.seriesC.displayName, 'Series C');

      expect(FundingRoundType.fromJson('PRE_SEED'), FundingRoundType.preSeed);
      expect(FundingRoundType.fromJson('SERIES_A'), FundingRoundType.seriesA);
      expect(FundingRoundType.fromJson('UNKNOWN'), FundingRoundType.seed);
    });
  });

  group('Investor Model Unit Tests', () {
    test('fromJson and toJson round-trip', () {
      final json = {
        'id': 'inv-1',
        'companyId': 'comp-1',
        'name': 'Sequoia Capital',
        'firmName': 'Sequoia',
        'email': 'partner@sequoia.com',
      };

      final investor = Investor.fromJson(json);
      expect(investor.id, 'inv-1');
      expect(investor.companyId, 'comp-1');
      expect(investor.name, 'Sequoia Capital');
      expect(investor.firmName, 'Sequoia');
      expect(investor.email, 'partner@sequoia.com');

      final output = investor.toJson();
      expect(output['id'], 'inv-1');
      expect(output['companyId'], 'comp-1');
      expect(output['name'], 'Sequoia Capital');
    });
  });

  group('FundingRoundRepository Unit Tests', () {
    late MockApiClient mockApiClient;
    late FundingRoundRepository repository;

    setUp(() {
      mockApiClient = MockApiClient();
      repository = FundingRoundRepository(apiClient: mockApiClient);
    });

    test('createFundingRound sends POST to /funding', () async {
      mockApiClient.postResponse = {
        'id': 'fr-new',
        'companyId': 'comp-1',
        'investorId': 'inv-1',
        'roundType': 'SEED',
        'amountRaised': 1000000.0,
        'currency': 'USD',
        'closedAt': '2025-01-01T00:00:00.000Z',
      };

      final input = FundingRound(
        companyId: 'comp-1',
        investorId: 'inv-1',
        roundType: FundingRoundType.seed,
        amountRaised: 1000000.0,
        closedAt: DateTime.parse('2025-01-01T00:00:00.000Z'),
      );

      final result = await repository.createFundingRound(input);

      expect(mockApiClient.lastPath, '/funding');
      expect(mockApiClient.lastData['companyId'], 'comp-1');
      expect(mockApiClient.lastData['investorId'], 'inv-1');
      expect(result.id, 'fr-new');
      expect(result.amountRaised, 1000000.0);
    });

    test('getFundingRoundsByCompany sends GET to /funding/company/:id and handles list', () async {
      mockApiClient.getResponse = [
        {
          'id': 'fr-1',
          'companyId': 'comp-1',
          'investorId': 'inv-1',
          'roundType': 'SEED',
          'amountRaised': 500000.0,
          'currency': 'USD',
          'closedAt': '2024-01-01T00:00:00.000Z',
        },
        {
          'id': 'fr-2',
          'companyId': 'comp-1',
          'investorId': 'inv-2',
          'roundType': 'SERIES_A',
          'amountRaised': 2000000.0,
          'currency': 'USD',
          'closedAt': '2025-01-01T00:00:00.000Z',
        },
      ];

      final results = await repository.getFundingRoundsByCompany('comp-1');

      expect(mockApiClient.lastPath, '/funding/company/comp-1');
      expect(results.length, 2);
      expect(results[0].roundType, FundingRoundType.seed);
      expect(results[1].roundType, FundingRoundType.seriesA);
    });

    test('getFundingRoundsByCompany returns empty list when company has no rounds', () async {
      mockApiClient.getResponse = [];

      final results = await repository.getFundingRoundsByCompany('comp-empty');

      expect(mockApiClient.lastPath, '/funding/company/comp-empty');
      expect(results, isEmpty);
    });

    test('handles NotFoundException properly', () async {
      mockApiClient.errorToThrow = NotFoundException('Funding round not found');

      expect(
        () => repository.getFundingRoundById('missing-id'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('handles ValidationException properly', () async {
      mockApiClient.errorToThrow = ValidationException('companyId is required');

      final input = FundingRound(
        companyId: '',
        investorId: '',
        roundType: FundingRoundType.seed,
        amountRaised: 0,
        closedAt: DateTime.now(),
      );

      expect(
        () => repository.createFundingRound(input),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('InvestorRepository Unit Tests', () {
    late MockApiClient mockApiClient;
    late InvestorRepository repository;

    setUp(() {
      mockApiClient = MockApiClient();
      repository = InvestorRepository(apiClient: mockApiClient);
    });

    test('createInvestor sends POST to /investor', () async {
      mockApiClient.postResponse = {
        'id': 'inv-created',
        'companyId': 'comp-1',
        'name': 'Andreessen Horowitz',
      };

      const input = Investor(companyId: 'comp-1', name: 'Andreessen Horowitz');
      final result = await repository.createInvestor(input);

      expect(mockApiClient.lastPath, '/investor');
      expect(mockApiClient.lastData['name'], 'Andreessen Horowitz');
      expect(result.id, 'inv-created');
    });

    test('getInvestorsByCompany sends GET with queryParameters', () async {
      mockApiClient.getResponse = [
        {'id': 'inv-1', 'companyId': 'comp-1', 'name': 'Investor A'},
      ];

      final results = await repository.getInvestorsByCompany('comp-1');

      expect(mockApiClient.lastPath, '/investor');
      expect(mockApiClient.lastQueryParams?['companyId'], 'comp-1');
      expect(results.length, 1);
      expect(results.first.name, 'Investor A');
    });
  });
}
