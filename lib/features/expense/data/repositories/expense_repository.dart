import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../domain/models/expense.dart';
import '../../domain/repositories/expense_repository_interface.dart';

class ExpenseRepository implements IExpenseRepository {
  final ApiClient _apiClient;

  ExpenseRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<Expense> createExpense(Expense expense) async {
    try {
      final response = await _apiClient.post('/expenses', data: expense.toJson());
      final map = _extractMap(response);
      return Expense.fromJson(map);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<List<Expense>> getAllExpenses() async {
    try {
      final response = await _apiClient.get('/expenses');
      final list = _extractList(response);
      return list
          .map((item) => Expense.fromJson(item as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<Expense> getExpenseById(String id) async {
    try {
      final response = await _apiClient.get('/expenses/$id');
      final map = _extractMap(response);
      return Expense.fromJson(map);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<List<Expense>> getExpensesByCompany(String companyId) async {
    try {
      final response = await _apiClient.get('/expenses/company/$companyId');
      final list = _extractList(response);
      return list
          .map((item) => Expense.fromJson(item as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<Expense> updateExpense(String id, Expense expense) async {
    try {
      final response = await _apiClient.put('/expenses/$id', data: expense.toJson());
      final map = _extractMap(response);
      return Expense.fromJson(map);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    try {
      await _apiClient.delete('/expenses/$id');
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
