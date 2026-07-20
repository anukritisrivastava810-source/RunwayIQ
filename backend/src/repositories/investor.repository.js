import prisma from '../config/prisma.js';

export class InvestorRepository {
  async create(data) {
    return await prisma.investor.create({ data });
  }

  async findById(id) {
    return await prisma.investor.findUnique({ where: { id } });
  }

  async findAll(skip, take) {
    return await prisma.investor.findMany({ skip, take });
  }

  async update(id, data) {
    return await prisma.investor.update({
      where: { id },
      data,
    });
  }

  async delete(id) {
    return await prisma.investor.delete({ where: { id } });
  }

  async findByCompany(companyId) {
    return await prisma.investor.findMany({ where: { companyId } });
  }
}
