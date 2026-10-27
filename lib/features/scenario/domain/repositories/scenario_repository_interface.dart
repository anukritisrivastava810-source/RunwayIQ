import '../models/scenario.dart';

abstract class IScenarioRepository {
  Future<List<Scenario>> getScenariosByCompany(String companyId);
  Future<Scenario> createScenario(Scenario scenario);
  Future<Scenario> updateScenario(String id, Scenario scenario);
  Future<void> deleteScenario(String id);
  Future<SimulationResult> simulate({
    String? companyId,
    String? scenarioId,
    double additionalBurn = 0,
    double additionalRevenue = 0,
    double additionalCash = 0,
  });
}
