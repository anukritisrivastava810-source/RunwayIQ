import 'package:flutter_test/flutter_test.dart';
import 'package:runway_iq/core/network/api_client.dart';
import 'package:runway_iq/core/network/api_exceptions.dart';
import 'package:runway_iq/features/treasury/data/repositories/treasury_repository.dart';
import 'package:runway_iq/features/treasury/domain/models/treasury_investment.dart';

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
  group('Treasury Model & Repository Tests', () {
    test('TreasuryInvestment fromJson and toJson round-trip', () {
      final json = {
        'id': 'treasury-1',
        'companyId': 'comp-1',
        'assetType': 'BOND',
        'name': 'US Treasury 3-Month Bills',
        'purchasePrice': 50000.0,
        'totalInvested': 50000.0,
        'currency': 'USD',
        'investmentDate': '2026-01-10T00:00:00.000Z',
        'maturityDate': '2026-04-10T00:00:00.000Z',
        'interestRate': 0.0525,
        'notes': 'Purchased via TreasuryDirect',
      };

      final inv = TreasuryInvestment.fromJson(json);
      expect(inv.id, 'treasury-1');
      expect(inv.name, 'US Treasury 3-Month Bills');
      expect(inv.assetType, AssetType.bond);
      expect(inv.totalInvested, 50000.0);
      expect(inv.currency, TreasuryCurrency.usd);
      expect(inv.interestRate, 0.0525);
      expect(inv.notes, 'Purchased via TreasuryDirect');

      final outJson = inv.toJson();
      expect(outJson['assetType'], 'BOND');
      expect(outJson['name'], 'US Treasury 3-Month Bills');
      expect(outJson['totalInvested'], 50000.0);
      expect(outJson['interestRate'], 0.0525);
    });

    test('TreasuryRepository creates investment via POST /treasury', () async {
      final mockClient = MockApiClient();
      final repo = TreasuryRepository(apiClient: mockClient);

      mockClient.postResponse = {
        'data': {
          'id': 'inv-created',
          'companyId': 'comp-1',
          'assetType': 'FIXED_DEPOSIT',
          'name': 'Goldman Sachs 6-Month CD',
          'purchasePrice': 100000.0,
          'totalInvested': 100000.0,
          'currency': 'USD',
          'investmentDate': '2026-02-15T00:00:00.000Z',
        }
      };

      final created = await repo.createTreasuryInvestment(
        TreasuryInvestment(
          companyId: 'comp-1',
          assetType: AssetType.fixedDeposit,
          name: 'Goldman Sachs 6-Month CD',
          purchasePrice: 100000.0,
          totalInvested: 100000.0,
          investmentDate: DateTime(2026, 2, 15),
        ),
      );

      expect(created.id, 'inv-created');
      expect(mockClient.lastPath, '/treasury');
      expect(mockClient.lastData['assetType'], 'FIXED_DEPOSIT');
    });

    test('TreasuryRepository retrieves investments by company', () async {
      final mockClient = MockApiClient();
      final repo = TreasuryRepository(apiClient: mockClient);

      mockClient.getResponse = {
        'data': [
          {
            'id': 'inv-1',
            'companyId': 'comp-1',
            'assetType': 'BOND',
            'name': 'US Treasury 3-Month Bills',
            'purchasePrice': 50000.0,
            'totalInvested': 50000.0,
            'currency': 'USD',
            'investmentDate': '2026-01-10T00:00:00.000Z',
          }
        ]
      };

      final list = await repo.getTreasuryInvestmentsByCompany('comp-1');
      expect(list.length, 1);
      expect(list.first.name, 'US Treasury 3-Month Bills');
      expect(mockClient.lastPath, '/treasury/company/comp-1');
    });

    test('TreasuryRepository handles NotFoundException properly', () async {
      final mockClient = MockApiClient();
      final repo = TreasuryRepository(apiClient: mockClient);

      mockClient.errorToThrow = NotFoundException('Holding not found');

      expect(
        () => repo.getTreasuryInvestmentById('non-existent'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('Market-priced investment serialization preserves ticker, units, purchasePrice, and does not populate currentPrice with purchasePrice', () {
      final stockInv = TreasuryInvestment(
        companyId: 'comp-1',
        assetType: AssetType.stock,
        name: 'Apple Inc.',
        ticker: 'AAPL',
        units: 50.0,
        purchasePrice: 150.0,
        totalInvested: 7500.0,
        currency: TreasuryCurrency.usd,
        investmentDate: DateTime(2026, 3, 1),
      );

      final json = stockInv.toJson();
      expect(json['assetType'], 'STOCK');
      expect(json['name'], 'Apple Inc.');
      expect(json['ticker'], 'AAPL');
      expect(json['units'], 50.0);
      expect(json['purchasePrice'], 150.0);
      expect(json['totalInvested'], 7500.0);
      expect(json['currentPrice'], isNull); // Never populated from purchasePrice!
      expect(json['currentValue'], isNull);

      // Round-trip verification
      final restored = TreasuryInvestment.fromJson(json);
      expect(restored.ticker, 'AAPL');
      expect(restored.units, 50.0);
      expect(restored.purchasePrice, 150.0);
      expect(restored.totalInvested, 7500.0);
      expect(restored.currentPrice, isNull);
    });

    test('Non-market investment serialization excludes ticker and units', () {
      final bondInv = TreasuryInvestment(
        companyId: 'comp-1',
        assetType: AssetType.bond,
        name: 'US Treasury Note',
        ticker: null,
        units: null,
        purchasePrice: 20000.0,
        totalInvested: 20000.0,
        currency: TreasuryCurrency.usd,
        investmentDate: DateTime(2026, 1, 1),
      );

      final json = bondInv.toJson();
      expect(json['assetType'], 'BOND');
      expect(json.containsKey('ticker'), isFalse);
      expect(json.containsKey('units'), isFalse);
      expect(json['purchasePrice'], 20000.0);
      expect(json['totalInvested'], 20000.0);
    });

    test('TreasuryRepository updates investment via PUT /treasury/:id', () async {
      final mockClient = MockApiClient();
      final repo = TreasuryRepository(apiClient: mockClient);

      mockClient.putResponse = {
        'data': {
          'id': 'inv-123',
          'companyId': 'comp-1',
          'assetType': 'STOCK',
          'name': 'Apple Stock Holding',
          'ticker': 'AAPL',
          'units': 75.0,
          'purchasePrice': 160.0,
          'totalInvested': 12000.0,
          'currency': 'USD',
          'investmentDate': '2026-03-01T00:00:00.000Z',
        }
      };

      final updated = await repo.updateTreasuryInvestment(
        'inv-123',
        TreasuryInvestment(
          id: 'inv-123',
          companyId: 'comp-1',
          assetType: AssetType.stock,
          name: 'Apple Stock Holding',
          ticker: 'AAPL',
          units: 75.0,
          purchasePrice: 160.0,
          totalInvested: 12000.0,
          investmentDate: DateTime(2026, 3, 1),
        ),
      );

      expect(updated.id, 'inv-123');
      expect(updated.ticker, 'AAPL');
      expect(updated.units, 75.0);
      expect(mockClient.lastPath, '/treasury/inv-123');
      expect(mockClient.lastData['units'], 75.0);
      expect(mockClient.lastData['ticker'], 'AAPL');
      expect(mockClient.lastData['totalInvested'], 12000.0);
    });
  });
}
