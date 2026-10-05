import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../domain/models/treasury_investment.dart';
import '../../domain/repositories/treasury_repository_interface.dart';

class TreasuryRepository implements ITreasuryRepository {
  final ApiClient _apiClient;

  TreasuryRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<TreasuryInvestment> createTreasuryInvestment(TreasuryInvestment investment) async {
    try {
      final response = await _apiClient.post('/treasury', data: investment.toJson());
      final map = _extractMap(response);
      return TreasuryInvestment.fromJson(map);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<List<TreasuryInvestment>> getAllTreasuryInvestments() async {
    try {
      final response = await _apiClient.get('/treasury');
      final list = _extractList(response);
      return list
          .map((item) => TreasuryInvestment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<TreasuryInvestment> getTreasuryInvestmentById(String id) async {
    try {
      final response = await _apiClient.get('/treasury/$id');
      final map = _extractMap(response);
      return TreasuryInvestment.fromJson(map);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<List<TreasuryInvestment>> getTreasuryInvestmentsByCompany(String companyId) async {
    try {
      final response = await _apiClient.get('/treasury/company/$companyId');
      final list = _extractList(response);
      return list
          .map((item) => TreasuryInvestment.fromJson(item as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<TreasuryInvestment> updateTreasuryInvestment(String id, TreasuryInvestment investment) async {
    try {
      final response = await _apiClient.put('/treasury/$id', data: investment.toJson());
      final map = _extractMap(response);
      return TreasuryInvestment.fromJson(map);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<void> deleteTreasuryInvestment(String id) async {
    try {
      await _apiClient.delete('/treasury/$id');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  Map<String, dynamic> _extractMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      if (response.containsKey('data') && response['data'] is Map<String, dynamic>) {
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
        response.containsKey('data') &&
        response['data'] is List) {
      return response['data'] as List;
    }
    throw UnknownException('Unexpected response format: Expected JSON List');
  }
}
