import { EmployeeRepository } from '../repositories/employee.repository.js';

const repository = new EmployeeRepository();

export class EmployeeService {
  async createEmployee(data) {
    // TODO: Add business logic here
    return await repository.create(data);
  }

  async getEmployeeById(id) {
    return await repository.findById(id);
  }

  async getAllEmployees(skip, take) {
    return await repository.findAll(skip, take);
  }

  async updateEmployee(id, data) {
    return await repository.update(id, data);
  }

  async deleteEmployee(id) {
    return await repository.delete(id);
  }

  async getByCompany(companyId) {
    return await repository.findByCompany(companyId);
  }
}
