import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../domain/models/investor.dart';
import '../../domain/repositories/investor_repository_interface.dart';

class InvestorRepository implements IInvestorRepository {
  final ApiClient _apiClient;

  InvestorRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<Investor> createInvestor(Investor investor) async {
    try {
      final response = await _apiClient.post('/investor', data: investor.toJson());
      final map = _extractMap(response);
      return Investor.fromJson(map);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<List<Investor>> getInvestorsByCompany(String companyId) async {
    try {
      final response = await _apiClient.get('/investor', queryParameters: {'companyId': companyId});
      final list = _extractList(response);
      return list
          .map((item) => Investor.fromJson(item as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<Investor> getInvestorById(String id) async {
    try {
      final response = await _apiClient.get('/investor/$id');
      final map = _extractMap(response);
      return Investor.fromJson(map);
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
