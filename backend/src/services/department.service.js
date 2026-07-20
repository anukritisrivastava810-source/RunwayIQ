import { DepartmentRepository } from '../repositories/department.repository.js';

const repository = new DepartmentRepository();

export class DepartmentService {
  async createDepartment(data) {
    // TODO: Add business logic here
    return await repository.create(data);
  }

  async getDepartmentById(id) {
    return await repository.findById(id);
  }

  async getAllDepartments(skip, take) {
    return await repository.findAll(skip, take);
  }

  async updateDepartment(id, data) {
    return await repository.update(id, data);
  }

  async deleteDepartment(id) {
    return await repository.delete(id);
  }

  async getByCompany(companyId) {
    return await repository.findByCompany(companyId);
  }
}
