import { CompanyRepository } from '../repositories/company.repository.js';

const repository = new CompanyRepository();

export class CompanyService {
  async createCompany(data) {
    // TODO: Add business logic here
    return await repository.create(data);
  }

  async getCompanyById(id) {
    return await repository.findById(id);
  }

  async getAllCompanys(skip, take) {
    return await repository.findAll(skip, take);
  }

  async updateCompany(id, data) {
    return await repository.update(id, data);
  }

  async deleteCompany(id) {
    return await repository.delete(id);
  }

  async getByCompany(companyId) {
    return await repository.findByCompany(companyId);
  }
}
