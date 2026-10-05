import prisma from '../config/prisma.js';

/**
 * FundingRepository
 * 
 * Responsible ONLY for database access related to the FundingRound model.
 * Contains no business logic or validations.
 */
class FundingRepository {
  /**
   * Create a new funding round
   * @param {Object} fundingData - The data to create a funding round
   * @returns {Promise<Object>} The created funding round object
   */
  async create(fundingData) {
    return await prisma.fundingRound.create({
      data: fundingData,
    });
  }

  /**
   * Find a funding round by its ID
   * @param {string} id - The UUID of the funding round
   * @returns {Promise<Object|null>} The funding round object or null if not found
   */
  async findById(id) {
    return await prisma.fundingRound.findUnique({
      where: { id },
    });
  }

  /**
   * Get all funding rounds
   * @returns {Promise<Array>} Array of funding round objects
   */
  async findAll() {
    return await prisma.fundingRound.findMany();
  }

  /**
   * Find funding rounds by company ID
   * @param {string} companyId - The UUID of the company
   * @returns {Promise<Array>} Array of funding round objects
   */
  async findByCompanyId(companyId) {
    return await prisma.fundingRound.findMany({
      where: { companyId },
    });
  }

  /**
   * Update a funding round by its ID
   * @param {string} id - The UUID of the funding round to update
   * @param {Object} updateData - The data to update
   * @returns {Promise<Object>} The updated funding round object
   */
  async update(id, updateData) {
    return await prisma.fundingRound.update({
      where: { id },
      data: updateData
    });
  }

  /**
   * Delete a funding round by its ID
   * @param {string} id - The UUID of the funding round to delete
   * @returns {Promise<Object>} The deleted funding round object
   */
  async delete(id) {
    return await prisma.fundingRound.delete({
      where: { id },
    });
  }
}

// Export a singleton instance
export default new FundingRepository();
