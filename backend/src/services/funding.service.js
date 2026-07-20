import { FundingRepository } from '../repositories/funding.repository.js';

const repository = new FundingRepository();

export class FundingService {
  async createFunding(data) {
    // TODO: Add business logic here
    return await repository.create(data);
  }

  async getFundingById(id) {
    return await repository.findById(id);
  }

  async getAllFundings(skip, take) {
    return await repository.findAll(skip, take);
  }

  async updateFunding(id, data) {
    return await repository.update(id, data);
  }

  async deleteFunding(id) {
    return await repository.delete(id);
  }

  async getByCompany(companyId) {
    return await repository.findByCompany(companyId);
  }
}
