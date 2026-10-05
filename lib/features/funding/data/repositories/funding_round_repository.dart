import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../domain/models/funding_round.dart';
import '../../domain/repositories/funding_round_repository_interface.dart';

class FundingRoundRepository implements IFundingRoundRepository {
  final ApiClient _apiClient;

  FundingRoundRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<FundingRound> createFundingRound(FundingRound fundingRound) async {
    try {
      final response = await _apiClient.post('/funding', data: fundingRound.toJson());
      final map = _extractMap(response);
      return FundingRound.fromJson(map);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<List<FundingRound>> getAllFundingRounds() async {
    try {
      final response = await _apiClient.get('/funding');
      final list = _extractList(response);
      return list
          .map((item) => FundingRound.fromJson(item as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<FundingRound> getFundingRoundById(String id) async {
    try {
      final response = await _apiClient.get('/funding/$id');
      final map = _extractMap(response);
      return FundingRound.fromJson(map);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<List<FundingRound>> getFundingRoundsByCompany(String companyId) async {
    try {
      final response = await _apiClient.get('/funding/company/$companyId');
      final list = _extractList(response);
      return list
          .map((item) => FundingRound.fromJson(item as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<FundingRound> updateFundingRound(String id, FundingRound fundingRound) async {
    try {
      final response = await _apiClient.put('/funding/$id', data: fundingRound.toJson());
      final map = _extractMap(response);
      return FundingRound.fromJson(map);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<void> deleteFundingRound(String id) async {
    try {
      await _apiClient.delete('/funding/$id');
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
