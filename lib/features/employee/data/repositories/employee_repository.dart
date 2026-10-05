import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../domain/models/employee.dart';
import '../../domain/repositories/employee_repository_interface.dart';

class EmployeeRepository implements IEmployeeRepository {
  final ApiClient _apiClient;

  EmployeeRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<Employee> createEmployee(Employee employee) async {
    try {
      final response = await _apiClient.post('/employees', data: employee.toJson());
      final map = _extractMap(response);
      return Employee.fromJson(map);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<List<Employee>> getAllEmployees() async {
    try {
      final response = await _apiClient.get('/employees');
      final list = _extractList(response);
      return list
          .map((item) => Employee.fromJson(item as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<Employee> getEmployeeById(String id) async {
    try {
      final response = await _apiClient.get('/employees/$id');
      final map = _extractMap(response);
      return Employee.fromJson(map);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<List<Employee>> getEmployeesByCompany(String companyId) async {
    try {
      final response = await _apiClient.get('/employees/company/$companyId');
      final list = _extractList(response);
      return list
          .map((item) => Employee.fromJson(item as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<Employee> updateEmployee(String id, Employee employee) async {
    try {
      final response = await _apiClient.put('/employees/$id', data: employee.toJson());
      final map = _extractMap(response);
      return Employee.fromJson(map);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<void> deleteEmployee(String id) async {
    try {
      await _apiClient.delete('/employees/$id');
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
