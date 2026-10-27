import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runway_iq/core/network/api_exceptions.dart';
import 'package:runway_iq/features/company/data/repositories/company_repository.dart';
import 'package:runway_iq/features/company/domain/models/company.dart';
import 'package:runway_iq/features/treasury/data/repositories/treasury_repository.dart';
import 'package:runway_iq/features/treasury/domain/models/treasury_investment.dart';
import 'package:runway_iq/features/treasury/domain/models/market_quote.dart';
import 'package:runway_iq/screens/treasury_screen.dart';

class MockTreasuryRepository extends TreasuryRepository {
  List<TreasuryInvestment> investmentsToReturn = [];
  Map<String, MarketQuote> quotesToReturn = {};
  Map<String, Exception> quoteErrorsToThrow = {};

  final List<String> quoteCalls = [];
  final List<bool?> forceRefreshCalls = [];

  @override
  Future<List<TreasuryInvestment>> getTreasuryInvestmentsByCompany(String companyId) async {
    return investmentsToReturn;
  }

  @override
  Future<MarketQuote> getInvestmentQuote(String id, {bool? forceRefresh}) async {
    quoteCalls.add(id);
    forceRefreshCalls.add(forceRefresh);

    if (quoteErrorsToThrow.containsKey(id)) {
      throw quoteErrorsToThrow[id]!;
    }

    if (quotesToReturn.containsKey(id)) {
      return quotesToReturn[id]!;
    }

    throw NotFoundException('Quote not found');
  }
}

class MockCompanyRepository extends CompanyRepository {
  List<Company> companiesToReturn = [];

  @override
  Future<List<Company>> getCompanies() async {
    return companiesToReturn;
  }
}

void main() {
  group('MarketQuote Model Unit Tests', () {
    test('correctly calculates unrealized P/L and P/L percentage', () {
      final quote = MarketQuote(
        investmentId: 'inv-1',
        companyId: 'comp-1',
        name: 'Apple Inc.',
        assetType: 'STOCK',
        ticker: 'AAPL',
        price: 200.0,
        currency: 'USD',
        units: 50.0,
        currentValue: 10000.0, // 200 * 50
        totalInvested: 8000.0,
        retrievedAt: DateTime.now(),
      );

      expect(quote.unrealizedGainLoss, 2000.0);
      expect(quote.unrealizedGainLossPercent, 25.0); // (2000 / 8000) * 100 = 25%
    });

    test('handles negative unrealized P/L (loss) correctly', () {
      final quote = MarketQuote(
        investmentId: 'inv-2',
        companyId: 'comp-1',
        name: 'Tesla Inc.',
        assetType: 'STOCK',
        ticker: 'TSLA',
        price: 150.0,
        currency: 'USD',
        units: 10.0,
        currentValue: 1500.0,
        totalInvested: 2000.0,
        retrievedAt: DateTime.now(),
      );

      expect(quote.unrealizedGainLoss, -500.0);
      expect(quote.unrealizedGainLossPercent, -25.0); // (-500 / 2000) * 100 = -25%
    });

    test('guards against zero totalInvested without dividing by zero', () {
      final quote = MarketQuote(
        investmentId: 'inv-3',
        companyId: 'comp-1',
        name: 'Free Grant Stock',
        assetType: 'STOCK',
        ticker: 'GRNT',
        price: 10.0,
        currency: 'USD',
        units: 100.0,
        currentValue: 1000.0,
        totalInvested: 0.0,
        retrievedAt: DateTime.now(),
      );

      expect(quote.unrealizedGainLoss, isNull);
      expect(quote.unrealizedGainLossPercent, isNull);
    });

    test('parses cache metadata, stale flag, and delayed provider status correctly', () {
      final json = {
        'investmentId': 'inv-1',
        'companyId': 'comp-1',
        'name': 'Apple Stock',
        'assetType': 'STOCK',
        'ticker': 'AAPL',
        'price': '192.45',
        'currency': 'USD',
        'units': '100',
        'currentValue': '19245.0',
        'totalInvested': '15000.0',
        'persisted': true,
        'retrievedAt': '2026-10-27T07:14:11.124Z',
        'cached': true,
        'cacheStatus': 'HIT',
        'source': 'CACHE',
        'ageSeconds': 42,
        'isRealTime': false,
        'isStale': false,
      };

      final quote = MarketQuote.fromJson(json);
      expect(quote.ticker, 'AAPL');
      expect(quote.price, 192.45);
      expect(quote.units, 100.0);
      expect(quote.currentValue, 19245.0);
      expect(quote.cached, isTrue);
      expect(quote.cacheStatus, 'HIT');
      expect(quote.ageSeconds, 42);
      expect(quote.isRealTime, isFalse);
      expect(quote.isStale, isFalse);
    });
  });

  group('TreasuryScreen Market Valuations UI Integration Tests', () {
    late MockTreasuryRepository mockRepo;
    late MockCompanyRepository mockCompanyRepo;

    setUp(() {
      mockRepo = MockTreasuryRepository();
      mockCompanyRepo = MockCompanyRepository();
      mockCompanyRepo.companiesToReturn = [
        Company(
          id: 'test-comp-1',
          name: 'Acme Corp',
          industry: 'Software',
          currency: 'USD',
          createdAt: DateTime(2026, 1, 1),
        ),
      ];
    });

    testWidgets('renders Market Assets Valuation card with aggregate value, cost, and P/L', (tester) async {
      final stockHolding = TreasuryInvestment(
        id: 'stock-1',
        companyId: 'test-comp-1',
        assetType: AssetType.stock,
        name: 'Apple Inc.',
        ticker: 'AAPL',
        units: 50.0,
        purchasePrice: 150.0,
        totalInvested: 7500.0,
        currency: TreasuryCurrency.usd,
        investmentDate: DateTime(2026, 1, 15),
      );

      final bondHolding = TreasuryInvestment(
        id: 'bond-1',
        companyId: 'test-comp-1',
        assetType: AssetType.bond,
        name: 'US Treasury 6M Bill',
        totalInvested: 25000.0,
        purchasePrice: 25000.0,
        currency: TreasuryCurrency.usd,
        investmentDate: DateTime(2026, 1, 15),
        interestRate: 0.052,
      );

      mockRepo.investmentsToReturn = [stockHolding, bondHolding];
      mockRepo.quotesToReturn['stock-1'] = MarketQuote(
        investmentId: 'stock-1',
        companyId: 'test-comp-1',
        name: 'Apple Inc.',
        assetType: 'STOCK',
        ticker: 'AAPL',
        price: 200.0, // price rose from 150 to 200
        currency: 'USD',
        units: 50.0,
        currentValue: 10000.0, // 50 * 200
        totalInvested: 7500.0,
        cached: true,
        cacheStatus: 'HIT',
        source: 'CACHE',
        ageSeconds: 30,
        isRealTime: false,
        retrievedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TreasuryScreen(
            treasuryRepository: mockRepo,
            companyRepository: mockCompanyRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Market Assets Valuation card is displayed
      expect(find.text('Market Assets Valuation'), findsOneWidget);
      expect(find.text('15m delay'), findsWidgets);

      // 2. Market portfolio shows calculated valuation: $10,000.00 and Cost Basis: $7,500.00
      expect(find.text('\$10000.00'), findsOneWidget);
      expect(find.textContaining('Cost Basis: \$7500.00'), findsOneWidget);

      // 3. Unrealized P/L is displayed with gain (+33.33%)
      expect(find.textContaining('33.33%'), findsWidgets);
      expect(find.textContaining('+\$2500.00'), findsWidgets);

      // 4. Non-market asset (BOND) is NOT requested for quote
      expect(mockRepo.quoteCalls, contains('stock-1'));
      expect(mockRepo.quoteCalls, isNot(contains('bond-1')));
    });

    testWidgets('displays holding details, price per unit, value, P/L, and cached indicator', (tester) async {
      final stockHolding = TreasuryInvestment(
        id: 'stock-1',
        companyId: 'test-comp-1',
        assetType: AssetType.stock,
        name: 'Apple Inc.',
        ticker: 'AAPL',
        units: 10.0,
        purchasePrice: 150.0,
        totalInvested: 1500.0,
        currency: TreasuryCurrency.usd,
        investmentDate: DateTime(2026, 1, 15),
      );

      mockRepo.investmentsToReturn = [stockHolding];
      mockRepo.quotesToReturn['stock-1'] = MarketQuote(
        investmentId: 'stock-1',
        companyId: 'test-comp-1',
        name: 'Apple Inc.',
        assetType: 'STOCK',
        ticker: 'AAPL',
        price: 180.0,
        currency: 'USD',
        units: 10.0,
        currentValue: 1800.0,
        totalInvested: 1500.0,
        cached: true,
        cacheStatus: 'HIT',
        source: 'CACHE',
        ageSeconds: 45,
        isRealTime: false,
        retrievedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TreasuryScreen(
            treasuryRepository: mockRepo,
            companyRepository: mockCompanyRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Holding displays ticker pill
      expect(find.text('AAPL'), findsOneWidget);

      // Displays quantity & purchase price: 10.0 units @ $150.00
      expect(find.textContaining('10.0 units @ \$150.00'), findsOneWidget);

      // Displays current market price and holding value
      expect(find.text('Market: \$180.00'), findsOneWidget);
      expect(find.text('Value: \$1800.00'), findsOneWidget);

      // Displays unrealized P/L: +$300.00 (20.00%)
      expect(find.text('+\$300.00 (20.00%)'), findsWidgets);

      // Displays cache indicator with 15m delay tag
      expect(find.text('Cached (45s ago • 15m delay)'), findsOneWidget);
    });

    testWidgets('displays Stale Quote warning when quote is marked stale', (tester) async {
      final etfHolding = TreasuryInvestment(
        id: 'etf-1',
        companyId: 'test-comp-1',
        assetType: AssetType.etf,
        name: 'S&P 500 ETF',
        ticker: 'SPY',
        units: 20.0,
        purchasePrice: 500.0,
        totalInvested: 10000.0,
        currency: TreasuryCurrency.usd,
        investmentDate: DateTime(2026, 1, 15),
      );

      mockRepo.investmentsToReturn = [etfHolding];
      mockRepo.quotesToReturn['etf-1'] = MarketQuote(
        investmentId: 'etf-1',
        companyId: 'test-comp-1',
        name: 'S&P 500 ETF',
        assetType: 'ETF',
        ticker: 'SPY',
        price: 510.0,
        currency: 'USD',
        units: 20.0,
        currentValue: 10200.0,
        totalInvested: 10000.0,
        cached: true,
        cacheStatus: 'STALE',
        source: 'STALE',
        isStale: true, // STALE QUOTE
        ageSeconds: 950,
        isRealTime: false,
        retrievedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TreasuryScreen(
            treasuryRepository: mockRepo,
            companyRepository: mockCompanyRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Displays Stale Quote warning chip
      expect(find.text('Stale Quote (Provider Error)'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('displays error state and allows user to retry quote fetch', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final cryptoHolding = TreasuryInvestment(
        id: 'crypto-1',
        companyId: 'test-comp-1',
        assetType: AssetType.crypto,
        name: 'Bitcoin Holding',
        ticker: 'BTC/USD',
        units: 0.5,
        purchasePrice: 60000.0,
        totalInvested: 30000.0,
        currency: TreasuryCurrency.usd,
        investmentDate: DateTime(2026, 1, 15),
      );

      mockRepo.investmentsToReturn = [cryptoHolding];
      mockRepo.quoteErrorsToThrow['crypto-1'] = ServerException('Rate limit exceeded (8 calls/min)');

      await tester.pumpWidget(
        MaterialApp(
          home: TreasuryScreen(
            treasuryRepository: mockRepo,
            companyRepository: mockCompanyRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Displays error message and Retry button
      expect(find.text('Rate limit exceeded (8 calls/min)'), findsOneWidget);
      final retryButton = find.widgetWithText(TextButton, 'Retry');
      expect(retryButton, findsOneWidget);

      // Clear error and provide quote for retry
      mockRepo.quoteErrorsToThrow.remove('crypto-1');
      mockRepo.quotesToReturn['crypto-1'] = MarketQuote(
        investmentId: 'crypto-1',
        companyId: 'test-comp-1',
        name: 'Bitcoin Holding',
        assetType: 'CRYPTO',
        ticker: 'BTC/USD',
        price: 68000.0,
        currency: 'USD',
        units: 0.5,
        currentValue: 34000.0,
        totalInvested: 30000.0,
        retrievedAt: DateTime.now(),
      );

      await tester.tap(retryButton);
      await tester.pumpAndSettle();

      // Verify retry succeeded and displayed new value
      expect(find.text('Rate limit exceeded (8 calls/min)'), findsNothing);
      expect(find.text('Market: \$68000.00'), findsOneWidget);
      expect(find.text('Value: \$34000.00'), findsOneWidget);
    });

    testWidgets('guards against missing quantity and missing ticker', (tester) async {
      final missingTickerHolding = TreasuryInvestment(
        id: 'stock-no-ticker',
        companyId: 'test-comp-1',
        assetType: AssetType.stock,
        name: 'Unlisted Startup Stock',
        ticker: '', // MISSING TICKER
        units: 100.0,
        purchasePrice: 10.0,
        totalInvested: 1000.0,
        currency: TreasuryCurrency.usd,
        investmentDate: DateTime(2026, 1, 15),
      );

      final missingUnitsHolding = TreasuryInvestment(
        id: 'stock-no-units',
        companyId: 'test-comp-1',
        assetType: AssetType.stock,
        name: 'Legacy Stock Holding',
        ticker: 'GOOGL',
        units: null, // MISSING UNITS
        purchasePrice: 150.0,
        totalInvested: 1500.0,
        currency: TreasuryCurrency.usd,
        investmentDate: DateTime(2026, 1, 15),
      );

      mockRepo.investmentsToReturn = [missingTickerHolding, missingUnitsHolding];

      await tester.pumpWidget(
        MaterialApp(
          home: TreasuryScreen(
            treasuryRepository: mockRepo,
            companyRepository: mockCompanyRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check missing ticker message
      expect(find.text('Missing ticker symbol. Edit investment to enable live quotes.'), findsOneWidget);

      // Check missing quantity message
      expect(find.text('Quantity missing. Edit investment to enable valuation.'), findsOneWidget);
    });

    testWidgets('guards against currency mismatch between quote and investment', (tester) async {
      final eurHolding = TreasuryInvestment(
        id: 'eur-stock',
        companyId: 'test-comp-1',
        assetType: AssetType.stock,
        name: 'Euro Stock Holding',
        ticker: 'SAP',
        units: 20.0,
        purchasePrice: 150.0,
        totalInvested: 3000.0,
        currency: TreasuryCurrency.eur, // EUR currency
        investmentDate: DateTime(2026, 1, 15),
      );

      mockRepo.investmentsToReturn = [eurHolding];
      mockRepo.quotesToReturn['eur-stock'] = MarketQuote(
        investmentId: 'eur-stock',
        companyId: 'test-comp-1',
        name: 'Euro Stock Holding',
        assetType: 'STOCK',
        ticker: 'SAP',
        price: 175.0,
        currency: 'USD', // Quote returned in USD (mismatch)
        units: 20.0,
        totalInvested: 3000.0,
        retrievedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TreasuryScreen(
            treasuryRepository: mockRepo,
            companyRepository: mockCompanyRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Warns user of currency mismatch without computing distorted P/L
      expect(find.text('Currency mismatch: Quote is in USD, but holding is in EUR.'), findsOneWidget);
    });

    testWidgets('allows manual quote refresh on holding', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final stockHolding = TreasuryInvestment(
        id: 'stock-refresh',
        companyId: 'test-comp-1',
        assetType: AssetType.stock,
        name: 'Microsoft Corp',
        ticker: 'MSFT',
        units: 10.0,
        purchasePrice: 400.0,
        totalInvested: 4000.0,
        currency: TreasuryCurrency.usd,
        investmentDate: DateTime(2026, 1, 15),
      );

      mockRepo.investmentsToReturn = [stockHolding];
      mockRepo.quotesToReturn['stock-refresh'] = MarketQuote(
        investmentId: 'stock-refresh',
        companyId: 'test-comp-1',
        name: 'Microsoft Corp',
        assetType: 'STOCK',
        ticker: 'MSFT',
        price: 420.0,
        currency: 'USD',
        units: 10.0,
        currentValue: 4200.0,
        totalInvested: 4000.0,
        cached: true,
        cacheStatus: 'HIT',
        source: 'CACHE',
        ageSeconds: 120,
        isRealTime: false,
        retrievedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TreasuryScreen(
            treasuryRepository: mockRepo,
            companyRepository: mockCompanyRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(mockRepo.quoteCalls.length, 1);
      expect(mockRepo.forceRefreshCalls.last, false);

      // Tap manual refresh icon button
      final refreshButton = find.byTooltip('Refresh quote');
      expect(refreshButton, findsOneWidget);
      await tester.tap(refreshButton);
      await tester.pumpAndSettle();

      // Assert second call requested with forceRefresh: true
      expect(mockRepo.quoteCalls.length, 2);
      expect(mockRepo.forceRefreshCalls.last, true);
    });
  });
}
