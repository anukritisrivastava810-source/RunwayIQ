import employeeRepository, { EmployeeRepository } from '../repositories/employee.repository.js';
import companyRepository from '../repositories/company.repository.js';
import prisma from '../config/prisma.js';

/**
 * EmployeeService
 * 
 * Handles business logic, validation, and orchestrates repository calls
 * for the Employee entity.
 */
export class EmployeeService {
  constructor(repository = employeeRepository) {
    this.repository = repository;
  }

  /**
   * Create a new employee
   * @param {Object} employeeData - Data for the new employee
   * @returns {Promise<Object>} The created employee
   */
  async createEmployee(employeeData) {
    const { companyId, firstName, lastName, email, role, annualSalary } = employeeData;

    if (!companyId || !firstName || !lastName || !email || !role || annualSalary === undefined || annualSalary === null) {
      throw new Error('companyId, firstName, lastName, email, role, and annualSalary are required fields');
    }

    // Verify Company exists
    const company = await companyRepository.findById(companyId);
    if (!company) {
      throw new Error('Company not found');
    }

    // Verify Email is unique
    const existingEmployee = await this.repository.findByEmail(email);
    if (existingEmployee) {
      throw new Error('Employee with this email already exists');
    }

    const data = { ...employeeData };

    // Validate or assign departmentId
    if (data.departmentId) {
      const department = await prisma.department.findUnique({
        where: { id: data.departmentId }
      });
      if (!department) {
        throw new Error('Department not found');
      }
    } else {
      // Find existing department or create a default "General" department for the company
      let defaultDept = await prisma.department.findFirst({
        where: { companyId }
      });
      if (!defaultDept) {
        defaultDept = await prisma.department.create({
          data: {
            companyId,
            name: 'General',
          }
        });
      }
      data.departmentId = defaultDept.id;
    }

    // Validate & parse annualSalary
    const numSalary = Number(data.annualSalary);
    if (isNaN(numSalary) || numSalary < 0) {
      throw new Error('Invalid annualSalary');
    }
    data.annualSalary = numSalary;

    // Validate & parse dates
    if (data.joinedAt) {
      const parsedDate = new Date(data.joinedAt);
      if (isNaN(parsedDate.getTime())) {
        throw new Error('Invalid value for joinedAt');
      }
      data.joinedAt = parsedDate;
    } else {
      data.joinedAt = new Date();
    }

    if (data.exitedAt) {
      const parsedDate = new Date(data.exitedAt);
      if (isNaN(parsedDate.getTime())) {
        throw new Error('Invalid value for exitedAt');
      }
      data.exitedAt = parsedDate;
    }

    return await this.repository.createEmployee(data);
  }

  /**
   * Get an employee by ID
   * @param {string} id - The UUID of the employee
   * @returns {Promise<Object>} The employee object
   */
  async getEmployeeById(id) {
    const employee = await this.repository.getEmployeeById(id);
    if (!employee) {
      throw new Error('Employee not found');
    }
    return employee;
  }

  /**
   * Get all employees
   * @param {number} [skip] - Pagination skip
   * @param {number} [take] - Pagination take
   * @returns {Promise<Array>} Array of all employees
   */
  async getAllEmployees(skip, take) {
    return await this.repository.getAllEmployees(skip, take);
  }

  /**
   * Get all employees for a company
   * @param {string} companyId - The UUID of the company
   * @returns {Promise<Array>} Array of employees
   */
  async getEmployeesByCompany(companyId) {
    const company = await companyRepository.findById(companyId);
    if (!company) {
      throw new Error('Company not found');
    }
    return await this.repository.getEmployeesByCompany(companyId);
  }

  getEmployeesByCompanyId(companyId) {
    return this.getEmployeesByCompany(companyId);
  }

  getByCompany(companyId) {
    return this.getEmployeesByCompany(companyId);
  }

  /**
   * Update an employee by ID
   * @param {string} id - The UUID of the employee
   * @param {Object} updateData - Data to update
   * @returns {Promise<Object>} The updated employee
   */
  async updateEmployee(id, updateData) {
    const existingEmployee = await this.repository.getEmployeeById(id);
    if (!existingEmployee) {
      throw new Error('Employee not found');
    }

    if (updateData.companyId && updateData.companyId !== existingEmployee.companyId) {
      const company = await companyRepository.findById(updateData.companyId);
      if (!company) {
        throw new Error('Company not found');
      }
    }

    if (updateData.departmentId && updateData.departmentId !== existingEmployee.departmentId) {
      const department = await prisma.department.findUnique({
        where: { id: updateData.departmentId }
      });
      if (!department) {
        throw new Error('Department not found');
      }
    }

    if (updateData.email && updateData.email !== existingEmployee.email) {
      const emailTaken = await this.repository.findByEmail(updateData.email);
      if (emailTaken && emailTaken.id !== id) {
        throw new Error('Employee with this email already exists');
      }
    }

    const data = { ...updateData };

    if (data.annualSalary !== undefined && data.annualSalary !== null) {
      const numSalary = Number(data.annualSalary);
      if (isNaN(numSalary) || numSalary < 0) {
        throw new Error('Invalid annualSalary');
      }
      data.annualSalary = numSalary;
    }

    if (data.joinedAt !== undefined && data.joinedAt !== null) {
      const parsedDate = new Date(data.joinedAt);
      if (isNaN(parsedDate.getTime())) {
        throw new Error('Invalid value for joinedAt');
      }
      data.joinedAt = parsedDate;
    }

    if (data.exitedAt !== undefined && data.exitedAt !== null) {
      const parsedDate = new Date(data.exitedAt);
      if (isNaN(parsedDate.getTime())) {
        throw new Error('Invalid value for exitedAt');
      }
      data.exitedAt = parsedDate;
    }

    return await this.repository.updateEmployee(id, data);
  }

  /**
   * Delete an employee by ID
   * @param {string} id - The UUID of the employee
   * @returns {Promise<Object>} Confirmation message
   */
  async deleteEmployee(id) {
    const existingEmployee = await this.repository.getEmployeeById(id);
    if (!existingEmployee) {
      throw new Error('Employee not found');
    }

    await this.repository.deleteEmployee(id);

    return {
      success: true,
      message: 'Employee deleted successfully'
    };
  }
}

const employeeService = new EmployeeService();
export default employeeService;
