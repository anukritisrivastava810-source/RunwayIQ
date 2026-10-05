import '../models/department.dart';

abstract class IDepartmentRepository {
  Future<Department> createDepartment(Department department);
  Future<List<Department>> getAllDepartments();
  Future<Department> getDepartmentById(String id);
  Future<List<Department>> getDepartmentsByCompany(String companyId);
  Future<Department> updateDepartment(String id, Department department);
  Future<void> deleteDepartment(String id);
}
