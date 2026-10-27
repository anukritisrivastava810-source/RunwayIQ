import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../domain/models/scenario.dart';
import '../../domain/repositories/scenario_repository_interface.dart';

class ScenarioRepository implements IScenarioRepository {
  final ApiClient _apiClient;

  ScenarioRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<List<Scenario>> getScenariosByCompany(String companyId) async {
    try {
      final response = await _apiClient.get('/scenarios/company/$companyId');
      final list = _extractList(response);
      return list
          .map((item) => Scenario.fromJson(item as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<Scenario> createScenario(Scenario scenario) async {
    try {
      final response =
          await _apiClient.post('/scenarios', data: scenario.toJson());
      final map = _extractMap(response);
      return Scenario.fromJson(map);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<Scenario> updateScenario(String id, Scenario scenario) async {
    try {
      final response =
          await _apiClient.put('/scenarios/$id', data: scenario.toJson());
      final map = _extractMap(response);
      return Scenario.fromJson(map);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<void> deleteScenario(String id) async {
    try {
      await _apiClient.delete('/scenarios/$id');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<SimulationResult> simulate({
    String? companyId,
    String? scenarioId,
    double additionalBurn = 0,
    double additionalRevenue = 0,
    double additionalCash = 0,
  }) async {
    try {
      final body = <String, dynamic>{
        'additionalBurn': additionalBurn,
        'additionalRevenue': additionalRevenue,
        'additionalCash': additionalCash,
      };
      if (companyId != null) body['companyId'] = companyId;
      if (scenarioId != null) body['scenarioId'] = scenarioId;
      final response = await _apiClient.post('/scenarios/simulate', data: body);
      final map = _extractMap(response);
      return SimulationResult.fromJson(map);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  Map<String, dynamic> _extractMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      if (response.containsKey('data') &&
          response['data'] is Map<String, dynamic>) {
        return response['data'] as Map<String, dynamic>;
      }
      return response;
    }
    throw UnknownException('Unexpected response format: Expected JSON Map');
  }

  List<dynamic> _extractList(dynamic response) {
    if (response is List) {
      return response;
    }
    if (response is Map<String, dynamic> &&
        response.containsKey('data')) {
      if (response['data'] is List) {
        return response['data'] as List;
      }
      if (response['data'] == null) {
        return [];
      }
    }
    throw UnknownException('Unexpected response format: Expected JSON List');
  }
}
