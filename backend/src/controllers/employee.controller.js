import employeeService from '../services/employee.service.js';

/**
 * EmployeeController
 * 
 * Handles incoming HTTP requests for Employee operations,
 * routes them to the EmployeeService, and formats the HTTP responses.
 */
class EmployeeController {
  
  /**
   * Helper method to handle errors and send appropriate HTTP responses
   * @private
   */
  _handleError(res, error) {
    let message = error.message || 'Internal Server Error';
    let statusCode = 500;
    
    if (error.code === 'P2002') {
      statusCode = 400;
      message = 'Employee with this unique field already exists';
    } else if (error.code === 'P2025') {
      statusCode = 404;
      message = 'Employee not found';
    } else if (message.includes('required') || message.includes('Invalid') || message.includes('already exists')) {
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
   * Create a new employee
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  createEmployee = async (req, res) => {
    try {
      const employee = await employeeService.createEmployee(req.body);
      return res.status(201).json(employee);
    } catch (error) {
      return this._handleError(res, error);
    }
  }

  /**
   * Get an employee by ID
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  getEmployeeById = async (req, res) => {
    try {
      const { id } = req.params;
      const employee = await employeeService.getEmployeeById(id);
      return res.status(200).json(employee);
    } catch (error) {
      return this._handleError(res, error);
    }
  }

  /**
   * Get all employees (optionally filtered by companyId in query)
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  getAllEmployees = async (req, res) => {
    try {
      const { skip, take, companyId } = req.query;
      if (companyId) {
        const employees = await employeeService.getEmployeesByCompany(companyId);
        return res.status(200).json(employees);
      }
      const employees = await employeeService.getAllEmployees(
        skip !== undefined ? Number(skip) : undefined,
        take !== undefined ? Number(take) : undefined
      );
      return res.status(200).json(employees);
    } catch (error) {
      return this._handleError(res, error);
    }
  }

  /**
   * Get all employees by company ID
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  getEmployeesByCompanyId = async (req, res) => {
    try {
      const { companyId } = req.params;
      const employees = await employeeService.getEmployeesByCompany(companyId);
      return res.status(200).json(employees);
    } catch (error) {
      return this._handleError(res, error);
    }
  }

  /**
   * Update an employee
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  updateEmployee = async (req, res) => {
    try {
      const { id } = req.params;
      const updatedEmployee = await employeeService.updateEmployee(id, req.body);
      return res.status(200).json(updatedEmployee);
    } catch (error) {
      return this._handleError(res, error);
    }
  }

  /**
   * Delete an employee
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   */
  deleteEmployee = async (req, res) => {
    try {
      const { id } = req.params;
      const result = await employeeService.deleteEmployee(id);
      return res.status(200).json(result);
    } catch (error) {
      return this._handleError(res, error);
    }
  }
}

const employeeController = new EmployeeController();

// Export singleton instance as default
export default employeeController;

// Named exports for compatibility
export const createEmployee = employeeController.createEmployee;
export const getEmployeeById = employeeController.getEmployeeById;
export const getAllEmployees = employeeController.getAllEmployees;
export const getEmployees = employeeController.getAllEmployees;
export const getEmployeesByCompanyId = employeeController.getEmployeesByCompanyId;
export const updateEmployee = employeeController.updateEmployee;
export const deleteEmployee = employeeController.deleteEmployee;
export { EmployeeController };
