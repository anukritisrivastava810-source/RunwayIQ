import companyRepository from '../repositories/company.repository.js';

/**
 * CompanyService
 * 
 * Handles business logic, validation, and orchestrates repository calls 
 * for the Company entity.
 */
class CompanyService {
  /**
   * Create a new company
   * @param {Object} companyData - Data for the new company
   * @returns {Promise<Object>} The created company
   */
  async createCompany(companyData) {
    if (!companyData.name) {
      throw new Error('Company name is required');
    }

    const existingCompany = await companyRepository.findByName(companyData.name);
    if (existingCompany) {
      throw new Error('Company with this name already exists');
    }

    return await companyRepository.create(companyData);
  }

  /**
   * Get a company by ID
   * @param {string} id - The UUID of the company
   * @returns {Promise<Object>} The company object
   */
  async getCompanyById(id) {
    const company = await companyRepository.findById(id);
    if (!company) {
      throw new Error('Company not found');
    }
    return company;
  }

  /**
   * Get a company by name
   * @param {string} name - The name of the company
   * @returns {Promise<Object>} The company object
   */
  async getCompanyByName(name) {
    const company = await companyRepository.findByName(name);
    if (!company) {
      throw new Error('Company not found');
    }
    return company;
  }

  /**
   * Get all companies
   * @returns {Promise<Array>} Array of all companies
   */
  async getAllCompanies() {
    return await companyRepository.findAll();
  }

  /**
   * Update a company by ID
   * @param {string} id - The UUID of the company
   * @param {Object} updateData - Data to update
   * @returns {Promise<Object>} The updated company object
   */
  async updateCompany(id, updateData) {
    const existingCompany = await companyRepository.findById(id);
    if (!existingCompany) {
      throw new Error('Company not found');
    }

    if (updateData.name && updateData.name !== existingCompany.name) {
      const nameTaken = await companyRepository.findByName(updateData.name);
      if (nameTaken) {
        throw new Error('Company with this name already exists');
      }
    }

    return await companyRepository.update(id, updateData);
  }

  /**
   * Delete a company by ID
   * @param {string} id - The UUID of the company
   * @returns {Promise<Object>} Success confirmation object
   */
  async deleteCompany(id) {
    const existingCompany = await companyRepository.findById(id);
    if (!existingCompany) {
      throw new Error('Company not found');
    }

    await companyRepository.delete(id);

    return {
      success: true,
      message: 'Company deleted successfully'
    };
  }
}

// Export a singleton instance
export default new CompanyService();
