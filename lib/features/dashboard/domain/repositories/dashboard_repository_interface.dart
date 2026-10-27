import '../models/burn_trend.dart';

abstract class IDashboardRepository {
  Future<BurnTrendResponse> getBurnTrend(String companyId, {int months = 6});
}
