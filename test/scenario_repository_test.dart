import 'package:flutter_test/flutter_test.dart';
import 'package:runway_iq/core/network/api_client.dart';
import 'package:runway_iq/core/network/api_exceptions.dart';
import 'package:runway_iq/features/scenario/data/repositories/scenario_repository.dart';
import 'package:runway_iq/features/scenario/domain/models/scenario.dart';

// ── Mock API client ────────────────────────────────────────────────────────────

class MockScenarioApiClient extends ApiClient {
  final Map<String, dynamic> responses = {};
  final Map<String, ApiException> errors = {};

  @override
  Future<dynamic> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    if (errors.containsKey(path)) throw errors[path]!;
    if (responses.containsKey(path)) return responses[path];
    return {'data': []};
  }

  @override
  Future<dynamic> post(String path,
      {dynamic data, Map<String, dynamic>? queryParameters}) async {
    if (errors.containsKey('POST:$path')) throw errors['POST:$path']!;
    if (responses.containsKey('POST:$path')) return responses['POST:$path'];
    return {'data': null};
  }

  @override
  Future<dynamic> put(String path,
      {dynamic data, Map<String, dynamic>? queryParameters}) async {
    if (errors.containsKey('PUT:$path')) throw errors['PUT:$path']!;
    if (responses.containsKey('PUT:$path')) return responses['PUT:$path'];
    return {'data': null};
  }

  @override
  Future<dynamic> delete(String path,
      {dynamic data, Map<String, dynamic>? queryParameters}) async {
    if (errors.containsKey('DELETE:$path')) throw errors['DELETE:$path']!;
    if (responses.containsKey('DELETE:$path')) return responses['DELETE:$path'];
    return {'data': null, 'message': 'Scenario deleted successfully'};
  }
}

// ── Test helpers ──────────────────────────────────────────────────────────────

Map<String, dynamic> _scenarioJson({
  String id = 's-1',
  String companyId = 'co-1',
  String name = 'Test Scenario',
}) =>
    {
      'id': id,
      'companyId': companyId,
      'name': name,
      'description': 'A sample scenario',
      'baseCash': '300000.00',
      'baseMonthlyBurn': '30000.00',
      'baseMonthlyRevenue': '0.00',
      'baseRunwayMonths': '10.00',
      'additionalBurn': '5000.00',
      'additionalRevenue': '2000.00',
      'additionalCash': '0.00',
      'simulatedRunway': null,
      'currency': 'USD',
      'isActive': true,
      'createdAt': '2026-01-01T00:00:00.000Z',
      'updatedAt': '2026-01-01T00:00:00.000Z',
    };

Map<String, dynamic> _simulateResponse({
  double? simulatedRunway = 8.5,
  double simulatedBurn = 33000.0,
  double simulatedCash = 302000.0,
  double? baseRunway = 10.0,
  double baseBurn = 30000.0,
  double baseCash = 300000.0,
  String companyId = 'co-1',
}) =>
    {
      'data': {
        'companyId': companyId,
        'scenarioId': null,
        'scenarioName': null,
        'baseline': {
          'cash': baseCash,
          'burn': baseBurn,
          'runway': baseRunway,
        },
        'simulated': {
          'cash': simulatedCash,
          'burn': simulatedBurn,
          'runway': simulatedRunway,
        },
        'adjustments': {
          'additionalBurn': 5000.0,
          'additionalRevenue': 2000.0,
          'additionalCash': 0.0,
        },
      }
    };

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late MockScenarioApiClient mockClient;
  late ScenarioRepository repo;

  setUp(() {
    mockClient = MockScenarioApiClient();
    repo = ScenarioRepository(apiClient: mockClient);
  });

  // ── Scenario model parsing ──────────────────────────────────────────────────
  group('Scenario.fromJson and toJson', () {
    test('parses decimal strings from Prisma schema correctly', () {
      final s = Scenario.fromJson(_scenarioJson());
      expect(s.id, 's-1');
      expect(s.baseCash, 300000.0);
      expect(s.baseMonthlyBurn, 30000.0);
      expect(s.additionalBurn, 5000.0);
      expect(s.additionalRevenue, 2000.0);
      expect(s.additionalCash, 0.0);
      expect(s.simulatedRunway, isNull);
      expect(s.currency, 'USD');
      expect(s.isActive, isTrue);
    });

    test('handles null simulatedRunway', () {
      final json = _scenarioJson();
      json['simulatedRunway'] = null;
      final s = Scenario.fromJson(json);
      expect(s.simulatedRunway, isNull);
    });

    test('handles numeric simulatedRunway', () {
      final json = _scenarioJson();
      json['simulatedRunway'] = 12.5;
      final s = Scenario.fromJson(json);
      expect(s.simulatedRunway, 12.5);
    });

    test('toJson serializes correctly', () {
      final s = Scenario(
        id: 's-1',
        companyId: 'co-1',
        name: 'New Scenario',
        baseCash: 100000,
        baseMonthlyBurn: 10000,
        additionalBurn: 2000,
      );
      final json = s.toJson();
      expect(json['id'], 's-1');
      expect(json['companyId'], 'co-1');
      expect(json['name'], 'New Scenario');
      expect(json['baseCash'], 100000.0);
      expect(json['additionalBurn'], 2000.0);
    });
  });

  // ── SimulationResult parsing ────────────────────────────────────────────────
  group('SimulationResult.fromJson', () {
    test('parses standard response with finite baseline and simulated runway', () {
      final data = _simulateResponse()['data'] as Map<String, dynamic>;
      final result = SimulationResult.fromJson(data);
      expect(result.companyId, 'co-1');
      expect(result.baseline.cash, 300000.0);
      expect(result.baseline.burn, 30000.0);
      expect(result.baseline.runway, 10.0);
      expect(result.simulated.cash, 302000.0);
      expect(result.simulated.burn, 33000.0);
      expect(result.simulated.runway, 8.5);
      expect(result.adjustments.additionalBurn, 5000.0);
    });

    test('null simulated runway indicates unlimited runway (zero or negative burn)', () {
      final data = _simulateResponse(
        simulatedRunway: null,
        simulatedBurn: -5000.0,
      )['data'] as Map<String, dynamic>;
      final result = SimulationResult.fromJson(data);
      expect(result.simulated.runway, isNull);
      expect(result.simulated.burn, -5000.0);
    });

    test('zero simulated runway indicates depleted cash (cash <= 0)', () {
      final data = _simulateResponse(
        simulatedRunway: 0.0,
        simulatedCash: -1000.0,
      )['data'] as Map<String, dynamic>;
      final result = SimulationResult.fromJson(data);
      expect(result.simulated.runway, 0.0);
      expect(result.simulated.cash, -1000.0);
    });
  });

  // ── Repository: getScenariosByCompany ──────────────────────────────────────
  group('ScenarioRepository.getScenariosByCompany', () {
    test('returns list of scenarios for valid company', () async {
      mockClient.responses['/scenarios/company/co-1'] = {
        'data': [_scenarioJson()]
      };
      final scenarios = await repo.getScenariosByCompany('co-1');
      expect(scenarios.length, 1);
      expect(scenarios.first.name, 'Test Scenario');
      expect(scenarios.first.companyId, 'co-1');
    });

    test('returns empty list when company has no scenarios', () async {
      mockClient.responses['/scenarios/company/co-1'] = {'data': []};
      final scenarios = await repo.getScenariosByCompany('co-1');
      expect(scenarios, isEmpty);
    });

    test('rethrows NotFoundException for nonexistent company', () async {
      mockClient.errors['/scenarios/company/bad-id'] =
          NotFoundException('Company not found');
      expect(
        () => repo.getScenariosByCompany('bad-id'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('rethrows UnauthorizedException on 401 missing or invalid token', () async {
      mockClient.errors['/scenarios/company/co-1'] =
          UnauthorizedException('Unauthorized');
      expect(
        () => repo.getScenariosByCompany('co-1'),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('ensures company-scoped isolation (403 for unauthorized company)', () async {
      mockClient.errors['/scenarios/company/other-co'] =
          UnauthorizedException('Forbidden: You do not have access to this company');
      expect(
        () => repo.getScenariosByCompany('other-co'),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });

  // ── Repository: createScenario ─────────────────────────────────────────────
  group('ScenarioRepository.createScenario', () {
    test('creates and returns scenario with correct companyId', () async {
      mockClient.responses['POST:/scenarios'] = {'data': _scenarioJson()};
      final scenario = Scenario(
        companyId: 'co-1',
        name: 'Test Scenario',
        baseCash: 300000,
        baseMonthlyBurn: 30000,
        baseMonthlyRevenue: 0,
        baseRunwayMonths: 10,
        additionalBurn: 5000,
        additionalRevenue: 2000,
        additionalCash: 0,
      );
      final created = await repo.createScenario(scenario);
      expect(created.id, 's-1');
      expect(created.name, 'Test Scenario');
      expect(created.companyId, 'co-1');
    });

    test('rethrows ValidationException on invalid input', () async {
      mockClient.errors['POST:/scenarios'] =
          ValidationException('Name is required');
      final scenario = Scenario(companyId: 'co-1', name: '');
      expect(
        () => repo.createScenario(scenario),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  // ── Repository: updateScenario ─────────────────────────────────────────────
  group('ScenarioRepository.updateScenario', () {
    test('updates and returns scenario', () async {
      mockClient.responses['PUT:/scenarios/s-1'] = {
        'data': _scenarioJson(name: 'Updated Scenario Name')
      };
      final scenario = Scenario(
        companyId: 'co-1',
        name: 'Updated Scenario Name',
        id: 's-1',
      );
      final updated = await repo.updateScenario('s-1', scenario);
      expect(updated.name, 'Updated Scenario Name');
    });

    test('rethrows NotFoundException when scenario does not exist', () async {
      mockClient.errors['PUT:/scenarios/missing-id'] =
          NotFoundException('Scenario not found');
      final scenario = Scenario(companyId: 'co-1', name: 'X', id: 'missing-id');
      expect(
        () => repo.updateScenario('missing-id', scenario),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  // ── Repository: deleteScenario ─────────────────────────────────────────────
  group('ScenarioRepository.deleteScenario', () {
    test('deletes scenario successfully', () async {
      await expectLater(repo.deleteScenario('s-1'), completes);
    });

    test('rethrows NotFoundException when deleting nonexistent scenario', () async {
      mockClient.errors['DELETE:/scenarios/bad-id'] =
          NotFoundException('Not found');
      expect(
        () => repo.deleteScenario('bad-id'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  // ── Repository: simulate ───────────────────────────────────────────────────
  group('ScenarioRepository.simulate', () {
    test('returns SimulationResult with finite simulated runway', () async {
      mockClient.responses['POST:/scenarios/simulate'] =
          _simulateResponse(simulatedRunway: 8.5);
      final result = await repo.simulate(
        companyId: 'co-1',
        additionalBurn: 5000,
        additionalRevenue: 2000,
      );
      expect(result.simulated.runway, 8.5);
      expect(result.baseline.cash, 300000.0);
    });

    test('preserves null runway when backend returns null (unlimited runway)', () async {
      mockClient.responses['POST:/scenarios/simulate'] =
          _simulateResponse(simulatedRunway: null, simulatedBurn: 0.0);
      final result = await repo.simulate(companyId: 'co-1');
      expect(result.simulated.runway, isNull);
    });

    test('handles zero runway for depleted cash safely', () async {
      mockClient.responses['POST:/scenarios/simulate'] =
          _simulateResponse(simulatedRunway: 0.0, simulatedCash: 0.0);
      final result = await repo.simulate(companyId: 'co-1');
      expect(result.simulated.runway, 0.0);
    });

    test('rethrows NotFoundException on invalid company ID', () async {
      mockClient.errors['POST:/scenarios/simulate'] =
          NotFoundException('Company not found');
      expect(
        () => repo.simulate(companyId: 'nonexistent-co'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('rethrows UnauthorizedException on missing token', () async {
      mockClient.errors['POST:/scenarios/simulate'] =
          UnauthorizedException('Unauthorized');
      expect(
        () => repo.simulate(companyId: 'co-1'),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('rethrows ValidationException on invalid adjustment inputs', () async {
      mockClient.errors['POST:/scenarios/simulate'] =
          ValidationException('Invalid adjustment values: numbers expected');
      expect(
        () => repo.simulate(companyId: 'co-1'),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
