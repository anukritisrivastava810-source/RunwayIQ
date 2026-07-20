import prisma from '../config/prisma.js';

export class CompanyRepository {
  async create(data) {
    return await prisma.company.create({ data });
  }

  async findById(id) {
    return await prisma.company.findUnique({ where: { id } });
  }

  async findAll(skip, take) {
    return await prisma.company.findMany({ skip, take });
  }

  async update(id, data) {
    return await prisma.company.update({
      where: { id },
      data,
    });
  }

  async delete(id) {
    return await prisma.company.delete({ where: { id } });
  }

  async findByCompany(companyId) {
    return await prisma.company.findMany({ where: { companyId } });
  }
}
