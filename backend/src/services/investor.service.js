import { InvestorRepository } from '../repositories/investor.repository.js';

const repository = new InvestorRepository();

export class InvestorService {
  async createInvestor(data) {
    // TODO: Add business logic here
    return await repository.create(data);
  }

  async getInvestorById(id) {
    return await repository.findById(id);
  }

  async getAllInvestors(skip, take) {
    return await repository.findAll(skip, take);
  }

  async updateInvestor(id, data) {
    return await repository.update(id, data);
  }

  async deleteInvestor(id) {
    return await repository.delete(id);
  }

  async getByCompany(companyId) {
    return await repository.findByCompany(companyId);
  }
}
