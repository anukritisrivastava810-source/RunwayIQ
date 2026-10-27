import prisma from '../config/prisma.js';

/**
 * EmployeeRepository
 * 
 * Responsible ONLY for database access related to the Employee model.
 * Contains no business logic or validations.
 */
export class EmployeeRepository {
  /**
   * Create a new employee
   * @param {Object} employeeData - The data to create an employee
   * @returns {Promise<Object>} The created employee object
   */
  async createEmployee(employeeData) {
    return await prisma.employee.create({
      data: employeeData,
      include: { department: true },
    });
  }

  create(employeeData) {
    return this.createEmployee(employeeData);
  }

  /**
   * Find an employee by ID
   * @param {string} id - The UUID of the employee
   * @returns {Promise<Object|null>} The employee object or null
   */
  async getEmployeeById(id) {
    return await prisma.employee.findUnique({
      where: { id },
      include: { department: true },
    });
  }

  findById(id) {
    return this.getEmployeeById(id);
  }

  /**
   * Find an employee by email
   * @param {string} email - The email of the employee
   * @returns {Promise<Object|null>} The employee object or null
   */
  async findByEmail(email) {
    return await prisma.employee.findUnique({
      where: { email },
      include: { department: true },
    });
  }

  /**
   * Get all employees
   * @param {number} [skip] - Number of records to skip
   * @param {number} [take] - Number of records to take
   * @returns {Promise<Array>} Array of employee objects
   */
  async getAllEmployees(skip, take) {
    const query = {
      include: { department: true },
      orderBy: { createdAt: 'desc' },
    };
    if (skip !== undefined && !isNaN(skip)) query.skip = skip;
    if (take !== undefined && !isNaN(take)) query.take = take;
    return await prisma.employee.findMany(query);
  }

  findAll(skip, take) {
    return this.getAllEmployees(skip, take);
  }

  /**
   * Get all employees for a company
   * @param {string} companyId - The UUID of the company
   * @returns {Promise<Array>} Array of employee objects
   */
  async getEmployeesByCompany(companyId) {
    return await prisma.employee.findMany({
      where: { companyId },
      include: { department: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  findByCompany(companyId) {
    return this.getEmployeesByCompany(companyId);
  }

  findByCompanyId(companyId) {
    return this.getEmployeesByCompany(companyId);
  }

  /**
   * Update an employee by ID
   * @param {string} id - The UUID of the employee to update
   * @param {Object} updateData - The data to update
   * @returns {Promise<Object>} The updated employee object
   */
  async updateEmployee(id, updateData) {
    return await prisma.employee.update({
      where: { id },
      data: updateData,
      include: { department: true },
    });
  }

  update(id, updateData) {
    return this.updateEmployee(id, updateData);
  }

  /**
   * Delete an employee by ID
   * @param {string} id - The UUID of the employee to delete
   * @returns {Promise<Object>} The deleted employee object
   */
  async deleteEmployee(id) {
    return await prisma.employee.delete({
      where: { id },
    });
  }

  delete(id) {
    return this.deleteEmployee(id);
  }
}

const employeeRepository = new EmployeeRepository();
export default employeeRepository;
