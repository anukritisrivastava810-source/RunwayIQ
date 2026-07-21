import companyService from '../services/company.service.js';

/**
 * CompanyController
 * 
 * Handles incoming HTTP requests for Company operations,
 * routes them to the CompanyService, and formats the HTTP responses.
 */
class CompanyController {
  
  /**
   * Helper method to handle errors and send appropriate HTTP responses
   * @private
   */
  _handleError(res, error) {
    const message = error.message || 'Internal Server Error';
    let statusCode = 500;
    
    if (message.includes('required') || message.includes('already exists')) {
      statusCode = 400;
    } else if (message.includes('not found')) {
      statusCode = 404;
    }

    return res.status(statusCode).json({
      success: false,
      message
    });
  }

  /**
   * Create a new company
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  createCompany = async (req, res) => {
    try {
      const company = await companyService.createCompany(req.body);
      return res.status(201).json(company);
    } catch (error) {
      return this._handleError(res, error);
    }
  }

  /**
   * Get a company by ID
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  getCompanyById = async (req, res) => {
    try {
      const { id } = req.params;
      const company = await companyService.getCompanyById(id);
      return res.status(200).json(company);
    } catch (error) {
      return this._handleError(res, error);
    }
  }

  /**
   * Get a company by name
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  getCompanyByName = async (req, res) => {
    try {
      const { name } = req.params;
      const company = await companyService.getCompanyByName(name);
      return res.status(200).json(company);
    } catch (error) {
      return this._handleError(res, error);
    }
  }

  /**
   * Get all companies
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  getAllCompanies = async (req, res) => {
    try {
      const companies = await companyService.getAllCompanies();
      return res.status(200).json(companies);
    } catch (error) {
      return this._handleError(res, error);
    }
  }

  /**
   * Update a company
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  updateCompany = async (req, res) => {
    try {
      const { id } = req.params;
      const updatedCompany = await companyService.updateCompany(id, req.body);
      return res.status(200).json(updatedCompany);
    } catch (error) {
      return this._handleError(res, error);
    }
  }

  /**
   * Delete a company
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  deleteCompany = async (req, res) => {
    try {
      const { id } = req.params;
      const result = await companyService.deleteCompany(id);
      return res.status(200).json(result);
    } catch (error) {
      return this._handleError(res, error);
    }
  }
}

// Export a singleton instance
export default new CompanyController();
