import fundingService from '../services/funding.service.js';

/**
 * FundingController
 * 
 * Handles incoming HTTP requests for Funding operations,
 * routes them to the FundingService, and formats the HTTP responses.
 */
class FundingController {
  
  /**
   * Helper method to handle errors and send appropriate HTTP responses
   * @private
   */
  _handleError(res, error) {
    const message = error.message || 'Internal Server Error';
    let statusCode = 500;
    
    if (message.includes('required') || message.includes('Invalid')) {
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
   * Create a new funding round
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  createFunding = async (req, res) => {
    try {
      const fundingRound = await fundingService.createFunding(req.body);
      return res.status(201).json(fundingRound);
    } catch (error) {
      return this._handleError(res, error);
    }
  }

  /**
   * Get a funding round by ID
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  getFundingById = async (req, res) => {
    try {
      const { id } = req.params;
      const fundingRound = await fundingService.getFundingById(id);
      return res.status(200).json(fundingRound);
    } catch (error) {
      return this._handleError(res, error);
    }
  }

  /**
   * Get all funding rounds
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  getAllFundings = async (req, res) => {
    try {
      const fundingRounds = await fundingService.getAllFundings();
      return res.status(200).json(fundingRounds);
    } catch (error) {
      return this._handleError(res, error);
    }
  }

  /**
   * Get all funding rounds by company ID
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  getFundingByCompanyId = async (req, res) => {
    try {
      const { companyId } = req.params;
      const fundingRounds = await fundingService.getFundingByCompanyId(companyId);
      return res.status(200).json(fundingRounds);
    } catch (error) {
      return this._handleError(res, error);
    }
  }

  /**
   * Update a funding round
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  updateFunding = async (req, res) => {
    try {
      const { id } = req.params;
      const updatedFundingRound = await fundingService.updateFunding(id, req.body);
      return res.status(200).json(updatedFundingRound);
    } catch (error) {
      return this._handleError(res, error);
    }
  }

  /**
   * Delete a funding round
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  deleteFunding = async (req, res) => {
    try {
      const { id } = req.params;
      const result = await fundingService.deleteFunding(id);
      return res.status(200).json(result);
    } catch (error) {
      return this._handleError(res, error);
    }
  }
}

// Export a singleton instance
export default new FundingController();
