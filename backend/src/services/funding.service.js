import fundingRepository from '../repositories/funding.repository.js';
import companyRepository from '../repositories/company.repository.js';
import prisma from '../config/prisma.js';

/**
 * FundingService
 * 
 * Handles business logic, validation, and orchestrates repository calls 
 * for the FundingRound entity.
 */
class FundingService {
  /**
   * Create a new funding round
   * @param {Object} fundingData - Data for the new funding round
   * @returns {Promise<Object>} The created funding round
   */
  async createFunding(fundingData) {
    const { companyId, investorId, roundType, amountRaised, closedAt } = fundingData;
    
    if (!companyId || !investorId || !roundType || amountRaised === undefined || !closedAt) {
      throw new Error('companyId, investorId, roundType, amountRaised, and closedAt are required fields');
    }

    // Verify Company exists
    const company = await companyRepository.findById(companyId);
    if (!company) {
      throw new Error('Company not found');
    }

    // Verify Investor exists
    const investor = await prisma.investor.findUnique({
      where: { id: investorId }
    });
    if (!investor) {
      throw new Error('Investor not found');
    }

    const data = { ...fundingData };
    if (data.closedAt) {
      const parsedDate = new Date(data.closedAt);
      if (isNaN(parsedDate.getTime())) {
        throw new Error('Invalid value for closedAt');
      }
      data.closedAt = parsedDate;
    }

    return await fundingRepository.create(data);
  }

  /**
   * Get a funding round by ID
   * @param {string} id - The UUID of the funding round
   * @returns {Promise<Object>} The funding round object
   */
  async getFundingById(id) {
    const fundingRound = await fundingRepository.findById(id);
    if (!fundingRound) {
      throw new Error('Funding round not found');
    }
    return fundingRound;
  }

  /**
   * Get all funding rounds
   * @returns {Promise<Array>} Array of all funding rounds
   */
  async getAllFundings() {
    return await fundingRepository.findAll();
  }

  /**
   * Get all funding rounds by company ID
   * @param {string} companyId - The UUID of the company
   * @returns {Promise<Array>} Array of funding rounds
   */
  async getFundingByCompanyId(companyId) {
    const company = await companyRepository.findById(companyId);
    if (!company) {
      throw new Error('Company not found');
    }
    return await fundingRepository.findByCompanyId(companyId);
  }

  /**
   * Update a funding round by ID
   * @param {string} id - The UUID of the funding round
   * @param {Object} updateData - Data to update
   * @returns {Promise<Object>} The updated funding round object
   */
  async updateFunding(id, updateData) {
    const existingFunding = await fundingRepository.findById(id);
    if (!existingFunding) {
      throw new Error('Funding round not found');
    }

    if (updateData.companyId && updateData.companyId !== existingFunding.companyId) {
      const company = await companyRepository.findById(updateData.companyId);
      if (!company) {
        throw new Error('Company not found');
      }
    }

    if (updateData.investorId && updateData.investorId !== existingFunding.investorId) {
      const investor = await prisma.investor.findUnique({
        where: { id: updateData.investorId }
      });
      if (!investor) {
        throw new Error('Investor not found');
      }
    }

    const data = { ...updateData };
    if (data.closedAt !== undefined && data.closedAt !== null) {
      const parsedDate = new Date(data.closedAt);
      if (isNaN(parsedDate.getTime())) {
        throw new Error('Invalid value for closedAt');
      }
      data.closedAt = parsedDate;
    }

    return await fundingRepository.update(id, data);
  }

  /**
   * Delete a funding round by ID
   * @param {string} id - The UUID of the funding round
   * @returns {Promise<Object>} Success confirmation object
   */
  async deleteFunding(id) {
    const existingFunding = await fundingRepository.findById(id);
    if (!existingFunding) {
      throw new Error('Funding round not found');
    }

    await fundingRepository.delete(id);

    return {
      success: true,
      message: 'Funding round deleted successfully'
    };
  }
}

// Export a singleton instance
export default new FundingService();
