import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../domain/models/burn_trend.dart';
import '../../domain/repositories/dashboard_repository_interface.dart';

class DashboardRepository implements IDashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<BurnTrendResponse> getBurnTrend(String companyId, {int months = 6}) async {
    try {
      final response = await _apiClient.get(
        '/dashboard/company/$companyId/burn-trend',
        queryParameters: {'months': months},
      );
      final map = _extractMap(response);
      return BurnTrendResponse.fromJson(map);
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
}
