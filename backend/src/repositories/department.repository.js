import prisma from '../config/prisma.js';

export class DepartmentRepository {
  async create(data) {
    return await prisma.department.create({ data });
  }

  async findById(id) {
    return await prisma.department.findUnique({ where: { id } });
  }

  async findAll(skip, take) {
    return await prisma.department.findMany({ skip, take });
  }

  async update(id, data) {
    return await prisma.department.update({
      where: { id },
      data,
    });
  }

  async delete(id) {
    return await prisma.department.delete({ where: { id } });
  }

  async findByCompany(companyId) {
    return await prisma.department.findMany({ where: { companyId } });
  }
}
