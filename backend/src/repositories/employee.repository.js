import prisma from '../config/prisma.js';

export class EmployeeRepository {
  async create(data) {
    return await prisma.employee.create({ data });
  }

  async findById(id) {
    return await prisma.employee.findUnique({ where: { id } });
  }

  async findAll(skip, take) {
    return await prisma.employee.findMany({ skip, take });
  }

  async update(id, data) {
    return await prisma.employee.update({
      where: { id },
      data,
    });
  }

  async delete(id) {
    return await prisma.employee.delete({ where: { id } });
  }

  async findByCompany(companyId) {
    return await prisma.employee.findMany({ where: { companyId } });
  }
}
