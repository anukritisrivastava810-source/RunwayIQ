import prisma from '../config/prisma.js';

/**
 * CompanyRepository
 * 
 * Responsible ONLY for database access related to the Company model.
 * Contains no business logic or validations.
 */
class CompanyRepository {
  /**
   * Create a new company
   * @param {Object} companyData - The data to create a company
   * @returns {Promise<Object>} The created company object
   */
  async create(companyData) {
    return await prisma.company.create({
      data: companyData,
    });
  }

  /**
   * Find a company by its ID
   * @param {string} id - The UUID of the company
   * @returns {Promise<Object|null>} The company object or null if not found
   */
  async findById(id) {
    return await prisma.company.findUnique({
      where: { id },
    });
  }

  /**
   * Find a company by its name
   * @param {string} name - The name of the company
   * @returns {Promise<Object|null>} The company object or null if not found
   */
  async findByName(name) {
    return await prisma.company.findFirst({
      where: { name },
    });
  }

  /**
   * Get all companies
   * @returns {Promise<Array>} Array of company objects
   */
  async findAll() {
    return await prisma.company.findMany();
  }

  /**
   * Update a company by its ID
   * @param {string} id - The UUID of the company to update
   * @param {Object} updateData - The data to update
   * @returns {Promise<Object>} The updated company object
   */
  async update(id, updateData) {
    return await prisma.company.update({
      where: { id },
      data: updateData,
    });
  }

  /**
   * Delete a company by its ID
   * @param {string} id - The UUID of the company to delete
   * @returns {Promise<Object>} The deleted company object
   */
  async delete(id) {
    return await prisma.company.delete({
      where: { id },
    });
  }
}

// Export a singleton instance
export default new CompanyRepository();
