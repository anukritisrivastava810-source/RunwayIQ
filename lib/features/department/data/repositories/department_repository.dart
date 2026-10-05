import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../domain/models/department.dart';
import '../../domain/repositories/department_repository_interface.dart';

class DepartmentRepository implements IDepartmentRepository {
  final ApiClient _apiClient;

  DepartmentRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<Department> createDepartment(Department department) async {
    try {
      final response = await _apiClient.post('/departments', data: department.toJson());
      final map = _extractMap(response);
      return Department.fromJson(map);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<List<Department>> getAllDepartments() async {
    try {
      final response = await _apiClient.get('/departments');
      final list = _extractList(response);
      return list
          .map((item) => Department.fromJson(item as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<Department> getDepartmentById(String id) async {
    try {
      final response = await _apiClient.get('/departments/$id');
      final map = _extractMap(response);
      return Department.fromJson(map);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<List<Department>> getDepartmentsByCompany(String companyId) async {
    try {
      final response = await _apiClient.get('/departments/company/$companyId');
      final list = _extractList(response);
      return list
          .map((item) => Department.fromJson(item as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<Department> updateDepartment(String id, Department department) async {
    try {
      final response = await _apiClient.put('/departments/$id', data: department.toJson());
      final map = _extractMap(response);
      return Department.fromJson(map);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  @override
  Future<void> deleteDepartment(String id) async {
    try {
      await _apiClient.delete('/departments/$id');
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
