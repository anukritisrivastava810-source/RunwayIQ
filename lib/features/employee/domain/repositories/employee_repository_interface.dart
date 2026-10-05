import '../models/employee.dart';

abstract class IEmployeeRepository {
  Future<Employee> createEmployee(Employee employee);
  Future<List<Employee>> getAllEmployees();
  Future<Employee> getEmployeeById(String id);
  Future<List<Employee>> getEmployeesByCompany(String companyId);
  Future<Employee> updateEmployee(String id, Employee employee);
  Future<void> deleteEmployee(String id);
}
